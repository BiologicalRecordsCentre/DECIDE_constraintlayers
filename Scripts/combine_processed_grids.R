# combine all the processed .RDS files into a big raster
library(purrr)
library(raster)

#set working directory to `/processed_data`

#load in all the data
df <- list.files(pattern = ".RDS") %>%
  map(readRDS) %>% 
  bind_rows()

#make a raster from the data
big_raster <- rasterFromXYZ(df)

#set the CRS
crs(big_raster) <- 27700

#does it look right?
big_raster

#write the raster
writeRaster(big_raster,"access_raster_full.grd")

#plot(big_raster)


