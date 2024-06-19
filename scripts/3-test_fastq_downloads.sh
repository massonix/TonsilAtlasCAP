#!/bin/bash

# List of FASTQ files (modify this to read from your file if needed)
fastq_files=$(cut -f 8 data/fastq_list_tonsil_atlas_scRNA.tsv | awk -F ';' '{split($1, a, "/"); split($2, b, "/"); print a[length(a)] ";" b[length(b)]}' | tr ";" "\n")

# Base directory where files are stored
base_dir="data/fastq"

# Function to check each file
check_file() {
  local file=$1
  local gem_id=$(echo $file | cut -d. -f4)

  if [ -f "$base_dir/$gem_id/$file" ]; then
    if [ -s "$base_dir/$gem_id/$file" ]; then
      echo "$file,present"
    else
      echo "$file,empty"
    fi
  else
    echo "$file,missing"
  fi
}

# Loop through each FASTQ file and check
for file in $fastq_files; do
  check_file "$file"
done > data/test_fastq_downloads.txt
