# This script processes the SingleCellExperiment object saved in the previous script
# It first converts it to a Seurat object and then runs the Seurat pipeline
# (https://satijalab.org/seurat/articles/pbmc3k_tutorial)


# Load packages
library(Seurat)
library(SingleCellExperiment)
library(scuttle)
library(harmony)
library(glue)
library(here)
library(tidyverse)


# Read data
sce <- readRDS(here("data/processed_objects/TonsilAtlasSCE.rds"))
sce

# Convert to Seurat and process
sce <- logNormCounts(sce, transform = "log")
se <- as.Seurat(sce)
se <- FindVariableFeatures(se)
se <- ScaleData(se)
se <- RunPCA(se)


# Save