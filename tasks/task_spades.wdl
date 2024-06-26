version 1.0

task spades_pe {
  input {
    File read1
    File read2
    Int contig_threshold
    String samplename
    String docker = "staphb/spades:4.0.0"

  }
  command <<<
    # date and version control
    date | tee DATE
    spades.py -v > VERSION 

    # assembly
    spades.py --careful --only-assembler --pe1-1 ~{read1} --pe1-2 ~{read2} -o out

    # get & rename output   
    mv out/contigs.fasta ~{samplename}_contigs.fasta
    mv out/scaffolds.fasta ~{samplename}_scaffolds.fasta

    # remove short contigs
    echo "removing contigs shorter than ~{contig_threshold}"
    python <<CODE
    import re
    with open("~{samplename}_scaffolds.fasta", "r") as input:
        with open("~{samplename}_scaffolds_trim.fasta", "w") as output:
            for line in input:
                if line.startswith('>'):
                    num = re.findall('[0-9]+', line)[1]
                    if int(num) < ~{contig_threshold}:
                        break
                    else:
                        output.write(line)
                else:
                    output.write(line)
    CODE
  >>>

  output {
	  File scaffolds = "~{samplename}_scaffolds.fasta"
	  File contigs = "~{samplename}_contigs.fasta"
    File scaffolds_trim  = "~{samplename}_scaffolds_trim.fasta"
    String spades_version = read_string("VERSION")
    String spades_docker = docker
  }

  runtime {
    docker: "~{docker}"
    memory: "32 GB"
    cpu: 4
    disks: "local-disk 100 SSD"
    preemptible:  0
  }
}