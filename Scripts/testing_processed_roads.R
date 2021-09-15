
## script to show you how to get roads for your local area

# get the functions to load grid numbers and crop
source("../../rstudio-adaptsampthomas/DECIDE_adaptivesampling/Scripts/modules/load_gridnumbers.R")
source("../../rstudio-adaptsampthomas/DECIDE_adaptivesampling/Scripts/modules/filter_distance.R")

# location of interest and distance
location = c(-1.110557, 51.602436) # wallingford
distance = 5000

# grid that we used
grid = st_read('/data/notebooks/rstudio-setupconsthomas/DECIDE_constraintlayers/Data/raw_data/UK_grids/uk_grid_10km.shp')

# find grid numbers that location + buffered zone covers
grid_numbers <- load_gridnumbers(location = location,
                                 distance = distance,
                                 grid = grid)
grid_numbers

# file location of roads
rds_loc <- '/data/notebooks/rstudio-setupconsthomas/DECIDE_constraintlayers/Data/raw_data/OS_roadnetwork/data/gridded_link_road_10km'


roads_list <- lapply(c(1:length(grid_numbers)), FUN = function(n){
  
  # rds .shp
  rds_files <- list.files(rds_loc,
                          full.names = T,
                          pattern = paste0('_', grid_numbers[n], '.shp'))
  
  if(length(rds_files) != 0) {
    rds <- sf::st_read(rds_files, quiet = TRUE)
    # sf::st_crs(rds) <- 27700
  } else { rds <- NULL }
})

all_outs <- do.call(rbind, roads_list)
all_outs


# crop shapes to exact region of interest
final_rds <- filter_distance(all_outs,
                             location = location,
                             distance = distance,
                             method = 'buffer')

## plotting!
plot(st_geometry(final_rds))
