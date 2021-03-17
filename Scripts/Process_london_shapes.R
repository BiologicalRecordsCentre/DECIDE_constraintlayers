library(sf)
library(tidyverse)
library(foreach)
library(doParallel)

# unzip('Data/raw_data/greater-london-latest-free.shp.zip',
#       exdir='Data/raw_data/greater-london-latest-free/')

list.files('Data/raw_data/greater-london-latest-free/')

lond_builds <- st_read('Data/raw_data/greater-london-latest-free/gis_osm_buildings_a_free_1.shp') ## buildings
plot(st_geometry(lond_builds))

lond_pofw <- st_read('Data/raw_data/greater-london-latest-free/gis_osm_pofw_a_free_1.shp') ## places of worship
plot(st_geometry(lond_prow))  

lond_natural <- st_read('Data/raw_data/greater-london-latest-free/gis_osm_natural_free_1.shp') ## natural features e.g. trees
lond_natural
plot(st_geometry(lond_natural), pch = 20, cex = 0.5)

lond_roads <- st_read('Data/raw_data/greater-london-latest-free/gis_osm_roads_free_1.shp') ## roads including all paths/bridleways etc.
lond_roads

unique(lond_roads$fclass)

lond_paths <- lond_roads[lond_roads$fclass %in% unique(lond_roads$fclass)[c(5,11,15,16,17,20:22,24,25,27)],]
unique(lond_paths$fclass)

lond_paths <- st_transform(lond_paths, crs = 27700)

ggplot() +
  geom_sf(data=lond_paths, aes(colour = fclass)) +
  theme_bw()


# jon's house 
source("/data/notebooks/rstudio-adaptsampthomas/DECIDE_adaptivesampling/Scripts/modules/filter_distance.R")
jons <- filter_distance(lond_paths,
                        location = c(-0.028030, 51.530894),
                        method = 'buffer',
                        distance = 5000)

ggplot() +
  geom_sf(data = jons, aes(colour = fclass)) +
  theme_bw()


### can I crop it by 1km and replace the files that I've already created, rather than running the whole thing again?
# read in map and grid of desired cell size
uk <- st_read('/data/notebooks/rstudio-setupconsthomas/DECIDE_constraintlayers/Data/raw_data/UK_grids/uk_map.shp')
uk_grid <- st_read('/data/notebooks/rstudio-setupconsthomas/DECIDE_constraintlayers/Data/raw_data/UK_grids/uk_grid_10km.shp')

st_crs(uk) <- 27700
st_crs(uk_grid) <- 27700

plot(st_geometry(uk), reset = T)
plot(st_geometry(uk_grid), add = T, border = 'orange')

prow_loc <- '/data/notebooks/rstudio-setupconsthomas/DECIDE_constraintlayers/Data/raw_data/rowmaps_footpathbridleway/rowmaps_footpathbridleway/gridded_data_10km'
list.files(prow_loc)

# which grids intersect london?
grid_num <- st_intersects(lond_paths, uk_grid, sparse = T)
lond_ints <- apply(st_intersects(uk_grid, lond_paths, sparse = FALSE), 1, any)
unique(uk_grid$FID[lond_ints])

# check
plot(st_geometry(uk), reset = T)
plot(st_geometry(uk_grid), add = T, border = 'orange')
plot(st_geometry(uk_grid[lond_ints,]), add = T, border = 'red')
## looks good!

for(i in c(350:600)) {
  
  print(i)
  
  lond_paths_sub <- lond_paths[st_intersects(lond_paths, uk_grid[i,], sparse = F),]
  
  if(dim(lond_paths_sub)[1] == 0){
    print('###   skipping to next grid, not london   ###')
    next
  }
  
  # original prow files
  prow_files <- list.files(prow_loc,
                           full.names = T,
                           pattern = paste0('_', i, '.shp'))
  
  orig_file <- st_read(prow_files)
  
  
  # if(dim(orig_file)[1]>0 && dim(lond_paths_sub)[1] > 0){
  #   
  #   print('###   merging datasets   ###')
  #   
  #   out_file <- st_join(lond_paths_sub, orig_file)
  #   
  # } else 
  # if(dim(orig_file)[1]==0 && 
  if(dim(lond_paths_sub)[1] > 0){
    
    print('###   only paths from london being saved   ###')
    
    out_file <- lond_paths_sub
    
  } else {
    
    print(i)
    stop('!!!!!     Something weird going on, stopping     !!!!!')
    
  }
  
  # save output
  print('#####    saving output     #####')
  
  st_write(out_file, dsn = paste0('Data/raw_data/rowmaps_footpathbridleway/rowmaps_footpathbridleway/gridded_data_10km/prow_gridnumber_',i,'.shp'),
           driver = "ESRI Shapefile", delete_layer = T)
  
}







