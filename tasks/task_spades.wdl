version 1.0

task spades_pe {
  input {
    File read1
    File read2
    Int contig_threshold
    String samplename
    Int cpu = 4
    Int memory = 32
    String docker = "staphb/spades:4.2.0"    
  }
  
  command <<<
    # version control
    spades.py -v > VERSION 

    # assembly
    spades.py \
      --careful \
      --only-assembler \
      --pe1-1 ~{read1} \
      --pe1-2 ~{read2} \
      -o out

    # get & rename output   
    mv out/contigs.fasta ~{samplename}_contigs.fasta
    mv out/scaffolds.fasta ~{samplename}_scaffolds.fasta

    # remove short scaffolds
    echo "Removing scaffolds shorter than ~{contig_threshold}"
    python <<CODE
    import re
    # Copy lines from the input file to the output file until a scaffold shorter than the threshold is found
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
    # Count the number of scaffolds before and after trimming
    pre_trim_num = 0
    post_trim_num = 0
    with open("~{samplename}_scaffolds.fasta", "r") as input:
        for line in input:
            if line.startswith('>'):
                pre_trim_num += 1
    with open("~{samplename}_scaffolds_trim.fasta", "r") as input:
        for line in input:
            if line.startswith('>'):
                post_trim_num += 1
    print("Number of scaffolds before trimming:", pre_trim_num)
    print("Number of scaffolds after trimming:", post_trim_num)
    print("Number of scaffolds removed:", pre_trim_num - post_trim_num)
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
    memory: "~{memory} GB"
    cpu: cpu
    disks: "local-disk 100 SSD"
    preemptible:  0
  }
}