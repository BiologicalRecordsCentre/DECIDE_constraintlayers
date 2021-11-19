#a script for processing the meta data into something that can easily be accessed by the app getNudgesVer2 function

library(purrr)
library(dplyr) 
library(fst)


#set working directory to `/processed_data`
if(F){
  setwd("/data/data/DECIDE_constraintlayers/processed_data") #datalabs
}

#load data
df <- list.files(pattern = ".RDS") %>%
  map(readRDS) %>% 
  bind_rows()

str(df)

#for testing purposes only work with 10000 rows 
df <- sample_n(df)

#clean access feature names
unique_types <- strsplit(df$feat,split = ",") %>% unlist() %>% unique()

#define some conversions
conversions <- list("public_bridleway" = "Bridleway",
     "footway" = "Footpath",
     "residential" = "Road",
     "unclassified" = "Lane",
     "tertiary" = "Road",
     "public_footpath" = "Footpath",
     "path" = "Footpath",
     "restricted_byway" = "Restricted Byway",
     "core_path" = "Footpath",
     "track"="Track",
     "primary" = "Road",
     "secondary" = "Road",
     "Path- stone track / Slope - steep / Waymarked / Obstacles- Bridge/s" = "Footpath",
     "BOAT" = "Byway open to all traffic",
     "byway_open_to_all_traffic" = "Byway open to all traffic",
     "public_footway" = "Footpath",
     "quiet_lane" = "Lane",
     " section on public road" = "Road",
     " cattle grid" = "Road",
     "trunk" = "Road",
     "track_grade1" = "Track",
     "estate road" = "Road",
     "cycleway" = "Cycleway"
     )

df$feat <- strsplit(df$feat,split = ",") %>% lapply(function(x){
  needs_replacing <- x %in% names(conversions)
  x[needs_replacing] <- unlist(conversions, use.names=FALSE)[match(x[needs_replacing],names(conversions))]
  x <- unique(x)
  paste(x,collapse=",")
}) %>% unlist()

#strsplit(df$feat,split = ",") %>% unlist() %>% unique()

# clean to lowercase?



# remove NAs















setwd("/data/data/DECIDE_constraintlayers/metadata_tables")

#making lots of files

x_breaks <- seq(from = 0,to = 700000, by = 10000)
y_breaks <- seq(from = 0,to = 1300000, by = 10000)

files <- expand.grid(x = x_breaks,y = y_breaks) %>% data.frame()
options("scipen"=10)

files$file_names <- paste0(files$x,"-",files$y,".fst")


str(files)

for (i in 1564:nrow(files)){
  print(i)
  df_temp <- df %>% filter(x >= files$x[i],
                           x <  files$x[i]+10000,
                           y >= files$y[i],
                           y <  files$y[i]+10000)
  
  if(nrow(df_temp)>0){
    write_fst(df_temp,files$file_names[i])
  }
}




# 
# #vector of xs and vectory of ys
# get_meta_data <- function(x,y){
#   x_grid <- (x %/% 10000) * 10000
#   y_grid <- (y %/% 10000) * 10000
#   
#   # read files
#   file_location <- 
#   
#   # bind files
#   
#   #return meta data
#   
# }









