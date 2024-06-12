# This script downloads the fastq files for one gem_id, all the necessary metadata
# and runs cellranger count


# Get list of fastq files and subset to scRNA-seq
PATH_TSV="https://www.ebi.ac.uk/ena/portal/api/filereport?accession=PRJEB75429&result=read_run&fields=study_accession,sample_accession,experiment_accession,run_accession,tax_id,scientific_name,fastq_ftp,submitted_ftp,sra_ftp,bam_ftp&format=tsv&download=true&limit=0"
wget -O fastq_list_tonsil_atlas.tsv "$PATH_TSV"
grep "scRNA-seq" fastq_list_tonsil_atlas.tsv > fastq_list_tonsil_atlas_scRNA.tsv


# Create metadata from fastqs
cut -f8 fastq_list_tonsil_atlas_scRNA.tsv | cut -d'/' -f6 | cut -d';' -f1 > fastq_names_scRNA.txt
echo "technology,donor_id,subproject,gem_id,library_id,library_type,lane,read" > tonsil_atlas_fastq_metadata.csv
sed 's/\.fastq\.gz//g' fastq_names_scRNA.txt | sed 's/\./,/g' >> tonsil_atlas_fastq_metadata.csv


# Download feature barcoding
URL_HASHING_METADATA=https://www.ebi.ac.uk/biostudies/files/E-MTAB-13687/cell_hashing_metadata.csv
wget -O cell_hashing_metadata.csv "$URL_HASHING_METADATA"


# Download cellranger 8.0.1
curl -o cellranger-8.0.1.tar.gz "https://cf.10xgenomics.com/releases/cell-exp/cellranger-8.0.1.tar.gz?Expires=1717561298&Key-Pair-Id=APKAI7S6A5RYOXBWRPDA&Signature=iZkk2k4-4RDbLSuDzbjBzW4C71N2TvyPy0NTYq1l9T2SxqMNeGtLiNuVE9O12OY72G~DStTUjQwB4oa1sawTbO0eOoiXK0SpM8lNuHJYdhhsP~sgmLfSVDJHfMNm0gyWBTx0sjv~A22sHtZ1Tdpp369z9vnbzZbvpLmrP7XYPvfyGMa98DWsRXSABVHAFMrJiuuyWU2JmooG-fbNA4Gs6BhLy9YbFqm-bhcR6znfKtQm76PqmB0M1Y22BioPgh1UHCp85Q1uDN5Pel73zhgDuac0Xz7Ri~AkLD1Tz3Z0ZX37gIFajH5-nCyLpak83UF9ViMfnb3~mo8lDQ4aMkLlbw__"
tar -xzf cellranger-8.0.1.tar.gz


# Download human reference
curl -O "https://cf.10xgenomics.com/supp/cell-exp/refdata-gex-GRCh38-2024-A.tar.gz"
tar -xzf refdata-gex-GRCh38-2024-A.tar.gz


# Download fastqs for one gem_id
gem_id="y7qn780g_p6jkgk63"
fastqs_urls=$(grep $gem_id fastq_list_tonsil_atlas_scRNA.tsv | cut -f8)
mkdir -p $gem_id/fastqs
for url in $fastqs_urls;
do
    url_fastq1=$(echo $url | cut -d';' -f1)
    echo $url_fastq1
    wget -P $gem_id/fastqs $url_fastq1
    url_fastq2=$(echo $url | cut -d';' -f2)
    echo $url_fastq2
    wget -P $gem_id/fastqs $url_fastq2
done

# Create an associative array to hold the mapping from pair_id to lane_id
declare -A lane_dict
counter=1
pair_ids=$(ls $gem_id/fastqs | cut -d'.' -f7 | sort | uniq)
for pair_id in $pair_ids; do
    echo $pair_id
    lane_dict[$pair_id]=$counter
    ((counter++))
done


# Change fastq names to cellranger-friendly
for fastq in $(ls $gem_id/fastqs); do
    read=$(echo $fastq | cut -d'.' -f8)
    pair_id=$(echo $fastq | cut -d'.' -f7)
    lane=${lane_dict[$pair_id]}
    new_name="${gem_id}_S1_L00${lane}_${read}_001.fastq.gz"
    echo "Creating symbolic link for $fastq as $new_name"
    ln -s "$fastq" "$gem_id/fastqs/$new_name"
done


# Run cellranger count
cellranger-8.0.1/cellranger count --id="run_count_${gem_id}" \
   --fastqs=$gem_id/fastqs \
   --sample=$gem_id \
   --transcriptome=refdata-gex-GRCh38-2024-A \
   --include-introns false \
   --create-bam false  \
   --output-dir=$gem_id