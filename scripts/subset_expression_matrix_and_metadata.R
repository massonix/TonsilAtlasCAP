# This script loads the expression matrix produced by cellranger count and
# subsets it to the high-quality cells in the tonsil atlas for a given GEM id


# Load packages
library(Seurat)
library(SingleCellExperiment)
library(Matrix)
library(HCATonsilData)
library(tidyverse)
library(here)
library(glue)


# Read data
gem_id <- "y7qn780g_p6jkgk63"
mat <- Read10X(here("data/filtered_feature_bc_matrix"), gene.column = 1)
colnames(mat) <- glue("{gem_id}_{colnames(mat)}")
features <- read_tsv(
    here("data/filtered_feature_bc_matrix/features.tsv.gz"),
  col_names = c("gene_id", "gene_symbol", "gene_type")
)


# Download SingleCellExperiment object of all tonsillar cell and filter out multiome
tonsil <- HCATonsilData(assayType = "RNA", cellType = "All")
tonsil <- tonsil[, tonsil$assay != "multiome"]


# Add Azimuth annotation
azimuth_annot_url <- "https://raw.githubusercontent.com/satijalab/azimuth-references/master/human_tonsil_v2/data/celltype_annotations.csv"
download.file(url = azimuth_annot_url, destfile = here("data/azimuth_annotations.csv"))
azimuth_annot <- read_csv(here("data/azimuth_annotations.csv"), col_names = TRUE)
colnames(azimuth_annot) <- c("barcode", "azimuth.celltype.l1", "azimuth.celltype.l2")


# Check that all cells in SingleCellExperiment object for that gem_id are in the
# expression matrix
tonsil_sub <- tonsil[, tonsil$gem_id == gem_id]
if (all(colnames(tonsil_sub) %in% colnames(mat))) {
  mat_sub <- mat[, colnames(tonsil_sub)]
} else {
  stop("Cell barcodes do not match!")
}


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
