

library(raster)
library(sf)
library(dismo)
library(tidyverse) # this is a very old version even though newer version is on CRAN...
library(reshape2)
# source("/data/notebooks/rstudio-adaptivesampling/scripts/modules/filter_distance.R") ## doesn't work, why?

######     load a file to test different functions

list.files('/data/notebooks/rstudio-constraintlayers/Data/raw_data/subset_species_ranfor_29_01_21/')

list.files('data')

load(list.files('/data/notebooks/rstudio-constraintlayers/Data/raw_data/subset_species_ranfor_29_01_21/', full.names = T)[1])

all_mods[[1]]$sdm_output$Species
all_mods[[1]]$sdm_output$AUC

par(mfrow=c(1,2))
plot(all_mods[[1]]$sdm_output$Predictions)
plot(all_mods[[1]]$quantile_range)
points(x = 460805, y = 190209, pch = 20, col = 'red', cex = 1)
par(mfrow=c(1,1))

wall_2k_err <- filter_distance(raster = all_mods[[1]]$quantile_range,
                               method = 'buffer',
                               distance = 2000)

wall_2k_pred <- filter_distance(raster = all_mods[[1]]$sdm_output$Predictions,
                                method = 'buffer',
                                distance = 2000)
par(mfrow = c(1,2))
plot(wall_2k_pred)
plot(wall_2k_err)
par(mfrow = c(1,1))



#####     For multiple species     #####

## load files

all_spp <- list()
all_spp_name <- c()

# load in the model outputs for each species in turn
# store them as a list and the species names as a list too
# easier to get the names in the for loop to name the different entries

for(i in 1:length(list.files('/data/notebooks/rstudio-constraintlayers/Data/raw_data/subset_species_ranfor_29_01_21/'))){
  
  # load
  load(list.files('/data/notebooks/rstudio-constraintlayers/Data/raw_data/subset_species_ranfor_29_01_21/', full.names = T)[i])
  
  # store sdm output file
  all_spp[[i]] <- all_mods
  
  # store names
  all_spp_name[i] <- as.character(all_mods[[1]]$sdm_output$Species)
  
}

# name the list the names of each species
names(all_spp) <- all_spp_name

# plot Zygaena loti
par(mfrow = c(1,2))
plot(all_spp[[7]]$rf$sdm_output$Predictions, main = all_spp[[7]]$rf$sdm_output$Species)
plot(all_spp[[7]]$rf$quantile_range, main = paste(all_spp[[7]]$rf$sdm_output$Species, '95% quantile range'))
par(mfrow = c(1,1))

# Check full plot with Jordanita globulariae
par(mfrow = c(1, 2))
plot(all_spp[[3]]$rf$sdm_output$Predictions, main = all_spp[[3]]$rf$sdm_output$Species)
points(x = all_spp[[3]]$rf$sdm_output$Data$lon, y = all_spp[[3]]$rf$sdm_output$Data$lat, col = 'red', pch = 20)
plot(all_spp[[3]]$rf$quantile_range, main = 'Bootstrapped variation')
par(mfrow = c(1, 1))


#############           Get region of interest            ###############

# get the predictions and error around wallingford for each species
# using the filter_distance() function
# default location is coordinates for wallingford
# we could create a wrapper function to do this with:

## _input_ prediction raster; region method (i.e. 'buffer'); location; distance; SDM method (one or all of glm, rf, gam, me)
## _output_ predictions from all species; bootstrapped variation all species; plots?

par(mfrow = c(2,2))

wall_ls_pred <- list()
wall_ls_err <- list()
wall_ls <- list()

for(j in 1:length(all_spp)) {
  
  # crop the predictions
  wall_2k_pred <- filter_distance(raster = all_spp[[j]]$rf$sdm_output$Predictions,
                                  method = 'buffer',
                                  distance = 2000)
  names(wall_2k_pred) <- 'predictions'
  
  # crop the error
  wall_2k_err <- filter_distance(raster = all_spp[[j]]$rf$quantile_range,
                                 method = 'buffer',
                                 distance = 2000)
  names(wall_2k_err) <- 'error'
  
  # plot the predictions and error
  plot(wall_2k_pred, main = all_spp[[j]]$rf$sdm_output$Species)
  plot(wall_2k_err, main = 'Bootstrapped error')
  
  # store everything in three lists
  # although don't actually use 'wall_ls'
  wall_ls[[j]] <- list(wall_2k_pred, wall_2k_err) 
  wall_ls_pred[[j]] <- wall_2k_pred
  wall_ls_err[[j]] <- wall_2k_err
  
}

