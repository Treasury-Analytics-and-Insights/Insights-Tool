#### Section 01: Setup ----
### libraries control
require(checkpoint)
checkpoint("2017-03-10", R.version = "3.3.1",
           checkpointLocation = "D:/R")

### libraries
## data managements
require(sp)
require(tidyverse)
require(lubridate)
require(stringr)
require(readr)

# environmental control
rm(list = ls()); gc()

### directories
dir.data_raw <- "data/raw"
dir.data_raw_tyo <- "data/raw/TYO"
dir.data_db <- "data"
dir.data_rollback <- "data/rollback"
dir.src <- "scripts"

### utility functions
source(file.path(dir.src, "utility functions.r"))

### data
df.raw_tyo_mapping <- read_csv(file.path(dir.data_raw_tyo, "TYO - mapping.csv"))
df.raw_tyo_map_mapping <- read_csv(file.path(dir.data_raw_tyo, "TYO - map - mapping.csv"))
df.raw_tyo_col_mapping <- read_csv(file.path(dir.data_raw_tyo, "TYO - col_mapping.csv"))

df.raw_tyo_age <- read_csv(file.path(dir.data_raw_tyo, "/23-Mar-update/YT_age.csv"))
df.raw_tyo_risk2_age <- read_csv(file.path(dir.data_raw_tyo, "/23-Mar-update/YT_risk2_age.csv"))
df.raw_tyo_risk3_age <- read_csv(file.path(dir.data_raw_tyo, "/23-Mar-update/YT_risk3_age.csv"))
# df.raw_tyo_reg_risk2_age <- read_csv(file.path(dir.data_raw_tyo, "YT_reg_risk2_age.csv"))
# df.raw_tyo_reg_risk3_age <- read_csv(file.path(dir.data_raw_tyo, "YT_reg_risk3_age.csv"))

df.raw_tyo_reg <- read_csv(file.path(dir.data_raw_tyo, "/23-Mar-update/YT_REGION_final_2015.csv"))
df.raw_tyo_ta <- read_csv(file.path(dir.data_raw_tyo, "/23-Mar-update/YT_TA_final_2015.csv"))
df.raw_tyo_au <- read_csv(file.path(dir.data_raw_tyo, "/23-Mar-update/YT_AU_final_2015.csv"))

df.tyo_mapping_region <- read_csv(file.path(dir.data_raw, "Regional Mapping.csv"))

# df.snz_area_mapping <- read_csv(file.path(dir.data_raw, "2016_Areas_Table.txt"))

### data processing
df.tyo_mapping <- df.raw_tyo_mapping %>%
  change_names(c("variable", "Shortened"),
               c("COLNAMES", "TRAC_IND")) %>% 
  left_join(df.raw_tyo_col_mapping) %>%
  filter(FAG_KEEP == 1) %>%
  select(COLNAMES, TRAC_IND)

df.tyo_age <- df.raw_tyo_age %>% 
  # mutate_each(funs(./denom_adj*100), contains("pp_")) %>%
  mutate_each(funs(.*100), contains("pp")) %>%
  gather(COLNAMES, COUNT, -year, -age, -x_gender_desc,-eth) %>% 
  left_join(df.tyo_mapping) %>% 
  change_names(c("year", "age", "x_gender_desc", "eth"),
               c("YEAR", "AGE", "GENDER", "ETHNICITY")) %>%
  mutate(RISK_FACTOR = "Overall") %>%
  filter(!is.na(TRAC_IND)) %>%
  #mutate(COUNT = signif(COUNT, 2)) %>%
  select(YEAR, AGE, GENDER, ETHNICITY, RISK_FACTOR, TRAC_IND, COUNT)

