
## Process OS roads 
library(sf)

# load a road network
list.files('Data/raw_data/OS_roadnetwork/data', pattern = '.shp')

# road link
rds <- st_read('Data/raw_data/OS_roadnetwork/data/HP_RoadLink.shp')
plot(rds$geometry)

rds_NK <- st_read('Data/raw_data/OS_roadnetwork/data/NK_RoadLink.shp')

t <- do.call('rbind', list(rds, rds_NK))
plot(t$geometry)

# road nodes
rds_nd <- st_read('Data/raw_data/OS_roadnetwork/data/HP_RoadNode.shp')
rds_nd
plot(rds_nd, add = T)

t <- do.call('rbind', list(rds, rds_nd))
# will need to keep roads and nodes separate

# motorway junctions
motor_jun <- st_read('Data/raw_data/OS_roadnetwork/data/NO_MotorwayJunction.shp')
motor_jun
plot(motor_jun)


##### start with road links
links <- list.files('Data/raw_data/OS_roadnetwork/data', pattern = 'Link.shp', full.names = T)
links

link_rds <- vector(mode = "list", length = 20)

for(i in 1:20){
  print(i)
  
  li_fl <- st_read(links[i], quiet = T) 
  link_rds[[i]] <- li_fl
  
}

all_rds <- do.call('rbind', link_rds)

all_rds_wr <- st_zm(all_rds, drop = T)

# write
st_write(all_rds_wr, dsn = 'Data/raw_data/OS_roadnetwork/combined_rds_links_part1.shp',
         driver = "ESRI Shapefile")



links1.5 <- links[21:35]
link_rds1.5 <- vector(mode = "list", length = 15)

for(i in 1:15){
  print(i)
  
  li_fl <- st_read(links1.5[i], quiet = T) 
  link_rds1.5[[i]] <- li_fl
  
}

all_rds1.5 <- do.call('rbind', link_rds1.5)

all_rds1.5_wr <- st_zm(all_rds1.5, drop = T)

# write
st_write(all_rds1.5_wr, dsn = 'Data/raw_data/OS_roadnetwork/combined_rds_links_part1_5.shp',
         driver = "ESRI Shapefile")



links2 <- links[36:52]
link_rds2 <- vector(mode = "list", length = length(links2))
for(i in 1:17){
  print(i)
  
  li_fl <- st_read(links2[i], quiet = T) 
  link_rds_2[[i]] <- li_fl
  
}

all_rds2 <- do.call('rbind', link_rds_2) 
all_rds2

# drop z layer
all_rds2_wr <- st_zm(all_rds2, drop = T)

# write
st_write(all_rds2_wr, dsn = 'Data/raw_data/OS_roadnetwork/combined_rds_links_part2.shp',
         driver = "ESRI Shapefile")

