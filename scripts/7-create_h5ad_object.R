# This script creates the final matrix from the subsetted matrices for each gem_id
# and saves it as h5ad and RDS (AnnData and SingleCellExperiment)


# Load packages
library(Seurat)
library(zellkonverter)
library(SingleCellExperiment)
library(here)
library(tidyverse)


# Check that all features match for all gem_ids
directories <- list.dirs(path = here("data/subsetted_matrices"), full.names = TRUE, recursive = FALSE)
read_first_column <- function(dir) {
    file_path <- file.path(dir, "genes.tsv")
    read_tsv(file_path, col_names = FALSE, col_types = cols())[[1]]
}
gene_ids_list <- map(directories, read_first_column)
all_identical <- all(map_lgl(gene_ids_list, \(x) identical(x, gene_ids_list[[1]])))
if (all_identical) {
    print("All features are identical for all gem_ids")
} else {
    stop("Features are different!")
}


# Merge matrices
matrices <- map(directories, Read10X, gene.column = 1)
combined_matrix <- do.call(cbind, matrices)
rm(matrices)
gc()


# Ensure that the cell barcodes and features match the ones in the tonsil atlas
tonsil <- HCATonsilData(assayType = "RNA", cellType = "All")
tonsil <- tonsil[, tonsil$assay != "multiome"]
if (setequal(colnames(tonsil), colnames(combined_matrix))) {
    print("All columns are equal")
} else {
    stop("Columns do not match!")
}


# Get Azimuth annotation
azimuth_annot_url <- "https://raw.githubusercontent.com/satijalab/azimuth-references/master/human_tonsil_v2/data/celltype_annotations.csv"
download.file(url = azimuth_annot_url, destfile = here("data/azimuth_annotations.csv"))
azimuth_annot <- read_csv(here("data/azimuth_annotations.csv"), col_names = TRUE)
colnames(azimuth_annot) <- c("barcode", "azimuth.celltype.l1", "azimuth.celltype.l2")


# Get metadata and create SingleCellExperiment
combined_matrix <- combined_matrix[, colnames(tonsil)]
coldata <- as.data.frame(colData(tonsil))
coldata <- left_join(coldata, azimuth_annot, by = "barcode")
rownames(coldata) <- coldata$barcode
rowdata <- read_tsv(
    here("data/subsetted_matrices/altbaco5_45sf3wul/genes.tsv"),
    col_names = c("ensembl_id", "gene_symbol")
)
rowdata <- as.data.frame(rowdata)
rownames(rowdata) <- rowdata$ensembl_id
sce <- SingleCellExperiment(
    list(counts = combined_matrix),
    colData = coldata,
    rowData = rowdata,
    metadata = list(
        Study = "10.1016/j.immuni.2024.01.006",
        ArrayExpress = "E-MTAB-13687",
        Zenodo = "10.5281/zenodo.11355186",
        HCATonsilData = "bioconductor.org/packages/release/data/experiment/html/HCATonsilData.html",
        Azimuth = "https://azimuth.hubmapconsortium.org/references/#Human%20-%20Tonsil%20v2",
        GitHub = "github.com/Single-Cell-Genomics-Group-CNAG-CRG/TonsilAtlas"
    )
)


# Save h5ad and SingleCellExperiment objects
dir.create(here("data/processed_objects"))
saveRDS(sce, here("data/processed_objects/TonsilAtlasSCE.rds"))
writeH5AD(sce, file = here("data/processed_objects/TonsilAtlas.h5ad"))

          