# name the different entries in the list as the species they are
names(wall_ls_pred) <- all_spp_name
names(wall_ls_err) <- all_spp_name
names(wall_ls) <- all_spp_name

# stack the predictions and error, plot them
pred <- raster::stack(wall_ls_pred)
err <- raster::stack(wall_ls_err)
plot(pred)
plot(err)

####' Need to figure out how to incorporate different models in this workflow
####' Do we want to keep each model separate - could be useful for WP3?



#############         Recommending a location        ###############

# testing a metric of uncertainty to find the grid cells with
# the highest probability of presence and error
# we are trying to send people to areas with high probability of presence
# and large amounts of variability in the predictions
# need to be careful about how to do this as it will have a big impact on
# the locations that are recommended
# what I have done below is just to outline the process
#####    THIS NEEDS REFINING    #####

## multiply predictions and errors
mult_err <- pred*err
plot(mult_err)

## Sum predictions and errors
sum_err <- pred+err
plot(sum_err)


##' recommend_metric function
##' A function to combine the predictions and errors
##' Need to add more (better) metrics to those listed below
##' Maybe need to only return one metric, rather than the possibility of multiple
# 
# _input_ rasterstack predictions each species; rasterstack error each species
# _output_ tbd

recommend_metric <- function(prediction_raster, 
                             error_raster, 
                             method = c('multiply', 'additive')){
  
  if(!all(method %in% c('multiply', 'additive'))){
    
    stop("'methods are limited to:'multiply', 'additive'")
    
  }
  
  # multiplication metric
  if('multiply' %in% method) {
    mult_err <- prediction_raster*error_raster
  } else {
    mult_err <- NULL
  }
  
  # additive metric
  if('additive' %in% method) {
    sum_err <- prediction_raster+error_raster
  } else {
    sum_err <- NULL
  }
  
  return(list(multiply = mult_err,
              additive = sum_err))
  
}

addit_met <- recommend_metric(prediction_raster = pred,
                              error_raster = err, 
                              method = 'additive')$additive ## for now in case we want to be able to return ultiple metrics

addit_met


#### going to stick with addition for now as it is simple
#### This is bad, I think, because it will weight things towards probability of presence 


####    The three different methods of providing recommendations 
## see the Teams document, but simply:

# 1) agreggate all species
# 2) all species separately
# 3) all species separately and then aggregate by rank


## 1) aggregate across all species
plot(pred)
plot(addit_met)

# sum probability of presence across all species
sum_prob_all_spp <- sum(pred)

# sum all error metric across species
a_spp_sum_pred_err <- sum(addit_met)

#### plot them side-by-side
# these look similar because the error variation is so small
par(mfrow = c(1, 2))
plot(sum_prob_all_spp, main = 'Probability presence all species')
plot(a_spp_sum_pred_err, main = 'sum all spp, pred + var')
par(mfrow = c(1, 1))

#####     rank the cells most pred+var to least pred+var     #####
# convert to data frame
a_spp_sum_df <- as.data.frame(a_spp_sum_pred_err, xy = T)
head(a_spp_sum_df)

# rank the cells
# need to rank them by the best place to visit being the largest number
# to avoid problems with plotting the raster
rank_all_spp_sum <- a_spp_sum_df %>%
  arrange(layer) %>% 
  mutate(rank = seq(1, length(layer)),
         rank = ifelse(is.na(layer), NA, rank)) %>% 
  rename(sum_prob_err = layer)
head(rank_all_spp_sum)

# convert back to raster
spg <- rasterFromXYZ(rank_all_spp_sum)
plot(spg) # raw summed prediction and error values, and ranked cells next to it


##### function recommend_aggregate()
##' aggregate prediction, errors and ranks across all species
##' Include in the function a way to get the rank across all species when added together
##' but also get a rank that done for each species separately
##' This is to solve points 1, 2 and 3 in the Teams document
##' _input_ prediction+error rasterstack of species (output of recommend_metric()); 
##' _input_ cont.: method for recommendation (only rank so far);
##' _input_ cont.: how to aggregate predictions (don't know if useful) - across species/species separately ---- HAVE A THINK ----
##' _outout_ method = 'additive' : 2 rasters, original metric and inverse rank of cells metric 
##' _outout_ method = 'species_rank' :  2 rasters for each species, original metric and inverse rank of cells metric 

