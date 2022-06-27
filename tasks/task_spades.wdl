version 1.0

task spades_pe {
  input {
    File read1
    File read2
    String samplename
    String docker = "quay.io/biocontainers/spades:3.15.4--h95f258a_0"

  }
  command <<<
    # date and version control
    date | tee DATE
    spades.py -v > VERSION 

    spades.py -o out \
    --careful \
    --pe1-1 ~{read1} --pe1-2 ~{read2}
 
    cp ./out/scaffolds.fasta ~{samplename}_scaffolds.fasta
    cp ./out/contigs.fasta ~{samplename}_contigs.fasta

  >>>
  output {
	  File scaffolds = "~{samplename}_scaffolds.fasta"
	  File contigs = "~{samplename}_contigs.fasta"
    String spades_version = read_string("VERSION")
  }

  runtime {
    docker: "~{docker}"
    memory: "8 GB"
    cpu: 4
    disks: "local-disk 100 SSD"
    preemptible:  0
  }
}