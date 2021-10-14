#this is a copy of the chunk `data_prep` from prepprocessing_access_layers_v3.Rmd to run from the command line on JASMIN to download
# the OSM files for pre-processing access layers

library(osmextract)
library(sf)

#JASMIN
setwd(file.path("","home","users","simrol","DECIDE","DECIDE_constraintlayers","Scripts"))

raw_data_location <- file.path("","home","users","simrol","DECIDE","raw_data")
processed_data_location <- file.path("","home","users","simrol","DECIDE","processed_data")
environmental_data_location <- file.path("","home","users","simrol","DECIDE","environmental_data")


#set the extent of the area to get data from (use a geofabrik region name)
download_area <- "Great Britain"
#download_area <- "North Yorkshire" # use a smaller area for testing

#Access lines
vt_opts_1 = c(
  "-select", "osm_id, highway, designation, footway, sidewalk",
  "-where", "highway IN ('footway', 'path', 'residential','unclassified','tertiary','sidewalk') OR designation IN ('public_footpath','byway_open_to_all_traffic','restricted_byway','public_bridleway','access_land') OR footway = 'sidewalk' OR sidewalk IN ('both','left','right')"
)

oe_get(
  download_area,
  layer = "lines",
  provider = "geofabrik",
  match_by = "name",
  max_string_dist = 1,
  level = NULL,
  download_directory = file.path(raw_data_location,"OSM"),
  force_download = F,
  vectortranslate_options = vt_opts_1,
  extra_tags = c("designation","footway","sidewalk"),
  force_vectortranslate = T,
  quiet = FALSE
) %>% st_write(file.path(raw_data_location,"OSM","access_lines.gpkg"),delete_layer = T)


# No-go lines
vt_opts_2 <- c(
  "-select", "osm_id, highway, railway",
  "-where", "highway IN ('motorway','trunk') OR railway = 'rail'"
)

oe_get(
  download_area,
  layer = "lines",
  provider = "geofabrik",
  match_by = "name",
  max_string_dist = 1,
  level = NULL,
  download_directory = file.path(raw_data_location,"OSM"),
  force_download = F,
  vectortranslate_options = vt_opts_2,
  extra_tags = c("railway"),
  force_vectortranslate = T,
  quiet = FALSE
) %>% st_write(file.path(raw_data_location,"OSM","no_go_lines.gpkg"),delete_layer = T)


#no go areas
vt_opts_3 <- c(
  "-select", "osm_id, landuse, aeroway",
  "-where", "landuse IN ('quarry','landfill','industrial','military') OR aeroway = 'aerodrome'"
)

oe_get(
  download_area,
  layer = "multipolygons",
  provider = "geofabrik",
  max_string_dist = 1,
  level = NULL,
  download_directory = file.path(raw_data_location,"OSM"),
  force_download = F,
  vectortranslate_options = vt_opts_3,
  force_vectortranslate = T,
  quiet = FALSE
) %>% st_write(file.path(raw_data_location,"OSM","no_go_areas.gpkg"),delete_layer = T)


# water areas
vt_opts_4 <- c(
  "-select", "osm_id, natural",
  "-where", "natural = 'water'"
)

oe_get(
  download_area,
  layer = "multipolygons",
  provider = "geofabrik",
  max_string_dist = 1,
  level = NULL,
  download_directory = file.path(raw_data_location,"OSM"),
  force_download = F,
  vectortranslate_options = vt_opts_4,
  force_vectortranslate = T,
  quiet = FALSE
) %>% st_write(file.path(raw_data_location,"OSM","water_areas.gpkg"),delete_layer = T)