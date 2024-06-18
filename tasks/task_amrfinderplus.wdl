version 1.0

task amrfinderplus_nuc {
  input {
    File assembly
    String samplename 
    String bracken_organism
    String? mash_organism
    File? prodigal_faa
    File? prodigal_gff
    Int cpu = 4
    String docker = "staphb/ncbi-amrfinderplus:3.12.8-2024-05-02.2"
  }
  command <<<
    # logging info
    date | tee DATE
    amrfinder --version | tee AMRFINDER_VERSION

    # check prodigal files
    if [[ -f "~{prodigal_faa}" ]] && [[ -f "~{prodigal_gff}" ]]; then
      protein=true
    else
      protein=false
    fi

    # select mash organism if avalible
    if [[ "~{mash_organism}" != "" ]]; then
      organism="~{mash_organism}"
    else
      organism="~{bracken_organism}"
    fi
    echo "organism is set to:" $organism

    ## curated organisms ##
    # A. baumannii-calcoaceticus species complex
    declare -a abcc=(
      "Acinetobacter baumannii"
      "Acinetobacter calcoaceticus"
      "Acinetobacter lactucae"
      "Acinetobacter nosocomialis"
      "Acinetobacter pittii"
      "Acinetobacter seifertii"
    )
    # Burkholderia cepacia species complex
    declare -a bcc=(
      "Burkholderia aenigmatica"
      "Burkholderia ambifaria"   
      "Burkholderia anthina"   
      "Burkholderia arboris"   
      "Burkholderia catarinensis"   
      "Burkholderia cenocepacia"   
      "Burkholderia cepacia" 
      "Burkholderia cf. cepacia"  
      "Burkholderia contaminans"   
      "Burkholderia diffusa"   
      "Burkholderia dolosa"   
      "Burkholderia lata"   
      "Burkholderia latens"
      "Burkholderia metallica"  
      "Burkholderia multivorans"   
      "Burkholderia orbicola"   
      "Burkholderia paludis"   
      "Burkholderia pseudomultivorans"   
      "Burkholderia puraquae"   
      "Burkholderia pyrrocinia"   
      "Burkholderia semiarida"   
      "Burkholderia seminalis"   
      "Burkholderia sola"   
      "Burkholderia stabilis"   
      "Burkholderia stagnalis"   
      "Burkholderia territorii"   
      "Burkholderia ubonensis"   
      "Burkholderia vietnamiensis" 
    )
    # Burkholderia pseudomallei species complex
    declare -a bpc=(
      "Burkholderia humptydooensis"   
      "Burkholderia mallei"   
      "Burkholderia mayonis"   
      "Burkholderia oklahomensis"   
      "Burkholderia pseudomallei"   
      "Burkholderia savannae"   
      "Burkholderia singularis"   
      "Burkholderia thailandensis"   
    )
    # other species
    declare -a taxa=(   
      "Citrobacter freundii"
      "Clostridioides difficile"
      "Enterobacter asburiae"
      "Enterobacter cloacae"
      "Enterococcus faecalis"    
      "Klebsiella oxytoca"
      "Neisseria meningitidis"
      "Neisseria gonorrhoeae"
      "Pseudomonas aeruginosa" 
      "Serratia marcescens"  
      "Staphylococcus aureus"
      "Staphylococcus pseudintermedius"
      "Streptococcus agalactiae"
      "Streptococcus pyogenes"
      "Vibrio cholerae"
      "Vibrio parahaemolyticus"
      "Vibrio vulnificus"
    )

    # check organism in curated organism list
    genus=$(echo $organism | cut -d " " -f1)
    taxon=$(echo $organism | cut -d " " -f1,2)

    if [[ "$genus" == "Acinetobacter" ]]; then
      for i in "${abcc[@]}"; do
        if [[ "$taxon" == "$i" ]]; then
          amrfinder_organism="Acinetobacter_baumannii"
          break
        fi
      done
    elif [[ "$genus" == "Burkholderia" ]]; then
      for i in "${bcc[@]}"; do
        if [[ "$taxon" == "$i" ]]; then
          amrfinder_organism="Burkholderia_cepacia"
          break
        fi
      done
      for i in "${bpc[@]}"; do
        if [[ "$taxon" == "$i" ]]; then
          amrfinder_organism="Burkholderia_pseudomallei"
          break
        fi
      done
    elif [[ "$genus" == "Shigella" ]] || [[ "$genus" == "Escherichia" ]]; then
      amrfinder_organism="Escherichia"
    elif [[ "$genus" == "Salmonella" ]]; then
      amrfinder_organism="Salmonella"
    elif [[ "$taxon" == "Campylobacter coli" ]] || [[ "$taxon" == "Campylobacter jejuni" ]]; then
      amrfinder_organism="Campylobacter"
    elif [[ "$taxon" == "Enterococcus faecium" ]] || [[ "$taxon" == "Enterococcus hirae" ]]; then
      amrfinder_organism="Enterococcus_faecium"
    elif [[ "$taxon" == "Klebsiella pneumoniae" ]] || [[ "$taxon" == "Klebsiella aerogenes" ]]; then
      amrfinder_organism="Klebsiella_pneumoniae"
    elif [[ "$taxon" == "Streptococcus pneumoniae" ]] || [[ "$taxon" == "Streptococcus mitis" ]]; then
      amrfinder_organism="Streptococcus_pneumoniae"
    else    
      for i in "${taxa[@]}"; do
        if [[ "$taxon" == "$i" ]]; then
          amrfinder_organism=${taxon// /_}
          break
        fi
      done
    fi

    # checking bash variable
    echo "amrfinder_organism is set to:" ${amrfinder_organism}
    
    # protein + nucleotide (activate HMM)
    if [[ -f "~{prodigal_faa}" ]] && [[ -f "~{prodigal_gff}" ]]; then
      # protein + nucleotide & use --organism 
      if [[ -v amrfinder_organism ]]; then
        amrfinder --plus \
          --organism "${amrfinder_organism}" \
          ~{'--name ' + samplename} \
          ~{'--nucleotide ' + assembly} \
          ~{'--protein ' + prodigal_faa} \
          ~{'--gff ' + prodigal_gff} \
          --annotation_format prodigal \
          ~{'-o ' + samplename + '_amrfinder_all.tsv'} \
          ~{'--threads ' + cpu} 2>&1 | tee amrfinder.STDOUT-and-STDERR.log
      # protein + nucleotide & no organism
      else        
        amrfinder --plus \
          ~{'--name ' + samplename} \
          ~{'--nucleotide ' + assembly} \
          ~{'--protein ' + prodigal_faa} \
          ~{'--gff ' + prodigal_gff} \
          --annotation_format prodigal \
          ~{'-o ' + samplename + '_amrfinder_all.tsv'} \
          ~{'--threads ' + cpu} 2>&1 | tee amrfinder.STDOUT-and-STDERR.log
        fi
    # nucleotide only
    else
      # nucletode only & use --organism 
      if [[ -v amrfinder_organism ]] ; then
        amrfinder --plus \
          --organism "${amrfinder_organism}" \
          ~{'--name ' + samplename} \
          ~{'--nucleotide ' + assembly} \
          ~{'-o ' + samplename + '_amrfinder_all.tsv'} \
          ~{'--threads ' + cpu} 2>&1 | tee amrfinder.STDOUT-and-STDERR.log
      # nucletode only & no organism 
      else 
        amrfinder --plus \
          ~{'--name ' + samplename} \
          ~{'--nucleotide ' + assembly} \
          ~{'-o ' + samplename + '_amrfinder_all.tsv'} \
          ~{'--threads ' + cpu} 2>&1 | tee amrfinder.STDOUT-and-STDERR.log
      fi
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