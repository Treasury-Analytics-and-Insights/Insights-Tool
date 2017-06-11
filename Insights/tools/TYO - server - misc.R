#=====================================================================#
# About this programme
# Programme: "TYO - server - misc.R"
# Objective: Server script for updating base data in TYO panel
#
# Key data:
#          1.tyo_panel
#          2.tyo_panel$base_data
#          3.tyo_panel$filtered_data
#          4.tyo_panel$map_data
#          5.tyo_panel$map_filtered_data
#
# Author: Ethan Li Created on 19/03/2017
# ====================================================================#

### panel data ----
tyo_panel <- reactiveValues(
  # base_data = df.init_tyo_base_data,
  # filtered_data = df.init_tyo_filtered_data,
  map_base_data = df.init_tyo_map_data,
  map_filtered_data = df.init_tyo_map_filtered_data,
  map = spldf.init_tyo_map,
  param_area_ind = NULL,
  prev_shape_id = unique(spldf.init_tyo_map@data$AREA_CODE),
  bubble_chart = df.init_bubble_chart_data,
  is_hover = FALSE
)

### base data ----
# observeEvent(input$tyo_param_refresh, {
#   vt.param_gender <- input$tyo_param_gender
#   vt.param_year <- input$tyo_param_year
# 
#   ## add year selector when available
#   df.base_data <- df.db_tyo %>%
#     filter(YEAR %in% vt.param_year) %>%
#     filter(GENDER %in% vt.param_gender)
# 
#   df.map_data <- df.db_tyo_sp %>%
#     filter(YEAR %in% vt.param_year) %>%
#     filter(GENDER %in% vt.param_gender)
# 
#   tyo_panel$base_data <- df.base_data
#   tyo_panel$map_base_data <- df.map_data
# 
# })

# ### filtered data ----
# df.tyo_filtered_data <- df.meta_control %>%
#   filter(PROC %in% "tyo_filtered_data")
# 
# for (i in df.tyo_filtered_data$NAME) {
#   local({
#     vt.name_cur <- i
#     vt.group_cur <-df.tyo_filtered_data %>%
#       filter(NAME %in% vt.name_cur) %>%
#       .[["GROUP"]]
# 
#     vt.trigger <- paste(vt.group_cur, vt.name_cur, sep = "$")
# 
#     observeEvent(eval(parse(text = vt.trigger)), {
#       vt.param_risk_ind <- input$tyo_param_risk_ind
#       df.base_data <- tyo_panel$base_data
#       df.map_base_data <- tyo_panel$map_base_data
# 
# 
#       validate(
#         need(
#           vt.param_risk_ind %in% df.map_base_data$RISK_DESC & vt.param_risk_ind %in% df.base_data$RISK_DESC,
#           "No update!!!"
#         )
#       )
# 
#       df.filtered_data <- df.base_data %>%
#         filter(RISK_DESC %in% vt.param_risk_ind)
# 
#       df.map_filtered_data <- df.map_base_data %>%
#         filter(RISK_DESC %in% vt.param_risk_ind)
# 
#       tyo_panel$filtered_data <- df.filtered_data
#       tyo_panel$map_filtered_data <- df.map_filtered_data
# 
#     }, ignoreNULL = FALSE)
#   })
# }

