version 1.0

task krakenuniq {
  input {
    File kraken_report
    File krakenuniq_db
    String samplename
    String docker = "quay.io/biocontainers/krakenuniq:0.7.3--pl5321h19e8d03_0"
    Int? memory = 16
    Int? cpu = 4
  }

  command <<<
  # Decompress the KrakenUniq database
    mkdir db
    tar -C ./db/ -xzvf ~{krakenuniq_db} 

  # run krakenuniq
    krakenuniq \
    --db ./db \
    --threads ~{cpu} \
    --report-file ~{karken_report} > ~{samplename}.krakenuniq.tsv
  >>>

  output {
    File krakenuniq_report = "~{samplename}.krakenuniq.tsv"
  }

  runtime {
    docker: "~{docker}"
    memory: "~{memory} GB"
    cpu: cpu
    disks: "local-disk 100 SSD"
    preemptible: 0
  }
}