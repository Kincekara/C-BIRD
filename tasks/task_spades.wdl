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

    out_dir="$(mktemp -d ./spades.XXXXXXXXX)"

    # assembly
    spades.py --careful --only-assembler --pe1-1 ~{read1} --pe1-2 ~{read2} -o $out_dir

    # get & rename output   
    cp "$out_dir"/contigs.fasta ~{samplename}_contigs.fasta
    cp "$out_dir"/scaffolds.fasta ~{samplename}_scaffolds.fasta

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