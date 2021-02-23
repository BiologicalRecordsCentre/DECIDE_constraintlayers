
## processing kml bridleway and footpath files

# I'm not 100% but I think running init again will overwrite the existing library 
# with an empty one. That would explain why no packages are installed
# packrat::init()
# packrat::on()

library(sf)
library(rgdal)
library(rgdal)
library(doParallel)
library(foreach)
library(xml2)
library(purrr)
library(tidyverse)
library(smoothr)
library(raster)


# unzip('Data/raw_data/rowmaps_footpathbridleway/rowmaps_footpathbridleway/ALL_PATHS_MERGED.zip', exdir = 'Data/raw_data/rowmaps_footpathbridleway/rowmaps_footpathbridleway/')

file_loc <- "Data/raw_data/rowmaps_footpathbridleway/rowmaps_footpathbridleway/ALL_PATHS_MERGED.shp"
prow <- sf::st_read(file_loc)

plot(prow$geometry) # throws error

# found that number 596 causing issue
plot(prow$geometry[596]) # not the only one in the data set

# the problem is that the geometry is 0m long, i.e. just a point
st_length(prow$geometry[596])
st_length(prow$geometry[597]) # compared to this for e.g.

# so, remove all the linestrings with length = 0m (i.e. just a point)
prow_long <- prow[as.numeric(st_length(prow$geometry)) > 0,]

BNG_prow <- st_transform(prow_long, crs = 27700) # transform to BNG coords

# # plot
# plot(BNG_prow) # works, takes ages

# # write the whol prow shapefile to file
# st_write(BNG_prow, dsn = 'Data/raw_data/rowmaps_footpathbridleway/rowmaps_footpathbridleway/ALL_PATHS_MERGED_long.shp', 
#          driver = "ESRI Shapefile", delete_layer = T)




########      testing

ap_merge <- st_read('Data/raw_data/rowmaps_footpathbridleway/rowmaps_footpathbridleway/ALL_PATHS_MERGED_long.shp')
st_crs(ap_merge) <- 27700

####    find points in a desired location    ####
location = c(-1.110557, 51.602436)
distance = 10000

dat_sf <- st_sf(st_sfc(st_point(location)), crs = 4326) # load location points, convert to spatial lat/lon
trans_loc <- st_transform(dat_sf, crs = 27700) # transform to BNG
buffed <- st_buffer(trans_loc, distance) # create a buffer around the point

?st_intersects
c_buf <- st_intersects(ap_merge, buffed) # crop the sf object -  
plot(c_buf$Name)
plot(c_buf$geometry)



####    Might be useful (quicker) to store the shapefile in grids   ####

# convert to a grid so can load them in
# individually - code from Reto

# create overlapping grid
uk_map <- st_as_sf(getData("GADM", country = "GBR", level = 1, path='Data/raw_data/UK_grids'))
uk_map <- st_transform(uk_map, 27700)
uk_grid <- sf::st_make_grid(uk_map, cellsize = 25000, what = 'polygons', square=TRUE)
uk_grid2 <- st_make_grid(uk_map, cellsize = 25000, what = 'polygons', square=TRUE, offset = c(extent(uk_map)[1]-50000, extent(uk_map)[3]))
uk_grid3 <- st_make_grid(uk_map, cellsize = 25000, what = 'polygons', square=TRUE, offset = c(extent(uk_map)[1], extent(uk_map)[3]-50000))
# uk_grid4 <- st_make_grid(uk_map, cellsize = 50000, what = 'polygons', square=TRUE)

plot(st_geometry(uk_map), reset = FALSE)
plot(st_geometry(uk_grid), border = 'orange', lty = 2, add=TRUE)
plot(st_geometry(uk_grid2), border = 'cyan4', lty = 2, add=TRUE)
plot(st_geometry(uk_grid3), border = 'dodgerblue3', lty = 2, add=TRUE)
# plot(st_geometry(uk_grid4), border = 'pink', lty = 2, add=TRUE)

# remove cells over water
grid_intersect <- apply(st_intersects(uk_grid, uk_map, sparse = FALSE), 1, any)
grid_intersect2 <- apply(st_intersects(uk_grid2, uk_map, sparse = FALSE), 1, any)
grid_intersect3 <- apply(st_intersects(uk_grid3, uk_map, sparse = FALSE), 1, any)

