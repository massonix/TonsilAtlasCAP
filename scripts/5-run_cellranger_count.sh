# This script runs cellranger count for a given gem_id
# The first argument ($1) should be the gem_id

# Get library type for that gem_id 
gem_id=$1
working_dir=$(pwd)
library_type=$(grep $gem_id $working_dir/data/tonsil_atlas_fastq_metadata.csv | cut -d, -f6 | head -n1)

# Run cellranger
mkdir -p data/outs_cellranger/$gem_id
if [ "$library_type" == "not_hashed" ]; then
    echo "Library type is not hashed"
    software/cellranger-8.0.1/cellranger count --id=$gem_id \
       --fastqs="data/fastq/${gem_id}/symlinks/" \
       --sample=$gem_id \
       --transcriptome=refdata-gex-GRCh38-2024-A \
       --include-introns false \
       --create-bam false \
       --output-dir="data/outs_cellranger/${gem_id}"
else
    echo "Library type is hashed"
    software/cellranger-8.0.1/cellranger count --id=$gem_id \
       --libraries="${working_dir}/data/libraries_csvs/${gem_id}_libraries.csv" \
       --feature-ref="${working_dir}/data/feature_reference_csvs/${gem_id}_feature_reference.csv" \
       --transcriptome=refdata-gex-GRCh38-2024-A \
       --include-introns false \
       --create-bam false \
       --output-dir="data/outs_cellranger/${gem_id}"
fi

