# This script loads the expression matrix produced by cellranger count and
# subsets it to the high-quality cells in the tonsil atlas for a given GEM id


# Load packages
library(Seurat)
library(SingleCellExperiment)
library(Matrix)
library(HCATonsilData)
library(DropletUtils)
library(tidyverse)
library(here)
library(glue)


# Parse command-line arguments
args <- commandArgs(trailingOnly = TRUE)
gem_id <- args[[1]]


# Read data
outs_dir <- here(glue("data/outs_cellranger/{gem_id}/outs/raw_feature_bc_matrix"))
mat <- Read10X(outs_dir, gene.column = 1)
if (class(mat) == "list") {
  mat <- mat$`Gene Expression`
}
colnames(mat) <- glue("{gem_id}_{colnames(mat)}")
features <- read_tsv(
  glue("{outs_dir}/features.tsv.gz"),
  col_names = c("gene_id", "gene_symbol", "gene_type")
)
features <- features[features$gene_type == "Gene Expression", ]
if (!all(features$gene_id == rownames(mat))){
  stop("Features do not match!")
}


# Download SingleCellExperiment object of all tonsillar cell and filter out multiome
tonsil <- HCATonsilData(assayType = "RNA", cellType = "All")
tonsil <- tonsil[, tonsil$assay != "multiome"]


# # Add Azimuth annotation
# azimuth_annot_url <- "https://raw.githubusercontent.com/satijalab/azimuth-references/master/human_tonsil_v2/data/celltype_annotations.csv"
# download.file(url = azimuth_annot_url, destfile = here("data/azimuth_annotations.csv"))
# azimuth_annot <- read_csv(here("data/azimuth_annotations.csv"), col_names = TRUE)
# colnames(azimuth_annot) <- c("barcode", "azimuth.celltype.l1", "azimuth.celltype.l2")
# 

# Check that all cells in SingleCellExperiment object for that gem_id are in the
# expression matrix
tonsil_sub <- tonsil[, tonsil$gem_id == gem_id]
if (all(colnames(tonsil_sub) %in% colnames(mat))) {
  mat_sub <- mat[, colnames(tonsil_sub)]
} else {
  stop("Cell barcodes do not match!")
}
rm(mat)
gc()


# Save
dir.create(here(glue("data/subsetted_matrices/")), recursive = TRUE)
DropletUtils::write10xCounts(
  x = mat_sub,
  path = here(glue("data/subsetted_matrices/{gem_id}")),
  barcodes = colnames(mat_sub),
  gene.id = rownames(mat_sub),
  gene.symbol = features$gene_symbol,
  type = "sparse"
)
