#a script for processing the meta data into something that can easily be accessed by the app getNudgesVer2 function

library(purrr)
library(dplyr) 


#set working directory to `/processed_data`
if(F){
  setwd("/data/data/DECIDE_constraintlayers/processed_data") #datalabs
}

#load data
df <- list.files(pattern = ".RDS") %>%
  map(readRDS) %>% 
  bind_rows()


#for testing purposes only work with 10000 rows 
df <- sample_n(df,1000)

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

strsplit(df$feat,split = ",") %>% unlist() %>% unique()






# clean to lowercase?



# remove NAs
