version 1.0

task resfinder {
  input {
    File assembly
    File db_resfinder
    String samplename
    String docker = "kincekara/resfinder:4.1.11"
    Float? min_coverage = 0.7
    Float? threshold = 0.9
  }

  command <<<
    # Decompress the Kraken2 database
    mkdir db
    tar -C ./db/ -xzvf ~{db_resfinder} 

    # Run resfinder
    run_resfinder.py \
    --inputfasta ~{assembly} \
    -db_res ./db/ \
    -o ./out \
    -l ~{min_coverage} \
    -t ~{threshold} \
    --acquired
    # rename results
    mv out/ResFinder_results_tab.txt ~{samplename}.amr.tsv
    # version
    run_resfinder.py -v > VERSION
  >>>

  output {
    String resfinder_version = read_string("VERSION")
    String resfinder_docker = docker
    File resfinder_report = "~{samplename}.amr.tsv"
  }
  runtime {
    docker: "~{docker}"
    memory: "8 GB"
    cpu: 4
    disks: "local-disk 50 SSD"
    preemptible: 0
  }
}