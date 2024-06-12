# This script downloads all fastqs for a given gem_id (Gel-Bead-in-Emulsion)
# first argument ($1) needs to be the actual gem_id

mkdir -p $1/fastqs
grep $1 fastq_list_tonsil_atlas_scRNA.tsv | cut -f8 | xargs -n 1 -P 4 -I {} wget -P $1/fastqs {}