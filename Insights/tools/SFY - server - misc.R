#=====================================================================#
# About this programme
# Programme: "SFY - server - misc.R"
# Objective: Server script for updating base data in SFY panel
#
# Key data:
#          1.sfy_panel
#
# Author: Ethan Li Created on 13/03/2017
# ====================================================================#

### panel data ----
sfy_panel <- reactiveValues(
  base_data = df.init_sfy_base_data,
  hl_01 = NULL,
  hl_02 = NULL,
  hl_03 = NULL,
  hl_04 = NULL,
  hl_05 = NULL,
  hl_title_01 = NULL,
  hl_title_02 = NULL,
  hl_title_03 = NULL,
  hl_title_04 = NULL,
  hl_title_05 = NULL,
  param_serv_ind = vt.init_sfy_param_serv_ind,
  param_risk_ind = vt.init_sfy_param_risk_ind,
  param_zoom_ind = vt.init_sfy_param_zoom_ind,
  param_area_ind = NULL,
  map_data = df.init_sfy_map_data,
  map = spldf.init_sfy_map,
  prev_shape_id = vt.init_sfy_param_shape_id
)

### parameters selection highlight ----
output$sfy_param_serv_highlight <- renderUI({
  input$sfy_param_refresh
  
  vt.param_serv_ind <- sfy_panel$param_serv_ind
  
  isolate({
    vt.param_year <- input$sfy_param_year
    vt.param_serv_type <- input$sfy_param_serv_type
    vt.param_age <- input$sfy_param_age
    vt.param_other_ind <- input$sfy_param_other_ind
    vt.param_other_ind_title <- ifelse(vt.param_serv_type == "Employment", "subset to on benefit", "subset to in education")
    vt.param_period <- input$sfy_param_period
  })
  
  vt.output_main <- paste0(
    "<h4 style='text-align-last: center;'>",
    vt.param_serv_type,
    ": ",
    vt.param_serv_ind,
    " selected",
    "</h4>"
  )
  
  vt.output_sub <- paste0(
    "<p style='text-align-last: center;'>",
    vt.param_year,
    " calendar year, ",
    vt.param_age,
    " old, ",
    ifelse(vt.param_other_ind == "No", paste0("not ", vt.param_other_ind_title), vt.param_other_ind_title),
    ", service use in ",
    vt.param_period,
    "</p>",
    "<p style='text-align-last: center;'>",
    "(click on a bar to select a service)",
    "</p>"   
  )
  
  vt.output <- HTML(paste0(
    vt.output_main,
    vt.output_sub
  ))
  
  return(vt.output)
  
})

output$sfy_param_risk_highlight <- renderUI({
  input$sfy_param_refresh
  
  vt.param_risk_ind <- sfy_panel$param_risk_ind
  
  isolate({
    vt.param_year <- input$sfy_param_year
    vt.param_serv_type <- input$sfy_param_serv_type
    vt.param_age <- input$sfy_param_age
    vt.param_other_ind <- input$sfy_param_other_ind
    vt.param_other_ind_title <- ifelse(vt.param_serv_type == "Employment", "subset to on benefit", "subset to in education")
    vt.param_period <- input$sfy_param_period
  })
  
  vt.output_main <- paste0(
    "<h4 style='text-align-last: center;'>",
    "Risk groups: ",
    vt.param_risk_ind,
    " selected",
    "</h4>"
  )
  
  vt.output_sub <- paste0(
    "<p style='text-align-last: center;'>",
    vt.param_year,
    " calendar year, ",
    vt.param_age,
    " old, ",
    ifelse(vt.param_other_ind == "No", paste0("not ", vt.param_other_ind_title), vt.param_other_ind_title),
    ", service use in ",
    vt.param_period,
    "</p>",
    "<p style='text-align-last: center;'>",
    "(click on a bar to select a risk group)",
    "</p>"
  )
  
  vt.output <- HTML(paste0(
    vt.output_main,
    vt.output_sub
  ))
  
  return(vt.output)
  
})

