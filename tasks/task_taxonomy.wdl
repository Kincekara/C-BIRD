version 1.0

task taxon {
  input {
    File read1
    File read2
    File kraken2_db
    String samplename
    String docker = "kincekara/kraken-bracken:k2.1.2-b2.7"
    String? level = "S"
    Int? bracken_read_len = 75
    Int? bracken_threshold = 10
    String? kraken_confidence = "0.05"
    Int? memory = 32
    Int? cpu = 4
    String? bracken_version = "Bracken 2.7"
  }
  
  command <<<
    echo $(kraken2 --version 2>&1) | sed 's/^.*Kraken version //;s/ .*$//' | tee KVERSION
    date | tee DATE

    # Decompress the Kraken2 database
    mkdir db
    tar -C ./db/ -xzvf ~{kraken2_db} 

    # Run Kraken2
    kraken2 \
    --db ./db/ \
    --threads ~{cpu} \
    --report ~{samplename}.kraken.report.txt \
    --gzip-compressed \
    --paired \
    --confidence ~{kraken_confidence} \
    ~{read1} ~{read2}
    
    # run bracken
    echo ~{bracken_version} > BVERSION

    bracken \
    -d ./db/ \
    -i ~{samplename}.kraken.report.txt \
    -o ~{samplename}.bracken.txt \
    -r ~{bracken_read_len} \
    -l ~{level} \
    -t ~{bracken_threshold}

    # filter report
    awk 'NR==1; NR>1 {if ($NF >= 0.01){print}}' ~{samplename}.bracken.txt > ~{samplename}.bracken.filtered.txt
    awk 'NR==1; NR>1 {print $0 | "sort -k 7nr"}' ~{samplename}.bracken.txt | awk 'NR==2 {print $1,$2}' > TAXON
  >>>

  output {
    String kraken2_version = read_string("KVERSION")
    String kraken2_docker = docker
    File kraken2_report = "~{samplename}.kraken.report.txt"
    File bracken_report = "~{samplename}.bracken.filtered.txt"
    String bracken_taxon = read_string("TAXON")
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

