version 1.0

task bbduk_pe {
  input {
    File read1_trimmed
    File read2_trimmed
    String samplename
    Int mem_size_gb=8
    String docker = "kincekara/bbduk:38.98"
  }

  command <<<
    # version control
    echo "$(java -ea -Xmx31715m -Xms31715m -cp /bbmap/current/ jgi.BBDuk 2>&1)" | grep version > VERSION

    # re-pairing & phiX cleaning
    repair.sh in1=~{read1_trimmed} in2=~{read2_trimmed} out1=~{samplename}.paired_1.fastq.gz out2=~{samplename}.paired_2.fastq.gz
    bbduk.sh in1=~{samplename}.paired_1.fastq.gz in2=~{samplename}.paired_2.fastq.gz out1=~{samplename}_1.clean.fastq.gz out2=~{samplename}_2.clean.fastq.gz outm=~{samplename}.matched_phix.fq ref=/bbmap/resources/phix174_ill.ref.fa.gz k=31 hdist=1 stats=~{samplename}.phix.stats.txt

    grep Matched ~{samplename}.phix.stats.txt | awk '{print $3}' > PHIX_RATIO
  >>>
  
  output {
    File read1_clean = "~{samplename}_1.clean.fastq.gz"
    File read2_clean = "~{samplename}_2.clean.fastq.gz"
    File phiX_stats = "~{samplename}.phix.stats.txt"
    String bbduk_docker = docker
    String bbduk_version = read_string("VERSION")
    String phix_ratio = read_string("PHIX_RATIO")
  }

  runtime {
    docker: "~{docker}"
    memory: "~{mem_size_gb} GB"
    cpu: 4
    disks: "local-disk 100 SSD"
    preemptible: 0
    maxRetries: 3
  }
}
