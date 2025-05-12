version 1.0

task assembly_prep {
  input {
    File read1_trimmed
    File read2_trimmed
    String samplename
    Boolean normalization = true
    Int total_reads
    Int norm_target = 100
    Int min_depth = 5
    Int read_threshold = 8000000
    Int memory = 8
    Int cpu = 4
    String docker = "staphb/bbtools:39.23"
  }

  command <<<
    set -euxo pipefail

    # max memory argument    
    memory="-Xmx$((~{memory}-1))g"

    # version control
    bbversion.sh > VERSION
    
    # PhiX cleaning   
    bbduk.sh \
      "$memory" \
      threads=~{cpu} \
      in1=~{read1_trimmed} \
      in2=~{read2_trimmed} \
      out1=~{samplename}_1.clean.fastq.gz \
      out2=~{samplename}_2.clean.fastq.gz \
      outm=~{samplename}.matched_phix.fq \
      ref=/bbmap/resources/phix174_ill.ref.fa.gz \
      k=31 \
      hdist=1 \
      stats=~{samplename}.phix.stats.txt

    grep Matched ~{samplename}.phix.stats.txt | awk '{print $3}' > PHIX_RATIO
    
    # normalization
    if ~{normalization} && [ "~{total_reads}" -gt "~{read_threshold}" ]      
      then
        echo "normalizing reads..."
        bbnorm.sh \
          "$memory" \
          threads=~{cpu} \
          in=~{samplename}_1.clean.fastq.gz \
          in2=~{samplename}_2.clean.fastq.gz \
          out=~{samplename}_1.clean.norm.fastq.gz \
          out2=~{samplename}_2.clean.norm.fastq.gz \
          target=~{norm_target} \
          min=~{min_depth}
      else
        echo "skipping normalization..."
        mv ~{samplename}_1.clean.fastq.gz ~{samplename}_1.clean.norm.fastq.gz
        mv ~{samplename}_2.clean.fastq.gz ~{samplename}_2.clean.norm.fastq.gz
    fi
  >>>
  
  output {
    File read1_clean_norm = "~{samplename}_1.clean.norm.fastq.gz"
    File read2_clean_norm = "~{samplename}_2.clean.norm.fastq.gz"
    File phiX_stats = "~{samplename}.phix.stats.txt"
    String bbtools_docker = docker
    String bbmap_version = read_string("VERSION")
    String phix_ratio = read_string("PHIX_RATIO")
  }

  runtime {
    docker: "~{docker}"
    memory: "~{memory} GB"
    cpu: cpu
    disks: "local-disk 100 SSD"
    preemptible: 0
    maxRetries: 3
  }
}

task insert_size_dist {
  input {
    String samplename
    File reference
    File read1
    File read2
    Int max_reads = 1000000
    Int max_indel = 16000
    Int memory = 8
    String docker = "staphb/bbtools:39.23"
  }

  command <<<
    set -euxo pipefail

    # version control
    bbversion.sh > VERSION

    # map reads and create histogram
    bbmap.sh \
      ref=~{reference} \
      in1=~{read1} \
      in2=~{read2} \
      ihist=~{samplename}.ihist.txt \
      reads=~{max_reads} \
      maxindel=~{max_indel} \
      fast

    #parse histogram file
    sed '6,1006!d' ~{samplename}.ihist.txt > ~{samplename}.hist.txt
    mean=$(awk -F "\t" 'NR==1 {print $2}' ~{samplename}.ihist.txt)
    median=$(awk -F "\t" 'NR==2 {print $2}' ~{samplename}.ihist.txt)
    mode=$(awk -F "\t" 'NR==3 {print $2}' ~{samplename}.ihist.txt)
    stdev=$(awk -F "\t" 'NR==4 {print $2}' ~{samplename}.ihist.txt)
    echo "$median" > MEDIAN

    # create a html plot
    touch ~{samplename}.hist.html
    x=$(awk -vORS=, 'NR>1 {print $1}' "~{samplename}.hist.txt" | sed 's/,$/\n/')
    y=$(awk -vORS=, 'NR>1 {print $2}' "~{samplename}.hist.txt" | sed 's/,$/\n/')

    cat > ~{samplename}.hist.html <<EOF
    <!DOCTYPE html>
    <html lang="en-us">
    <html>
        <head>
            <meta charset="utf-8">
            <title>~{samplename}</title>
            <style>
                h1{
                  font-family: Arial, Helvetica, sans-serif;
                  font-size: 1.5em;
                  text-align: center;
                  color: #1e5c85
                }
                table {
                  border-collapse: collapse;
                  border: none;
                  margin-left: 80px;
                }                
                th, td {
                  text-align: left;
                  padding-left: 10px;
                  padding-right: 10px;
                  padding-top: 2px;
                  padding-bottom: 2px;
                  border: none;
                }
                tr:nth-child(even) {
                  background-color: #f2f2f2;
                }        
                th {
                  background-color: #1e5c85;
                  color: white;                
                }
            </style>
            <script src="https://cdn.plot.ly/plotly-2.16.3.min.js" charset="utf-8"></script>
        </head>
        <body>
            <h1>Estimated insert size distribution</h1>
            <div id="gd"></div>
            <script>
            Plotly.newPlot("gd", /* JSON object */ {
                "data": [{x:[$x],y:[$y]}],
                "layout": {xaxis:{title: "Insert Size"}, yaxis:{title: "Number of Pairs"}, "width": 1000, "height": 600}
            })
            </script>
            <p></p>
            <table>
                <th></th><th></th>
                <tr>
                  <td>Mean</td><td>$mean</td>
                </tr><tr>
                  <td>Median</td><td>$median</td>
                </tr><tr>
                  <td>Mode</td><td>$mode</td>
                </tr><tr>
                  <td>STDev</td><td>$stdev</td>
                </tr>
            </table>          
        </body>
        </html>
    EOF

  >>>

  output {
    String bbmap_version = read_string("VERSION")
    String bbtools_docker = docker
    File insert_size_hist = "~{samplename}.ihist.txt"
    File insert_size_plot = "~{samplename}.hist.html"
    Int median_insert_size = read_int("MEDIAN")
  }

  runtime {
    docker: "~{docker}"
    memory: "~{memory} GB"
    cpu: 4
    disks: "local-disk 100 SSD"
    preemptible: 0
  }
}


