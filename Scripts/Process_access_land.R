
library(sf)
library(rgeos)
library(lwgeom)

source("/data/notebooks/rstudio-adaptsampthomas/DECIDE_adaptivesampling/Scripts/modules/filter_distance.R")

# load access land England
crow <- st_read('Data/raw_data/CRoW_Act_2000_-_Access_Layer_(England)-shp/CRoW_Access_Land___Natural_England.shp')

plot(st_geometry(crow)) ## cooool

# weird self-intersecting polygons
lancs <- filter_distance(crow,
                         location = c(-2.722295, 54.038337),
                         method = 'buffer',
                         distance = 10000)

# found online - make geometries valid - remove self-intersection problem
crow_valid <- st_make_valid(crow)

# and now it works!
lancs <- filter_distance(crow_valid,
                         location = c(-2.722295, 54.038337),
                         method = 'buffer',
                         distance = 10000)

plot(st_geometry(lancs)) ## lancaster and Forest of Bowland


###### Splitting access land into grids #######
uk <- st_read('/data/notebooks/rstudio-setupconsthomas/DECIDE_constraintlayers/Data/raw_data/UK_grids/uk_map.shp')
uk_grid <- st_read('/data/notebooks/rstudio-setupconsthomas/DECIDE_constraintlayers/Data/raw_data/UK_grids/uk_grid_25km.shp')

st_crs(uk) <- 27700
st_crs(uk_grid) <- 27700

plot(st_geometry(uk), reset = T)
plot(st_geometry(uk_grid), add = T, border = 'orange')

# all in one line
crow_valid[st_intersects(crow_valid, uk_grid[1,], sparse = F),]

## so, now is easy to loop through and save the footpaths in each grid to file
## will need to redo this once we have the footpaths for scotland and missing places
dim(uk_grid)[1]


# system.time(
#   for(i in 1:dim(uk_grid)[1]){
#     print(i)
#     
#     grid_sub <- crow_valid[st_intersects(crow_valid, uk_grid[i,], sparse = F),]
#     
#     # st_write(grid_sub, dsn = paste0('Data/raw_data/rowmaps_footpathbridleway/rowmaps_footpathbridleway/gridded_data/prow_gridnumber_',i,'.shp'),
#     #          driver = "ESRI Shapefile", delete_layer = T)
#     
#     saveRDS(grid_sub, 
#             file = paste0('Data/raw_data/CRoW_Act_2000_-_Access_Layer_(England)-shp/gridded_data/access_land_gridnumber_',i,'.rds'))
#     
#   }
# )

