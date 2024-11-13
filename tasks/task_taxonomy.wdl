version 1.0

task profile {
  input {
    File read1
    File read2
    File kraken2_db
    String samplename
    String docker = "staphb/bracken:2.9"
    Int? bracken_read_len = 100
    Int? bracken_threshold = 10
    String? min_hit_groups = 3
    Int? memory = 32
    Int? cpu = 4
    String? k2_db_version = "Standard-8 2024-01-12"
  }
  
  command <<<
    echo $(kraken2 --version 2>&1) | sed 's/^.*Kraken version //;s/ .*$//' | tee KVERSION
    date | tee DATE
    

    # Decompress the Kraken2 database
    mkdir db
    tar -I pigz -C ./db/ -xvf ~{kraken2_db} 

    # Run Kraken2
    kraken2 \
    --db ./db/ \
    --threads ~{cpu} \
    --report ~{samplename}.kraken.report.txt \
    --gzip-compressed \
    --paired \
    --minimum-hit-groups ~{min_hit_groups} \
    --report-minimizer-data \
    ~{read1} ~{read2}
    
    # run bracken
    bracken -v > BVERSION

    bracken \
    -d ./db/ \
    -i ~{samplename}.kraken.report.txt \
    -o ~{samplename}.bracken.txt \
    -r ~{bracken_read_len} \
    -l S \
    -t ~{bracken_threshold}

    # filter report
    awk 'NR==1; NR>1 {if ($NF >= 0.01){print}}' ~{samplename}.bracken.txt > ~{samplename}.bracken.filtered.txt
    awk '{print $NF,$0}' ~{samplename}.bracken.txt | sort -nr | cut -f2- -d' ' | awk -F "\t" 'NR==1 {print $1}' > TAXON
    awk '{print $NF,$0}' ~{samplename}.bracken.txt | sort -nr | cut -f2- -d' ' | awk -F "\t" 'NR==1 {printf "%.2f\n", $NF*100}' > RATIO
    awk '{print $NF,$0}' ~{samplename}.bracken.txt | sort -nr | cut -f2- -d' ' | awk -F "\t" 'NR==1 {print $2}' > ~{samplename}.taxid.txt 
    awk '{print $NF,$0}' ~{samplename}.bracken.txt | sort -nr | cut -f2- -d' ' | awk 'NR==1 {print $1}' > GENUS

  >>>

  output {
    String kraken2_version = read_string("KVERSION")
    String kraken2_db_version = k2_db_version
    String kraken2_docker = docker
    File kraken2_report = "~{samplename}.kraken.report.txt"
    File bracken_report = "~{samplename}.bracken.txt"
    File bracken_report_filter = "~{samplename}.bracken.filtered.txt"
    File taxid = "~{samplename}.taxid.txt"
    Float top_taxon_ratio = read_float("RATIO")
    String bracken_taxon = read_string("TAXON")
    String bracken_genus = read_string("GENUS")
    String bracken_version = read_string("BVERSION")
    String bracken_docker = docker
  }
  
  runtime {
    docker: "staphb/bracken:2.9"
    memory: "~{memory} GB"
    cpu: cpu
    disks: "local-disk 100 SSD"
    preemptible: 0
  }
}