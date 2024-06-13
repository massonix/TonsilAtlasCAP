# This script runs cellranger for a given gem_id
# The first argument ($1) should be the gem_id

# Get library type for that gem_id 
gem_id=$1
library_type=$(grep $gem_id data/tonsil_atlas_fastq_metadata.csv | cut -d, -f6 | head -n1)


# Rename fastq files given cellranger-friendly names, accounting for library_type
# For cell-hashed we follow the feature barcoding pipeline from cellranger
if [ "$library_type" == "not_hashed" ]; then
    echo "Library type is not hashed"
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

else
    echo "Library type is hashed"
    # Rename fastqs cDNA
    mkdir -p $gem_id/fastqs/cDNA
    fastqs_dna=$(ls -ath ${gem_id}/fastqs | grep ".fastq.gz" | grep cdna)
    declare -A lane_dict_cdna
    counter=1
    pair_ids_cdna=$(ls $gem_id/fastqs | grep ".fastq.gz" | grep cdna | cut -d'.' -f7 | sort | uniq)
    for pair_id in $pair_ids_cdna; do
        echo $pair_id
        lane_dict_cdna[$pair_id]=$counter
        ((counter++))
    done
    for fastq in $fastqs_dna; do
        read=$(echo $fastq | cut -d'.' -f8)
        pair_id=$(echo $fastq | cut -d'.' -f7)
        lane=${lane_dict_cdna[$pair_id]}
        new_name="${gem_id}_S1_L00${lane}_${read}_001.fastq.gz"
        echo "Creating symbolic link for $fastq as $new_name"
        ln -s "$working_dir/$gem_id/fastqs/$fastq" "$working_dir/$gem_id/fastqs/cDNA/$new_name"
    done
    
    
    # Rename fastqs HTO
    mkdir -p $gem_id/fastqs/hto
    fastqs_hto=$(ls -ath ${gem_id}/fastqs | grep ".fastq.gz" | grep hto)
    declare -A lane_dict_hto
    counter=1
    pair_ids_hto=$(ls $gem_id/fastqs | grep ".fastq.gz" | grep hto | cut -d'.' -f7 | sort | uniq)
    for pair_id in $pair_ids_hto; do
        echo $pair_id
        lane_dict_hto[$pair_id]=$counter
        ((counter++))
    done
    for fastq in $fastqs_hto; do
        read=$(echo $fastq | cut -d'.' -f8)
        pair_id=$(echo $fastq | cut -d'.' -f7)
        lane=${lane_dict_hto[$pair_id]}
        new_name="${gem_id}_S1_L00${lane}_${read}_001.fastq.gz"
        echo "Creating symbolic link for $fastq as $new_name"
        ln -s "$working_dir/$gem_id/fastqs/$fastq" "$working_dir/$gem_id/fastqs/hto/$new_name"
    done
    
    
    # Rename fastqs and create libraries.csv file
    echo "fastqs,sample,library_type" > $working_dir/$gem_id/libraries.csv
    echo "${working_dir}/${gem_id}/fastqs/cDNA/,${gem_id},Gene Expression" >> $working_dir/$gem_id/libraries.csv
    echo "${working_dir}/${gem_id}/fastqs/hto/,${gem_id},Antibody Capture" >> $working_dir/$gem_id/libraries.csv
    
    
    # Create feature_reference.csv
    head -n1 cell_hashing_metadata.csv | cut -d, -f3-8 > $working_dir/$gem_id/feature_reference.csv
    grep $gem_id cell_hashing_metadata.csv | cut -d, -f3-8 >> $working_dir/$gem_id/feature_reference.csv
    
    
fi

### Simplified version by GPT4o
#!/bin/bash
# This script runs cellranger for a given gem_id
# The first argument ($1) should be the gem_id

# Get library type for that gem_id 
gem_id=$1
working_dir=$(pwd)
library_type=$(grep $gem_id data/tonsil_atlas_fastq_metadata.csv | cut -d, -f6 | head -n1)

# Function to create symbolic links with cellranger-friendly names
create_symlinks() {
    local fastq_dir=$1
    local output_dir=$2
    local suffix=$3

    mkdir -p "$output_dir"
    declare -A lane_dict
    counter=1
    pair_ids=$(ls "$fastq_dir" | grep "$suffix" | cut -d'.' -f7 | sort | uniq)

    for pair_id in $pair_ids; do
        lane_dict[$pair_id]=$counter
        ((counter++))
    done

    for fastq in $(ls "$fastq_dir" | grep "$suffix"); do
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
    create_symlinks "$gem_id/fastqs" "$gem_id/fastqs" ""
else
    echo "Library type is hashed"
    
    # Rename fastqs cDNA
    create_symlinks "$gem_id/fastqs" "$gem_id/fastqs/cDNA" "cdna"
    
    # Rename fastqs HTO
    create_symlinks "$gem_id/fastqs" "$gem_id/fastqs/hto" "hto"
    
    # Create libraries.csv file
    cat <<EOL > "$working_dir/$gem_id/libraries.csv"
fastqs,sample,library_type
${working_dir}/${gem_id}/fastqs/cDNA/,${gem_id},Gene Expression
${working_dir}/${gem_id}/fastqs/hto/,${gem_id},Antibody Capture
EOL

    # Create feature_reference.csv
    head -n1 cell_hashing_metadata.csv | cut -d, -f3-8 > "$working_dir/$gem_id/feature_reference.csv"
    grep $gem_id cell_hashing_metadata.csv | cut -d, -f3-8 >> "$working_dir/$gem_id/feature_reference.csv"
fi

