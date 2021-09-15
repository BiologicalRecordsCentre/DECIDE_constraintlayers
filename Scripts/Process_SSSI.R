### process SSSIs

library(sf)

# england
sssi_england <- st_read(list.files('Data/raw_data/SSSIs/NE_SitesOfSpecialScientificInterestEngland/data/', full.names = T, pattern='.shp$'))
plot(st_geometry(sssi_england))
sssi_eng <- sssi_england[,c('sssi_name', 'geometry')]


# wales
sssi_wales <- st_read(list.files('Data/raw_data/SSSIs//NRW_Wales_SSSI', full.names = T, pattern='.shp$'))
plot(st_geometry(sssi_wales))
sssi_wal <- sssi_wales[,c('SSSI_Name', 'geometry')]
colnames(sssi_wal) <- c('sssi_name', 'geometry')

# scotland
sssi_scot <- st_read(list.files('Data/raw_data/SSSIs//SSSI_Scotland', full.names = T, pattern='.shp$'))
plot(st_geometry(sssi_scot))
sssi_SCOT <- sssi_scot[,c('NAME', 'geometry')]
colnames(sssi_SCOT) <- c('sssi_name', 'geometry')

sssi <- rbind(sssi_eng, sssi_wal, sssi_SCOT)
plot(st_geometry(sssi))

# read in grid
uk_grid <- st_read('/data/notebooks/rstudio-setupconsthomas/DECIDE_constraintlayers/Data/raw_data/UK_grids/uk_grid_10km.shp')
st_crs(uk_grid) <- 27700

# plot(st_geometry(uk_grid), add = T, col = 'orange')

for(i in 1:dim(uk_grid)[1]) {
  
  print(i)
  
  # load files in grid cell
  sssi_sub <- sssi[st_intersects(sssi, uk_grid[i,], sparse = F),]
  
  if(dim(sssi_sub)[1] > 0){ ## if grid cell contains some of shape
    
    print('###   grid contains SSSI   ###')
    
    st_write(sssi_sub, dsn = paste0('Data/raw_data/SSSIs/gridded_data_10km/SSSI_gridnumber_',i,'.shp'),
             driver = "ESRI Shapefile", delete_layer = T)
    
  }
  
}
