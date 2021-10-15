#run chunk from script v3 to get filepaths
library(sf)
library(raster)

#load in raster and grids
raster100 <- raster::stack(file.path(environmental_data_location,'100mRastOneLayer.grd'))
raster_crs <- st_crs(raster100)
raster100_df <- as.data.frame(raster100, xy=T, centroids=TRUE)[,1:2]

uk_grid <- st_read(file.path(raw_data_location,'UK_grids','uk_grid_10km.shp'),quiet = T)
st_crs(uk_grid) <- 27700

#loop through grids
for(grid_number in 1:3025){
  print(grid_number)
  this_10k_grid <- uk_grid[grid_number,]$geometry #get the 10kgrid
  grid_bb <- st_bbox(this_10k_grid)
  
  raster_this_grid <- raster100_df %>% filter(x > grid_bb$xmin,
                                           x < grid_bb$xmax,
                                           y > grid_bb$ymin,
                                           y < grid_bb$ymax)
  
  saveRDS(raster_this_grid,file = file.path(environmental_data_location,paste0("100mrast_grid_",grid_number,".RDS")))
}
