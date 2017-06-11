#require(checkpoint)
#checkpoint("2017-03-10", R.version = "3.3.1",
           # checkpointLocation = "C:\\Users\\lceth\\Dropbox\\Working Space")
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
dir.data_raw_cyar <- "data/raw/CYAR"
dir.data_db <- "data"
dir.data_rollback <- "data/rollback"
dir.src <- "scripts"

### utility functions
source(file.path(dir.src, "utility functions.r"))

### data
df.raw_cyar_national <- read_csv(file.path(dir.data_raw_cyar, "/23-Mar-update/RT_national_table.csv"))

df.raw_cyar_0014 <- read_csv(file.path(dir.data_raw_cyar, "Table_0014.csv"))
df.raw_cyar_1524 <- read_csv(file.path(dir.data_raw_cyar, "Table_1524.csv"))
df.cyar_mapping_risk_base <- read_csv(file.path(dir.data_raw_cyar, "Risk Description - mapping base.csv"))
df.cyar_mapping_risk_area <- read_csv(file.path(dir.data_raw_cyar, "Risk Description - mapping area code.csv"))
#df.raw_cyar_region <- read_csv(file.path(dir.data_raw_cyar, "RT_REGION_final_2015.csv"))
#df.raw_cyar_ta <- read_csv(file.path(dir.data_raw_cyar, "RT_TA_final_2015.csv"))
#df.raw_cyar_au <- read_csv(file.path(dir.data_raw_cyar, "RT_AU_final_2015.csv"))

df.raw_cyar_region <- read_csv(file.path(dir.data_raw_cyar, "/3-Mar-sp-update/RT_REGION_final_3Mar2017.csv"))
df.raw_cyar_ta <- read_csv(file.path(dir.data_raw_cyar, "/3-Mar-sp-update/RT_TA_final_3Mar2017.csv"))
df.raw_cyar_au <- read_csv(file.path(dir.data_raw_cyar, "/3-Mar-sp-update/RT_AU_final_3Mar2017.csv"))

df.cyar_mapping_region <- read_csv(file.path(dir.data_raw, "Regional Mapping.csv"))


### data process ----
df.tmp_cyar_0014 <- df.raw_cyar_0014 %>% 
  change_names(c("Age group", "Risk group", "N"), c("AGE", "RISK", "POP")) %>% 
  gather(METRIC, VALUE, -AGE, -RISK, -POP) 
 
df.tmp_cyar_1524 <- df.raw_cyar_1524 %>% 
  change_names(c("Age group", "Risk group", "N"), c("AGE", "RISK", "POP")) %>% 
  gather(METRIC, VALUE, -AGE, -RISK, -POP) 

df.db_cyar <- df.tmp_cyar_0014 %>% 
  bind_rows(df.tmp_cyar_1524) %>%
  mutate(VALUE = gsub("\\$", "", VALUE)) %>% 
  mutate(VALUE = gsub(",", "", VALUE)) %>% 
  mutate(VALUE = as.numeric(VALUE)) %>% 
  mutate(IND_METRIC = ifelse(grepl("%", METRIC), "percent", "cost")) %>% 
  mutate(AGE = plyr::mapvalues(AGE, c("0 to 5", "6 to 14", "15 to 19", "20 to 24"), 
                               c("0-5 years", "6-14 years", "15-19 years", "20-24 years"))) %>% 
  left_join(df.cyar_mapping_risk_base)

df.db_cyar <- df.db_cyar %>% 
  filter(RISK_DESC == "2+ Risk Indicators") %>% 
  mutate(RISK_DESC = plyr::mapvalues(RISK_DESC, "2+ Risk Indicators", "In any target population risk group")) %>% 
  bind_rows(df.db_cyar) 

temp.db_cyar_POP_TOTAL <- df.db_cyar %>%
  filter(RISK_DESC %in% c("Fewer than 2 Risk Indicators", 
                          "2+ Risk Indicators",
                          "Not in a target population risk group",
                          "In any target population risk group")) %>%
  filter(!((AGE %in% c("0-5 years", "6-14 years")) & (RISK_DESC %in% "In any target population risk group"))) %>%
  group_by(AGE,METRIC) %>%
  summarise(POP_TOTAL = sum(POP))

df.db_cyar <- df.db_cyar %>% 
  left_join(temp.db_cyar_POP_TOTAL) %>%
  mutate(POP_PC = round(POP/POP_TOTAL*100,2))

#### data national consolidation ----
df.db_cyar_national <- df.raw_cyar_national %>% 
  gather(COLNAMES, COUNT, -all, -age_desc, -x_gender_desc, -eth, -year) %>% 
  left_join(df.cyar_mapping_risk_area, by=c("COLNAMES"="RISK", "age_desc"="AGE")) %>%
  change_names(c("year", "age_desc", "x_gender_desc", "all", "eth"),
               c("YEAR", "AGE", "GENDER", "TOTAL", "ETHNICITY")) %>%
  filter(!is.na(RISK_DESC)) %>%
  mutate(AGE = plyr::mapvalues(AGE, 
                               c("00-05", "06-14", "15-19", "20-24"), 
                               c("0-5 years", "6-14 years", "15-19 years", "20-24 years")))
  

