
## Process OS roads 
library(sf)
library(tidyverse)

####    Testing

# load a road network
list.files('Data/raw_data/OS_roadnetwork/data', pattern = 'Link.shp')

t1 <- st_read(list.files('Data/raw_data/OS_roadnetwork/data', pattern = 'Link.shp', full.names = T)[1])
t2 <- st_read(list.files('Data/raw_data/OS_roadnetwork/data', pattern = 'Link.shp', full.names = T)[2])

t3 <- st_read(list.files('Data/raw_data/OS_roadnetwork/data', pattern = 'Link.shp', full.names = T)[3])
t4 <- st_read(list.files('Data/raw_data/OS_roadnetwork/data', pattern = 'Link.shp', full.names = T)[4])

plot(st_geometry(t1))
plot(st_geometry(t2), add = T)


ggplot() +
  geom_sf(data = t1, col = 'red') +
  geom_sf(data = t2, col = 'blue') +
  geom_sf(data = t3, col = 'green') +
  geom_sf(data = t4, col = 'yellow')

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
plot(motor_jun, add = T)



####    Splitting into grids    ####

####    for loop to go through whole grid and split up data
## load grid
uk <- st_read('/data/notebooks/rstudio-setupconsthomas/DECIDE_constraintlayers/Data/raw_data/UK_grids/uk_map.shp')
uk_grid <- st_read('/data/notebooks/rstudio-setupconsthomas/DECIDE_constraintlayers/Data/raw_data/UK_grids/uk_grid_10km.shp')

st_crs(uk) <- 27700
st_crs(uk_grid) <- 27700

plot(st_geometry(uk), reset = T)
plot(st_geometry(uk_grid), add = T, border = 'orange')
## good

all_rds <- list.files('Data/raw_data/OS_roadnetwork/data', pattern = 'Link.shp', full.names = T)
all_rds


## For each road file go through all grids
## and split them into corresponding cells
for(rds in 1:length(all_rds)) {
  print(rds)
  
  rd_of_interest <- st_transform(st_read(all_rds[rds], quiet = T), crs = 27700)
  
  for(g in 1:dim(uk_grid)[1]){
    
    print(paste(g, '/', dim(uk_grid)[1]))
    
    rd_int <- rd_of_interest[st_intersects(rd_of_interest, uk_grid[g,], sparse = F),]
    
    if(dim(rd_int)[1]==0){
      
      # print('no road in grid')
      
      next
      
    } else if(dim(rd_int)[1]>0) {
      
      print('###   grid contains road   ###')
      
      ## check to see if any roads before it were also in same grid
      prev_files_list <- list.files(paste0('Data/raw_data/OS_roadnetwork/gridded_link_road_10km/',
                                           pattern =  paste0('_', g, '.shp')),
                                    full.names = T)
      
      ## if there are then, combine them with the new files
      if(length(prev_files_list)>0){ 
        
        print(paste('grid also contains other road grid =', g, 'road =', rds))
        
        # read them in 
        prev_files <- st_read(prev_files_list, quiet = TRUE)
        
        # join them together
        out_files <- rbind(prev_files, rd_int)
        
      } else if(length(prev_files_list)==0) { ## if not, rename roads of interest for output
        
        out_files <- rd_int
        
      }
      
      st_write(st_zm(out_files), dsn = paste0('Data/raw_data/OS_roadnetwork/data/gridded_link_road_10km/road_gridnumber_',g,'.shp'),
               driver = "ESRI Shapefile", delete_layer = T)
      
    }
    
  }
}



##### start with road links

#### clearly takes too long....
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
  link_rds2[[i]] <- li_fl
  
}

all_rds2 <- do.call('rbind', link_rds2) 
all_rds2

# drop z layer
all_rds2_wr <- st_zm(all_rds2, drop = T)

# write
st_write(all_rds2_wr, dsn = 'Data/raw_data/OS_roadnetwork/combined_rds_links_part2.shp',
         driver = "ESRI Shapefile")


t <- st_read('Data/raw_data/OS_roadnetwork/combined_rds_links_part1_5.shp')
