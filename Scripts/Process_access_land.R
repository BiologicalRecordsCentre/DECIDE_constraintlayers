
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

# load in uk map
uk <- st_read('/data/notebooks/rstudio-setupconsthomas/DECIDE_constraintlayers/Data/raw_data/UK_grids/uk_map.shp')
st_crs(uk) <- 27700

# # create grid
# uk_grid_10k <- sf::st_make_grid(uk, cellsize = 10000, what = 'polygons', square=TRUE)
# # grid_intersect <- apply(st_intersects(uk, uk_grid_10k, sparse = FALSE), 1, any)
# # simp_grid_uk <- uk[grid_intersect, ]
# 
# # check with plot
# plot(st_geometry(uk))
# plot(st_geometry(uk_grid_10k), border = 'orange', add = TRUE)
# 
# # write to file
# st_write(obj = uk_grid_10k, dsn = '/data/notebooks/rstudio-setupconsthomas/DECIDE_constraintlayers/Data/raw_data/UK_grids/uk_grid_10km.shp',
#          driver = "ESRI Shapefile", delete_layer = T)

# read in grid
uk_grid <- st_read('/data/notebooks/rstudio-setupconsthomas/DECIDE_constraintlayers/Data/raw_data/UK_grids/uk_grid_10km.shp')

st_crs(uk) <- 27700
st_crs(uk_grid) <- 27700

plot(st_geometry(uk), reset = T)
plot(st_geometry(uk_grid), add = T, border = 'orange')

# all in one line
crow_valid[st_intersects(crow_valid, uk_grid[1,], sparse = F),]

## so, now is easy to loop through and save the footpaths in each grid to file
## will need to redo this once we have the footpaths for scotland and missing places
dim(uk_grid)[1]


system.time(
  for(i in 2684:dim(uk_grid)[1]){
    print(i)

    grid_sub <- crow_valid[st_intersects(crow_valid, uk_grid[i,], sparse = F),]
   
    if(dim(grid_sub)!=0 && class(st_geometry(grid_sub))[1]=="sfc_GEOMETRY"){
          grid_sub <- st_collection_extract(grid_sub, "POLYGON")
    }
    

    st_write(grid_sub, dsn = paste0('Data/raw_data/CRoW_Act_2000_-_Access_Layer_(England)-shp/gridded_data_10km/access_land_gridnumber_',i,'.shp'),
             driver = "ESRI Shapefile", delete_layer = T)

    # saveRDS(grid_sub,
    #         file = paste0('Data/raw_data/CRoW_Act_2000_-_Access_Layer_(England)-shp/gridded_data/access_land_gridnumber_',i,'.rds'))

  }
)

