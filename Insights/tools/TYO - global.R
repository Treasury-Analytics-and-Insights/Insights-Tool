#=====================================================================#
# About this programme
# Programme: "TYO - global.R"
# Objective: global values and initial values for TYO panel
#
# Key components:
#          1.vt.tyo_col_*
#          2.vt.init_tyo_*
#          3.df.init_tyo_base_data
#          4.df.init_tyo_filtered_data
#          5.df.init_tyo_map_data
#          6.df.init_tyo_map_filtered_data
#          7.spldf.init_tyo_map
#          8.spldf.tyo_map_ov
#
# Author: Danny Wu Created on 15/03/2017
# ====================================================================#

### help funtion ----
x_percent <- function(x){
  return(percent(x/100))
}

### color options ----
vt.tyo_col_white <- "#ffffff"

vt.tyo_col_blue_d1 <- df.treasury_color %>%
  filter(colour == "blue4", degree == 1) %>%
  .[['code']]

vt.tyo_col_blue_d2 <- df.treasury_color %>%
  filter(colour == "blue4", degree == 2) %>%
  .[['code']]

vt.tyo_col_blue_d3 <- df.treasury_color %>%
  filter(colour == "blue4", degree == 3) %>%
  .[['code']]

vt.tyo_col_blue2_d3 <- df.treasury_color %>%
  filter(colour == "blue3", degree == 3) %>%
  .[['code']]

vt.tyo_col_green_d1 <- df.treasury_color %>%
  filter(colour == "green1", degree == 1) %>%
  .[['code']]

vt.tyo_col_green_d2 <- df.treasury_color %>%
  filter(colour == "green1", degree == 2) %>%
  .[['code']]

vt.tyo_col_green_d3 <- df.treasury_color %>%
  filter(colour == "green1", degree == 3) %>%
  .[['code']]

vt.tyo_col_orange_d1 <- df.treasury_color %>%
  filter(colour == "orange1", degree == 1) %>%
  .[['code']]

vt.tyo_col_orange_d2 <- df.treasury_color %>%
  filter(colour == "orange1", degree == 2) %>%
  .[['code']]

vt.tyo_col_orange_d3 <- df.treasury_color %>%
  filter(colour == "orange1", degree == 3) %>%
  .[['code']]

vt.tyo_col_red_d3 <- df.treasury_color %>%
  filter(colour == "red2", degree == 3) %>%
  .[['code']]

###  analysis panel initial value and list ----
vt.init_tyo_param_gender <- "All"

vt.init_tyo_param_map_metric <- TRUE

vt.init_tyo_param_year_select <- unique(df.db_tyo$YEAR)
vt.init_tyo_param_year <- 2015

vt.init_tyo_param_an_risk_list <- df.db_tyo %>% 
  filter(GENDER %in% vt.init_tyo_param_gender) %>% 
  filter(YEAR %in% vt.init_tyo_param_year) %>% 
  .[["RISK_FACTOR"]] %>% 
  unique()

vt.init_tyo_param_an_risk <- vt.init_tyo_param_an_risk_list[1]

vt.init_tyo_param_gender_list <- df.db_tyo %>% 
  filter(RISK_FACTOR %in% vt.init_tyo_param_an_risk) %>% 
  filter(YEAR %in% vt.init_tyo_param_year) %>% 
  .[["GENDER"]] %>% 
  unique()

vt.init_tyo_param_eth_list <- df.db_tyo %>% 
  filter(RISK_FACTOR %in% vt.init_tyo_param_an_risk) %>% 
  filter(YEAR %in% vt.init_tyo_param_year) %>% 
  filter(GENDER %in% vt.init_tyo_param_gender) %>% 
  .[["ETHNICITY"]] %>%
  unique()

vt.init_tyo_param_eth <- vt.init_tyo_param_eth_list[1]

### map panel initial value and list ----
vt.init_tyo_param_map_age_group_list <- df.db_tyo_sp %>%
  filter(GENDER %in% vt.init_tyo_param_gender) %>%
  filter(YEAR %in% vt.init_tyo_param_year) %>%
  .[["AGE"]] %>%
  unique()

vt.init_tyo_param_map_age_group <- vt.init_tyo_param_map_age_group_list[1]

vt.init_tyo_param_map_risk_list <- df.db_tyo_sp %>%
  filter(GENDER %in% vt.init_tyo_param_gender) %>%
  filter(YEAR %in% vt.init_tyo_param_year) %>%
  filter(AGE %in% vt.init_tyo_param_map_age_group) %>%
  .[["RISK_FACTOR"]] %>%
  unique()

vt.init_tyo_param_map_risk <- vt.init_tyo_param_map_risk_list[3]

vt.init_tyo_param_map_trac_ind_list <- df.db_tyo_sp %>%
  filter(GENDER %in% vt.init_tyo_param_gender) %>%
  filter(YEAR %in% vt.init_tyo_param_year) %>%
  filter(AGE %in% vt.init_tyo_param_map_age_group) %>%
  filter(RISK_FACTOR %in% vt.init_tyo_param_map_risk) %>%
  .[["TRAC_IND"]] %>%
  unique()

vt.init_tyo_param_map_trac_ind <- vt.init_tyo_param_map_trac_ind_list[2]


#################################################################################################
### initial data ----
# df.init_tyo_base_data <- df.db_tyo %>% 
#   filter(YEAR %in% vt.init_tyo_param_year)
# 
# df.init_tyo_filtered_data <- df.init_tyo_base_data %>% 
#   filter(RISK_FACTOR %in% vt.init_tyo_param_an_risk)

vt.init_tyo_param_zoom_ind <- "Region"

df.init_tyo_map_data <- df.db_tyo_sp %>% 
  filter(YEAR %in% vt.init_tyo_param_year)

df.init_tyo_map_filtered_data <- df.init_tyo_map_data 

df.tmp_tyo_map_sp_attr <- df.init_tyo_map_filtered_data %>%
  filter(AGE %in% vt.init_tyo_param_map_age_group) %>%
  filter(AREA_TYPE %in% vt.init_tyo_param_zoom_ind) %>%
  filter(RISK_FACTOR %in% vt.init_tyo_param_map_risk) %>%
  filter(TRAC_IND %in% vt.init_tyo_param_map_trac_ind) %>%
  mutate(FLAG_SD = vt.init_tyo_param_map_metric) %>%
  mutate(COL_VAR = ifelse(FLAG_SD, PERCENT, PEOPLE))

df.init_bubble_chart_data <- df.tmp_tyo_map_sp_attr %>% 
  filter(GENDER != "All")

df.tmp_tyo_map_sp_attr <- df.tmp_tyo_map_sp_attr %>%
  filter(GENDER %in% vt.init_tyo_param_gender)

spldf.init_tyo_map <- spldf.nz_region
spldf.init_tyo_map@data <- spldf.nz_region@data %>%
  left_join(df.tmp_tyo_map_sp_attr)

spldf.tyo_map_ov <- spldf.nz_region

