vt.sfy_col_white <- "#ffffff"

vt.sfy_col_orange_light <- df.treasury_color %>%
  filter(colour == "orange1", degree == 2) %>%
  .[['code']]

vt.sfy_col_orange <- df.treasury_color %>%
  filter(colour == "orange1", degree == 3) %>%
  .[['code']]

vt.sfy_col_blue_light <- df.treasury_color %>%
  filter(colour == "blue4", degree == 2) %>%
  .[['code']]

vt.sfy_col_blue <- df.treasury_color %>%
  filter(colour == "blue4", degree == 3) %>%
  .[['code']]

vt.sfy_col_blue_dark <- df.treasury_color %>%
  filter(colour == "blue3", degree == 3) %>%
  .[['code']]

vt.sfy_col_blue_lightest <- df.treasury_color %>%
  filter(colour == "blue3", degree == 1) %>%
  .[['code']]

vt.sfy_risk_verbs = c("Not in a target population risk group", 
                      "Any target population", 
                      "Teenage boys with Youth Justice or Corrections history",
                      "Mental health service users with stand-down or CYF history",
                      "Young offenders with community sentence and CYF history",
                      "Young offenders with custodial sentence",
                      "Teenage girls supported by benefits",
                      "Teenagers with health, disability issues or special needs",
                      "Sole parents not in full-time employment with CYF history",
                      "Long-term disability beneficiaries",
                      "Jobseekers in poor health with CYF history"
                      )

df.db_sfy <- df.db_sfy %>%
  mutate(SERV_IND = replace(SERV_IND, SERV_IND == "Secondary Tertiary Programmes", "Secondary-Tertiary Programme")) %>% 
  mutate(OTHER_IND = replace(OTHER_IND, AGE == "6-14 years", "Yes")) %>%
  filter(GENDER == "All") %>% 
  # filter(RISK_DESC != "No Risk") %>% 
  mutate(RISK_DESC = ifelse(RISK_DESC == "In any of the above groups", "All", RISK_DESC)) %>% 
  mutate(METRIC_TYPE = ifelse(SERV_IND == "Total", "People", "Service")) %>%
  mutate(SERV_IND = replace(SERV_IND, SERV_IND == "Secondary Tertiary Programmes", "Secondary-Tertiary Programme"))

df.db_sfy_sp <- df.db_sfy_sp %>%
  mutate(SERV_IND = replace(SERV_IND, SERV_IND == "Secondary Tertiary Programmes", "Secondary-Tertiary Programme")) %>%
  mutate(OTHER_IND = replace(OTHER_IND, AGE == "6-14 years", "Yes")) %>%
  filter(GENDER == "All") %>% 
  mutate(RISK_DESC = ifelse(RISK_DESC == "In any of the above groups", "All", RISK_DESC)) %>% 
  mutate(METRIC_TYPE = ifelse(SERV_IND == "Total", "People", "Service"))
  

vt.init_sfy_param_year_select <- unique(df.db_sfy$YEAR)
vt.init_sfy_param_year <- 2015

vt.init_sfy_param_serv_type_select <- df.db_sfy %>% 
  filter(YEAR %in% vt.init_sfy_param_year) %>% 
  .[["SERV_TYPE"]] %>% 
  unique()

vt.init_sfy_param_serv_type <- vt.init_sfy_param_serv_type_select[1]

vt.init_sfy_param_age_select <- df.db_sfy %>% 
  filter(SERV_TYPE %in% vt.init_sfy_param_serv_type) %>% 
  .[["AGE"]] %>% 
  unique()

vt.init_sfy_param_age <- vt.init_sfy_param_age_select[1]

vt.init_sfy_param_other_ind_select <- df.db_sfy %>% 
  filter(SERV_TYPE %in% vt.init_sfy_param_serv_type) %>% 
  filter(AGE %in% vt.init_sfy_param_age) %>% 
  .[["OTHER_IND"]] %>% 
  unique()

vt.init_sfy_param_other_ind <- vt.init_sfy_param_other_ind_select[1]

vt.init_sfy_param_other_ind_title <- df.db_sfy %>% 
  filter(SERV_TYPE %in% vt.init_sfy_param_serv_type) %>% 
  filter(AGE %in% vt.init_sfy_param_age) %>% 
  filter(OTHER_IND %in% vt.init_sfy_param_other_ind) %>% 
  .[["OTHER_TYPE"]] %>% 
  unique()

vt.init_sfy_param_period_select <- df.db_sfy %>% 
  filter(SERV_TYPE %in% vt.init_sfy_param_serv_type) %>% 
  filter(AGE %in% vt.init_sfy_param_age) %>% 
  filter(OTHER_IND %in% vt.init_sfy_param_other_ind) %>% 
  .[["PERIOD"]] %>% 
  unique()

# vt.init_sfy_param_period <- vt.init_sfy_param_period_select[1]
vt.init_sfy_param_period <- vt.init_sfy_param_period_select[2]

vt.init_sfy_param_switch_risk_serv_list <- c("% of risk group using the service", "% of services users in risk group")

vt.init_sfy_param_switch_risk_serv <- vt.init_sfy_param_switch_risk_serv_list[2]


df.init_sfy_base_data <- df.db_sfy %>% 
  filter(YEAR == vt.init_sfy_param_year) %>% 
  filter(SERV_TYPE == vt.init_sfy_param_serv_type) %>% 
  filter(AGE == vt.init_sfy_param_age) %>% 
  filter(OTHER_IND == vt.init_sfy_param_other_ind) %>% 
  filter(PERIOD == vt.init_sfy_param_period)

