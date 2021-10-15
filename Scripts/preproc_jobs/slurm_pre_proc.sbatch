#!/bin/bash 
#SBATCH --partition=short-serial 
#SBATCH --job-name=accessLayerPreProcessing
#SBATCH -o out/%A/%a.out
#SBATCH -e err/%A/%a.err
#SBATCH --time=60:00
#SBATCH --array=1-3025
#SBATCH --mem=16000
module add jaspy/3.7/r20200606
Rscript preprocessing_access_layers_job_slurm.R ${SLURM_ARRAY_TASK_ID}