df.tyo_age_2p <- df.raw_tyo_risk2_age %>% 
  # mutate_each(funs(./denom_adj*100), contains("pp_")) %>%
  mutate_each(funs(.*100), contains("pp")) %>%
  gather(COLNAMES, COUNT, -year, -age, -x_gender_desc, -risk_factors_2plus_by15, -eth) %>% 
  left_join(df.tyo_mapping) %>% 
  change_names(c("year", "age", "x_gender_desc", "eth"),
               c("YEAR", "AGE", "GENDER", "ETHNICITY")) %>%
  mutate(RISK_FACTOR = ifelse(risk_factors_2plus_by15 == 1, "2+ Risk Indicators", "<2 Risk Indicators")) %>%
  filter(!is.na(TRAC_IND)) %>%
  #mutate(COUNT = signif(COUNT, 2)) %>%
  select(YEAR, AGE, GENDER, ETHNICITY, RISK_FACTOR, TRAC_IND, COUNT)

df.tyo_age_3p <- df.raw_tyo_risk3_age %>% 
  # mutate_each(funs(./denom_adj*100), contains("pp_")) %>%
  mutate_each(funs(.*100), contains("pp")) %>%
  gather(COLNAMES, COUNT, -year, -age, -x_gender_desc, -risk_factors_3plus_by15, -eth) %>% 
  left_join(df.tyo_mapping) %>% 
  change_names(c("year", "age", "x_gender_desc", "eth"),
               c("YEAR", "AGE", "GENDER", "ETHNICITY")) %>%
  filter(risk_factors_3plus_by15 == 1) %>%
  mutate(RISK_FACTOR = "3+ Risk Indicators") %>%
  filter(!is.na(TRAC_IND)) %>%
  #mutate(COUNT = signif(COUNT, 2)) %>%
  select(YEAR, AGE, GENDER, ETHNICITY, RISK_FACTOR, TRAC_IND, COUNT)

df.db_tyo <- df.tyo_age %>%
  bind_rows(df.tyo_age_2p) %>% 
  bind_rows(df.tyo_age_3p)


### regional table consolidation
df.tyo_map_mapping <- df.raw_tyo_map_mapping %>%
  change_names(c("variable"),
               c("COLNAMES")) %>% 
  filter(TRAC_IND != "NONE") %>%
  select(COLNAMES, TRAC_IND)

df.tyo_reg <- df.raw_tyo_reg %>% 
  mutate(pp_neet = pp_lt6_neet + pp_st6_neet) %>%
  gather(COLNAMES, COUNT, -year, -risk_factors_2plus_by15, -reg, -age_desc, -x_gender_desc, -denom_adj) %>% 
  left_join(df.tyo_map_mapping) %>%
  change_names(c("year", "age_desc", "x_gender_desc", "reg"),
               c("YEAR", "AGE", "GENDER", "AREA_CODE")) %>%
  mutate(RISK_FACTOR = ifelse(risk_factors_2plus_by15 == 1, "2+ Risk Indicators", "<2 Risk Indicators")) %>%
  mutate(AREA_TYPE = "Region") %>%
  filter(!is.na(TRAC_IND)) %>%
  group_by(YEAR, AREA_CODE, AREA_TYPE, AGE, GENDER, RISK_FACTOR, TRAC_IND) %>%
  summarise(COUNT = sum(COUNT), TOTAL = sum(denom_adj), PERCENT = 100*sum(COUNT)/sum(denom_adj)) %>%
  mutate(PEOPLE = COUNT/12) %>%
  select(YEAR, AREA_CODE, AREA_TYPE, AGE, GENDER, RISK_FACTOR, TRAC_IND, COUNT, PERCENT, PEOPLE, TOTAL)

