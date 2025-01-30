version 1.0

task qc {
  input {
    Float r1_q30_trim
    Float r2_q30_trim
    Int  total_reads_trim
    Float coverage
    Float coverage_trim
    Int number_of_scaffolds
    String completeness
    String contamination
    Float genome_ratio
  }

  command <<<    
    # coverage
    if awk "BEGIN {exit !(~{coverage} < 40)}"; then
        echo "FAIL:Coverage<40X, " | tee -a QC_EVAL
    elif awk "BEGIN {exit !(~{coverage_trim} < 30)}"; then
        echo "WARN:Trimmed Coverage<30X, " | tee -a QC_EVAL
    fi
    # contamination
    if awk "BEGIN {exit !(~{contamination} > 2.5)}"; then
        echo "FAIL:contamination>2.5%," | tee -a QC_EVAL
    elif awk "BEGIN {exit !(~{contamination} > 1.2)}"; then
        echo "WARN:contamination>1.2%, " | tee -a QC_EVAL
    fi
    # completeness
    if awk "BEGIN {exit !(~{completeness} < 95)}"; then
        echo "FAIL:genome_completeness<95%," | tee -a QC_EVAL
    elif awk "BEGIN {exit !(~{completeness} < 97.9)}"; then
        echo "WARN:genome_completeness<97.9%," | tee -a QC_EVAL
    fi
    # q30
    if awk "BEGIN {exit !(~{r1_q30_trim} < 90)}"; then
        echo "FAIL:R1 Q30<90%, " | tee -a QC_EVAL
    fi
    if awk "BEGIN {exit !(~{r2_q30_trim} < 70)}"; then
        echo "FAIL:R2 Q30<70%, " | tee -a QC_EVAL
    fi
    # reads
    if awk "BEGIN {exit !(~{total_reads_trim} < 1000000)}"; then
        echo "WARN:trimmed reads<1M, " | tee -a QC_EVAL
    fi
    # contigs
    if awk "BEGIN {exit !(~{number_of_scaffolds} > 200)}"; then
        echo "FAIL:Contigs>200, " | tee -a QC_EVAL
    fi
    # genome ratio
    if awk "BEGIN {exit !(~{genome_ratio} > 1.25)}"; then 
        echo "WARN:genome ratio>1.25, " | tee -a QC_EVAL
    elif awk "BEGIN {exit !(~{genome_ratio} < 0.75)}"; then 
        echo "WARN:genome ratio<0.75, " | tee -a QC_EVAL
    fi

    # write pass if no fail
    if [ ! -f QC_EVAL ]; then
        echo "PASS" | tee QC_EVAL    
    fi
  >>>

  output {
    String qc_eval = read_string("QC_EVAL")
  }

  runtime {
    memory: "256 MB"
    cpu: 1
    docker: "ubuntu:jammy-20240911.1"
    disks: "local-disk 10 HDD"
    dx_instance_type: "mem1_ssd1_v2_x2" 
  }
}