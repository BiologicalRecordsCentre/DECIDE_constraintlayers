
## process policy relevance

library(tidyverse)
library(readxl)
pol <- read_xlsx('/data/notebooks/rstudio-adaptivesampling/data/taxonomy/butterfly_moth_orthop_conservation_designation.xlsx')
head(pol)

pt <- pol %>% mutate(species = `Recommended taxon name`,
                     tax = str_remove(`Taxon group`, pattern = 'insect - '),
                     rep_cat = `Reporting category`,
                     desig = Designation) %>% 
  dplyr::select(species, tax, rep_cat, desig)

head(pt)
unique(pt$rep_cat)

## clean the reporting category column to have only some of the following:
# "Wildlife and Countryside Act 1981"                        
# "Biodiversity Lists - England"                             
# "Biodiversity Lists - Wales"                               
# "Biodiversity Action Plan UK list of priority species"     
# "Biodiversity Lists - Scotland"                            
# "The Wildlife (Northern Ireland) Order 1985"               
# "Biodiversity Lists - Northern Ireland"                    
# "Convention on Migratory Species"                          
# "Global Red list status"                                   
# "Bern Convention"                                          
# "Habitats Directive"                                       
# "The Conservation of Habitats and Species Regulations 2010"
# "Rare and scarce species (not based on IUCN criteria)"     
# "Red Listing based on pre 1994 IUCN guidelines"            
# "Nationally Scarce, Nationally Rare and Other Species" 

pt_icun <- pt[grep(pattern = '2001 IUCN', x  = pt$rep_cat),]
pt_icun[grep(pattern = 'Near Threatened', x = pt_icun$desig),]


# get biodiversity lists
bio_list <- pt[grep(pattern = 'Biodiversity Lists', x  = pt$rep_cat),]
unique(bio_list$rep_cat)
unique(bio_list$desig)

bio_list <- bio_list %>% 
  mutate(rep_cat_clean = 'Biodiversity lists',
         desig_clean = ifelse(desig == "England NERC S.41", 'England biodiversity list S.41',
                              ifelse(desig == "Env (Wales) Act S7", 'Welsh environment act S7',
                                     ifelse(desig == "Scottish Biodiversity List", "Scottish biodiversity List",
                                            ifelse(desig == "Priority Species (Northern Ireland)", 'NI priority species', NA)))))

criteria <- 'Biodiversity lists'
## nah this is shit
filt_crit <- function(crit){
  
  return(bio_list[bio_list$rep_cat_clean == crit,])
  
  # ls_crit <- list(species = unique(bio_list$species[bio_list$rep_cat_clean == crit]),
  #                 criteria = unique(bio_list$desig_clean[bio_list$rep_cat_clean == crit]))
  # 
  # return(ls_crit)
}


filt_crit(criteria)

# Biodiversity action plan
bio_act <- pt[grep(pattern = 'Biodiversity Action', x  = pt$rep_cat),]
unique(bio_act$rep_cat)
unique(bio_act$desig)

bio_act <- bio_act %>%
  mutate(rep_cat_clean = 'Biodiversity Action Plan',
         desig_clean = desig)

# get IUCN 2001+
iucn <- pt[grep(pattern = '2001 IUCN', x  = pt$rep_cat),]
unique(iucn$rep_cat)
unique(iucn$desig)

iucn <- iucn %>% 
  mutate(rep_cat_clean = 'IUCN',
         desig_clean = desig)


# habitats directive
hab_dir <- pt[grep(pattern = 'Habitats Directive', x  = pt$rep_cat),]
unique(hab_dir$rep_cat)
unique(hab_dir$desig)

hab_dir <- hab_dir %>% 
  mutate(rep_cat_clean = rep_cat,
         desig_clean = desig)

# wildlife and countryside act
wild <- pt[grep(pattern = 'Wildlife and Countryside', x  = pt$rep_cat),]
unique(wild$rep_cat)
unique(wild$desig)

wild <- wild %>% 
  mutate(rep_cat_clean = rep_cat,
         desig_clean = 'Schedule 5 Section 9.X')

# wildlife order (NI)
wild_NI <- pt[grep(pattern = 'The Wildlife', x  = pt$rep_cat),]
unique(wild_NI$rep_cat)
unique(wild_NI$desig)

wild_NI <- wild_NI %>% 
  mutate(rep_cat_clean = 'Northern Ireland Wildlife Order 1985',
         desig_clean = desig)


## combine
clean_pol <- rbind(bio_act, iucn, hab_dir, wild, wild_NI) %>% 
  select(-rep_cat, -desig)
clean_pol


#####    Testing outline of function

unique(clean_pol$rep_cat_clean)
criteria = unique(clean_pol$rep_cat_clean)[1:2] # for testing

## how will this link with the other functions?
## it will probably need to accept a dataframe of species within a given area, perhaps from one of
## the other 'filter' functions?

filter_policy_relevance <- function(criteria = c("Biodiversity Action Plan", "IUCN", "Habitats Directive", 
                                                 "Wildlife and Countryside Act 1981", "Northern Ireland Wildlife Order 1985"), # one or multiple of unique(clean_pol$rep_cat_clean)
                                    location = c(51.602436, -1.110557)){
  
  # get the species listed under the relevant criteria
  policy_relevance_spp <- clean_pol[clean_pol$rep_cat_clean %in% criteria,] %>% arrange(species)
  
  # create data frame
  policy_relevance <- data.frame(species = policy_relevance_spp$species,
                                 criteria = policy_relevance_spp$rep_cat_clean,
                                 status = policy_relevance_spp$desig_clean)
  
  # policy_relevance <- data.frame(species = 'Polyommatus bellargus',
  #                                status = 'LC')
  
  # set attributes
  attr(policy_relevance, which = 'criteria') <- criteria
  
  return(policy_relevance)
  
}


filter_policy_relevance('IUCN')
