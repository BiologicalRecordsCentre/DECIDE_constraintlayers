

### Travel times with road map

## this is need to test to see if it works


## testing process following this example:
## https://geocompr.robinlovelace.net/transport.html


library(sf)
library(dplyr)
# library(spDataLarge)
library(stplanr)      # geographic transport data package
library(tmap)         # visualization package (see Chapter 8)
library(osrm)         # routing package

hp <- st_read('Data/raw_data/OS_roadnetwork/data/HP_RoadLink.shp')
plot(hp)
class(hp)

ht <- st_read('Data/raw_data/OS_roadnetwork/data/HT_RoadLink.shp')
plot(ht)

comb <- st_union(hp, ht)
plot(comb)

attributes(comb)


rd_list <- list()

files <- list.files('Data/raw_data/OS_roadnetwork/data/', pattern = ".shp", full.names = T)

for(i in 1:length(files)){
  rd_list[[i]] <- st_read(files[i])
}
