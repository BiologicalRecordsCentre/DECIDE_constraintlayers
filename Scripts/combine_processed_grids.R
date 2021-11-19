# combine all the processed .RDS files into a big raster
library(purrr)
library(raster)
library(dplyr) # or magrittr for the pipe (%>%)

#set working directory to `/processed_data`
if(F){
  setwd("/data/data/DECIDE_constraintlayers/processed_data") # datalabs
}

# run these lines in R on jasmin

#load in all the data
df <- list.files(pattern = ".RDS") %>%
  map(readRDS) %>% 
  bind_rows()

#make a raster from the data
big_raster <- rasterFromXYZ(df)





#set the CRS
#crs(big_raster) <- 27700
crs(big_raster) <- "+proj=tmerc +lat_0=49 +lon_0=-2 +k=0.9996012717 +x_0=400000 +y_0=-100000 +ellps=airy +datum=OSGB36 +units=m +no_defs"

#does it look right?
big_raster

#write the raster
writeRaster(big_raster,"access_raster_full.grd",overwrite=TRUE)

#plot(big_raster)