### base data preparation ----
observeEvent(input$sfy_param_refresh, {
  vt.param_year <- input$sfy_param_year
  vt.param_serv_type <- input$sfy_param_serv_type
  vt.param_age <- input$sfy_param_age
  vt.param_other_ind <- input$sfy_param_other_ind
  vt.param_period <- input$sfy_param_period
  
  ## base
  df.base_data <- df.db_sfy %>% 
    filter(YEAR == vt.param_year) %>% 
    filter(SERV_TYPE == vt.param_serv_type) %>%
    filter(AGE == vt.param_age) %>% 
    filter(OTHER_IND == vt.param_other_ind) %>% 
    filter(PERIOD == vt.param_period) 
  
  ## map
  df.tmp_sfy_map <- df.db_sfy_sp %>%
    filter(YEAR == vt.param_year) %>%
    filter(SERV_TYPE == vt.param_serv_type) %>%
    filter(AGE == vt.param_age) %>%
    filter(OTHER_IND == vt.param_other_ind) %>%
    filter(PERIOD == vt.param_period) %>%
    select(AREA_CODE, AREA_TYPE, GENDER, SERV_IND, RISK_DESC, METRIC_TYPE, COUNT)

  vt.risk_grps = df.sfy_mapping_risk %>%
    filter(AGE == vt.param_age, TOTAL_COLUMN) %>%
    .[["RISK_DESC"]]

  df.tmp_sfy_map_total_people <- df.tmp_sfy_map %>%
    filter(SERV_IND %in% "Total") %>%
    group_by(AREA_CODE, AREA_TYPE, GENDER, RISK_DESC) %>%
    summarise(TOTAL_RISK = sum(COUNT))

  df.tmp_sfy_map_total_serv <- df.tmp_sfy_map %>%
    filter(RISK_DESC %in% vt.risk_grps) %>%
    group_by(AREA_CODE, AREA_TYPE, GENDER, SERV_IND) %>%
    summarise(TOTAL_SERV = sum(COUNT))
  
  df.map_data <- df.tmp_sfy_map %>%
    left_join(df.tmp_sfy_map_total_serv, by = c("AREA_CODE", "AREA_TYPE", "GENDER", "SERV_IND")) %>%
    left_join(df.tmp_sfy_map_total_people, by = c("AREA_CODE", "AREA_TYPE", "GENDER", "RISK_DESC")) %>%
    mutate(PC_RISK = ifelse(TOTAL_RISK == 0, 0, 100*COUNT/TOTAL_RISK)) %>%
    mutate(PC_SERV = ifelse(TOTAL_SERV == 0, 0, 100*COUNT/TOTAL_SERV))
  #browser()
  # df.tmp_sfy_map <- df.db_sfy_sp %>%
  #   filter(YEAR == vt.param_year) %>%
  #   filter(SERV_TYPE == vt.param_serv_type) %>%
  #   filter(AGE == vt.param_age) %>%
  #   filter(OTHER_IND == vt.param_other_ind) %>%
  #   filter(PERIOD == vt.param_period) %>%
  #   select(AREA_CODE, AREA_TYPE, GENDER, SERV_IND, RISK_DESC, METRIC_TYPE, COUNT)
  # 
  # df.tmp_sfy_map_ppl <- df.tmp_sfy_map %>%
  #   filter(METRIC_TYPE %in% "People") %>%
  #   change_names("COUNT", "CNT_PEOPLE", reminder = FALSE) %>%
  #   select(-SERV_IND, -METRIC_TYPE)
  # 
  # df.tmp_sfy_map_serv <- df.tmp_sfy_map %>%
  #   filter(METRIC_TYPE %in% "Service") %>%
  #   change_names("COUNT", "CNT_SERV", reminder = FALSE) %>%
  #   select(-METRIC_TYPE)
  # browser()
  # df.map_data <- df.tmp_sfy_map_serv %>%
  #   left_join(df.tmp_sfy_map_ppl, c("AREA_CODE", "AREA_TYPE", "GENDER", "RISK_DESC")) %>%
  #   mutate(PC_SERV = ifelse(CNT_PEOPLE == 0, 0, CNT_SERV/CNT_PEOPLE))
  
  sfy_panel$base_data <- df.base_data
  sfy_panel$map_data <- df.map_data
  
  if (vt.param_age == "15-19 years" | vt.param_age == "20-24 years") {
    sfy_panel$param_risk_ind = "2+ risk indicators at age 15"
  } else {
  sfy_panel$param_risk_ind = df.base_data %>%
    .[["RISK_DESC"]] %>%
    unique() %>%
    sort() %>%
    .[1]
  }
  
  if (vt.param_age == "15-19 years" & vt.param_serv_type == "Education") {
    sfy_panel$param_serv_ind = "Youth Guarantee: Fees-Free"
  } else {
  sfy_panel$param_serv_ind = df.base_data %>%
    arrange(desc(COUNT)) %>%
    .[["SERV_IND"]] %>%
    unique() %>%
    .[2]
  }
})

