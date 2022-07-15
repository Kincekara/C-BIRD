version 1.0

task resfinder {
  input {
    File assembly
    File db_resfinder
    String samplename
    String docker = "kincekara/resfinder:latest"
    Float? min_coverage = 0.6
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
    -o out \
    -l ~{min_coverage} \
    -t ~{threshold} \
    --acquired
    # rename results
    mv out/ResFinder_results_tab.txt ~{samplename}.amr.tsv
  >>>

  output {
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