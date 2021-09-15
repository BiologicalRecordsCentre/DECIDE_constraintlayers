
### Step 1: Downloading the data from OSM

#Following this vignette: https://cran.r-project.org/web/packages/osmdata/vignettes/osmdata.html

#load packages
library(osmdata)
library(sf)

if(F){

  # manually specify a bounding box
  # coordinates from https://gist.github.com/graydon/11198540
  bb <- matrix(c(-7.57216793459,49.959999905,1.68153079591,58.6350001085),2,2,dimnames = list(c("x","y"),c("min","max")))
  
  # make the query
  q <- opq(bbox = bb) %>%
    add_osm_feature(key = 'landuse', value = 'military')
  
  #change the timeout
  q$prefix <- "[out:xml][timeout:1000];\n(\n"
  
  #do the query
  military_data <- osmdata_sf(q)
  
  # get the simple feature polygons
  military_data$osm_polygons
  plot(st_geometry(military_data$osm_polygons))
  
  # save the military data
  saveRDS(military_data, "/data/data/DECIDE_constraintlayers/raw_data/military_areas/military_data.RDS")
}

### Step 2: processing data

#load military data
military_data <- readRDS("/data/data/DECIDE_constraintlayers/raw_data/military_areas/military_data.RDS")
military_data_polygons <- military_data$osm_polygons

#we're in the wrong projection
st_crs(military_data_polygons) # data is in WGS84

#transform to osgb
military_data_polygons <- st_transform(military_data_polygons,27700)

#projection is correct now
st_crs(military_data_polygons) # now in OSGB 1936 / British National Grid


# load the UK grid
uk_grid <- st_read('/data/data/DECIDE_constraintlayers/raw_data/UK_grids/uk_grid_10km.shp')
st_crs(uk_grid) <- 27700

#check that things are aligned
plot(st_geometry(uk_grid), add = F, col = 'orange')
plot(st_geometry(military_data_polygons), add = T,col='blue')

# loop through the grids
for(i in 1:dim(uk_grid)[1]) {
  
  print(i)
  
  # load files in grid cell
  military_sub <- military_data_polygons[st_intersects(military_data_polygons, uk_grid[i,], sparse = F),]
  
  if(dim(military_sub)[1] > 0){ ## if grid cell contains some of shape
    
    print('###   grid contains Military areas   ###')
    
    st_write(military_sub, dsn = paste0('/data/data/DECIDE_constraintlayers/raw_data/military_areas/gridded_data_10km/military_gridnumber_',i,'.shp'),
             driver = "ESRI Shapefile", delete_layer = T)
    
  }
}