plot(st_geometry(uk_map), reset = FALSE)
plot(st_geometry(uk_grid[grid_intersect ]), border = 'orange', add = TRUE)
plot(st_geometry(uk_grid2[grid_intersect2 ]), border = 'cyan4', add = TRUE)
plot(st_geometry(uk_grid3[grid_intersect3 ]), border = 'dodgerblue3', add = TRUE)


# find cell that corresponds to a location
pt_df <- data.frame(x_coord = 368400, y_coord = 244142 )
pt_sf <- st_as_sf(pt_df, coords = c("x_coord", "y_coord"), crs = st_crs(uk_grid))
plot(pt_sf, pch = 19, col= 'magenta', add = TRUE)

# combine the three overlapping grids
uk_grid_all <- c(st_geometry(uk_grid[grid_intersect ]), 
                 st_geometry(uk_grid2[grid_intersect2 ]),
                 st_geometry(uk_grid3[grid_intersect3 ]))

plot(st_geometry(uk_map), reset = FALSE)
plot(pt_sf, pch = 19, col= 'magenta', add = TRUE)
plot(st_geometry(uk_grid_all)[st_within(st_buffer(pt_sf, 25000), uk_grid_all)[[1]]], border = 'magenta', add = TRUE)

pt_df2 <- data.frame(x_coord = 458400, y_coord = 354142 )
pt_sf2 <- st_as_sf(pt_df2, coords = c("x_coord", "y_coord"), crs = st_crs(uk_grid))
plot(pt_sf2, pch = 19, col= 'cyan4', add = TRUE)
plot(st_geometry(uk_grid_all)[st_within(st_buffer(pt_sf2, 25000), uk_grid_all)[[1]]], border = 'cyan4', add = TRUE)

pt_df3 <- data.frame(x_coord = 400400, y_coord = 354142 )
pt_sf3 <- st_as_sf(pt_df3, coords = c("x_coord", "y_coord"), crs = st_crs(uk_grid))
plot(pt_sf3, pch = 19, col= 'black', add = TRUE)
plot(st_geometry(uk_grid_all)[st_within(st_buffer(pt_sf3, 30000), uk_grid_all)[[1]]], border = 'cyan4', add = TRUE)

pt_df4 <- data.frame(x_coord = 390400, y_coord = 300142 )
pt_sf4 <- st_as_sf(pt_df4, coords = c("x_coord", "y_coord"), crs = st_crs(uk_grid))
plot(pt_sf4, pch = 19, col= 'red', add = TRUE)
plot(st_geometry(uk_grid_all)[st_within(st_buffer(pt_sf4, 20000), uk_grid_all)[[1]]], border = 'red', add = TRUE)



## st_within only returns TRUE when the buffer falls entirely within a cell -
## this breaks down for some points when the buffer is too big.
## for e.g.

plot(st_geometry(uk_map), reset = FALSE)
plot(pt_sf, pch = 19, col= 'magenta', add = TRUE)
plot(st_geometry(uk_grid_all)[st_within(st_buffer(pt_sf, 25000), uk_grid_all)[[1]]], border = 'magenta', add = TRUE) ## works
plot(st_geometry(uk_grid_all)[st_within(st_buffer(pt_sf, 40000), uk_grid_all)[[1]]], border = 'blue', add = TRUE) ## with 40000 - doesn't work

# so can use st_intersects which returns all the grids that a buffer overlaps
plot(st_geometry(uk_map), reset = FALSE)
plot(pt_sf, pch = 19, col= 'magenta', add = TRUE)
plot(st_geometry(uk_grid_all)[st_intersects(st_buffer(pt_sf, 25000), uk_grid_all)[[1]]], border = 'magenta', add = TRUE) ## works
plot(st_geometry(uk_grid_all)[st_intersects(st_buffer(pt_sf, 40000), uk_grid_all)[[1]]], border = 'blue', add = TRUE) ## works


# could load in only the grids it intersects...

# get the grid numbers that the buffered region overlaps
st_intersects(st_buffer(pt_sf, 40000), uk_grid_all)[[1]]

# if using st_intersects then I don't need to worry about
# using the overlayed grid - just load in all the grids that
# the buffer touches, so could just use the original 
# gridded dataset.
simp_grid <- st_geometry(uk_grid[grid_intersect ])

plot(st_geometry(uk_map), reset = FALSE)
plot(pt_sf, pch = 19, col= 'magenta', add = TRUE)
plot(st_geometry(uk_grid_all)[st_intersects(st_buffer(pt_sf, 40000), simp_grid)[[1]]], border = 'magenta', add = T)



