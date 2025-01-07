version 1.0

task plasmidfinder {
  input {
    File assembly
    String samplename
    String docker = "kincekara/plasmidfinder:2.1.6-db_2023-03-17"
    Float min_coverage = 0.6
    Float threshold = 0.9
    }

  command <<<
    # version
    cp /VERSION .
    cp /DB_DATE .
    
    # Run plasmidfinder
    plasmidfinder.py \
    -i ~{assembly} \
    -p /plasmidfinder_db/ \
    -l ~{min_coverage} \
    -t ~{threshold} \
    -x 

    # parse outputs
    if [ ! -f results_tab.tsv ]; then
      PF="No plasmids detected in database"
    else
      PF="$(tail -n +2 results_tab.tsv | uniq | cut -f 2 | sort | paste -s -d, - )"
        if [ "$PF" == "" ]; then
          PF="No plasmids detected in database"
        fi  
    fi
    echo "$PF" | tee PLASMIDS

    # rename results
    mv results_tab.tsv ~{samplename}.plasmid.tsv
  >>>

  output {
    String plasmidfinder_version = read_string("VERSION")
    String plasmidfinder_db_date = read_string("DB_DATE")
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