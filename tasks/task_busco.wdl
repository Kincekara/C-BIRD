version 1.0

task busco {
  input {
    File assembly   
    File busco_db
    String samplename
    String docker = "kincekara/busco:5.4.7"
    Int? memory = 16
    Int? cpu = 4
  }

  command <<<
    busco -v > VERSION

    # Decompress the busco database
    mkdir db
    tar -C ./db/ -xzvf ~{busco_db} 

    # Run Busco
    busco \
    -i ~{assembly} \
    -l ./db/bacteria_odb10 \
    -o out \
    -m genome \
    --offline

    # parse results
    cp ./out/short_summary.specific.bacteria_odb10.out.txt ./~{samplename}_busco_results.txt
    cp ./out/short_summary.specific.bacteria_odb10.out.json ./~{samplename}_busco.json

    python3 <<CODE
    import json
    with open("./out/short_summary.specific.bacteria_odb10.out.json") as input:
      data = json.load(input)
    with open("BUSCO_SUM", "w") as summary:
      summary.write(data["results"]["one_line_summary"])
    with open("BUSCO_DB", "w") as db:
      db.write(data["lineage_dataset"]["name"])
    with open("BUSCO_DB_DATE", "w") as date:
      date.write(data["lineage_dataset"]["creation_date"])
    CODE
    >>>

  output {
    String busco_version = read_string("VERSION")
    String busco_docker = docker
    String busco_summary = read_string("BUSCO_SUM")
    String busco_db_name = read_string("BUSCO_DB")
    String busco_db_date = read_string("BUSCO_DB_DATE")
    File busco_report = "~{samplename}_busco_results.txt"
    File busco_json = "~{samplename}_busco.json"
    
  }
  runtime {
      docker: "~{docker}"
      memory: "~{memory} GB"
      cpu: cpu
      disks: "local-disk 100 SSD"
      preemptible: 0
  }
}