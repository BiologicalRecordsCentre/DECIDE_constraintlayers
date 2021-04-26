
# process national trust files
library(sf)
library(tidyverse)

# read national trust files
## always open
ao <- st_read('Data/raw_data/national_trust/always_open.shp')
ao$trust_type <- 'always_open'
ao ## already BNG

## limited access
la <- st_read('Data/raw_data/national_trust/limited_access.shp')
la$trust_type <- 'limited_access'
la ## already BNG

# combine the two
national_trust <- rbind(ao, la)
national_trust

plot(st_geometry(national_trust)) ## pretty much all of UK

# read in grid
uk_grid <- st_read('/data/notebooks/rstudio-setupconsthomas/DECIDE_constraintlayers/Data/raw_data/UK_grids/uk_grid_10km.shp')
st_crs(uk_grid) <- 27700


for(i in 1:dim(uk_grid)[1]) {
  
  print(i)
  
  # load files in grid cell
  national_trust_sub <- national_trust[st_intersects(national_trust, uk_grid[i,], sparse = F),]
  
  if(dim(national_trust_sub)[1] > 0){ ## if grid cell contains some of shape
    
    print('###   grid contains national trust property   ###')
    
    st_write(national_trust_sub, dsn = paste0('Data/raw_data/national_trust/gridded_data_10km/national_trust_gridnumber_',i,'.shp'),
             driver = "ESRI Shapefile", delete_layer = T)
    
  }
  
}
