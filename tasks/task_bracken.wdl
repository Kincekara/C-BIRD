version 1.0

task bracken {
  input {
    File kraken_report
    File kraken2_db
    String samplename
    String? level = "S"
    String docker = "quay.io/biocontainers/bracken:2.7--py39hc16433a_0"
    Int? read_len = 75
    Int? threshold = 10
  }

  command <<<
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
  >>>

  output {
    File bracken_report = "~{samplename}.bracken.txt"
  }

  runtime {
    docker: "~{docker}"
    memory: "8 GB"
    cpu: 4
    disks: "local-disk 100 SSD"
    preemptible: 0
  }
}