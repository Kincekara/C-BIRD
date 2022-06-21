version 1.0

task trimmomatic_pe {
  input {
    File read1
    File read2
    String samplename
    String docker = "quay.io/staphb/trimmomatic:0.39"
    File adapters
    Int? trimmommatic_leading = 3
    Int? trimmomatic_trailing = 3
    Int? trimmomatic_minlen = 36
    Int? trimmomatic_window_size = 10
    Int? trimmomatic_quality_trim_score = 20
    Int? threads = 4
  }
  command <<<
    # date and version control
    date | tee DATE
    trimmomatic -version > VERSION && sed -i -e 's/^/Trimmomatic /' VERSION

    trimmomatic PE \
    -threads ~{threads} \
    ~{read1} ~{read2} \
    -baseout ~{samplename}.fastq.gz \
    ILLUMINACLIP:~{adapters}:2:30:10 \
    LEADING:~{trimmommatic_leading} \
    TRAILING:~{trimmomatic_trailing} \
    SLIDINGWINDOW:~{trimmomatic_window_size}:~{trimmomatic_quality_trim_score} \
    MINLEN:~{trimmomatic_minlen} &> ~{samplename}.trim.stats.txt
  >>>
  output {
    File read1_trimmed = "~{samplename}_1P.fastq.gz"
    File read2_trimmed = "~{samplename}_2P.fastq.gz"
    File trimmomatic_stats = "~{samplename}.trim.stats.txt"
    String version = read_string("VERSION")
    String pipeline_date = read_string("DATE")
  }
  runtime {
    docker: "~{docker}"
    memory: "8 GB"
    cpu: 4
    disks: "local-disk 100 SSD"
    preemptible:  0
  }
}