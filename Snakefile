# Snakemake file

# Rule to download metadata and software
rule download_software_and_metadata:
    output:
        fastq_list="fastq_list_tonsil_atlas.tsv",
        fastq_list_scRNA="fastq_list_tonsil_atlas_scRNA.tsv",
        fastq_names="fastq_names_scRNA.txt",
        metadata_csv="tonsil_atlas_fastq_metadata.csv",
        cell_hashing_metadata="cell_hashing_metadata.csv",
        cellranger_tar="cellranger-8.0.1.tar.gz",
        cellranger_dir="cellranger-8.0.1",
        reference_tar="refdata-gex-GRCh38-2024-A.tar.gz",
        reference_dir="refdata-gex-GRCh38-2024-A"
    shell:
        """
        # Download and process metadata
        wget -O {output.fastq_list} "https://www.ebi.ac.uk/ena/portal/api/filereport?accession=PRJEB75429&result=read_run&fields=study_accession,sample_accession,experiment_accession,run_accession,tax_id,scientific_name,fastq_ftp,submitted_ftp,sra_ftp,bam_ftp&format=tsv&download=true&limit=0"
        grep "scRNA-seq" {output.fastq_list} > {output.fastq_list_scRNA}
        
        cut -f8 {output.fastq_list_scRNA} | cut -d'/' -f6 | cut -d';' -f1 > {output.fastq_names}
        echo "technology,donor_id,subproject,gem_id,library_id,library_type,lane,read" > {output.metadata_csv}
        sed 's/\.fastq\.gz//g' {output.fastq_names} | sed 's/\\./,/g' >> {output.metadata_csv}
        
        # Download feature barcoding metadata
        wget -O {output.cell_hashing_metadata} "https://www.ebi.ac.uk/biostudies/files/E-MTAB-13687/cell_hashing_metadata.csv"
        
        # Download and extract Cell Ranger
        curl -o {output.cellranger_tar} "https://cf.10xgenomics.com/releases/cell-exp/cellranger-8.0.1.tar.gz?Expires=1717561298&Key-Pair-Id=APKAI7S6A5RYOXBWRPDA&Signature=iZkk2k4-4RDbLSuDzbjBzW4C71N2TvyPy0NTYq1l9T2SxqMNeGtLiNuVE9O12OY72G~DStTUjQwB4oa1sawTbO0eOoiXK0SpM8lNuHJYdhhsP~sgmLfSVDJHfMNm0gyWBTx0sjv~A22sHtZ1Tdpp369z9vnbzZbvpLmrP7XYPvfyGMa98DWsRXSABVHAFMrJiuuyWU2JmooG-fbNA4Gs6BhLy9YbFqm-bhcR6znfKtQm76PqmB0M1Y22BioPgh1UHCp85Q1uDN5Pel73zhgDuac0Xz7Ri~AkLD1Tz3Z0ZX37gIFajH5-nCyLpak83UF9ViMfnb3~mo8lDQ4aMkLlbw__"
        tar -xzf {output.cellranger_tar}
        
        # Download and extract human reference
        curl -O "https://cf.10xgenomics.com/supp/cell-exp/refdata-gex-GRCh38-2024-A.tar.gz"
        tar -xzf {output.reference_tar}
        """
        
# Rule to download FASTQ files
rule download_fastq_files:
    input:
        fastq_list_scRNA="fastq_list_tonsil_atlas_scRNA.tsv"
    output:
        directory("fastqs/{gem_id}")
    params:
        gem_id="{gem_id}"
    shell:
        """
        mkdir -p fastqs/{params.gem_id}
        grep {params.gem_id} {input.fastq_list_scRNA} | cut -f8 | xargs -n 1 -P 4 -I {{}} wget -P fastqs/{params.gem_id} {{}}
        """

# Example of how to run it for a specific gem_id
# To run: snakemake fastqs/<gem_id> -j <number_of_jobs>
