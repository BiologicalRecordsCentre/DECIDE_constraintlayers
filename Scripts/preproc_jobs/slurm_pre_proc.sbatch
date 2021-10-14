#!/bin/bash 
#SBATCH --partition=short-serial 
#SBATCH --job-name=accessLayerPreProcessing
#SBATCH -o %A_%a.out
#SBATCH -e %A_%a.err
#SBATCH --time=30:00
#SBATCH --array=1-3025
module add jaspy/3.7/r20200606
Rscript preprocessing_access_layers_job_slurm.R ${SLURM_ARRAY_TASK_ID}