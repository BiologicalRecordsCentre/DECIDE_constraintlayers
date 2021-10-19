job_id <- 4
#THIS LINE IS REPLACED WITH JOB ID ASSIGNMENT if generating job or JASMIN files
#load packages
#messages suppressed so that the .err file from JASMIN/slurm only contains errors: https://stackoverflow.com/questions/14834841/when-does-quietly-true-actually-work-in-the-require-function
suppressMessages(suppressWarnings(library(osmextract))) #for using overpass API
suppressMessages(suppressWarnings(library(sf))) #for all the geographic operations
suppressMessages(suppressWarnings(library(leaflet))) # for making maps for sanity checking
suppressMessages(suppressWarnings(library(raster)))
suppressMessages(suppressWarnings(library(rgdal)))
suppressMessages(suppressWarnings(library(dplyr)))
suppressMessages(suppressWarnings(library(htmlwidgets)))
suppressMessages(suppressWarnings(library(htmltools))) # for htmlEscape()


## ----filepaths--------------------------------------------------------------------------------
if(exists("job_id")){
  #datalabs
  setwd(file.path("","data","notebooks","rstudio-conlayersimon","DECIDE_constraintlayers","Scripts"))
  
  raw_data_location <- file.path("","data","data","DECIDE_constraintlayers","raw_data")
  processed_data_location <- file.path("","data","data","DECIDE_constraintlayers","processed_data")
  environmental_data_location <- file.path("","data","data","DECIDE_constraintlayers","environmental_data")
}


if(exists("slurm_grid_id")){
  #JASMIN
  setwd(file.path("","home","users","simrol","DECIDE","DECIDE_constraintlayers","Scripts"))
  
  raw_data_location <- file.path("","home","users","simrol","DECIDE","raw_data")
  processed_data_location <- file.path("","home","users","simrol","DECIDE","processed_data")
  environmental_data_location <- file.path("","home","users","simrol","DECIDE","environmental_data")
}





## ---------------------------------------------------------------------------------------------
#Access lines
vt_opts_1 = c(
    "-select", "osm_id, highway, designation, footway, sidewalk",
    "-where", "highway IN ('track', 'cycleway')"
  )

oe_get(
  "Scotland",
  layer = "lines",
  provider = "geofabrik",
  match_by = "name",
  max_string_dist = 1,
  level = NULL,
  download_directory = file.path(raw_data_location,"OSM"),
  force_download = F,
  vectortranslate_options = vt_opts_1,
  extra_tags = c("designation","footway","sidewalk"),
  force_vectortranslate = T,
  quiet = FALSE
) %>% st_write(file.path(raw_data_location,"OSM","access_lines_scot.gpkg"),delete_layer = T)







## ----access_offline_data----------------------------------------------------------------------
#base location
base_location <- file.path(raw_data_location,"")

#folders
file_locations <- c(
  'CRoW_Act_2000_-_Access_Layer_(England)-shp/gridded_data_10km/',
  'OS_greenspaces/OS Open Greenspace (ESRI Shape File) GB/data/gridded_greenspace_data_10km/',
  'greater-london-latest-free/london_gridded_data_10km/',
  'rowmaps_footpathbridleway/rowmaps_footpathbridleway/gridded_data_10km/',
  #'RSPB_Reserve_Boundaries/gridded_data_10km/',
  'national_trust/gridded_data_10km/',
  
  'Scotland/cairngorms/gridded_data_10km/',
  'Scotland/core_paths/gridded_data_10km/',
  'Scotland/local_nature_conservation_sites/gridded_data_10km/',
  'Scotland/local_nature_reserves/gridded_data_10km/',
  'Scotland/lochlomond_tross/gridded_data_10km/',
  'Scotland/public_access_rural/gridded_data_10km/',
  'Scotland/public_access_wiat/gridded_data_10km/',
  'Scotland/wildland_scotland/gridded_data_10km/'
  
)

