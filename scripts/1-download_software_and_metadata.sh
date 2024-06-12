# This script downloads all the necessary metadata and software to run cellranger on the 
# entire tonsil atlas


# Get list of fastq files and subset to scRNA-seq
PATH_TSV="https://www.ebi.ac.uk/ena/portal/api/filereport?accession=PRJEB75429&result=read_run&fields=study_accession,sample_accession,experiment_accession,run_accession,tax_id,scientific_name,fastq_ftp,submitted_ftp,sra_ftp,bam_ftp&format=tsv&download=true&limit=0"
wget -O data/fastq_list_tonsil_atlas.tsv "$PATH_TSV"
grep "scRNA-seq" data/fastq_list_tonsil_atlas.tsv > data/fastq_list_tonsil_atlas_scRNA.tsv


# Create metadata from fastqs
cut -f8 data/fastq_list_tonsil_atlas_scRNA.tsv | cut -d'/' -f6 | cut -d';' -f1 > data/fastq_names_scRNA.txt
echo "technology,donor_id,subproject,gem_id,library_id,library_type,lane,read" > data/tonsil_atlas_fastq_metadata.csv
sed 's/\.fastq\.gz//g' data/fastq_names_scRNA.txt | sed 's/\./,/g' >> data/tonsil_atlas_fastq_metadata.csv


# Download feature barcoding
URL_HASHING_METADATA=https://www.ebi.ac.uk/biostudies/files/E-MTAB-13687/cell_hashing_metadata.csv
wget -O data/cell_hashing_metadata.csv "$URL_HASHING_METADATA"


# Download cellranger 8.0.1
curl -o cellranger-8.0.1.tar.gz "https://cf.10xgenomics.com/releases/cell-exp/cellranger-8.0.1.tar.gz?Expires=1717561298&Key-Pair-Id=APKAI7S6A5RYOXBWRPDA&Signature=iZkk2k4-4RDbLSuDzbjBzW4C71N2TvyPy0NTYq1l9T2SxqMNeGtLiNuVE9O12OY72G~DStTUjQwB4oa1sawTbO0eOoiXK0SpM8lNuHJYdhhsP~sgmLfSVDJHfMNm0gyWBTx0sjv~A22sHtZ1Tdpp369z9vnbzZbvpLmrP7XYPvfyGMa98DWsRXSABVHAFMrJiuuyWU2JmooG-fbNA4Gs6BhLy9YbFqm-bhcR6znfKtQm76PqmB0M1Y22BioPgh1UHCp85Q1uDN5Pel73zhgDuac0Xz7Ri~AkLD1Tz3Z0ZX37gIFajH5-nCyLpak83UF9ViMfnb3~mo8lDQ4aMkLlbw__"
tar -xzf cellranger-8.0.1.tar.gz


# Download human reference
curl -O "https://cf.10xgenomics.com/supp/cell-exp/refdata-gex-GRCh38-2024-A.tar.gz"
tar -xzf refdata-gex-GRCh38-2024-A.tar.gz