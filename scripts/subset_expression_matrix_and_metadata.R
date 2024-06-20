# This script loads the expression matrix produced by cellranger count and
# subsets it to the high-quality cells in the tonsil atlas


# Load packages
library(Seurat)
library(SingleCellExperiment)
library(Matrix)
library(HCATonsilData)
library(tidyverse)
library(here)
library(glue)


# Read data
gem_ids <- list.dirs(here("data/outs_cellranger"), recursive = FALSE, full.names = FALSE)
cellranger_outs <- map(gem_ids, \(gem_id) {
  print(gem_id)
  outs_dir <- here(glue("data/outs_cellranger/{gem_id}/outs/raw_filtered_feature_bc_matrix"))
  mat <- Read10X(outs_dir, gene.column = 1)
  if (class(mat) == "list") {
    mat <- mat$`Gene Expression`
  }
  colnames(mat) <- glue("{gem_id}_{colnames(mat)}")
  features <- read_tsv(
    glue("{outs_dir}/features.tsv.gz"),
    col_names = c("gene_id", "gene_symbol", "gene_type")
  )
  out <- list(mat = mat, features = features)
  out
})
names(cellranger_outs) <- gem_ids


# Download SingleCellExperiment object of all tonsillar cell and filter out multiome
tonsil <- HCATonsilData(assayType = "RNA", cellType = "All")
tonsil <- tonsil[, tonsil$assay != "multiome"]


# Check that all cells in SingleCellExperiment object for that gem_id are in the
# expression matrix
mats_sub <- map(gem_ids, \(gem_id) {
  tonsil_sub <- tonsil[, tonsil$gem_id == gem_id]
  mat <- cellranger_outs[[gem_id]]$mat
  if (all(colnames(tonsil_sub) %in% colnames(mat))) {
    mat_sub <- mat[, colnames(tonsil_sub)]
  } else {
    stop("Cell barcodes do not match!")
  }
  mat_sub
})


# Add Azimuth annotation
azimuth_annot_url <- "https://raw.githubusercontent.com/satijalab/azimuth-references/master/human_tonsil_v2/data/celltype_annotations.csv"
download.file(url = azimuth_annot_url, destfile = here("data/azimuth_annotations.csv"))
azimuth_annot <- read_csv(here("data/azimuth_annotations.csv"), col_names = TRUE)
colnames(azimuth_annot) <- c("barcode", "azimuth.celltype.l1", "azimuth.celltype.l2")




# Subset metadata
cell_metadata <- as.data.frame(colData(tonsil_sub))[colnames(mat_sub), ]
cell_metadata <- left_join(cell_metadata, azimuth_annot, by = "barcode")


# Save
DropletUtils::write10xCounts(
  x = mat_sub,
  path = here(glue("data/{gem_id}_subsetted_matrix")),
  barcodes = colnames(mat_sub),
  gene.id = rownames(mat_sub),
  gene.symbol = features$gene_symbol,
  type = "sparse"
)
write_delim(
  cell_metadata,
  file = here(glue("data/{gem_id}_cell_metadata.tsv")),
  col_names = TRUE,
  delim = ";"
)
