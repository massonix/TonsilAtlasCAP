# TonsilAtlasCAP

The following steps document how to download all raw fastq files for the scRNA-seq data of the
tonsil atlas from [ArrayExpress](https://www.ebi.ac.uk/biostudies/arrayexpress/studies/E-MTAB-13687) and subsequently use them as input to run [Cellranger](https://www.10xgenomics.com/support/software/cell-ranger/latest) to obtain
expression matrices. We will then upload the resulting matrix to the Cell Annotation Platform (CAP).


Step 1: clone this repository

```{bash}
git clone https://github.com/massonix/TonsilAtlasCAP.git
```


Step 2: download list of fastq files, relevant metadata, cellranger and human genome reference

```{bash}
bash scripts/1-download_software_and_metadata.sh
```


Step 3: download fastq files. For one sample (gem_id, Gel Bead in-emulsion):

```{bash}
gem_id=jb6vuao4_g4vi9ur0
bash scripts/2-download_fastq_files.sh $gem_id
```

We recommend parallelize the previous script across all gem_ids using a high performance computer (HPC, cluster).
For a SLURM-based cluster we can run it as follows:

```{bash}
gem_ids=$(cat data/tonsil_atlas_fastq_metadata.csv | grep -v technology | cut -d, -f4 | sort | uniq)
mkdir -p log
for gem_id in $gem_ids; do
    echo $gem_id
    sbatch -J $gem_id --error="log/${gem_id}_download_fastqs.err" --output="log/${gem_id}_download_fastqs.log" -c 8 --time=06:00:00 --mem=64G --wrap="
        echo [$(date '+%Y-%m-%d %T')] starting job on $HOSTNAME
        bash scripts/2-download_fastq_files.sh $gem_id
        echo [$(date '+%Y-%m-%d %T')] job finished"
done
```