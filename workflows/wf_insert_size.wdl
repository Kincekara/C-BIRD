version 1.0

import "../tasks/task_fetch_reference.wdl" as fetch_reference
import "../tasks/task_plot_ihist.wdl" as ihist

workflow estimate_inserts {

  meta {
  description: "C-BIRD auxiliary pipeline"
  }

  input {
    File read1
    File read2
    String samplename
    #File taxid
    String taxon
  }

  call fetch_reference.fetch_reference {
    input:
      samplename = samplename,
      #taxid = taxid
      taxon = taxon
  }

  call ihist.insert_size_dist {
    input:
      read1 = read1,
      read2 = read2,
      samplename = samplename,
      reference = fetch_reference.reference
  }

  output {
    File insert_size_hist = insert_size_dist.insert_size_hist
    File insert_size_plot = insert_size_dist.insert_size_plot 
    Int median_insert_size = insert_size_dist.median_insert_size
  }
}