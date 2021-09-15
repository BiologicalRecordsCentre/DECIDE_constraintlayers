### process RSPB reserves

library(sf)

rspb <- st_read(list.files('Data/raw_data/RSPB_Reserve_Boundaries/', full.names = T, pattern='.shp'))
plot(st_geometry(rspb))

# read in grid
uk_grid <- st_read('/data/notebooks/rstudio-setupconsthomas/DECIDE_constraintlayers/Data/raw_data/UK_grids/uk_grid_10km.shp')
st_crs(uk_grid) <- 27700

plot(st_geometry(uk_grid), add = T, col = 'orange')

for(i in 1:dim(uk_grid)[1]) {
  
  print(i)
  
  # load files in grid cell
  RSPB_sub <- rspb[st_intersects(rspb, uk_grid[i,], sparse = F),]
  
  if(dim(RSPB_sub)[1] > 0){ ## if grid cell contains some of shape
    
    print('###   grid contains national trust property   ###')
    
    st_write(RSPB_sub, dsn = paste0('Data/raw_data/RSPB_Reserve_Boundaries/gridded_data_10km/RSPB_gridnumber_',i,'.shp'),
             driver = "ESRI Shapefile", delete_layer = T)
    
  }
  
}



