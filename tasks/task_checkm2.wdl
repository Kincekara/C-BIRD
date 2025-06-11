version 1.0

task checkm2 {
  input {
    File assembly
    File checkm2_db   
    String samplename
    String docker = "staphb/checkm2:1.1.0"
    Int memory = 16
    Int cpu = 8
  }

  command <<<
    # version
    checkm2 --version > VERSION
    # prep inputs
    tar -C . -xvf ~{checkm2_db}     
    mkdir bins
    cp ~{assembly} ./bins/
    # run checkm2    
    export TMPDIR=/tmp # -> https://github.com/broadinstitute/cromwell/issues/3647    
    checkm2 predict \
    --threads ~{cpu} \
    --tmpdir /tmp \
    -x fasta \
    --input ./bins \
    --output-directory ./out \
    --database_path ./CheckM2_database/uniref100.KO.1.dmnd
    # parse results
    cp ./out/quality_report.tsv ./~{samplename}.checkm2.report.tsv
    awk -F '\t' 'NR==2 { print $2 }' out/quality_report.tsv > COMPLETENESS
    awk -F '\t' 'NR==2 { print $3 }' out/quality_report.tsv > CONTAMINATION
    
    # (bonus) run prodigal to get protein data
    prodigal -m -i ~{assembly} -f gff -o ~{samplename}.prodigal.gff -a ~{samplename}.prodigal.faa

    # clean up
    rm -rf ./CheckM2_database
  >>>

  output {
    String version = read_string("VERSION")
    String checkm2_docker = docker
    String completeness = read_string("COMPLETENESS")
    String contamination = read_string("CONTAMINATION")
    File report = "~{samplename}.checkm2.report.tsv"
    File prodigal_faa = "~{samplename}.prodigal.faa"
    File prodigal_gff = "~{samplename}.prodigal.gff"
  }
  runtime {
      docker: "~{docker}"
      memory: "~{memory} GB"
      cpu: cpu
      disks: "local-disk 100 SSD"
      preemptible: 0
  }
}
