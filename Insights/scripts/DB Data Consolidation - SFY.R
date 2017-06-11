#### Section 01: Setup ----
### libraries control
#require(checkpoint)
#checkpoint("2017-03-10", R.version = "3.3.1",
#           checkpointLocation = "D:/R")

setwd("//hamlet/shares/xdrive/ST/4 Cross-Agency and Whole of Government Processes/7 Performance Hub/10 Analytics and Insights/infographics 2015/Insights")

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
dir.data_raw_sfy <- "data/raw/SFY/May-update"
dir.data_db <- "data"
dir.data_rollback <- "data/rollback"
dir.src <- "scripts"

### utility functions
source(file.path(dir.src, "utility functions.r"))

### data
df.raw_sfy_empb <- read_csv(file.path(dir.data_raw_sfy, "S_agerisk_empb.csv"))
df.raw_sfy_edub <- read_csv(file.path(dir.data_raw_sfy, "S_agerisk_edub.csv"))

df.raw_sfy_empb_region <- read_csv(file.path(dir.data_raw_sfy, "S_REGION_empb.csv"))
df.raw_sfy_edub_region <- read_csv(file.path(dir.data_raw_sfy, "S_REGION_edub.csv"))

df.raw_sfy_empb_ta <- read_csv(file.path(dir.data_raw_sfy, "S_TA_empb.csv"))
df.raw_sfy_edub_ta <- read_csv(file.path(dir.data_raw_sfy, "S_TA_edub.csv"))

df.raw_sfy_mapping <- read_csv(file.path(dir.data_raw_sfy, "SFY - mapping.csv"))
df.sfy_mapping_risk <- read_csv(file.path(dir.data_raw_sfy, "Risk Description - mapping.csv")) %>% 
  mutate(AGE = replace(AGE, AGE == "Jun-14", "6-14"))
df.sfy_mapping_region <- read_csv(file.path(dir.data_raw, "Regional Mapping.csv"))

df.snz_area_mapping <- read_csv(file.path(dir.data_raw, "2016_Areas_Table.txt"))


### data processing
df.sfy_mapping <- df.raw_sfy_mapping %>% 
  change_names(c("Indicators", "Shortened", "Period", "Education", "Employment"),
               c("COLNAMES", "SERV_IND", "PERIOD", "FLAG_KEEP_EDU", "FLAG_KEEP_EMP")) %>% 
  select(COLNAMES, SERV_IND, PERIOD, FLAG_KEEP_EDU, FLAG_KEEP_EMP, FLAG_KEEP)

df.sfy_edub <- df.raw_sfy_edub %>% 
  gather(COLNAMES, COUNT, -year, -riskgrp, -age_desc, -schter_1519, -x_gender_desc) %>% 
  left_join(df.sfy_mapping) %>% 
  filter(FLAG_KEEP_EDU == 1,
         FLAG_KEEP == 1) %>% 
  change_names(c("year", "riskgrp", "age_desc", "x_gender_desc", "schter_1519"),
               c("YEAR", "RISK", "AGE", "GENDER", "OTHER_IND")) %>% 
  mutate(SERV_TYPE = "Education") %>% 
  select(YEAR, PERIOD, AGE, GENDER, RISK, SERV_TYPE, SERV_IND, OTHER_IND, COUNT) 

df.sfy_empb <- df.raw_sfy_empb %>% 
  gather(COLNAMES, COUNT, -year, -riskgrp, -age_desc, -ben_1524, -x_gender_desc) %>% 
  left_join(df.sfy_mapping) %>% 
  filter(FLAG_KEEP_EMP == 1,
         FLAG_KEEP == 1) %>% 
  change_names(c("year", "riskgrp", "age_desc", "x_gender_desc", "ben_1524"),
               c("YEAR", "RISK", "AGE", "GENDER", "OTHER_IND")) %>% 
  mutate(SERV_TYPE = "Employment") %>% 
  select(YEAR, PERIOD, AGE, GENDER, RISK, SERV_TYPE, SERV_IND, OTHER_IND, COUNT) 

df.db_sfy <- df.sfy_edub %>% 
  bind_rows(df.sfy_empb) %>% 
  left_join(df.sfy_mapping_risk) %>% 
  mutate(OTHER_IND = plyr::mapvalues(OTHER_IND, c(1, 0), c("Yes", "No"))) %>% 
  mutate(AGE = plyr::mapvalues(AGE, c("06-14", "15-19", "20-24"), c("6-14 years", "15-19 years", "20-24 years"))) %>% 
  mutate(OTHER_TYPE = ifelse(SERV_TYPE == "Employment", "On Benefit?", "In education?")) %>% 
  mutate(PERIOD = paste("Last ", PERIOD, " year", ifelse(PERIOD > 1, "s", ""), sep = ""))  
#  replace_na(list(RISK_DESC = "No Risk"))