predict_err_raster = addit_met

recommend_aggregate <- function(predict_err_raster,
                                method = NULL){ # c('additive', 'species_rank'), one of these options
  
  if(!all(method %in% c('additive', 'species_rank'))){
    
    stop("'methods are limited to:'additive', 'species_rank'")
    
  }
  
  # if additive, sum across all species,
  # if species retain the error for each species separately
  if(method == 'additive'){
    rast <- sum(predict_err_raster) # sum raster layer of predict_err_raster across all species
  } else if(method == 'species_rank') {
    rast <- predict_err_raster # keep the raster for each species separately
  }
  
  comb_df <- as.data.frame(rast, xy = T) # convert raster to data frame
  head(comb_df)
  
  # to get the rank need to use 'quo()' argument to create a conditional 'group_by()' statement later
  if(method == 'additive'){
    quo_var <- quo() # if ranking across all species, don't need to 'group_by()' anything, so need an empty variable
  } else if(method == 'species_rank'){
    # if want the rank for each species separately, need to 'group_by' species
    # to be able to do this, need to change the data frame created from 'as.data.frame' into long format
    
    # convert into long format to get rank in same way as above - would be easier with pivot_longer/pivot_wider
    comb_df <- melt(comb_df, id.vars = c('x', 'y'), 
                    variable.name = 'species',
                    value.name = 'layer')
    
    quo_var <- quo(species) # save 'species' as the grouping variable using the 'quo()' function
  }
  
  # now, need to create the ranking
  # it is the 'inverse_ranking' to make plotting easier later so don't have to mess with colour scale
  rank_df <- comb_df %>%
    group_by(!!quo_var) %>% # this will group_by() species if the method == 'species_rank'
    arrange(layer) %>% # sort by layer, increasing
    mutate(inverse_rank = seq(1, length(layer)), # create a rank, highest rank, highest prob+err
           inverse_rank = ifelse(is.na(layer), NA, inverse_rank)) %>% # get rid of NAs so left with original dimension raster
    rename(error_metric = layer)
  
  ##'  If the method=='species_rank' want to have it in wide format to convert to a raster stack for each species
  ##'  Could do this without an lapply() statement if could use pivot_wider.
  ##'  Without pivot_wider, need to convert each subset of data frame separately and store as list
  if(method == 'species_rank'){
    
    spp <- unique(rank_df$species) %>% sort()
    
    rank_df <- lapply(spp, ranked_df = rank_df, FUN = function(species, ranked_df){
      # subset the dataframe by species
      sub_df <- ranked_df[ranked_df$species == species,]
      
      # convert to raster
      sp_rast <- rasterFromXYZ(sub_df[,!names(sub_df) %in% c("species")]) # remove the species name from the layer
      
      # store raster
      return(sp_rast)
    })
    
    names(rank_df) <- spp
    
    return(rank_df)
  } else ( # for all species together, create the raster and return it
    
    # convert the back to raster
    return(rasterFromXYZ(rank_df)))
  
}

# aggregated rank across all species output = 2 rasters, original metric and inverse rank of cells metric 
agg_rank <- recommend_aggregate(addit_met,
                                method = 'additive')
plot(agg_rank)

# rank for each species output = 2 rasters for each species, original metric and inverse rank of cells metric 
species_rank <- recommend_aggregate(addit_met,
                                    method = 'species_rank')
plot(species_rank$Archiearis.parthenias)


# plot probability distribution across all species alongside
# the rank of which cells to visit
par(mfrow = c(1,2))
plot(sum_prob_all_spp, main = 'prob distrib all spp')
plot(agg_rank[[2]], main = 'ranked cells')
par(mfrow = c(1,1))
## heavily weighted in favour of probability of presence rather than variation


## 2) for each species separately
# probability of presence + variation
plot(addit_met)

sum_err_spp_df <- as.data.frame(sum_err, xy = T)
head(sum_err_spp_df)

