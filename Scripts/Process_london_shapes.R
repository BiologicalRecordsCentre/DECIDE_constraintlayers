library(sf)


unzip('Data/raw_data/greater-london-latest-free.shp.zip',
      exdir='Data/raw_data/greater-london-latest-free/')

list.files('Data/raw_data/greater-london-latest-free/')

lond_builds <- st_read('Data/raw_data/greater-london-latest-free/gis_osm_buildings_a_free_1.shp')
plot(st_geometry(lond_builds))

lond_pofw <- st_read('Data/raw_data/greater-london-latest-free/gis_osm_pofw_a_free_1.shp') ## places of worship
plot(st_geometry(lond_prow))  
  