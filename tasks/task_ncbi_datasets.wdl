version 1.0

task fetch_reference {
  input {
    String samplename
    String taxon
    String docker = "staphb/cbird-util:2.0"
  }

  command <<<    
    datasets summary genome taxon "~{taxon}" --reference > ref.json
    acc_id=$(jq -r '.reports[0].accession' ref.json)
    if [ ! -z "$acc_id" ]
    then
      datasets download genome accession $acc_id
      unzip ncbi_dataset.zip
      mv $(find ncbi_dataset/data -name "$acc_id*_genomic.fna") ~{samplename}_ref.fa
    fi
  >>>

  output {
    File reference = "~{samplename}_ref.fa"
  }

  runtime {
      docker: "~{docker}"
      memory: "1 GB"
      cpu: 1
      disks: "local-disk 100 SSD"
      preemptible:  0
  }
}

  