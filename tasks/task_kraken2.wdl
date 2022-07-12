version 1.0

task kraken2_pe {
  input {
    File read1
    File read2
    File kraken2_db
    String samplename
    String docker = "quay.io/staphb/kraken2:2.1.2-no-db"

    String? kraken2_args = ""
    String? classified_out = "classified#.fastq"
    String? unclassified_out = "unclassified#.fastq"
    Int? memory = 32
    Int? cpu = 4
  }
  command <<<
    echo $(kraken2 --version 2>&1) | sed 's/^.*Kraken version //;s/ .*$//' | tee VERSION
    date | tee DATE

    # Decompress the Kraken2 database
    mkdir db
    tar -C ./db/ -xzvf ~{kraken2_db} 

    # Run Kraken2
    kraken2 \
        --db ./db/ \
        --threads ~{cpu} \
        --report ~{samplename}.report.txt \
        --gzip-compressed \
        --paired \
        ~{kraken2_args} \
        ~{read1} ~{read2}
    
  >>>
  output {
    String kraken2_version = read_string("VERSION")
    String kraken2_docker = docker
    String analysis_date = read_string("DATE")
    File kraken2_report = "~{samplename}.report.txt"
  }
  runtime {
      docker: "~{docker}"
      memory: "~{memory} GB"
      cpu: cpu
      disks: "local-disk 100 SSD"
      preemptible: 0
  }
}

task rekraken {
  input {
    File seqs   
    File kraken2_db
    String samplename
    String docker = "quay.io/staphb/kraken2:2.1.2-no-db"

    String? kraken2_args = ""
    Int? memory = 32
    Int? cpu = 4
  }
  command <<<
    echo $(kraken2 --version 2>&1) | sed 's/^.*Kraken version //;s/ .*$//' | tee VERSION
    date | tee DATE

    # Decompress the Kraken2 database
    mkdir db
    tar -C ./db/ -xzvf ~{kraken2_db} 

    # Run Kraken2
    kraken2 \
        --db ./db/ \
        --threads ~{cpu} \
        --report ~{samplename}.scaffolds_report.txt \
        ~{seqs} \  
        ~{kraken2_args} 
    >>>

  output {
    String kraken2_version = read_string("VERSION")
    String kraken2_docker = docker
    String analysis_date = read_string("DATE")
    File kraken2_report = "~{samplename}.scaffolds_report.txt"

  }
  runtime {
      docker: "~{docker}"
      memory: "~{memory} GB"
      cpu: cpu
      disks: "local-disk 100 SSD"
      preemptible: 0
  }
}