#df.db_sfy <- df.db_sfy %>% 
#  filter(AGE == "6-14 years") %>% 
#  filter(RISK_DESC == "2+ Risk Indicators") %>% 
#  mutate(RISK_DESC = plyr::mapvalues(RISK_DESC, "2+ Risk Indicators", "In any of the above groups")) %>% 
#  mutate(RISK = plyr::mapvalues(RISK, 2, 6)) %>%
#  ## people between 6-14 years are not mutually exclusive 
#  # filter(RISK_DESC != "No Risk") %>% 
#  # group_by(YEAR, PERIOD, AGE, GENDER, SERV_TYPE, SERV_IND, OTHER_IND, OTHER_TYPE) %>% 
#  # summarise(COUNT = sum(COUNT, na.rm = TRUE)) %>% 
#  # mutate(RISK_DESC = "In any of the above groups") %>% 
#  # mutate(RISK = 6) %>%
#  ungroup() %>%
#  bind_rows(df.db_sfy) %>%
#  mutate(OTHER_TYPE = paste0("Subset to ", OTHER_TYPE)) %>%
#  arrange(desc(COUNT)) %>%
#  mutate(SERV_IND = gsub("\\Services", "", x = SERV_IND))

df.db_sfy <- df.db_sfy %>% 
  filter(!(AGE == "6-14 years" & SERV_IND %in% c("Secondary Tertiary Programmes","Student Allowance","Gateway Programme","Industry Training","Youth Guarantee: Fees-Free","Alternative Education Services"))) %>% 
  filter(!(AGE == "15-19 years" & SERV_IND %in% c("Resource Teachers: Learning And Behaviour Services","Reading Recovery Services","Interim Response Fund Services"))) %>% 
  mutate(OTHER_TYPE = paste0("Subset to ", OTHER_TYPE))  %>%
  arrange(desc(COUNT)) %>%
  mutate(SERV_IND = gsub("\\Services", "", x = SERV_IND))

### regional table consolidation
df.sfy_edub_region <- df.raw_sfy_edub_region %>% 
  gather(COLNAMES, COUNT, -year, -riskgrp, -reg, -age_desc, -schter_1519, -x_gender_desc) %>% 
  left_join(df.sfy_mapping) %>% 
  filter(FLAG_KEEP_EDU == 1,
         FLAG_KEEP == 1) %>% 
  change_names(c("year", "riskgrp", "age_desc", "x_gender_desc", "schter_1519", "reg"),
               c("YEAR", "RISK", "AGE", "GENDER", "OTHER_IND", "AREA_CODE")) %>% 
  mutate(SERV_TYPE = "Education") %>%
  mutate(AREA_TYPE = "Region") %>% 
  select(YEAR, PERIOD, AREA_CODE, AREA_TYPE, AGE, GENDER, RISK, SERV_TYPE, SERV_IND, OTHER_IND, COUNT)

df.sfy_empb_region <- df.raw_sfy_empb_region %>% 
  gather(COLNAMES, COUNT, -year, -riskgrp, -reg, -age_desc, -ben_1524, -x_gender_desc) %>% 
  left_join(df.sfy_mapping) %>% 
  filter(FLAG_KEEP_EMP == 1,
         FLAG_KEEP == 1) %>% 
  change_names(c("year", "riskgrp", "age_desc", "x_gender_desc", "ben_1524", "reg"),
               c("YEAR", "RISK", "AGE", "GENDER", "OTHER_IND", "AREA_CODE")) %>% 
  mutate(SERV_TYPE = "Employment") %>% 
  mutate(AREA_TYPE = "Region") %>% 
  select(YEAR, PERIOD, AREA_CODE, AREA_TYPE, AGE, GENDER, RISK, SERV_TYPE, SERV_IND, OTHER_IND, COUNT) 

df.sfy_edub_ta <- df.raw_sfy_edub_ta %>% 
  gather(COLNAMES, COUNT, -year, -riskgrp, -reg, -tla, -age_desc, -schter_1519, -x_gender_desc) %>% 
  left_join(df.sfy_mapping) %>% 
  filter(FLAG_KEEP_EDU == 1,
         FLAG_KEEP == 1) %>% 
  change_names(c("year", "riskgrp", "age_desc", "x_gender_desc", "schter_1519", "reg", "tla"),
               c("YEAR", "RISK", "AGE", "GENDER", "OTHER_IND", "REGION", "AREA_CODE")) %>% 
  mutate(SERV_TYPE = "Education") %>% 
  mutate(AREA_TYPE = "TA") %>% 
  # select(YEAR, PERIOD, AREA_CODE, AREA_TYPE, AGE, GENDER, RISK, SERV_TYPE, SERV_IND, OTHER_IND, COUNT) %>% 
  group_by(YEAR, PERIOD, AREA_CODE, AREA_TYPE, AGE, GENDER, RISK, SERV_TYPE, SERV_IND, OTHER_IND) %>% 
  summarise(COUNT = sum(COUNT, na.rm = TRUE))

