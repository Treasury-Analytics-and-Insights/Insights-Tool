vt.cyar_col_dark <- df.treasury_color %>%
  filter(colour %in% "blue2") %>%
  filter(degree %in% 3) %>%
  .[["code"]]

vt.cyar_col_mile <- df.treasury_color %>%
  filter(colour %in% "blue4") %>%
  filter(degree %in% 3) %>%
  .[["code"]]


vt.cyar_col_light <- df.treasury_color %>%
  filter(colour %in% "blue4") %>%
  filter(degree %in% 2) %>%
  .[["code"]]

vt.cyar_col_lighter <- df.treasury_color %>%
  filter(colour %in% "blue4") %>%
  filter(degree %in% 1) %>%
  .[["code"]]

# vt.cyar_col_light <- "#CAC9E0"
# vt.cyar_col_light <- "#525990"
# vt.cyar_col_light <- "#9DA2C7"
# vt.cyar_col_mile <- "#525990"
# vt.cyar_col_dark <- "#303251"
vt.cyar_col_white <- "#ffffff"

vt.cyar_rf_readme_cond <- "input.cyar_param_age == '0-5 years' | input.cyar_param_age == '6-14 years"

df.db_cyar <- df.db_cyar %>% 
  filter(!((RISK_DESC == "In any target population risk group") & (AGE %in% c("0-5 years", "6-14 years"))))

df.db_cyar_national <- df.db_cyar_national %>% 
  filter(!((RISK_DESC == "In any target population risk group") & (AGE %in% c("0-5 years", "6-14 years"))))

df.db_cyar_sp <- df.db_cyar_sp %>% 
  filter(!((RISK_DESC == "In any target population risk group") & (AGE %in% c("0-5 years", "6-14 years"))))

vt.init_cyar_param_age_select <- unique(df.db_cyar$AGE)
vt.init_cyar_param_age <- vt.init_cyar_param_age_select[1]

vt.init_cyar_param_year_select <- unique(df.db_cyar_national$YEAR)
vt.init_cyar_param_year <- 2015

vt.init_cyar_param_risk_ind_select <- df.db_cyar %>% 
  filter(AGE %in% vt.init_cyar_param_age) %>% 
  .[["RISK_DESC"]] %>% 
  unique()

vt.init_cyar_param_risk_ind <- vt.init_cyar_param_risk_ind_select[2]

df.init_cyar_base_data <- df.db_cyar %>% 
  filter(AGE %in% vt.init_cyar_param_age)

df.init_cyar_national_base_data <- df.db_cyar_national %>% 
  filter(AGE %in% vt.init_cyar_param_age) %>%
  filter(YEAR %in% vt.init_cyar_param_year)

df.init_cyar_filtered_data <- df.init_cyar_base_data %>% 
  filter(RISK_DESC %in% vt.init_cyar_param_risk_ind)

df.init_cyar_national_filtered_data <- df.init_cyar_national_base_data %>% 
  filter(RISK_DESC %in% vt.init_cyar_param_risk_ind)

vt.init_cyar_param_sd_loc <- TRUE
vt.init_cyar_param_gender_select <- unique(df.db_cyar_sp$GENDER)
vt.init_cyar_param_gender <- vt.init_cyar_param_gender_select[1]
vt.init_cyar_param_zoom_ind <- "Region"

df.init_cyar_map_data <- df.db_cyar_sp %>% 
  filter(AGE %in% vt.init_cyar_param_age) %>%
  filter(YEAR %in% vt.init_cyar_param_year)

df.init_cyar_map_filtered_data <- df.init_cyar_map_data %>% 
  filter(RISK_DESC %in% vt.init_cyar_param_risk_ind)

df.tmp_cyar_map_sp_attr <- df.init_cyar_map_filtered_data %>% 
  filter(AREA_TYPE %in% "Region") %>% 
  filter(GENDER %in% vt.init_cyar_param_gender) %>% 
  mutate(PC = round(COUNT/TOTAL * 100, 2)) %>% 
  mutate(FLAG_SD = vt.init_cyar_param_sd_loc) %>% 
  mutate(COL_VAR = ifelse(FLAG_SD, PC, COUNT))

spldf.init_cyar_map <- spldf.nz_region
spldf.init_cyar_map@data <- spldf.nz_region@data %>%
  left_join(df.tmp_cyar_map_sp_attr)

spldf.cyar_map_ov <- spldf.nz_region

