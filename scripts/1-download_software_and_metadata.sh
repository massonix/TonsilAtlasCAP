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
curl -o cellranger-8.0.1.tar.gz "https://cf.10xgenomics.com/releases/cell-exp/cellranger-8.0.1.tar.gz?Expires=1718237417&Key-Pair-Id=APKAI7S6A5RYOXBWRPDA&Signature=AMa6fcmGxE75OTXN1NjrhWXg7Z8Nca9SqWPKKdvQYVdLhghySrqK~-ZRgHUVHMOaN2UewOPzwPL~5ioMZWqlfnfZOsYM1476QlZQcfpvoXxwTWcknrnTxwG2UlvktUUy79Aham2oUNZJqiTcTNsIRoH9GmnZFu41uDPpFXvJIfyGcLBvlijpvQ4xAPOn2rY-gzq49lcqG4gK6TzPo7rDaudoHcU50RnHSxpoCMqet9Xnq--XPxrMwNzAG2u~EeLPazVSs97Cdsc2l9bVrEs5wcjzt4Qt70pI5ndtQbhbStM6RSQATLSrjOLn6B6-Xc9kN5t0ZbReQRMV8jDftDsHDQ__"
tar -xzf cellranger-8.0.1.tar.gz
rm cellranger-8.0.1.tar.gz
mkdir -p software
mv cellranger-8.0.1 software/


# Download human reference
curl -O "https://cf.10xgenomics.com/supp/cell-exp/refdata-gex-GRCh38-2024-A.tar.gz"
tar -xzf refdata-gex-GRCh38-2024-A.tar.gz
rm refdata-gex-GRCh38-2024-A.tar.gz