df.tyo_ta <- df.raw_tyo_ta %>%
  mutate(pp_neet = pp_lt6_neet + pp_st6_neet) %>%
  gather(COLNAMES, COUNT, -year, -risk_factors_2plus_by15, -reg, -tla, -age_desc, -x_gender_desc, -denom_adj) %>%
  left_join(df.tyo_map_mapping) %>%
  change_names(c("year", "age_desc", "x_gender_desc", "reg", "tla"),
               c("YEAR", "AGE", "GENDER", "REGION", "AREA_CODE")) %>%
  mutate(RISK_FACTOR = ifelse(risk_factors_2plus_by15 == 1, "2+ Risk Indicators", "<2 Risk Indicators")) %>%
  mutate(AREA_TYPE = "TA") %>%
  filter(!is.na(TRAC_IND)) %>%
  group_by(YEAR, AREA_CODE, AREA_TYPE, AGE, GENDER, RISK_FACTOR, TRAC_IND) %>%
  summarise(COUNT = sum(COUNT), TOTAL = sum(denom_adj), PERCENT = 100*sum(COUNT)/sum(denom_adj)) %>%
  mutate(PEOPLE = COUNT/12) %>%
  select(YEAR, AREA_CODE, AREA_TYPE, AGE, GENDER, RISK_FACTOR, TRAC_IND, COUNT, PERCENT, PEOPLE, TOTAL)

df.tyo_au = df.raw_tyo_au %>%
  mutate(pp_neet = pp_lt6_neet + pp_st6_neet) %>%
  gather(COLNAMES, COUNT, -year, -risk_factors_2plus_by15, -reg, -tla, -au, -age_desc, -x_gender_desc, -denom_adj) %>%
  left_join(df.tyo_map_mapping) %>%
  change_names(c("year", "age_desc", "x_gender_desc", "reg", "tla", "au"),
               c("YEAR", "AGE", "GENDER", "REGION", "TA", "AREA_CODE")) %>%
  mutate(RISK_FACTOR = ifelse(risk_factors_2plus_by15 == 1, "2+ Risk Indicators", "<2 Risk Indicators")) %>%
  mutate(AREA_TYPE = "AU") %>%
  filter(!is.na(TRAC_IND)) %>%
  group_by(YEAR, AREA_CODE, AREA_TYPE, AGE, GENDER, RISK_FACTOR, TRAC_IND) %>%
  summarise(COUNT = sum(COUNT), TOTAL = sum(denom_adj), PERCENT = 100*sum(COUNT)/sum(denom_adj)) %>%
  mutate(PEOPLE = COUNT/12) %>%
  select(YEAR, AREA_CODE, AREA_TYPE, AGE, GENDER, RISK_FACTOR, TRAC_IND, COUNT, PERCENT, PEOPLE, TOTAL)

df.db_tyo_sp <- df.tyo_reg %>%
  bind_rows(df.tyo_ta) %>%
  bind_rows(df.tyo_au) %>%
  ungroup() %>%
  left_join(df.tyo_mapping_region, by = c("AREA_TYPE" = "AREA_TYPE", "AREA_CODE" = "AREA_CODE")) %>%
  mutate(AREA_CODE = ifelse(is.na(AREA_CODE), MOD, AREA_CODE)) %>%
  select(-MOD) %>%
  mutate(AGE = plyr::mapvalues(AGE, c("15-19", "20-24"), c("15-19 years", "20-24 years")))

df.db_tyo_sp_risk_all <- df.db_tyo_sp %>%
  group_by(YEAR, AREA_CODE, AREA_TYPE, GENDER, AGE, TRAC_IND ) %>%
  summarise(COUNT=sum(COUNT), PERCENT=100*sum(COUNT)/sum(TOTAL), PEOPLE=sum(PEOPLE)) %>%
  mutate(RISK_FACTOR="All")

df.db_tyo_sp <- df.db_tyo_sp %>%
  bind_rows(df.db_tyo_sp_risk_all) %>%
  mutate(PEOPLE = ifelse(round(PEOPLE, 0)<6, 0, round(PEOPLE, 0)))

  
#### Section 03: Data Export ----
save(df.db_tyo, df.db_tyo_sp, file = file.path(dir.data_db, "CYAR Dashboard Data - TYO.rda"))

