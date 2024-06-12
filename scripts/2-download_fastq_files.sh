# This script downloads all fastqs for a given gem_id (Gel-Bead-in-Emulsion)
# first argument ($1) needs to be the actual gem_id

mkdir -p data/fastq/$1
grep $1 data/fastq_list_tonsil_atlas_scRNA.tsv | cut -f8 | tr ';' '\n' | xargs -n 1 -P 4 -I {} wget -P data/fastq/$1 {}