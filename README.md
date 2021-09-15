# Processing the constraint layers for the DECIDE project

## Background

The DECIDE project aims to enhance biodiversity citizen science through adaptive sampling, by using intelligent digital engagements (co-designed with recorders) so that they re-deploy a portion of their effort to the times and places where records will optimally improve the model outputs.

The DECIDE tool is available here: https://decide.ceh.ac.uk/

An important part of adaptive sampling with citizen scientists is being able to direct them to places that they can actually access like green spaces such as parks, accessible along access routes such as footpaths. We want to ensure that any suggestion that we give to recorders is based on the best information we can have to ensure. This information we refer to as 'constraint layers' because they are map layers which in some way constrain where we can realisitically send recorders. These can be positive areas where we want to send recorders like open access land, or negative areas such as military areas where we do not want to send recorders. 

## About this repository

This repository containts the scripts for processing the constraint layers. These scripts take the raw data files from the source do various processing steps and split them into 10km grid squares. It is these 10km grid squares that are loaded into the app. The scripts are located in the `/Scripts` folder. There is typically one script for processing each layer.

The raw data is not stored in the repository, but are stored on Datalabs in this file location `/data/data/DECIDE_constraintlayers`. Within that folder there is a folder called `raw_data` which then contains one folder for each data layer. Somewhere in each of these folders are folders containing the gridded 10km data in a folder called `gridded_data_10km` or something similar.

Note: as of 15/8/21 we have moved the file location of the data so running old scripts may fail and you will need to update the filepath. See: https://github.com/BiologicalRecordsCentre/DECIDE-app/issues/122

## The constraint layers

### Have got data on

 * CRoW
 * Greater london 
 * Land cover map 2019
 * Military areas (Work in progress)
 * National Trust
 * OS green spaces
 * OS roadnetwork
 * Footpath and bridleways
 * RSPB reserve boundaries
 * Scotland:
    * Cairngorms
    * Core paths
    * Local nature conservation sites
    * Local nature reserves
    * Lochlomond_tross
    * Public access rural
    * Public access wiat
    * Wildland Scotland
 * SSSIs