df.db_cyar_national <- df.db_cyar_national %>% 
  filter(AGE %in% c("15-19 years", "20-24 years")) %>% 
  filter(RISK_DESC %in% "In any target population risk group") %>% 
  mutate(COUNT = TOTAL - COUNT) %>% 
  mutate(RISK_DESC = plyr::mapvalues(RISK_DESC, "In any target population risk group", "Not in a target population risk group")) %>%
  bind_rows(df.db_cyar_national) %>%
  mutate(PC = round(COUNT/TOTAL * 100, 2)) %>% 
  select(YEAR, AGE, GENDER, ETHNICITY, RISK_DESC, COUNT,PC)

#### regional table consolidation -----
df.cyar_reg <- df.raw_cyar_region %>% 
  gather(COLNAMES, COUNT, -all, -age_desc, -reg, -x_gender_desc, -year) %>% 
  left_join(df.cyar_mapping_risk_area, by=c("COLNAMES"="RISK", "age_desc"="AGE")) %>%
  change_names(c("age_desc", "x_gender_desc", "reg", 'year', "all"),
               c("AGE", "GENDER", "AREA_CODE", "YEAR", "TOTAL")) %>%
  mutate(AREA_TYPE = "Region") %>%
  filter(!is.na(RISK_DESC)) %>%
  select(YEAR, AREA_CODE, AREA_TYPE, AGE, GENDER, RISK_DESC, TOTAL, COUNT)

df.cyar_ta <- df.raw_cyar_ta %>% 
  gather(COLNAMES, COUNT, -all, -age_desc, -reg, -tla, -x_gender_desc, -year) %>% 
  left_join(df.cyar_mapping_risk_area, by=c("COLNAMES"="RISK", "age_desc"="AGE")) %>%
  change_names(c("age_desc", "x_gender_desc", "reg", "tla", 'year', "all"),
               c("AGE", "GENDER", "Region", "AREA_CODE", "YEAR","TOTAL")) %>%
  mutate(AREA_TYPE = "TA") %>%
  filter(!is.na(RISK_DESC)) %>%
  select(YEAR, AREA_CODE, AREA_TYPE, AGE, GENDER, RISK_DESC, TOTAL, COUNT)

df.cyar_au <- df.raw_cyar_au %>% 
  gather(COLNAMES, COUNT, -all, -age_desc, -reg, -tla, -au, -x_gender_desc, -year) %>% 
  left_join(df.cyar_mapping_risk_area, by=c("COLNAMES"="RISK", "age_desc"="AGE")) %>%
  change_names(c("age_desc", "x_gender_desc", "reg", "tla", "au", 'year', "all"),
               c("AGE", "GENDER", "Region", "TA", "AREA_CODE", "YEAR", "TOTAL")) %>%
  mutate(AREA_TYPE = "AU") %>%
  filter(!is.na(RISK_DESC)) %>%
  select(YEAR, AREA_CODE, AREA_TYPE, AGE, GENDER, RISK_DESC, TOTAL, COUNT)

df.db_cyar_sp <- df.cyar_reg %>%
  bind_rows(df.cyar_ta) %>%
  bind_rows(df.cyar_au) %>%
  left_join(df.cyar_mapping_region, by = c("AREA_TYPE" = "AREA_TYPE", "AREA_CODE" = "AREA_CODE")) %>%
  mutate(AREA_CODE = ifelse(is.na(AREA_CODE), MOD, AREA_CODE)) %>%
  select(-MOD) %>%
  filter(!is.na(RISK_DESC)) %>%
  mutate(AGE = plyr::mapvalues(AGE, c("00-05", "06-14", "15-19", "20-24"), c("0-5 years", "6-14 years", "15-19 years", "20-24 years"))) 

df.db_cyar_sp <- df.db_cyar_sp %>% 
  filter(RISK_DESC == "2+ Risk Indicators") %>% 
  mutate(RISK_DESC = plyr::mapvalues(RISK_DESC, "2+ Risk Indicators", "In any target population risk group")) %>% 
  bind_rows(df.db_cyar_sp) %>%
  group_by(YEAR, AREA_CODE, AREA_TYPE, AGE, GENDER, RISK_DESC) %>%
  summarise(COUNT = sum(COUNT), TOTAL = sum(TOTAL)) %>%
  select(YEAR, AREA_CODE, AREA_TYPE, AGE, GENDER, RISK_DESC, TOTAL, COUNT)

df.db_cyar_sp <- df.db_cyar_sp %>% 
  filter(AGE %in% c("15-19 years", "20-24 years")) %>% 
  filter(RISK_DESC %in% "In any target population risk group") %>% 
  mutate(COUNT = TOTAL - COUNT) %>% 
  mutate(RISK_DESC = plyr::mapvalues(RISK_DESC, "In any target population risk group", "Not in a target population risk group")) %>%
  bind_rows(df.db_cyar_sp)

#### Section 03: Data Export ----
save(df.db_cyar, df.db_cyar_sp, df.db_cyar_national,
     file = file.path(dir.data_db,  "CYAR Dashboard Data - CYAR.rda"))