df.sfy_empb_ta <- df.raw_sfy_empb_ta %>% 
  gather(COLNAMES, COUNT, -year, -riskgrp, -reg, -tla, -age_desc, -ben_1524, -x_gender_desc) %>% 
  left_join(df.sfy_mapping) %>% 
  filter(FLAG_KEEP_EMP == 1,
         FLAG_KEEP == 1) %>% 
  change_names(c("year", "riskgrp", "age_desc", "x_gender_desc", "ben_1524", "reg", "tla"),
               c("YEAR", "RISK", "AGE", "GENDER", "OTHER_IND", "REGION", "AREA_CODE")) %>% 
  mutate(SERV_TYPE = "Employment") %>%
  mutate(AREA_TYPE = "TA") %>% 
  # select(YEAR, PERIOD, AREA_CODE, AREA_TYPE, AGE, GENDER, RISK, SERV_TYPE, SERV_IND, OTHER_IND, COUNT) 
  group_by(YEAR, PERIOD, AREA_CODE, AREA_TYPE, AGE, GENDER, RISK, SERV_TYPE, SERV_IND, OTHER_IND) %>% 
  summarise(COUNT = sum(COUNT, na.rm = TRUE))

df.db_sfy_sp <- df.sfy_edub_region %>% 
  bind_rows(df.sfy_empb_region) %>% 
  bind_rows(df.sfy_edub_ta) %>% 
  bind_rows(df.sfy_empb_ta) %>% 
  #mutate(AGE = replace(AGE, AGE == "Jun-14", "06-14")) %>%
  left_join(df.sfy_mapping_region, by = c("AREA_TYPE" = "AREA_TYPE", "AREA_CODE" = "AREA_CODE")) %>% 
  mutate(AREA_CODE = ifelse(is.na(AREA_CODE), MOD, AREA_CODE)) %>% 
  select(-MOD) %>% 
  left_join(df.sfy_mapping_risk) %>% 
  mutate(OTHER_IND = plyr::mapvalues(OTHER_IND, c(1, 0), c("Yes", "No"))) %>% 
  mutate(AGE = plyr::mapvalues(AGE, c("06-14", "15-19", "20-24"), c("6-14 years", "15-19 years", "20-24 years"))) %>% 
  mutate(OTHER_TYPE = ifelse(SERV_TYPE == "Employment", "On Benefit?", "In education?")) %>% 
  mutate(PERIOD = paste("Last ", PERIOD, " year", ifelse(PERIOD > 1, "s", ""), sep = "")) %>% 
  filter(!is.na(RISK_DESC))
  #replace_na(list(RISK_DESC = "No Risk"))

#df.db_sfy_sp <- df.db_sfy_sp %>% 
#  filter(AGE == "6-14 years") %>% 
#  filter(RISK_DESC == "2+ Risk Indicators") %>% 
#  mutate(RISK_DESC = plyr::mapvalues(RISK_DESC, "2+ Risk Indicators", "In any of the above groups")) %>% 
#  mutate(RISK = plyr::mapvalues(RISK, 2, 6)) %>%
#  ## people between 6-14 years are not mutually exclusive 
#  # filter(RISK_DESC != "No Risk") %>% 
#  # group_by(YEAR, PERIOD, AREA_CODE, AREA_TYPE, AGE, GENDER, SERV_TYPE, SERV_IND, OTHER_IND, OTHER_TYPE) %>% 
#  # summarise(COUNT = sum(COUNT, na.rm = TRUE)) %>% 
#  # mutate(RISK_DESC = "In any of the above groups") %>% 
#  # mutate(RISK = 6) %>%
#  ungroup() %>%
#  unique() %>% 
#  bind_rows(df.db_sfy_sp) %>%
#  mutate(OTHER_TYPE = paste0("Subset to ", OTHER_TYPE))  %>%
#  mutate(SERV_IND = gsub("\\Services", "", x = SERV_IND))

df.db_sfy_sp <- df.db_sfy_sp %>% 
  filter(!(AGE == "6-14 years" & SERV_IND %in% c("Secondary Tertiary Programmes","Student Allowance","Gateway Programme","Industry Training","Youth Guarantee: Fees-Free","Alternative Education"))) %>% 
  filter(!(AGE == "15-19 years" & SERV_IND %in% c("Resource Teachers: Learning And Behaviour Services","Reading Recovery Services","Interim Response Fund Services"))) %>% 
  mutate(OTHER_TYPE = paste0("Subset to ", OTHER_TYPE))  %>%
  mutate(SERV_IND = gsub("\\Services", "", x = SERV_IND))

df.tmp_area_mapping <- df.snz_area_mapping %>% 
  select(REGC2016_label, TA2016_label, AU2016_label, WARD2016_label) %>% 
  unique() %>% 
  change_names(c("REGC2016_label", "TA2016_label", "AU2016_label", "WARD2016_label"),
               c("REGION", "TA", "AU", "WARD"))

df.db_area_mapping <- df.db_sfy_sp  %>% 
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

df.meta_area <- df.db_sfy_sp %>% 
  select(AREA_CODE, AREA_TYPE) %>% 
  unique()


df.sfy_mapping_risk = df.sfy_mapping_risk %>%
  mutate(AGE = plyr::mapvalues(AGE, c("06-14", "15-19", "20-24"), c("6-14 years", "15-19 years", "20-24 years")))

#### Section 03: Data Export ----
save(df.db_sfy, df.db_sfy_sp, df.db_area_mapping, df.sfy_mapping_risk,
     file = file.path(dir.data_db, "CYAR Dashboard Data - SFY.rda"))