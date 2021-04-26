
### Process scottish data

library(sf)
library(tidyverse)

list.files('Data/raw_data/Scotland/core_paths/')


## core paths
cp <- st_read('Data/raw_data/Scotland/core_paths/pub_cpth.shp')
dim(cp)
cp

ggplot() +
  geom_sf(data = cp)

cp_bng <- st_transform(cp, crs = 27700)

plot(st_geometry(cp_bng), reset = FALSE)

# ggplot() +
#   geom_sf(data = cp_bng)


## public access rural
par <- st_read('Data/raw_data/Scotland/public_access_rural/FGS_SMF_Public_Access_Rural.shp')

par_bng <- st_transform(par, crs = 27700)

plot(st_geometry(par_bng), col = 'red', add = T) ## can't see it...


## public access urban
pau <- st_read('Data/raw_data/Scotland/public_access_wiat/FGS_SMF_Public_Access_WIAT.shp') ## woods
pau2 <- st_read('Data/raw_data/Scotland/public_access_wiat/RDC_WIAT_Challenge_Fund_Footpaths_2007_2013.shp') ## footpaths

pau_bng <- st_transform(pau, crs = 27700)
pau2_bng <- st_transform(pau2, crs = 27700)
pau_bng
pau2_bng

plot(st_geometry(pau_bng), col = 'grey', add = T)
plot(st_geometry(pau2_bng), col = 'grey', add = T)


## National parks
cairn <- st_read('Data/raw_data/Scotland/cairngorms/SG_CairngormsNationalPark_2010.shp')
tross <- st_read('Data/raw_data/Scotland/lochlomond_tross/SG_LochLomondTrossachsNationalPark_2002.shp')
cairn # already in BNG
tross # already in BNG

plot(st_geometry(cairn), add = T, col = 'green')
plot(st_geometry(tross), add = T, col = 'green')


## local nature conservation sites 
nat_cons <- st_read('Data/raw_data/Scotland/local_nature_conservation_sites/pub_lnatcs.shp')
nat_cons ## already BNG

plot(st_geometry(nat_cons), add = T, col = 'red')


## local nature reserves
nat_res <- st_read('Data/raw_data/Scotland/local_nature_reserves/pub_lnatr.shp')
nat_res ## already BNG

plot(st_geometry(nat_res), add = T, col = 'blue')


## wildland scotland
wild <- st_read('Data/raw_data/Scotland/wildland_scotland/WILDLAND_SCOTLAND.shp')
wild ## already BNG

plot(st_geometry(wild), add = T, col = 'darkgreen')


# which grids intersect core paths (all of scotland)?

## get 10km grid
uk <- st_read('/data/notebooks/rstudio-setupconsthomas/DECIDE_constraintlayers/Data/raw_data/UK_grids/uk_map.shp')
uk_grid <- st_read('/data/notebooks/rstudio-setupconsthomas/DECIDE_constraintlayers/Data/raw_data/UK_grids/uk_grid_10km.shp')

st_crs(uk) <- 27700
st_crs(uk_grid) <- 27700

plot(st_geometry(uk), reset = T)
plot(st_geometry(uk_grid), add = T, border = 'orange')

grid_num <- st_intersects(cp_bng, uk_grid, sparse = T)
cp_ints <- apply(st_intersects(uk_grid, cp_bng, sparse = FALSE), 1, any)
unique(uk_grid$FID[cp_ints])

plot(st_geometry(uk_grid[cp_ints,]), add = T, border = 'red')

# which grids to cycle through?
range(unique(uk_grid$FID[cp_ints]))


#####' Going to save all the scottish paths and open access areas separately to the 
#####' English ones and will have to write some code to check whether or not 
#####' The grids are in scotland


## time to split them up