output$sfy_venn_title <- renderUI({
  vt.param_risk_ind <- ifelse(is.null(sfy_panel$param_risk_ind), "All", sfy_panel$param_risk_ind)
  vt.param_serv_ind <- sfy_panel$param_serv_ind
  vt.param_serv_type <- input$sfy_param_serv_type
  
  # vt.output_main <- paste0(
  #   "<h3 style='text-align-last: center;'>",
  #   "<font color='", vt.sfy_col_blue_dark,
  #   "'>Overlap</font> between <font color='", vt.sfy_col_orange,
  #   "'>",vt.param_serv_ind, " </font> and <font color='", vt.sfy_col_blue,
  #   "'>", vt.param_risk_ind,
  #   "</font> </h3>"
  # )
  
  # vt.output_main <- paste0(
  #   "<h3 style='text-align-last: center;'>",
  #   "<font color='", vt.sfy_col_orange,"'>", vt.param_serv_ind, "</font>", 
  #   "and <font color='", vt.sfy_col_blue, "'>", vt.param_risk_ind,  "</font>",
  #   " with ", "<font color='", vt.sfy_col_blue_dark, "'>Overlap</font>",
  #   "</h3>"
  # )
  
  # vt.output_main <- paste0(
  #   "<h3 style='text-align-last: center;'>",
  #   "<font color='", vt.sfy_col_orange,"'>", trimws(vt.param_serv_ind), "</font>, ",
  #   "<font color='", vt.sfy_col_blue_dark, "'>Overlap</font>",
  #   " and <font color='", vt.sfy_col_blue, "'>", vt.param_risk_ind,  "</font>",
  #   "</h3>"
  # )
  
  # vt.output_main <- paste0(
  #   "<h3 style='text-align-last: center;'>",
  #   "<font color='", vt.sfy_col_orange,"'>", trimws(vt.param_serv_ind), "</font> - ",
  #   "<font color='", vt.sfy_col_blue_dark, "'>Overlap</font>",
  #   " - <font color='", vt.sfy_col_blue, "'>", vt.param_risk_ind,  "</font>",
  #   "</h3>"
  # )
  
  #vt.output <- HTML(vt.output_main)
  
  vt.output_main = paste0("<h4 style='text-align-last: center;'>", 
                     vt.param_serv_ind, " users (left circle), ",
                     vt.param_risk_ind, " risk group (right circle), and the overlap between these groups",
                     "</h4>")
  
  vt.output <- HTML(vt.output_main)
  
  return(vt.output)
})

# output$tmp <- DT::renderDataTable(
#   sfy_panel$base_data,
#   server = TRUE,
#   filter = 'top',
#   selection = list(mode = "single", target = "row",
#                    selected = list(rows = c(1))),
#   options = list(
#     pageLength = 5
#   )
# )
# 



# 
# output$tmp2 <- renderPrint({
#   list(sfy_panel$param_serv_ind, sfy_panel$param_risk_ind, vt.init_sfy_param_serv_ind, vt.init_sfy_param_risk_ind)
#   # list(sfy_panel$param_zoom_ind, sfy_panel$param_area_ind, sfy_panel$test_data)
# 
# })

