job_id <- 8
setwd("/data/notebooks/rstudio-conlayersimon/DECIDE_constraintlayers/Scripts")

#THIS LINE IS REPLACED WITH JOB ID ASSIGNMENT
#load packages
library(osmdata) #for using overpass API
library(sf)
library(leaflet) # for making maps for sanity checking
library(raster)
library(rgdal)
library(dplyr)
library(htmlwidgets)







## ----access_offline_data---------------------------------------------------------------------------------
#base location
base_location <- '/data/data/DECIDE_constraintlayers/raw_data/'

#folders
file_locations <- c(
  'CRoW_Act_2000_-_Access_Layer_(England)-shp/gridded_data_10km/',
  'OS_greenspaces/OS Open Greenspace (ESRI Shape File) GB/data/gridded_greenspace_data_10km/',
  #'SSSIs/gridded_data_10km/',
  'greater-london-latest-free/london_gridded_data_10km/',
  'rowmaps_footpathbridleway/rowmaps_footpathbridleway/gridded_data_10km/',
  #'RSPB_Reserve_Boundaries/gridded_data_10km/',
  'national_trust/gridded_data_10km/'
)

# function to get the data
get_offline_gridded_data <- function(grid_number){
  returned_files <- list()
  
  for (ii in 1:length(file_locations)){
    file_location <- file_locations[ii]
    all_grids <- list.files(paste0(base_location,file_location))
    
    right_file <- all_grids[grep(paste0("_",grid_number,".shp"), all_grids)]
    
    if (length(right_file)>0){
      #build file path
      file_path <- paste0(base_location,file_location,right_file)
      
      #load in file
      file_shp <- st_read(file_path, quiet = TRUE) %>% st_transform(4326)
      
      #add it to the object that this function returns
      returned_files[[length(returned_files)+1]] <- file_shp
    }
  }
  #return the files
  returned_files
}

# test <- get_offline_gridded_data(1516)
# 
# #check access with lapply
check_access_lapply <- function(...){
  st_is_within_distance(...) %>% rowSums()
}
# 
# test2 <- lapply(test,check_access_lapply,x = raster_as_sf,dist = 100,sparse = FALSE) %>% Reduce(f='+')




## ----data_processing-------------------------------------------------------------------------------------
sf::sf_use_s2(T)

#load in required to do the job

uk_grid <- st_read('/data/data/DECIDE_constraintlayers/raw_data/UK_grids/uk_grid_10km.shp')
st_crs(uk_grid) <- 27700

# the big raster
raster100 <- raster::stack('/data/data/DECIDE_constraintlayers/environmental_data/100mRastOneLayer.grd')
#plot(raster100)
#get the CRS for when we project back to raster from data ramew
raster_crs <- st_crs(raster100)
raster100_df <- as.data.frame(raster100, xy=T, centroids=TRUE)[,1:2]


#for testing:
#grid_number <- 1516
#grids <- uk_grid
#raster_df <- raster100_df