for(i in c(1650:3100)) {
  
  print(i)
  
  # core paths first
  core_paths_sub <- cp_bng[st_intersects(cp_bng, uk_grid[i,], sparse = F),]
  
  
  if(dim(core_paths_sub)[1] > 0){
    
    print('###   grid contains core paths   ###')
    
    core_paths_sub$object_type <- 'core_path'
    
    st_write(core_paths_sub, dsn = paste0('Data/raw_data/Scotland/core_paths/gridded_data_10km/pub_cpth_gridnumber_',i,'.shp'),
             driver = "ESRI Shapefile", delete_layer = T)
    
  }
  
  
  # public access rural
  pub_rur <- par_bng[st_intersects(par_bng, uk_grid[i,], sparse = F),]
  
  if(dim(pub_rur)[1] > 0){
    
    print('###   grid contains public access rural land   ###')
    
    pub_rur$object_type <- 'public_access_rural'
    
    st_write(pub_rur, dsn = paste0('Data/raw_data/Scotland/public_access_rural/gridded_data_10km/pub_rur_gridnumber_',i,'.shp'),
             driver = "ESRI Shapefile", delete_layer = T)
    
  }
  
  
  ## public access urban
  
  # woods
  urb_wood <- pau_bng[st_intersects(pau_bng, uk_grid[i,], sparse = F),]
  
  # paths
  urb_paths <- pau2_bng[st_intersects(pau2_bng, uk_grid[i,], sparse = F),]
  
 
  if(dim(urb_wood)[1] > 0){
    
    print('###   grid contains urban wood   ###')
    
    urb_wood$object_type <- 'urban_woodland'
    
    st_write(urb_wood, dsn = paste0('Data/raw_data/Scotland/public_access_wiat/gridded_data_10km/urb_wood_gridnumber_',i,'.shp'),
             driver = "ESRI Shapefile", delete_layer = T)
    
  }
  
  
  if(dim(urb_paths)[1] > 0){
    
    print('###   grid contains urban paths   ###')
    
    urb_paths$object_type <- 'urban_paths'
    
    st_write(urb_paths, dsn = paste0('Data/raw_data/Scotland/public_access_wiat/gridded_data_10km/urb_paths_gridnumber_',i,'.shp'),
             driver = "ESRI Shapefile", delete_layer = T)
    
  }
  
  
  ## National parks
  cairn_grid <- cairn[st_intersects(cairn, uk_grid[i,], sparse = F),]
  
  tross_grid <- cairn[st_intersects(tross, uk_grid[i,], sparse = F),]
  
  
  
  if(dim(cairn_grid)[1] > 0){
    
    print('###   grid contains cairngorms   ###')
    
    cairn_grid$object_type <- 'cairngorms'
    
    st_write(cairn_grid, dsn = paste0('Data/raw_data/Scotland/cairngorms/gridded_data_10km/cairngorm_gridnumber_',i,'.shp'),
             driver = "ESRI Shapefile", delete_layer = T)
    
  }
  
  if(dim(tross_grid)[1] > 0){
    
    print('###   grid contains trossacks   ###')
    
    tross_grid$object_type <- 'lochlomond_trossacks'
    
    st_write(tross_grid, dsn = paste0('Data/raw_data/Scotland/lochlomond_tross/gridded_data_10km/trossacks_gridnumber_',i,'.shp'),
             driver = "ESRI Shapefile", delete_layer = T)
    
  }
  
  
  ## local nature conservation sites
  nat_cons_grid <- nat_cons[st_intersects(nat_cons, uk_grid[i,], sparse = F),]
    
  ## local nature reserves
  nat_res_grid <- nat_res[st_intersects(nat_res, uk_grid[i,], sparse = F),]
  
  
  if(dim(nat_cons_grid)[1] > 0){
    
    print('###   grid contains nature conservation sites   ###')
    
    nat_cons_grid$object_type <- 'nature_conservation_sites'
    
    st_write(nat_cons_grid, dsn = paste0('Data/raw_data/Scotland/local_nature_conservation_sites/gridded_data_10km/nat_cons_gridnumber_',i,'.shp'),
             driver = "ESRI Shapefile", delete_layer = T)
    
  }
  
  
  if(dim(nat_res_grid)[1] > 0){
    
    print('###   grid contains nature reserves   ###')
    
    nat_res_grid$object_type <- 'nature_reserves'
    
    st_write(nat_res_grid, dsn = paste0('Data/raw_data/Scotland/local_nature_reserves/gridded_data_10km/nat_res_gridnumber_',i,'.shp'),
             driver = "ESRI Shapefile", delete_layer = T)
    
  }
  
  
  ## wildland scotland
  
  wildland_grid <- wild[st_intersects(wild, uk_grid[i,], sparse = F),]
  
  if(dim(wildland_grid)[1] > 0){
    
    print('###   grid contains wildland   ###')
    
    wildland_grid$object_type <- 'wildland'
    
    st_write(wildland_grid, dsn = paste0('Data/raw_data/Scotland/wildland_scotland/gridded_data_10km/wildland_gridnumber_',i,'.shp'),
             driver = "ESRI Shapefile", delete_layer = T)
    
  }
  
  
}