### pre select service indicators and risk indicators ----
vt.init_sfy_param_serv_ind <- df.init_sfy_base_data %>%
  arrange(desc(COUNT)) %>%
  .[["SERV_IND"]] %>%
  unique() %>%
  .[2]

vt.init_sfy_param_risk_ind <- df.init_sfy_base_data %>% 
  arrange(desc(COUNT)) %>%
  .[["RISK_DESC"]] %>% 
  unique() %>%
  .[2]

###pre select service indicators and risk indicators END####

vt.init_sfy_hl_data01 <- df.init_sfy_base_data %>% 
  filter(METRIC_TYPE == "People") %>% 
  filter(RISK_DESC == "All") %>%
  .[["COUNT"]] %>% 
  unique()

vt.init_sfy_hl_data02 <- df.init_sfy_base_data %>% 
  filter(METRIC_TYPE %in% "Service") %>% 
  summarise(COUNT = sum(COUNT, na.rm = TRUE)) %>% 
  .[["COUNT"]]

vt.init_sfy_hl_data03 <- df.init_sfy_base_data %>%
  filter(METRIC_TYPE == "Service") %>% 
  filter(RISK_DESC == "All") %>%  
  mutate(TOTAL = vt.init_sfy_hl_data01) %>% 
  mutate(PC = COUNT/vt.init_sfy_hl_data01) %>% 
  summarise(PC = round(mean(PC, na.rm = TRUE) * 100, 2))

vt.init_sfy_hl_data05 <- df.init_sfy_base_data %>% 
  filter(SERV_IND %in% vt.init_sfy_param_serv_ind) %>% 
  filter(RISK_DESC %in% vt.init_sfy_param_risk_ind) %>% 
  .[["COUNT"]]

### mapping data
df.tmp_sfy_map <- df.db_sfy_sp %>% 
  filter(YEAR == vt.init_sfy_param_year) %>% 
  filter(SERV_TYPE == vt.init_sfy_param_serv_type) %>% 
  filter(AGE == vt.init_sfy_param_age) %>% 
  filter(OTHER_IND == vt.init_sfy_param_other_ind) %>% 
  filter(PERIOD == vt.init_sfy_param_period) %>% 
  select(AREA_CODE, AREA_TYPE, GENDER, SERV_IND, RISK_DESC, METRIC_TYPE, COUNT)

#   filter(GENDER %in% "All") %>%
  # filter(RISK_DESC %in% vt.init_sfy_param_risk_ind) %>%
  # filter(SERV_IND %in% vt.init_sfy_param_serv_ind) %>%
  # filter(AREA_TYPE %in% "Region")

##############################################################################################################
vt.risk_grps = df.sfy_mapping_risk %>%
  filter(AGE == vt.init_sfy_param_age, TOTAL_COLUMN) %>%
  .[["RISK_DESC"]]


df.tmp_sfy_map_total_people <- df.tmp_sfy_map %>% 
  filter(SERV_IND %in% "Total") %>% 
  group_by(AREA_CODE, AREA_TYPE, GENDER, RISK_DESC) %>%
  summarise(TOTAL_RISK = sum(COUNT))

df.tmp_sfy_map_total_serv <- df.tmp_sfy_map %>% 
  filter(RISK_DESC %in% vt.risk_grps) %>% 
  group_by(AREA_CODE, AREA_TYPE, GENDER, SERV_IND) %>%
  summarise(TOTAL_SERV = sum(COUNT))

df.init_sfy_map_data <- df.tmp_sfy_map %>% 
  left_join(df.tmp_sfy_map_total_serv, by = c("AREA_CODE", "AREA_TYPE", "GENDER", "SERV_IND")) %>% 
  left_join(df.tmp_sfy_map_total_people, by = c("AREA_CODE", "AREA_TYPE", "GENDER", "RISK_DESC")) %>% 
  mutate(PC_RISK = ifelse(TOTAL_RISK == 0, 0, 100*COUNT/TOTAL_RISK)) %>%
  mutate(PC_SERV = ifelse(TOTAL_SERV == 0, 0, 100*COUNT/TOTAL_SERV))

if(vt.init_sfy_param_switch_risk_serv %in% "% of services users in risk group") {
  df.init_sfy_map_data <- df.init_sfy_map_data %>%
    mutate(COL_VAR  = PC_SERV)
} else {
  df.init_sfy_map_data <- df.init_sfy_map_data %>%
    mutate(COL_VAR  = PC_RISK)
}

#############################################################################################################

df.tmp_sfy_map_sp_attr <- df.init_sfy_map_data %>%
  filter(GENDER %in% "All") %>%
  filter(RISK_DESC %in% vt.init_sfy_param_risk_ind) %>%
  filter(SERV_IND %in% vt.init_sfy_param_serv_ind) %>%
  filter(AREA_TYPE %in% "Region") %>%
  group_by(AREA_CODE) %>%
  summarise(COL_VAR = sum(COL_VAR, na.rm = TRUE))

spldf.init_sfy_map <- spldf.nz_region
spldf.init_sfy_map@data <- spldf.nz_region@data %>%
  left_join(df.tmp_sfy_map_sp_attr)

vt.init_sfy_param_zoom_ind <- "Region"
vt.init_sfy_param_shape_id <- unique(spldf.init_sfy_map@data$AREA_CODE)

spldf.sfy_map_ov <- spldf.nz_region