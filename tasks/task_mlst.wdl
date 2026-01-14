version 1.0

task ts_mlst {
  meta {
    description: "Torsten Seeman's (TS) automatic MLST calling from assembled contigs"
  }
  input {
    File assembly
    String samplename
    String docker = "staphb/mlst:2.32.2"
    Int cpu = 2
    Boolean nopath = true
    String? scheme
    Float? minid
    Float? mincov
    Float? minscore
  }
  command <<<
    # version
    mlst --version 2>&1 | sed 's/mlst //' | tee VERSION  

    # run    
    mlst \
      --full \
      --threads ~{cpu} \
      ~{true="--nopath" false="" nopath} \
      ~{'--scheme ' + scheme} \
      ~{'--minid ' + minid} \
      ~{'--mincov ' + mincov} \
      ~{'--minscore ' + minscore} \
      ~{assembly} \
      --outfile ~{samplename}.mlst.tsv

    # rerun for abumannii oxford scheme
    scheme=$(awk -F'\t' 'NR==2 {print $2}' ~{samplename}.mlst.tsv)
    if [ "$scheme" == "abaumannii2" ]; then
      mlst \
      --full \
      --threads ~{cpu} \
      ~{true="--nopath" false="" nopath} \
      --scheme abaumannii \
      ~{'--minid ' + minid} \
      ~{'--mincov ' + mincov} \
      ~{'--minscore ' + minscore} \
      ~{assembly} \
      --outfile ~{samplename}.mlst.oxford.tsv
      # combine results
      awk 'NR==2' ~{samplename}.mlst.oxford.tsv >> ~{samplename}.mlst.tsv
    fi

    # parse ts mlst tsv for relevant outputs
    awk -F'\t' 'NR==2 {if ($3 == "-") print "No ST predicted"; else print "ST"$3 }' ~{samplename}.mlst.tsv | tee PREDICTED_MLST
    awk -F'\t' 'NR==2 {if ($2 == "-") print "NA"; else print $2 }' ~{samplename}.mlst.tsv | tee PUBMLST_SCHEME

    # create legacy output file for report scripts.
    echo -e "Filename\tPubMLST_Scheme_name\tSequence_Type_(ST)\tAllele_IDs" > ~{samplename}.legacy.mlst.tsv
    awk -F'\t' 'NR==2 {print $1"\t"$2"\t"$3"\t"$6}' ~{samplename}.mlst.tsv >> ~{samplename}.legacy.mlst.tsv 
  >>>

  output {
    File ts_mlst_results = "~{samplename}.mlst.tsv"
    File ts_legacy_mlst_results = "~{samplename}.legacy.mlst.tsv"
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