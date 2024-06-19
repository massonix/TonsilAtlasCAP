# TonsilAtlasCAP

The following steps document how to download all raw fastq files for the scRNA-seq data of the
tonsil atlas from [ArrayExpress](https://www.ebi.ac.uk/biostudies/arrayexpress/studies/E-MTAB-13687) and subsequently use them as input to run [Cellranger](https://www.10xgenomics.com/support/software/cell-ranger/latest) to obtain
expression matrices. We will then upload the resulting matrix to the Cell Annotation Platform (CAP).


## Step 1: clone this repository

```{bash}
git clone https://github.com/massonix/TonsilAtlasCAP.git
```


## Step 2: download list of fastq files, relevant metadata, cellranger and human genome reference

```{bash}
bash scripts/1-download_software_and_metadata.sh
```


## Step 3: download fastq files. For one sample (gem_id, Gel Bead in-emulsion)

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
    sbatch -J $gem_id --error="log/${gem_id}_download_fastqs.err" --output="log/${gem_id}_download_fastqs.log" -c 8 --time=14:00:00 --mem=96G --wrap="
        echo [$(date '+%Y-%m-%d %T')] starting job on $HOSTNAME
        bash scripts/2-download_fastq_files.sh $gem_id
        echo [$(date '+%Y-%m-%d %T')] job finished"
done
```


## Step 4: Test that all fastq files were downloaded successfully

```{bash}
bash scripts/3-test_fastq_downloads.sh
```

This script will create the file data/test_fastq_downloads.txt, which will help find any empty or missing fastqs:

```{bash}
grep missing data/test_fastq_downloads.txt
```


## Step 5: create symbolic links to fastq files with cellranger-compatible names (see [this webpage](https://www.10xgenomics.com/support/software/cell-ranger/latest/analysis/inputs/cr-specifying-fastqs)):

For one gem_id:

```{bash}
gem_id=jb6vuao4_g4vi9ur0
bash scripts/4-rename_fastqs.sh $gem_id
```

To parallelize it across all gem_ids in a SLURM-based cluster:

```{bash}
gem_ids=$(cat data/tonsil_atlas_fastq_metadata.csv | grep -v technology | cut -d, -f4 | sort | uniq)
for gem_id in $gem_ids; do
    echo $gem_id
    sbatch -J $gem_id --error="log/${gem_id}_symlinks_fastq.err" --output="log/${gem_id}_symlinks_fastq.log" -c 4 --time=00:30:00 --mem=30G --wrap="
        echo [$(date '+%Y-%m-%d %T')] starting job on $HOSTNAME
        bash scripts/4-rename_fastqs.sh $gem_id $gem_id
        echo [$(date '+%Y-%m-%d %T')] job finished"
done
```


## Step 6: Run cellranger count

For one gem_id:

```{bash}
gem_id=jb6vuao4_g4vi9ur0
bash scripts/5-run_cellranger_count.sh $gem_id
```

To parallelize it across all gem_ids in a SLURM-based cluster:

```{bash}
gem_ids=$(cat data/tonsil_atlas_fastq_metadata.csv | grep -v technology | cut -d, -f4 | sort | uniq)
for gem_id in $gem_ids; do
    echo $gem_id
    sbatch -J $gem_id --error="log/${gem_id}_run_cellranger.err" --output="log/${gem_id}_run_cellranger.log" -c 12 --time=08:00:00 --mem=250G --wrap="
        echo [$(date '+%Y-%m-%d %T')] starting job on $HOSTNAME
        bash scripts/5-run_cellranger_count.sh $gem_id
        echo [$(date '+%Y-%m-%d %T')] job finished"
done
```


## Step 7: Check that all runs finished correctly

```{bash}
for gem_id in $(ls data/outs_cellranger/); do
  if [ -d "data/outs_cellranger/$gem_id/outs" ]; then
    echo "${gem_id},TRUE"
  else
    echo "${gem_id},FALSE"
  fi
done > data/test_cellranger_runs_finished.txt
```
