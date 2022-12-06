version 1.0

task insert_size_dist {
  input {
    String samplename
    File reference
    File read1
    File read2
    Int max_reads = 1000000
    Int max_indel = 16000
    Int memory = 8
    String docker = "kincekara/bbduk:38.98"
  }

  command <<<
    # version control
    echo "$(java -ea -Xmx31715m -Xms31715m -cp /bbmap/current/ jgi.BBDuk 2>&1)" | grep version > VERSION
    # map reads and create histogram
    bbmap.sh ref=~{reference} in1=~{read1} in2=~{read2} ihist=~{samplename}.ihist.txt reads=~{max_reads} maxindel=~{max_indel} fast
    #parse histogram file
    awk -F "\t" 'NR==2 {print $2}' ~{samplename}.ihist.txt > MEDIAN
    cat ~{samplename}.ihist.txt | sed '6,1006!d' > ~{samplename}.hist.txt
    # create a html plot
    touch ~{samplename}.hist.html
    x=$(awk -vORS=, 'NR>1 {print $1}' "~{samplename}.hist.txt" | sed 's/,$/\n/')
    y=$(awk -vORS=, 'NR>1 {print $2}' "~{samplename}.hist.txt" | sed 's/,$/\n/')

    cat > ~{samplename}.hist.html << EOF
    <!DOCTYPE html>
    <html>
        <head>
            <title>~{samplename}</title>
            <script src="https://cdn.plot.ly/plotly-2.16.3.min.js"></script>
        </head>
        <body>
            <h1>Estimated insert size distribution</h1>
            <div id="gd"></div>
            <script>
            Plotly.newPlot("gd", /* JSON object */ {
                "data": [{x:[$x],y:[$y]}],
                "layout": { "width": 600, "height": 400}
            })
            </script>
        </body>
        </html>
    EOF

  >>>

  output {
    File insert_size_hist = "~{samplename}.hist.txt"
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