###### Splitting bridleway into grids #######
BNG_prow <- ap_merge
BNG_prow
uk_map <- st_as_sf(getData("GADM", country = "GBR", level = 1, path='Data/raw_data/UK_grids'))
uk_map <- st_transform(uk_map, 27700)
uk_grid <- st_make_grid(uk_map, cellsize = 25000, what = 'polygons', square=TRUE)
grid_intersect <- apply(st_intersects(uk_grid, uk_map, sparse = FALSE), 1, any)

plot(st_geometry(uk_map))
plot(st_geometry(uk_grid[grid_intersect ]), border = 'orange', add = TRUE)

simp_grid_uk <- uk_grid[grid_intersect ]

g <- (simp_grid_uk[[3]])
plot(g, add = T, border = 'red')

ints <- st_intersects(BNG_prow, g, sparse = F)
unique(ints)

# all in one line
(BNG_prow)[st_intersects(BNG_prow, simp_grid_uk[[3]], sparse = F),]

## so, now is easy to loop through and save the footpaths in each grid to file
## will need to redo this once we have the footpaths for scotland and missing places
length(simp_grid_uk)
# geom_bng_prow <- st_geometry(BNG_prow)


system.time(
  for(i in 1:length(simp_grid_uk)){
    print(i)

    grid_sub <- BNG_prow[st_intersects(BNG_prow, simp_grid_uk[[i]], sparse = F),]

    # st_write(grid_sub, dsn = paste0('Data/raw_data/rowmaps_footpathbridleway/rowmaps_footpathbridleway/gridded_data/prow_gridnumber_',i,'.shp'),
    #          driver = "ESRI Shapefile", delete_layer = T)
    
    saveRDS(grid_sub, 
            file = paste0('Data/raw_data/rowmaps_footpathbridleway/rowmaps_footpathbridleway/gridded_data/prow_gridnumber_',i,'.rds'))
    
  }
)


#### testing loading certain location

# get grid for UK
uk_map <- st_as_sf(getData("GADM", country = "GBR", level = 1))
uk_map <- st_transform(uk_map, 27700)
uk_grid <- st_make_grid(uk_map, cellsize = 100000, what = 'polygons', square=TRUE)
grid_intersect <- apply(st_intersects(uk_grid, uk_map, sparse = FALSE), 1, any)
simp_grid_uk2 <- uk_grid[grid_intersect]
plot(st_geometry(uk_map), reset = T)
plot(simp_grid_uk2, add = T)

# get location
location = c(-1.110557, 51.602436)
distance = 10000

# create buffer
dat_sf <- st_sf(st_sfc(st_point(location)), crs = 4326) # load location points, convert to spatial lat/lon
trans_loc <- st_transform(dat_sf, crs = 27700) # transform to BNG
buffed <- st_buffer(trans_loc, distance) # create a buffer around the point

grid_num <- st_intersects(buffed, simp_grid_uk2)[[1]]
grid_num

# load file of interest
file_loc <- list.files('Data/raw_data/rowmaps_footpathbridleway/rowmaps_footpathbridleway/gridded_data/', full.names = T)
file_loc
?grepl

system.time(t <- st_read(grep(pattern = paste0(grid_num, '.shp'), x = file_loc, value = T)))
plot(st_geometry(t))

# with the grid in 100km squares it takes 0.914 seconds although feels like longer - is this okay?

# what about with multiple grids?
# get location
location = c(-1.110557, 51.602436) ## wallingford
distance = 40000

# create buffer
dat_sf <- st_sf(st_sfc(st_point(location)), crs = 4326) # load location points, convert to spatial lat/lon
trans_loc <- st_transform(dat_sf, crs = 27700) # transform to BNG
buffed <- st_buffer(trans_loc, distance) # create a buffer around the point

grid_num <- st_intersects(buffed, simp_grid_uk2)[[1]]
grid_num ## two grids

outs <- list()
system.time(
  for(n in 1:length(grid_num)) {
    
    file_l <- list.files('Data/raw_data/rowmaps_footpathbridleway/rowmaps_footpathbridleway/gridded_data/', 
                         full.names = T,
                         pattern = paste0(grid_num[n], '.shp'))
    
    file <- sf::st_read(file_l)
    
    outs[[n]] <- file
  }
)

outs
test <- do.call('rbind', outs)
plot(st_geometry(test))
## turn it into an apply statement?

st_crs(test) <- 27700


# now subset  by loc and buffer
prow_buf <- st_intersection(test, buffed) # crop the sf object  
plot(st_geometry(prow_buf))