# convert into long format to get rank in same way as above
sum_err_spp_long <- melt(sum_err_spp_df, id.vars = c('x', 'y'), 
                         variable.name = 'species',
                         value.name = 'layer')
head(sum_err_spp_long)

# get the rank of priority cells for each species 
rank_each_spp_sum <- sum_err_spp_long %>%
  group_by(species) %>% 
  arrange(layer) %>% 
  mutate(rank = seq(1, length(layer)),
         rank = ifelse(is.na(layer), NA, rank)) %>% 
  rename(sum_prob_err_all_spp = layer) %>% 
  ungroup() %>% 
  arrange(species)
head(rank_each_spp_sum)



# use for loop to create rasters again and
# plot the probability of presence and cell rankings alongside
rast_out <- list()
spp_ls <- unique(rank_each_spp_sum$species) %>% sort()

par(mfrow = c(2,2), mar = c(3, 5, 2, 5))

for(i in 1:length(spp_ls)){
  
  # subset the dataframe by species
  sub_df <- rank_each_spp_sum[rank_each_spp_sum$species == spp_ls[i],]
  
  # convert to raster
  sp_rast <- rasterFromXYZ(sub_df[,!names(sub_df) %in% c("species")])
  
  # store raster
  rast_out[[i]] <- sp_rast
  
  # plot prediction (pred from above) and ranked cells 
  plot(pred[[i]], main = paste(names(pred[[i]]), 'presence prob'))
  plot(rast_out[[i]][[2]], main = paste(spp_ls[i], 'ranked_cells'))
  
}

# keep the names with the rasters
names(rast_out) <- spp_ls

# return to normal margins
par(mfrow = c(1,1), mar = c(5.1, 4.1, 4.1, 2.1))


## 3) Priority areas by aggregated rank across all species
# basically, just need to sum the rank layer from the rast_out list
rnk_out <- list()

for(j in 1:length(rast_out)){
  
  rnk <- rast_out[[j]][[2]]
  rnk_out[[j]] <- rnk
  
}

overall_rnk <- sum(stack(rnk_out))
plot(overall_rnk)


# function to get aggregated rank across species
# only works on recommend_aggregate with method = 'species_rank'

recommend_agg_rank <- function(rast) {
  
  rst_nms <- names(rast)
  
  ranks <- lapply(rst_nms, FUN = function(x){rast[[x]][[2]]})
  
  return(calc(stack(ranks), fun = sum)) # could it be useful to use different functions here? I.e. standard deviation? does the standard deviation of the rank make any sense?
         
}

agg_rnk <- recommend_agg_rank(rast)
plot(agg_rnk)

#####    Plot overall rank alongside rank of summed error+probability from 1)
par(mfrow = c(1,2), mar = c(5.1, 4.1, 4.1, 5))
plot(spg[[2]], main = '1) ranks from summed prob+error')
plot(overall_rnk, main = '3) summed rank of all species')
par(mfrow = c(1,1))
# This makes sense because the results from method 1)
# will weight the species with the highest probabilities the most.
# the results from method 2), because the cells were ranked for each species
# separately first, will be less driven by the highest probability species


#######       Identifying outlying species       #######
## tomorrow ##



# ## Filter distance function
# filter_distance <- function(raster,
#                             location = c(-1.110557, 51.602436), # has to be c(long, lat) as input
#                             method = c('buffer', 'travel'),
#                             distance = 20000){ # distance willing to go in metres
# 
#   if(method == 'buffer'){
# 
#     # first need to convert long lat to BNG
#     dat_sf <- st_sf(st_sfc(st_point(location)), crs = 4326) # load location points, convert to spatial lat/lon
#     trans_loc <- st_transform(dat_sf, crs = 27700) # transform to BNG
#     buffed <- st_buffer(trans_loc, distance) # create a buffer around the point
# 
#     # # show where the buffered zone is
#     # par(mfrow = c(1,2))
#     # plot(raster)
#     # plot(buffed, add = T)
# 
#     # extract the masked extent
#     c_buf <- crop(raster, buffed) # crop the raster - creates a square extent
#     masked_area <- mask(c_buf, buffed)
#     # plot(masked_area) # then mask it to get only the area within the 'travel distance'
#     # par(mfrow = c(1,1))
# 
#   }
# 
#   return(masked_area) # return only the masked region x distance from the 'location'
# 
# }