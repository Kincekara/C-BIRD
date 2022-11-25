version 1.0

task assembly_prep {
  input {
    File read1_trimmed
    File read2_trimmed
    String samplename
    Boolean normalization = true
    Int total_reads
    Int norm_target = 100
    Int min_depth = 5
    Int read_threshold = 8000000
    Int memory = 32
    String docker = "kincekara/bbduk:38.98"
  }

  command <<<
    # version control
    echo "$(java -ea -Xmx31715m -Xms31715m -cp /bbmap/current/ jgi.BBDuk 2>&1)" | grep version > VERSION
    
    # PhiX cleaning   
    bbduk.sh in1=~{read1_trimmed} in2=~{read2_trimmed} out1=~{samplename}_1.clean.fastq.gz out2=~{samplename}_2.clean.fastq.gz outm=~{samplename}.matched_phix.fq ref=/bbmap/resources/phix174_ill.ref.fa.gz k=31 hdist=1 stats=~{samplename}.phix.stats.txt
    grep Matched ~{samplename}.phix.stats.txt | awk '{print $3}' > PHIX_RATIO
    
    # normalization
    if ~{normalization} && [ "~{total_reads}" -gt "~{read_threshold}" ]      
      then
        echo "normalizing reads..."
        bbnorm.sh in=~{samplename}_1.clean.fastq.gz in2=~{samplename}_2.clean.fastq.gz out=~{samplename}_1.clean.norm.fastq.gz  out2=~{samplename}_2.clean.norm.fastq.gz target=~{norm_target} min=~{min_depth}
      else
        echo "skipping normalization..."
        mv ~{samplename}_1.clean.fastq.gz ~{samplename}_1.clean.norm.fastq.gz
        mv ~{samplename}_2.clean.fastq.gz ~{samplename}_2.clean.norm.fastq.gz
    fi
  >>>
  
  output {
    File read1_clean_norm = "~{samplename}_1.clean.norm.fastq.gz"
    File read2_clean_norm = "~{samplename}_2.clean.norm.fastq.gz"
    File phiX_stats = "~{samplename}.phix.stats.txt"
    String bbtools_docker = docker
    String bbmap_version = read_string("VERSION")
    String phix_ratio = read_string("PHIX_RATIO")
  }

  runtime {
    docker: "~{docker}"
    memory: "~{memory} GB"
    cpu: 4
    disks: "local-disk 100 SSD"
    preemptible: 0
    maxRetries: 3
  }
}
