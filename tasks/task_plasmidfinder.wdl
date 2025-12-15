version 1.0

task plasmidfinder {
  input {
    File assembly
    String samplename
    String docker = "staphb/plasmidfinder:3.0.1"
    Float min_coverage = 0.6
    Float threshold = 0.9
    }

  command <<<
    # version
    python -m plasmidfinder -v > VERSION
    cp /database/VERSION.txt ./DB_VERSION
    
    # Run plasmidfinder
    python -m plasmidfinder \
    -i ~{assembly} \
    -l ~{min_coverage} \
    -t ~{threshold} \
    -j data.json

    # Create legacy tsv output
    python <<CODE
    import json
    with open('data.json', 'r') as f:
        data = json.load(f)
    with open('results_tab.tsv', 'w') as f:
        headers = ['Database', 'Plasmid', 'Identity', 'Query / Template length', 'Contig', 'Position in contig', 'Note', 'Accession number']
        f.write('\t'.join(headers) + '\n')
        for seq_region in data['seq_regions'].values():
            # Extract required information
            database = seq_region['ref_database'][0]
            plasmid = seq_region['name']
            identity = f"{seq_region['identity']:.1f}"
            lengths = f"{seq_region['alignment_length']} / {seq_region['ref_gene_lenght']}"
            contig = seq_region['query_id']
            position = f"{seq_region['query_start_pos']}..{seq_region['query_end_pos']}"
            note = seq_region['note']
            accession = seq_region['ref_acc']        
            # Write the row
            row = [database, plasmid, identity, lengths, contig, position, note, accession]
            f.write('\t'.join(row) + '\n')
    # Extract plasmid names from seq_regions
    plasmids = [region['name'] for region in data['seq_regions'].values()]
    with open('PLASMIDS', 'w') as f:
        f.write(','.join(plasmids))
    CODE

    # rename results
    mv results_tab.tsv ~{samplename}.plasmid.tsv
  >>>

  output {
    String plasmidfinder_version = read_string("VERSION")
    String plasmidfinder_db_version = read_string("DB_VERSION")
    String plasmids = read_string("PLASMIDS")
    File plasmid_report = "~{samplename}.plasmid.tsv"
    String plasmidfinder_docker = docker
  }
  runtime {
    docker: "~{docker}"
    memory: "4 GB"
    cpu: 2
    disks: "local-disk 50 SSD"
    preemptible: 0
  }
}