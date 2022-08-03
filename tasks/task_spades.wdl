version 1.0

task spades_pe {
  input {
    File read1
    File read2
    Int? contig_threshold = 500
    String samplename
    String docker = "kincekara/spades:3.15.5"

  }
  command <<<
    # date and version control
    date | tee DATE
    spades.py -v > VERSION 

    tmp_dir="$(mktemp -d spades.XXXXXXXXX)"
    # assembly
    spades.py --careful --only-assembler -o out --tmp-dir $tmp_dir -1 ~{read1} -2 ~{read2} 

    # get & rename output   
    mv out/contigs.fasta ~{samplename}_contigs.fasta
    mv out/scaffolds.fasta ~{samplename}_scaffolds.fasta

    # remove short contigs
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