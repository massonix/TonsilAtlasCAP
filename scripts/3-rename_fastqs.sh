# This script runs cellranger for a given gem_id
# The first argument ($1) should be the gem_id

# Get library type for that gem_id 
gem_id=$1
working_dir=$(pwd)
library_type=$(grep $gem_id $working_dir/data/tonsil_atlas_fastq_metadata.csv | cut -d, -f6 | head -n1)

# Function to create symbolic links with cellranger-friendly names
create_symlinks() {
    local fastq_dir=$1
    local output_dir=$2
    local suffix=$3

    mkdir -p "$output_dir"
    declare -A lane_dict
    counter=1
    pair_ids=$(ls "$fastq_dir" | grep "fastq.gz" | grep "$suffix" | cut -d'.' -f7 | sort | uniq)

    for pair_id in $pair_ids; do
        lane_dict[$pair_id]=$counter
        ((counter++))
    done

    for fastq in $(ls "$fastq_dir" | grep "fastq.gz" | grep "$suffix"); do
        read=$(echo $fastq | cut -d'.' -f8)
        pair_id=$(echo $fastq | cut -d'.' -f7)
        lane=${lane_dict[$pair_id]}
        new_name="${gem_id}_S1_L00${lane}_${read}_001.fastq.gz"
        echo "Creating symbolic link for $fastq as $new_name"
        ln -s "$fastq_dir/$fastq" "$output_dir/$new_name"
    done
}

# Main script logic
if [ "$library_type" == "not_hashed" ]; then
    echo "Library type is not hashed"
    create_symlinks "${working_dir}/data/fastq/$gem_id" "${working_dir}/data/fastq/$gem_id" ""
else
    echo "Library type is hashed"
    
    # Rename fastqs cDNA
    create_symlinks "${working_dir}/data/fastq/$gem_id" "${working_dir}/data/fastq/$gem_id/cDNA" "cdna"
    
    # Rename fastqs HTO
    create_symlinks "${working_dir}/data/fastq/$gem_id" "${working_dir}/data/fastq/$gem_id/hto" "hto"
    
    # Create libraries.csv file
    mkdir -p data/libraries_csvs
    cat <<EOL > "${working_dir}/data/libraries_csvs/${gem_id}_libraries.csv"
fastqs,sample,library_type
${working_dir}/data/fastq/${gem_id}/cDNA/,${gem_id},Gene Expression
${working_dir}/data/fastq/${gem_id}/hto/,${gem_id},Antibody Capture
EOL

    # Create feature_reference.csv
    mkdir -p data/feature_reference_csvs
    head -n1 data/cell_hashing_metadata.csv | cut -d, -f3-8 > "${working_dir}/data/feature_reference_csvs/${gem_id}_feature_reference.csv"
    grep $gem_id data/cell_hashing_metadata.csv | cut -d, -f3-8 >> "${working_dir}/data/feature_reference_csvs/${gem_id}_feature_reference.csv"
fi