# function to get the data
get_offline_gridded_data <- function(grid_number){
  returned_files <- list()
  
  for (ii in 1:length(file_locations)){
    file_location <- file_locations[ii]
    all_grids <- list.files(file.path(base_location,file_location))
    
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

# test <- get_offline_gridded_data(1313)
# 
# #check access with lapply
check_access_lapply <- function(...){
  st_is_within_distance(...) %>% rowSums()
}
# requires taster_as_sf object which is defined later in the script so will error if you run this the script in order
# test2 <- lapply(test,check_access_lapply,x = raster_as_sf,dist = 100,sparse = FALSE) %>% Reduce(f='+')




## ----data_processing--------------------------------------------------------------------------
sf::sf_use_s2(T)

#load in required to do the job

uk_grid <- st_read(file.path(raw_data_location,'UK_grids','uk_grid_10km.shp'),quiet = T)
st_crs(uk_grid) <- 27700

# the big raster
#raster100 <- raster::stack(file.path(environmental_data_location,'100mRastOneLayer.grd'))
#plot(raster100)
#get the CRS for when we project back to raster from data ramew
#raster_crs <- st_crs(raster100)
#raster100_df <- as.data.frame(raster100, xy=T, centroids=TRUE)[,1:2]


#for testing:
#grid_number <- 1516
#grids <- uk_grid
#raster_df <- raster100_df

#define the function for assessing accessibility
assess_accessibility <- function(grid_number,grids,produce_map = F){
  
  #load 10k grid
  this_10k_grid <- grids[grid_number,]$geometry #get the 10kgrid
  this_10k_gridWGS84 <- st_transform(this_10k_grid, 4326) # convert to WGS84
  grid_bb <- st_bbox(this_10k_grid)
  
  #get the centroids of the the 100m grids within the 10k grid
  # raster_this_grid <- raster_df %>% filter(x > grid_bb$xmin,
  #                                             x < grid_bb$xmax,
  #                                             y > grid_bb$ymin,
  #                                             y < grid_bb$ymax)
  
  
  raster_this_grid <- readRDS(file.path(environmental_data_location,paste0("100mrast_grid_",grid_number,".RDS")))
  
  #LOAD raster_this_grid from file
  
  
  #get the easting and northing projection
  projcrs <- st_crs(this_10k_grid)
  
  # make the raster df into a sd object using the projection but transform it to WGS84 for these operations
  raster_as_sf <- st_as_sf(raster_this_grid,coords = c("x", "y"),crs = projcrs) %>% st_transform(4326)
  
  this_10k_gridWGS84_wkt <- this_10k_gridWGS84 %>% st_as_text()
  
  # load OSM data
  osm_layer1 <- st_read(file.path(raw_data_location,"OSM","access_lines.gpkg"),
                        wkt_filter = this_10k_gridWGS84_wkt,
                        quiet = T
                        )
  
  osm_layer1_scot <- st_read(file.path(raw_data_location,"OSM","access_lines_scot.gpkg"),
                        wkt_filter = this_10k_gridWGS84_wkt,
                        quiet = T
                        )

  osm_layer2 <- st_read(file.path(raw_data_location,"OSM","no_go_lines.gpkg"),
                        wkt_filter = this_10k_gridWGS84_wkt,
                        quiet = T
                        )

  osm_layer3_no_go <- st_read(file.path(raw_data_location,"OSM","no_go_areas.gpkg"),
                        wkt_filter = this_10k_gridWGS84_wkt,
                        quiet = T
                        ) %>% filter(aeroway == "aerodrome") 
  
  osm_layer3_warn <- st_read(file.path(raw_data_location,"OSM","no_go_areas.gpkg"),
                        wkt_filter = this_10k_gridWGS84_wkt,
                        quiet = T
                        ) %>% filter(landuse %in% c("military",'quarry','landfill','industrial'))

  osm_layer4 <- st_read(file.path(raw_data_location,"OSM","water_areas.gpkg"),
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
    
    #Scottish tracks and other features that we might want to exclude in England/Wales
    distance_check_good <- distance_check_good + rowSums(st_is_within_distance(raster_as_sf,osm_layer1_scot,dist = 100,sparse = FALSE))
    
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
    distance_check_good <- distance_check_good + rowSums(st_is_within_distance(raster_as_sf,osm_layer1_scot,dist = 100,sparse = FALSE))
    
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
  
  #memory checks
  #sort( sapply(ls(),function(x){object.size(get(x))})) %>% print()
  #sum( sapply(ls(),function(x){object.size(get(x))})) %>% print()
  
  if(produce_map){
    m <- leaflet() %>%
      addTiles() %>%
      addPolylines(data = osm_layer1,weight = 1) %>%
      addPolylines(data = osm_layer2,weight = 1,color = "red") %>%
      addPolygons(data = osm_layer3_warn,weight = 1,fillColor ="orange") %>%
      addPolygons(data = osm_layer3_no_go,weight = 1,fillColor ="red") %>%
      #addPolygons(data = osm_layer4,weight = 1) %>%
      addPolygons(data=this_10k_grid %>% st_transform(4326) ,opacity=1,fillOpacity = 0,weight=2,color = "black") %>%
      addCircles(data = raster_as_sf %>% filter(composite==1),radius = 50,weight=0,color = "blue") %>%
      addCircles(data = raster_as_sf %>% filter(composite==0),radius = 50,weight=0,color = "red") %>%
      addCircles(data = raster_as_sf %>% filter(composite==0.75),radius = 50,weight=0,color = "orange") %>%
      addCircles(data = raster_as_sf %>% filter(composite==0.25),radius = 50,weight=0,color = "red")
    
    #save
    saveWidget(m, file="../docs/access_map_grid.html",title =  paste0("Grid: ",grid_number," generated ",date()))
    
    #then rename (so that it's using the same supporting files folder as the other maps - to stop uploading endless copies of js libraries)
    file.rename(from = "../docs/access_map_grid.html", to = paste0("../docs/access_map_grid_",grid_number,".html"))
    #return(m)
  }
  
  raster_this_grid$access <- raster_as_sf$composite
  raster100_to_save <- raster_this_grid
  
  #raster_df[raster_df$x > grid_bb$xmin & raster_df$x < grid_bb$xmax & raster_df$y > grid_bb$ymin & raster_df$y < grid_bb$ymax,"access"] <- raster_as_sf$composite
  
  # raster100_to_save <- raster_df %>% filter(x > grid_bb$xmin,
  #                                              x < grid_bb$xmax,
  #                                              y > grid_bb$ymin,
  #                                              y < grid_bb$ymax)
  
  return(raster100_to_save)
}

#1313 is near Ladybower reservoir in the peak district
test <- assess_accessibility(944,uk_grid,produce_map = T)
test

#Assessing memory usage:
#sort( sapply(ls(),function(x){object.size(get(x),units="Mb")})) 
#print(object.size(x=lapply(ls(), get)), units="Mb")





## ----rstudio_job------------------------------------------------------------------------------
if(exists("job_id")){
  #set it all off as 8 seperate jobs, saving the individual 10k grids
  log_df <- data.frame(grid_no = 0,time_taken = "",time = "")[-1,]
  job_sequence <- seq.int(from = 1,to = 3025,length.out = 9)
  
  for (i in job_sequence[job_id]:job_sequence[job_id+1]){
    cat(paste('\r grid:',i," progress:",round((i-job_sequence[job_id])/378*100),"%"))
    time_taken <- system.time({
      access_raster <- assess_accessibility(i,uk_grid,produce_map = T)
      })
    
    log_df[nrow(log_df)+1,] <- c(i,time_taken[3],Sys.time()%>% toString())
    
    saveRDS(access_raster,file = paste0("/data/data/DECIDE_constraintlayers/processed_data/access_raster_grid",i,".RDS"))
    
    saveRDS(log_df,file = paste0("/data/data/DECIDE_constraintlayers/processed_data/logs/log_",job_id,".RDS"))
  }
}



## ---------------------------------------------------------------------------------------------

if(exists("slurm_grid_id")){
  
  time_taken <- system.time({
    access_raster <- assess_accessibility(slurm_grid_id,uk_grid,produce_map = T)
    })
  
  if(exists("access_raster")){
    print("Success, preprocced access raster produced!")
  } else {
    print("Failure, preprocced access raster not produced!")
  }
    
  saveRDS(access_raster,file = paste0(processed_data_location,"/access_raster_grid",slurm_grid_id,".RDS"))
  
  print(time_taken)
}


