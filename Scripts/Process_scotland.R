
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
plot(st_geometry(cp_bng))

ggplot() +
  geom_sf(data = cp_bng)


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

plot(st_geometry(pau_bng), col = 'red', add = F)
plot(st_geometry(pau2_bng), col = 'red', add = F)


## Cairngorms
