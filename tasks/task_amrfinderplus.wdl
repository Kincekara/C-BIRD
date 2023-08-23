version 1.0

task amrfinderplus_nuc {
  input {
    File assembly
    String samplename
    File amr_db     
    String bracken_organism
    String? mash_organism
    Float? minid
    Float? mincov
    Int cpu = 4
    String docker = "kincekara/amrfinder:3.11.18"
  }
  command <<<
    # logging info
    date | tee DATE
    amrfinder --version | tee AMRFINDER_VERSION

    mkdir db
    tar -C ./db/ -xzvf ~{amr_db}

    # select mash organism if avalible
    if [[ "~{mash_organism}" != "" ]]; then
      organism="~{mash_organism}"
    else
      organism="~{bracken_organism}"
    fi
    echo "organism is set to:" $organism

    # curated organisms
    declare -a taxa=(
      "Acinetobacter baumannii"
      "Burkholderia cepacia"
      "Burkholderia pseudomallei"      
      "Citrobacter freundii"
      "Clostridioides difficile"
      "Enterobacter asburiae"
      "Enterobacter cloacae"
      "Enterococcus faecalis"
      "Enterococcus faecium"      
      "Klebsiella oxytoca"
      "Klebsiella penumoniae"
      "Neisseria meningitidis"
      "Neisseria gonorrhoeae"
      "Pseudomonas aeruginosa" 
      "Serratia marcescens"  
      "Staphylococcus aureus"
      "Staphylococcus pseudintermedius"
      "Streptococcus agalactiae"
      "Streptococcus pneumoniae"
      "Streptococcus pyogenes"
      "Vibrio cholerae"
    )

    declare -a genera=(
      "Campylobacter"
      "Escherichia"
      "Salmonella"
    )

    # check organism in curated organism list
    genus=$(echo $organism | cut -d " " -f1)
    for i in "${genera[@]}"
    do
    if [[ "$genus" == "$i" ]]; then
     amrfinder_organism="$genus"
    fi
    done

    taxon=$(echo $organism | cut -d " " -f1,2)
    for i in "${taxa[@]}"
    do
    if [[ "$taxon" == "$i" ]]; then
     amrfinder_organism="$taxon"
    fi
    done
  
    # checking bash variable
    echo "amrfinder_organism is set to:" ${amrfinder_organism}
    
    # if amrfinder_organism variable is set, use --organism flag, otherwise do not use --organism flag
    if [[ -v amrfinder_organism ]] ; then
      # always use --plus flag, others may be left out if param is optional and not supplied 
      # send STDOUT/ERR to log file for capturing database version
      amrfinder --plus \
        -d ./db/ \
        --organism "${amrfinder_organism}" \
        ~{'--name ' + samplename} \
        ~{'--nucleotide ' + assembly} \
        ~{'-o ' + samplename + '_amrfinder_all.tsv'} \
        ~{'--threads ' + cpu} \
        ~{'--coverage_min ' + mincov} \
        ~{'--ident_min ' + minid} 2>&1 | tee amrfinder.STDOUT-and-STDERR.log
    else 
      # always use --plus flag, others may be left out if param is optional and not supplied 
      # send STDOUT/ERR to log file for capturing database version
      amrfinder --plus \
        -d ./db/ \
        ~{'--name ' + samplename} \
        ~{'--nucleotide ' + assembly} \
        ~{'-o ' + samplename + '_amrfinder_all.tsv'} \
        ~{'--threads ' + cpu} \
        ~{'--coverage_min ' + mincov} \
        ~{'--ident_min ' + minid} 2>&1 | tee amrfinder.STDOUT-and-STDERR.log
    fi

    # capture the database version from the stdout and stderr file that was just created
    grep "Database version:" amrfinder.STDOUT-and-STDERR.log | sed 's|Database version: ||' >AMRFINDER_DB_VERSION

    # Element Type possibilities: AMR, STRESS, and VIRULENCE 
    # create headers for 3 output files; tee to 3 files and redirect STDOUT to dev null so it doesn't print to log file
    head -n 1 ~{samplename}_amrfinder_all.tsv | tee ~{samplename}_amrfinder_stress.tsv ~{samplename}_amrfinder_virulence.tsv ~{samplename}_amrfinder_amr.tsv >/dev/null
    # looks for all rows with STRESS, AMR, or VIRULENCE and append to TSVs
    grep 'STRESS' ~{samplename}_amrfinder_all.tsv >> ~{samplename}_amrfinder_stress.tsv
    grep 'VIRULENCE' ~{samplename}_amrfinder_all.tsv >> ~{samplename}_amrfinder_virulence.tsv
    # || true is so that the final grep exits with code 0, preventing failures
    grep 'AMR' ~{samplename}_amrfinder_all.tsv >> ~{samplename}_amrfinder_amr.tsv || true

    # create string outputs for all genes identified in AMR, STRESS, VIRULENCE
    amr_genes=$(awk -F '\t' '{ print $7 }' ~{samplename}_amrfinder_amr.tsv | tail -n+2 | tr '\n' ', ' | sed 's/.$//')
    stress_genes=$(awk -F '\t' '{ print $7 }' ~{samplename}_amrfinder_stress.tsv | tail -n+2 | tr '\n' ', ' | sed 's/.$//')
    virulence_genes=$(awk -F '\t' '{ print $7 }' ~{samplename}_amrfinder_virulence.tsv | tail -n+2 | tr '\n' ', ' | sed 's/.$//')
    amr_subclass=$(awk -F '\t' '{ print $13 }' ~{samplename}_amrfinder_amr.tsv | tail -n+2 | awk '!seen[$0]++' | tr '\n' ', ' | sed 's/.$//')

    # if variable for list of genes is EMPTY, write string saying it is empty to float to Terra table
    if [ -z "${amr_genes}" ]; then
       amr_genes="No AMR genes detected by NCBI-AMRFinderPlus"
    fi 
    if [ -z "${stress_genes}" ]; then
       stress_genes="No STRESS genes detected by NCBI-AMRFinderPlus"
    fi 
    if [ -z "${virulence_genes}" ]; then
       virulence_genes="No VIRULENCE genes detected by NCBI-AMRFinderPlus"
    fi
    if [ -z "${amr_subclass}" ]; then
       amr_subclass="No AMR detected by NCBI-AMRFinderPlus"
    fi

    # create final output strings
    echo "${amr_genes}" > AMR_GENES
    echo "${stress_genes}" > STRESS_GENES
    echo "${virulence_genes}" > VIRULENCE_GENES
    echo "${amr_subclass}" > AMR_SUBCLASS
  >>>
  output {
    File amrfinderplus_all_report = "~{samplename}_amrfinder_all.tsv"
    File amrfinderplus_amr_report = "~{samplename}_amrfinder_amr.tsv"
    File amrfinderplus_stress_report = "~{samplename}_amrfinder_stress.tsv"
    File amrfinderplus_virulence_report = "~{samplename}_amrfinder_virulence.tsv"
    String amrfinderplus_amr_genes = read_string("AMR_GENES")
    String amrfinderplus_stress_genes = read_string("STRESS_GENES")
    String amrfinderplus_virulence_genes = read_string("VIRULENCE_GENES")
    String amrfinderplus_version = read_string("AMRFINDER_VERSION")
    String amrfinderplus_db_version = read_string("AMRFINDER_DB_VERSION")
    String amrfinderplus_amr_subclass = read_string("AMR_SUBCLASS")
    String amrfinderplus_docker = docker
  }
  runtime {
    memory: "8 GB"
    cpu: cpu
    docker: docker
    disks: "local-disk 100 SSD"
    preemptible: 0
    maxRetries: 3
  }
}