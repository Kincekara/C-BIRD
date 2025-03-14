version 1.0

task ts_mlst {
  meta {
    description: "Torsten Seeman's (TS) automatic MLST calling from assembled contigs"
  }
  input {
    File assembly
    String samplename
    String docker = "staphb/mlst:2.23.0-2024-12-31"
    Int cpu = 2
    Boolean nopath = true
    String? scheme
    Float? minid
    Float? mincov
    Float? minscore
  }
  command <<<
    mlst --version 2>&1 | sed 's/mlst //' | tee VERSION
    
    #create output header
    echo -e "Filename\tPubMLST_Scheme_name\tSequence_Type_(ST)\tAllele_IDs" > ~{samplename}_ts_mlst.tsv
    
    mlst \
      --threads ~{cpu} \
      ~{true="--nopath" false="" nopath} \
      ~{'--scheme ' + scheme} \
      ~{'--minid ' + minid} \
      ~{'--mincov ' + mincov} \
      ~{'--minscore ' + minscore} \
      ~{assembly} \
      >> ~{samplename}_ts_mlst.tsv
      
    # parse ts mlst tsv for relevant outputs
    if [ "$(tail -n +2 ~{samplename}_ts_mlst.tsv | wc -l)" -eq 0 ]; then
      predicted_mlst="No ST predicted"
      pubmlst_scheme="NA"
    else
      pubmlst_scheme="$(cut -f2 ~{samplename}_ts_mlst.tsv | tail -n 1)"
      predicted_mlst="ST$(cut -f3 ~{samplename}_ts_mlst.tsv | tail -n 1)"
        if [ "$pubmlst_scheme" = "-" ]; then
          predicted_mlst="No ST predicted"
          pubmlst_scheme="NA"
        else
          if [ "$predicted_mlst" = "ST-" ]; then
          predicted_mlst="No ST predicted"
          fi
        fi  
    fi
    
    echo "$predicted_mlst" | tee PREDICTED_MLST
    echo "$pubmlst_scheme" | tee PUBMLST_SCHEME
  >>>
  output {
    File ts_mlst_results = "~{samplename}_ts_mlst.tsv"
    String ts_mlst_predicted_st = read_string("PREDICTED_MLST")
    String ts_mlst_pubmlst_scheme = read_string("PUBMLST_SCHEME")
    String ts_mlst_version = read_string("VERSION")
    String ts_mlst_docker = docker
  }
  runtime {
    docker: "~{docker}"
    memory: "2 GB"
    cpu: cpu
    disks: "local-disk 50 SSD"
    preemptible: 0
  }
}