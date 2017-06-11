#=====================================================================#
# About this programme
# Programme: "SFY - server - master control.R"
# Objective: Server script for updating master control widgets in SFY panel
#
# Key data:
#          1.input$sfy_param_serv_type
#          2.input$sfy_param_age
#          2.input$sfy_param_other_ind
#          2.input$sfy_param_period
#
# Author: Ethan Li Created on 13/03/2017
# ====================================================================#

### service type ----
observe({
  
  vt.param_year <- input$sfy_param_year
  
  vt.param_serv_type_select <- df.db_sfy %>% 
    filter(YEAR %in% vt.param_year) %>% 
    .[["SERV_TYPE"]] %>% 
    unique()
  
  updateSelectInput(
    session = session,
    inputId = "sfy_param_serv_type", 
    label = "Service Type",
    choices = vt.param_serv_type_select
  )
})


### age group ----
observe({
  vt.param_year <- input$sfy_param_year
  vt.param_serv_type <- input$sfy_param_serv_type
  
  vt.param_age_select <- df.db_sfy %>% 
    filter(YEAR == vt.param_year) %>% 
    filter(SERV_TYPE %in% vt.param_serv_type) %>% 
    .[["AGE"]] %>% 
    unique()
  
  updateSelectInput(
    session = session,
    inputId = "sfy_param_age", 
    label = "Age Group",
    choices = vt.param_age_select,
    selected = vt.param_age_select[1]
  )
  
})

### at school/on benefit flag ----
observe({
  vt.param_year <- input$sfy_param_year
  vt.param_serv_type <- input$sfy_param_serv_type
  vt.param_age <- input$sfy_param_age
  
  vt.param_other_ind_select <- df.db_sfy %>% 
    filter(YEAR == vt.param_year) %>% 
    filter(SERV_TYPE %in% vt.param_serv_type) %>% 
    filter(AGE %in% vt.param_age) %>% 
    .[["OTHER_IND"]] %>% 
    unique()
  
  
  vt.param_other_ind <- vt.param_other_ind_select[1]
  
  vt.param_other_ind_title <- df.db_sfy %>% 
    filter(YEAR == vt.param_year) %>% 
    filter(SERV_TYPE %in% vt.param_serv_type) %>% 
    filter(AGE %in% vt.param_age) %>% 
    filter(OTHER_IND %in% vt.param_other_ind) %>% 
    .[["OTHER_TYPE"]] %>% 
    unique()
  
  updateSelectInput(
    session = session,
    inputId = "sfy_param_other_ind", 
    label = vt.param_other_ind_title,
    choices = vt.param_other_ind_select
  )
})

### time period ----
observe({
  vt.param_year <- input$sfy_param_year
  vt.param_serv_type <- input$sfy_param_serv_type
  vt.param_age <- input$sfy_param_age
  vt.param_other_ind <- input$sfy_param_other_ind
  
  vt.param_period_select <- df.db_sfy %>% 
    filter(YEAR == vt.param_year) %>% 
    filter(SERV_TYPE %in% vt.param_serv_type) %>% 
    filter(AGE %in% vt.param_age) %>% 
    filter(OTHER_IND %in% vt.param_other_ind)
  
  if (nrow(vt.param_period_select) == 0) {
    vt.param_period_select <- NULL
  }
  else {
    vt.param_period_select <- vt.param_period_select[["PERIOD"]] %>% 
      unique()
  }
  
  updateRadioButtons(
    session = session,
    inputId = "sfy_param_period", 
    label = "Time Period",
    choices = vt.param_period_select,
    selected = vt.param_period_select[2],
    inline = TRUE
  )
})
