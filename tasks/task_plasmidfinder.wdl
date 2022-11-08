version 1.0

task plasmidfinder {
  input {
    File assembly
    File plasmidfinder_db
    String samplename
    String docker = "staphb/plasmidfinder:2.1.6"
    Float? min_coverage = 0.6
    Float? threshold = 0.9
    String? version = "2.1.6"
    String? db_version = "2022-11-08"
  }

  command <<<
    # Decompress the plasmidfinder database
    mkdir db
    tar -C ./db/ -xzvf ~{plasmidfinder_db} 

    # Run resfinder
    plasmidfinder.py \
    -i ~{assembly} \
    -p ./db/ \
    -l ~{min_coverage} \
    -t ~{threshold} \
    -x 
    # rename results
    mv results_tab.tsv ~{samplename}.plasmid.tsv

    #version
    echo ~{version} > VERSION
    echo ~{db_version} > PLASMIDFINDER_DB_VERSION
  >>>

  output {
    String plasmidfinder_version = read_string("VERSION")
    String plasmidfinder_db_version = read_string("PLASMIDFINDER_DB_VERSION")
    String plasmidfinder_docker = docker
    File plasmid_report = "~{samplename}.plasmid.tsv"
  }
  runtime {
    docker: "~{docker}"
    memory: "8 GB"
    cpu: 4
    disks: "local-disk 50 SSD"
    preemptible: 0
  }
}