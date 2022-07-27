version 1.0

task bracken {
  input {
    File kraken_report
    File kraken2_db
    String samplename
    String? level = "S"
    String docker = "kincekara/bracken:2.7"
    Int? read_len = 75
    Int? threshold = 10
    String? version = "Bracken 2.7"
  }

  command <<<
  # version
    echo ~{version} > VERSION

  # Decompress the Kraken2 database
    mkdir db
    tar -C ./db/ -xzvf ~{kraken2_db} 

  # run bracken
    bracken \
    -d ./db/ \
    -i ~{kraken_report} \
    -o ~{samplename}.bracken.txt \
    -r ~{read_len} \
    -l ~{level} \
    -t ~{threshold}

  # filter report
    awk 'NR==1; NR>1 {if ($NF >= 0.01){print}}' ~{samplename}.bracken.txt > ~{samplename}.bracken.filtered.txt
    awk 'NR==1; NR>1 {print $0 | "sort -k 7nr"}' ~{samplename}.bracken.txt | awk 'NR==2 {print $1,$2}' > TAXON
  >>>

  output {
    File bracken_report = "~{samplename}.bracken.filtered.txt"
    String bracken_taxon = read_string("TAXON")
    String bracken_version = read_string("VERSION")
    String bracken_docker = docker
  }

  runtime {
    docker: "~{docker}"
    memory: "8 GB"
    cpu: 4
    disks: "local-disk 100 SSD"
    preemptible: 0
  }
}