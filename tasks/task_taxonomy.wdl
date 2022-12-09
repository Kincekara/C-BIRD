version 1.0

task taxon {
  input {
    File read1
    File read2
    File kraken2_db
    File? enterobacter_db
    File? citrobacter_db
    String samplename
    String docker = "kincekara/kraken-bracken:k2.1.2-b2.8"
    Int bracken_read_len = 100
    Int bracken_threshold = 10
    String min_hit_groups = 3
    Float confidence = 0.05
    Int memory = 32
    Int cpu = 4
    String? bracken_version = "Bracken 2.8"
    String? kraken2_db_version = "Standard-8 2022-09-26"
  }
  
  command <<<
    # version
    echo $(kraken2 --version 2>&1) | sed 's/^.*Kraken version //;s/ .*$//' | tee KVERSION
    date | tee DATE
    echo ~{kraken2_db_version} > KDBVERSION
    echo ~{bracken_version} > BVERSION
    
    # create db folders
    mkdir db_std
    mkdir db_complex

    # define taxonomy function
    run_taxon () {
      kraken2 \
      --db $db \
      --threads ~{cpu} \
      --report ~{samplename}.kraken.report.txt \
      --gzip-compressed \
      --paired \
      --minimum-hit-groups ~{min_hit_groups} \
      --confidence $confidence \
      --report-minimizer-data \
      ~{read1} ~{read2}

      bracken \
      -d $db \
      -i ~{samplename}.kraken.report.txt \
      -o ~{samplename}.bracken.txt \
      -r ~{bracken_read_len} \
      -l S \
      -t ~{bracken_threshold}  
    }

    # run taxon with standard database
    tar -C ./db_std/ -xzvf ~{kraken2_db}
    confidence=~{confidence}
    db="./db_std/"
    run_taxon

    awk '{print $NF,$0}' ~{samplename}.bracken.txt | sort -nr | cut -f2- -d' ' | awk -F "\t" 'NR==1 {print $1}' > TAXON_STD
    awk '{print $NF,$0}' ~{samplename}.bracken.txt | sort -nr | cut -f2- -d' ' | awk -F "\t" 'NR==1 {printf "%.2f\n", $NF*100}' > RATIO_STD

    # backup results with standard database
    cp ~{samplename}.kraken.report.txt ~{samplename}.kraken.report.std.txt
    cp ~{samplename}.bracken.txt ~{samplename}.bracken.std.txt

    # resolve complex species if exist
    genus=$(awk '{print $NF,$0}' ~{samplename}.bracken.txt | sort -nr | cut -f2- -d' ' | awk 'NR==1 {print $1}')
    confidence=0
    db="./db_complex/"
    
    if [ $genus = "Enterobacter" ] && [ -f "~{enterobacter_db}" ]
    then
      echo "resolving enterobacter complex..."      
      tar -C ./db_complex/ -xzvf ~{enterobacter_db}
      run_taxon  
    elif [ $genus = "Citrobacter" ] && [ -f "~{citrobacter_db}" ]
    then
      echo "resolving citrobacter complex..."
      tar -C ./db_complex/ -xzvf ~{citrobacter_db}
      run_taxon
    fi
    
    # filter report
    awk 'NR==1; NR>1 {if ($NF >= 0.01){print}}' ~{samplename}.bracken.txt > ~{samplename}.bracken.filtered.txt
    awk '{print $NF,$0}' ~{samplename}.bracken.txt | sort -nr | cut -f2- -d' ' | awk -F "\t" 'NR==1 {print $1}' > TAXON_CX
    awk '{print $NF,$0}' ~{samplename}.bracken.txt | sort -nr | cut -f2- -d' ' | awk -F "\t" 'NR==1 {printf "%.2f\n", $NF*100}' > RATIO_CX
    awk '{print $NF,$0}' ~{samplename}.bracken.txt | sort -nr | cut -f2- -d' ' | awk -F "\t" 'NR==1 {print $2}' > ~{samplename}.taxid.txt 

  >>>

  output {
    String kraken2_version = read_string("KVERSION")
    String kraken2_db_version = read_string("KDBVERSION")
    String kraken2_docker = docker
    File kraken2_report = "~{samplename}.kraken.report.std.txt"
    File bracken_report = "~{samplename}.bracken.std.txt"
    File? kraken2_cx_report = "~{samplename}.kraken.report.std.txt"
    File? bracken_cx_report = "~{samplename}.bracken.std.txt"
    File bracken_report_filter = "~{samplename}.bracken.filtered.txt"
    File taxid = "~{samplename}.taxid.txt"
    Float top_taxon_ratio = read_float("RATIO_STD")
    String bracken_taxon = read_string("TAXON_STD")
    Float? top_taxon_cx_ratio = read_float("RATIO_CX")
    String? bracken_cx_taxon = read_string("TAXON_CX")
    String bracken_version = read_string("BVERSION")
    String bracken_docker = docker
  }
  
  runtime {
    docker: "~{docker}"
    memory: "~{memory} GB"
    cpu: cpu
    disks: "local-disk 100 SSD"
    preemptible: 0
  }
}