#define the function for assessing accessibility
assess_accessibility <- function(grid_number,grids,raster_df,produce_map = F){
  
  #load 10k grid
  this_10k_grid <- grids[grid_number,]$geometry #get the 10kgrid
  this_10k_gridWGS84 <- st_transform(this_10k_grid, 4326) # convert to WGS84
  grid_bb <- st_bbox(this_10k_grid)
  
  #get the centroids of the the 100m grids within the 10k grid
  raster_this_grid <- raster100_df %>% filter(x > grid_bb$xmin,
                                              x < grid_bb$xmax,
                                              y > grid_bb$ymin,
                                              y < grid_bb$ymax)
  
  #get the easting and northing projection
  projcrs <- crs(this_10k_grid)
  
  # make the raster df into a sd object using the projection but transform it to WGS84 for these operations
  raster_as_sf <- st_as_sf(raster_this_grid,coords = c("x", "y"),crs = projcrs) %>% st_transform(4326)
  
  this_10k_gridWGS84_wkt <- this_10k_gridWGS84 %>% st_as_text()
  
  # load OSM data
  osm_layer1 <- st_read("/data/data/DECIDE_constraintlayers/raw_data/OSM/access_lines.gpkg",
                        wkt_filter = this_10k_gridWGS84_wkt,
                        quiet = T
                        )

  osm_layer2 <- st_read("/data/data/DECIDE_constraintlayers/raw_data/OSM/no_go_lines.gpkg",
                        wkt_filter = this_10k_gridWGS84_wkt,
                        quiet = T
                        )

  osm_layer3_no_go <- st_read("/data/data/DECIDE_constraintlayers/raw_data/OSM/no_go_areas.gpkg",
                        wkt_filter = this_10k_gridWGS84_wkt,
                        quiet = T
                        ) %>% filter(landuse != "military")
  
  osm_layer3_warn <- st_read("/data/data/DECIDE_constraintlayers/raw_data/OSM/no_go_areas.gpkg",
                        wkt_filter = this_10k_gridWGS84_wkt,
                        quiet = T
                        ) %>% filter(landuse == "military")

  osm_layer4 <- st_read("/data/data/DECIDE_constraintlayers/raw_data/OSM/water_areas.gpkg",
                        wkt_filter = this_10k_gridWGS84_wkt,
                        quiet = T
                        )
  
  
  # Load offline data
  offline_good_features_data <- get_offline_gridded_data(grid_number)
  
  
  #vectors for filling with info
  distance_check_bad <- distance_check_good <- distance_check_warning <- distance_check_water <- rep(0,nrow(raster_this_grid))
  
  #checking access for offline layers
  #first try using lapply because it's quickest but then there's an alternative approch which is slower by copes with the spherical geometry issue that sometimes occurs
  tryCatch({
    if (length(offline_good_features_data)>0){
      distance_check_good <- lapply(offline_good_features_data,check_access_lapply,x = raster_as_sf,dist = 100,sparse = FALSE) %>% Reduce(f='+')
    }
  }, error = function(err) {
    sf::sf_use_s2(F)
    
    
    if (length(offline_good_features_data)>0){
      for (ii in 1:length(offline_good_features_data)){
        distance_check_good <- distance_check_good + rowSums(st_is_within_distance(raster_as_sf,offline_good_features_data[[ii]]$geometry,dist = 100,sparse = FALSE))
      }
    }

    sf::sf_use_s2(T)
  })
  
  
  tryCatch({
    #check OSM data
    #good lines
    distance_check_good <- distance_check_good + rowSums(st_is_within_distance(raster_as_sf,osm_layer1,dist = 100,sparse = FALSE))  
    
    #bad lines and areas
    distance_check_bad <- distance_check_bad + rowSums(st_is_within_distance(raster_as_sf,osm_layer2,dist = 50,sparse = FALSE)) + rowSums(st_is_within_distance(raster_as_sf,osm_layer3_no_go,dist = 25,sparse = FALSE)) 
    
    # warning areas
    distance_check_warning <- distance_check_warning + rowSums(st_is_within_distance(raster_as_sf,osm_layer3_warn,dist = 25,sparse = FALSE))
    
    #Water
    distance_check_water <- distance_check_water + rowSums(st_is_within_distance(raster_as_sf,osm_layer4,dist = 0,sparse = FALSE))
    
  }, error = function(err){
    #same as before but without spherical geometry
    sf::sf_use_s2(F)
    distance_check_good <- distance_check_good + rowSums(st_is_within_distance(raster_as_sf,osm_layer1,dist = 100,sparse = FALSE))  
    distance_check_bad <- distance_check_bad + rowSums(st_is_within_distance(raster_as_sf,osm_layer2,dist = 50,sparse = FALSE)) + rowSums(st_is_within_distance(raster_as_sf,osm_layer3_no_go,dist = 25,sparse = FALSE)) 
    distance_check_warning <- distance_check_warning + rowSums(st_is_within_distance(raster_as_sf,osm_layer3_warn,dist = 25,sparse = FALSE))
    distance_check_water <- distance_check_water + rowSums(st_is_within_distance(raster_as_sf,osm_layer4,dist = 0,sparse = FALSE))
    sf::sf_use_s2(T)
  })
  
  
  
  # water buffering options (currently not used)
  # if(sum(distance_check_water>0)>0){
  #   buffered_water_points <- raster_as_sf[distance_check_water>0,] %>% st_buffer(dist=50)
  #   points_in_water <- st_covered_by(buffered_water_points,osm_layer4,sparse = F) %>% rowSums()
  #   rownames(buffered_water_points)[points_in_water>0]
  #   distance_check_water <- 0
  #   distance_check_water[rownames(raster_as_sf) %in% rownames(buffered_water_points)[points_in_water>0]] <- 1
  # }
  
  
  raster_as_sf$access <- distance_check_good
  raster_as_sf$no_go <- distance_check_bad
  raster_as_sf$warning <- distance_check_warning
  raster_as_sf$water <- distance_check_water
  
  raster_as_sf$composite <- 0.5 # neutral
  raster_as_sf$composite[raster_as_sf$no_go>0 | raster_as_sf$warning > 0] <- 0 #no go
  raster_as_sf$composite[raster_as_sf$access>0 & raster_as_sf$no_go==0] <- 1 #go
  raster_as_sf$composite[raster_as_sf$access>0 & raster_as_sf$warning > 0] <- 0.75 # warning
  raster_as_sf$composite[raster_as_sf$water>0] <- 0.25 #water
  
  if(produce_map){
    m <- leaflet() %>%
      addTiles() %>%
      addPolylines(data = osm_layer1,weight = 1) %>%
      addPolylines(data = osm_layer2,weight = 1,color = "red") %>%
      addPolygons(data = osm_layer3_warn,weight = 1,fillColor ="orange") %>%
      addPolygons(data = osm_layer3_no_go,weight = 1,fillColor ="red") %>%
      addPolygons(data = osm_layer4,weight = 1) %>%
      addPolygons(data=this_10k_grid %>% st_transform(4326) ,opacity=1,fillOpacity = 0,weight=2,color = "black") %>%
      addCircles(data = raster_as_sf %>% filter(composite==1),radius = 50,weight=0,color = "blue") %>%
      addCircles(data = raster_as_sf %>% filter(composite==0),radius = 50,weight=0,color = "red") %>%
      addCircles(data = raster_as_sf %>% filter(composite==0.75),radius = 50,weight=0,color = "orange") %>%
      addCircles(data = raster_as_sf %>% filter(composite==0.25),radius = 50,weight=0,color = "white")
    
    return(m)
  }
  
  
  raster100_df[raster100_df$x > grid_bb$xmin & raster100_df$x < grid_bb$xmax & raster100_df$y > grid_bb$ymin & raster100_df$y < grid_bb$ymax,"access"] <- raster_as_sf$composite
  
  raster100_to_save <- raster100_df %>% filter(x > grid_bb$xmin,
                                               x < grid_bb$xmax,
                                               y > grid_bb$ymin,
                                               y < grid_bb$ymax)
  
  return(raster100_to_save)
}

