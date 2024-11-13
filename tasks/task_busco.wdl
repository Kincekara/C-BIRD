version 1.0

task busco {
  input {
    File assembly   
    String samplename
    String docker = "staphb/busco:5.8.0-prok-bacteria_odb10_2024-01-08"
    Int? memory = 16
    Int? cpu = 4
  }

  command <<<
    busco -v > VERSION

    # Run Busco
    busco \
    -i ~{assembly} \
    -l /busco_downloads/lineages/bacteria_odb10 \
    -o out \
    -m genome \
    --offline

    # extract prodigal results
    cp ./out/prodigal_output/predicted_genes/predicted.faa ./~{samplename}.prodigal.faa
    cp ./out/prodigal_output/predicted_genes/tmp/*_out.log ./~{samplename}.prodigal.gff

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
    File? prodigal_faa = "~{samplename}.prodigal.faa"
    File? prodigal_gff = "~{samplename}.prodigal.gff"
  }
  runtime {
      docker: "~{docker}"
      memory: "~{memory} GB"
      cpu: cpu
      disks: "local-disk 100 SSD"
      preemptible: 0
  }
}