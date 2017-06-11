#### Section 01: Setup ----
### libraries control
require(checkpoint)
checkpoint("2017-03-10", R.version = "3.3.1",
           checkpointLocation = "D:/R")

### libraries
## data managements
require(tidyverse)
require(lubridate)
require(stringr)
require(readr)
require(rgdal)
require(sp)
require(rgeos)

# environmental control
rm(list = ls()); gc()

### directories
dir.data_raw <- "data/raw"
dir.data_db <- "data"
dir.data_rollback <- "data/rollback"
dir.src <- "scripts"

### utility functions
source(file.path(dir.src, "utility functions.r"))

### data
spldf.nz_region <- readRDS(file.path(dir.data_raw, "Region_Shape_16"))
spldf.nz_ta <- readRDS(file.path(dir.data_raw, "TA_Shape_16"))
# spldf.nz_au <- readRDS(file.path(dir.data_raw, "Area_Unit_Shape_16"))
spldf.nz_au <- readRDS(file.path(dir.data_raw, "Area_Unit_Shape_16_22_Mar_updated.rds"))

df.snz_area_mapping <- read_csv(file.path(dir.data_raw, "2016_Areas_Table.txt"))

load(file.path(dir.data_db, "CYAR Dashboard Data - CYAR.rda"))
# load(file.path(dir.data_db, "CYAR Dashboard Data - SFY.rda"))

### data processing
spldf.nz_region@data <- spldf.nz_region@data %>% 
  change_names("description", "AREA_CODE") %>% 
  mutate(AREA_CODE = as.character(AREA_CODE))

spldf.nz_ta@data <- spldf.nz_ta@data %>% 
  change_names("description", "AREA_CODE") %>% 
  mutate(AREA_CODE = as.character(AREA_CODE))

spldf.nz_au@data <- spldf.nz_au@data %>% 
  change_names("description", "AREA_CODE") %>% 
  mutate(AREA_CODE = as.character(AREA_CODE))

### incorrect method ----
# Some TA are wards in the auckland regions
# should never just replace na with unknown and drop it without checking
# df.tmp_area_mapping <- df.snz_area_mapping %>% 
#   select(TA2016_label, AU2016_label) %>% 
#   unique() %>% 
#   change_names(c("TA2016_label", "AU2016_label"),
#                c("TA", "AU"))
# 
# df.db_au_mapping <- df.db_area_mapping %>%
#   left_join(df.tmp_area_mapping) %>%
#   replace_na(list(AU="UNKOWN")) %>%
#   filter(AU!="UNKOWN") %>%
#   unique()



### create mapping table between TA, AU and REGION ----
df.tmp_area_mapping <- df.snz_area_mapping %>% 
  select(REGC2016_label, TA2016_label, AU2016_label, WARD2016_label) %>% 
  change_names(c("REGC2016_label", "TA2016_label", "AU2016_label", "WARD2016_label"),
               c("REGION", "TA", "AU", "WARD")) %>%
  unique()

df.tmp_ta_region_mapping <- df.db_cyar_sp  %>% 
  filter(AREA_TYPE %in% "TA")  %>% 
  select(AREA_CODE)  %>% 
  unique() %>% 
  left_join(
    df.tmp_area_mapping %>% 
      select(TA, REGION) %>% 
      change_names("REGION", "REGION_TA") %>% 
      mutate(FLAG_TA = TRUE),
    by = c("AREA_CODE" = "TA")
  ) %>%
  left_join(
    df.tmp_area_mapping %>% 
      select(WARD, REGION) %>% 
      change_names("REGION", "REGION_WD") %>% 
      mutate(FLAG_WD = TRUE),
    by = c("AREA_CODE" = "WARD")
  ) %>% 
  replace_na(list(FLAG_TA = FALSE, FLAG_WD = FALSE)) %>%
  unique() %>% 
  mutate(REGION = ifelse(FLAG_TA, REGION_TA,
                         ifelse(FLAG_WD, REGION_WD, "Unknown"))) %>% 
  select(AREA_CODE, REGION) %>% 
  change_names("AREA_CODE", "TA") %>% 
  group_by(TA) %>% 
  mutate(INDEX = 1:n()) %>% 
  ungroup() %>% 
  filter(INDEX == 1) %>% 
  select(-INDEX)

df.tmp_ta_au_mapping <- df.db_cyar_sp  %>% 
  filter(AREA_TYPE %in% "TA")  %>% 
  select(AREA_CODE)  %>% 
  unique() %>% 
  left_join(
    df.tmp_area_mapping %>% 
      select(AU, TA) %>% 
      change_names("AU", "AU_TA") %>% 
      mutate(FLAG_TA = TRUE),
    by = c("AREA_CODE" = "TA")
  ) %>%
  left_join(
    df.tmp_area_mapping %>% 
      select(WARD, AU) %>% 
      change_names("AU", "AU_WD") %>% 
      mutate(FLAG_WD = TRUE),
    by = c("AREA_CODE" = "WARD")
  ) %>% 
  replace_na(list(FLAG_TA = FALSE, FLAG_WD = FALSE)) %>%
  unique() %>% 
  mutate(AU = ifelse(FLAG_TA, AU_TA,
                     ifelse(FLAG_WD, AU_WD, "Unknown"))) %>% 
  select(AREA_CODE, AU) %>% 
  change_names("AREA_CODE", "TA") %>% 
  group_by(AU) %>% 
  mutate(INDEX = 1:n()) %>% 
  ungroup() %>% 
  filter(INDEX == 1) %>% 
  select(-INDEX)

df.db_au_mapping <- df.tmp_ta_region_mapping %>% 
  left_join(df.tmp_ta_au_mapping)

#### Section 03: Data Export ----
save(spldf.nz_region, spldf.nz_ta, spldf.nz_au, df.db_au_mapping,
     file = file.path(dir.data_db, "CYAR Dashboard Data - Shapefiles.rda"))