#test <- assess_accessibility(1516,uk_grid,raster100_df,produce_map = F)







## ----rstudio_job-----------------------------------------------------------------------------------------
if(exist(job_id)){
  #set it all off as 8 seperate jobs, saving the individual 10k grids
  log_df <- data.frame(grid_no = 0,time_taken = "",time = "")[-1,]
  job_sequence <- seq.int(from = 1,to = 3025,length.out = 9)
  
  for (i in job_sequence[job_id]:job_sequence[job_id+1]){
    cat(paste('\r grid:',i," progress:",round((i-job_sequence[job_id])/378*100),"%"))
    time_taken <- system.time({
      access_raster <- assess_accessibility(i,uk_grid,raster100_df,produce_map = F)
      })
    
    log_df[nrow(log_df)+1,] <- c(i,time_taken[3],Sys.time()%>% toString())
    
    saveRDS(access_raster,file = paste0("/data/data/DECIDE_constraintlayers/processed_data/access_raster_grid",i,".RDS"))
    
    saveRDS(log_df,file = paste0("/data/data/DECIDE_constraintlayers/processed_data/logs/log_",job_id,".RDS"))
  }
}



## --------------------------------------------------------------------------------------------------------

if(exist(slurm_grid_id)){
  
  time_taken <- system.time({
    access_raster <- assess_accessibility(slurm_grid_id,uk_grid,raster100_df,produce_map = F)
    })
    
  saveRDS(access_raster,file = paste0("/data/data/DECIDE_constraintlayers/processed_data/access_raster_grid",slurm_grid_id,".RDS"))
  
  print(time_taken)
}


