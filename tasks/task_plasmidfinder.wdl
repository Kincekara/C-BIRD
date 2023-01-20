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
    String? db_date = "2022-11-08"
  }

  command <<<
    #version
    echo ~{version} > VERSION
    echo ~{db_date} > PLASMIDFINDER_DB_DATE

    # Decompress the plasmidfinder database
    mkdir db
    tar -C ./db/ -xzvf ~{plasmidfinder_db} 

    # Run plasmidfinder
    plasmidfinder.py \
    -i ~{assembly} \
    -p ./db/ \
    -l ~{min_coverage} \
    -t ~{threshold} \
    -x 

    # parse outputs
    if [ ! -f results_tab.tsv ]; then
      PF="No plasmids detected in database"
    else
      PF="$(tail -n +2 results_tab.tsv | cut -f 2 | sort | uniq -u | paste -s -d, - )"
        if [ "$PF" == "" ]; then
          PF="No plasmids detected in database"
        fi  
    fi
    echo $PF | tee PLASMIDS

    # rename results
    mv results_tab.tsv ~{samplename}.plasmid.tsv
  >>>

  output {
    String plasmidfinder_version = read_string("VERSION")
    String plasmidfinder_db_date = read_string("PLASMIDFINDER_DB_DATE")
    String plasmids = read_string("PLASMIDS")
    File plasmid_report = "~{samplename}.plasmid.tsv"
    String plasmidfinder_docker = docker
  }
  runtime {
    docker: "~{docker}"
    memory: "8 GB"
    cpu: 4
    disks: "local-disk 50 SSD"
    preemptible: 0
  }
}