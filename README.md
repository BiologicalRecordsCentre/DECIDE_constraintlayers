# Processing the constraint layers for the DECIDE project

Collating and processing information about where recorders can or can't access for use in the DECIDE project. This project may be transferrable to other citizen science projects. This repository contains the code for downloading and processing constraint layers from a vareity of sources.

## Background

The DECIDE project aims to enhance biodiversity citizen science through adaptive sampling, by using intelligent digital engagements (co-designed with recorders) so that they re-deploy a portion of their effort to the times and places where records will optimally improve the model outputs.

The DECIDE tool is available here: [https://decide.ceh.ac.uk/](https://decide.ceh.ac.uk/)

Information about the DECIDE project is available here: [https://www.ceh.ac.uk/our-science/projects/decide](https://www.ceh.ac.uk/our-science/projects/decide)

An important part of adaptive sampling with citizen scientists is being able to direct them to places that they can actually access like green spaces such as parks, accessible along access routes such as footpaths. We want to ensure that any suggestion that we give to recorders is based on the best information we can have to ensure. This information we refer to as 'constraint layers' because they are map layers which in some way constrain where we can realisitically send recorders. These can be positive areas where we want to send recorders like open access land, or negative areas such as military areas where we do not want to send recorders. 

## About this repository

### File locations

The raw data is not stored in the repository and are intentionally stopped from being hosted in the GitHub repo by the `.gitignore` file.

**DataLabs**

Code is located at: `/data/notebooks/rstudio-conlayersimon/DECIDE_constraintlayers`

Data is located at `/data/data/DECIDE_constraintlayers`. 

![image](https://user-images.githubusercontent.com/17750766/137911089-2b69ae38-56f6-476d-bcb6-292286b818fc.png)


**JASMIN**

Code is located at: `/home/users/simrol/DECIDE/DECIDE_constraintlayers/`

Data is located at: `/home/users/simrol/DECIDE/`

![image](https://user-images.githubusercontent.com/17750766/137911281-1fe65709-ae1d-43cd-9087-f73d104b34ea.png)

Note that currently on JASMIN the data is located on a personal space `simrol` rather than a group workspace or the object store.

### File structure

**Data** (not in repository)

```
DECIDE_constraintlayers
│
└───raw_data
│   │
│   └───OSM
│   |   │   geofabrik_great-britain-latest.gpkg
│   |   │   ...
|   |
│   └───UK_grids
│   |   │   uk_grid_10km.shp
│   |   │   uk_grid_10km.prj
│   |   │   uk_grid_10km.dbf
│   |   │   uk_grid_10km.shx
│   │
│   └───CRoW_Act_2000_-_Access_Layer_(England)-shp
│   |   │
│   |   └───gridded_data_10km
│   |   │   access_land_gridnumber_33.shp
│   |   │   access_land_gridnumber_33.prj
│   |   │   access_land_gridnumber_33.dbf
│   |   │   access_land_gridnumber_33.shx
│   |   │   ...
│   |
│   └─── ...
│   
└───processed_data
|   │   access_raster_grid1.RDS
|   │   access_raster_grid2.RDS
|   │   ...
|
└───environmental_data
    │   100mRastOneLayer.gri
    │   100mRastOneLayer.grd
    │   100mrast_grid_1.RDS
    │   100mrast_grid_2.RDS
```

The `raw_data` holds the raw unprocessed data from any or all sources. The `OSM` folder is the download location for `osmextract` downloads (in `.osm.pbf` format) and subsequent vector translated `.gpkg` files with specifc features such as footpaths or water. The `UK_grids`folder contains a shapefile for the 3025 10km grid squares that cover the whole of the UK. There are one folder for each data layer (eg the public rights of way layer). Somewhere in each of these folders are folders containing the gridded 10km data in a folder called `gridded_data_10km` (or similar). File paths to these layers are defined in the `preprocessing_access_layers_v3.Rmd` script. New layers won't be picked up automatically so if you download a new layer of data then ensure you point the script to the folder containing the 10km gridded version of the script.

The `processed_data` folder contains a `.RDS` file which is a dataframe of the 100x100m grid square centroids and their accessibility value.

The `environmental_data` foder contains the UK 100x100m grid square raster, and the gridded version dataframe of this stored as `.RDS` files.

### Splitting national datasets into 10km grid squares (pre-pre-processing!)

This repository containts the scripts for processing the constraint layers. These scripts take the raw data files from the source do various processing steps and split them into 10km grid squares. It is these 10km grid squares that are loaded into the app. The scripts are located in the `/Scripts` folder. There is typically one script for processing each layer.

Note: as of 15/8/21 we have moved the file location of the data so running old scripts may fail and you will need to update the filepath. See: https://github.com/BiologicalRecordsCentre/DECIDE-app/issues/122

### Pre-processing the access layers into the 100m resolution access raster

The `preprocessing_access_layers_v3.Rmd` script contains the code but using the `purl ` function it generates a set of scripts that can either be run as jobs on Rstudio (https://solutions.rstudio.com/r/jobs/) or on JASMIN.

The JASMIN script is set up to take a single argument, the grid number (1-3025), and loads in all the relevant data for that grid square and returns a dataframe with easting, northing and access score. Navigate to the directory `DECIDE_constraintlayers/Scripts/preproc_jobs`

Test the script on a single grid square first:
```
module add jaspy/3.7/r20200606
Rscript preprocessing_access_layers_job_slurm.R 1313
```

Then run it with sbatch using the command
```
sbatch slurm_pre_proc.sbatch
```

Use this command to check the queue (replacing simrol with your JASMIN username)
```
squeue -u simrol
```

Here's a guide to the codes: https://slurm.schedmd.com/squeue.html#SECTION_JOB-STATE-CODES

### Generating maps

If the argument `produce_map` is `T` then the script will produce a leaflet map at https://github.com/BiologicalRecordsCentre/DECIDE_constraintlayers/tree/main/maps.

You can navigate to the right grid using the main grid map called `access_map_grid_master.html`.

## The constraint layers used for determing access score

Also outlined in excel sheet one OneDrive

### Offline files

 * CRoW (Countryside right of way act 2000)
 * Greater london
 * National Trust
 * OS green spaces
 * Footpath and bridleways
 * RSPB reserve boundaries (not currently used)
 * Scotland:
    * Cairngorms
    * Core paths
    * Local nature conservation sites
    * Local nature reserves
    * Lochlomond_tross
    * Public access rural
    * Public access wiat (woods in and around town: https://forestry.gov.scot/forests-people/communities/woods-in-and-around-towns-wiat)
    * Wildland Scotland

### OSM data

See https://github.com/BiologicalRecordsCentre/DECIDE_constraintlayers/blob/main/Scripts/preprocessing_access_layers_v3.md#data-preparation for query details

 * Access lines:
    * Footpath
    * bridleways
    * small roads
    * etc.
 * No go lines:
    * Motorways
    * Railways
 * No go areas:
    * Airports
    * Landfill sites
    * Quarrys
 * Water
