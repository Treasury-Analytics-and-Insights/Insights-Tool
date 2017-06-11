#=====================================================================#
# About this programme
# Programme: "CYAR - server - misc.R"
# Objective: Server script for updating base data in CYAR panel
#
# Key data:
#          1.cyar_panel
#          2.cyar_panel$base_data
#          3.cyar_panel$filtered_data
#          4.cyar_panel$map_data
#          5.cyar_panel$map_filtered_data
#
# Author: Ethan Li Created on 19/03/2017
# ====================================================================#

### panel data ----
cyar_panel <- reactiveValues(
  base_data = df.init_cyar_base_data,
  national_base_data = df.init_cyar_national_base_data,
  filtered_data = df.init_cyar_filtered_data,
  national_filtered_data = df.init_cyar_national_filtered_data,
  map_base_data = df.init_cyar_map_data,
  map_filtered_data = df.init_cyar_map_filtered_data,
  map = spldf.init_cyar_map,
  param_area_ind = NULL,
  prev_shape_id = unique(spldf.init_cyar_map@data$AREA_CODE),
  test_data = df.tmp_cyar_map_sp_attr,
  hl_01 = NULL,
  hl_02 = NULL,
  hl_title_01 = NULL
)

### base data ----
observeEvent(input$cyar_param_refresh, {
  vt.param_age <- input$cyar_param_age
  vt.param_year <- input$cyar_param_year
  
  ## add year selector when available
  df.base_data <- df.db_cyar %>% 
    filter(AGE %in% vt.param_age)
  
  df.national_base_data <- df.db_cyar_national %>%
    filter(AGE %in% vt.param_age) %>%
    filter(YEAR %in% vt.param_year)
  
  df.map_data <- df.db_cyar_sp %>% 
    filter(AGE %in% vt.param_age) %>%
    filter(YEAR %in% vt.param_year)
  
  updateSelectInput(
    session,
    inputId = "cyar_param_risk_ind",
    label = "Risk Group:",
    choices = unique(df.base_data$RISK_DESC),
    selected = unique(df.base_data$RISK_DESC)[2]
  )
  
  cyar_panel$base_data <- df.base_data
  cyar_panel$national_base_data <- df.national_base_data
  cyar_panel$map_base_data <- df.map_data

})

### filtered data ----
df.cyar_filtered_data <- df.meta_control %>% 
  filter(PROC %in% "cyar_filtered_data")

for (i in df.cyar_filtered_data$NAME) {
  local({
    vt.name_cur <- i
    vt.group_cur <-df.cyar_filtered_data %>% 
      filter(NAME %in% vt.name_cur) %>% 
      .[["GROUP"]]
    
    vt.trigger <- paste(vt.group_cur, vt.name_cur, sep = "$")
    
    observeEvent(eval(parse(text = vt.trigger)), {
      vt.param_risk_ind <- input$cyar_param_risk_ind
      df.base_data <- cyar_panel$base_data
      df.national_base_data <- cyar_panel$national_base_data
      df.map_base_data <- cyar_panel$map_base_data
      
      
      validate(
        need(
          vt.param_risk_ind %in% df.map_base_data$RISK_DESC & vt.param_risk_ind %in% df.base_data$RISK_DESC, 
          "No update!!!"
        )
      )
      
      df.filtered_data <- df.base_data %>% 
        filter(RISK_DESC %in% vt.param_risk_ind)
      
      df.national_filtered_data <- df.national_base_data %>% 
        filter(RISK_DESC %in% vt.param_risk_ind)
      
      df.map_filtered_data <- df.map_base_data %>% 
        filter(RISK_DESC %in% vt.param_risk_ind)
      
      cyar_panel$filtered_data <- df.filtered_data
      cyar_panel$national_filtered_data <- df.national_filtered_data
      cyar_panel$map_filtered_data <- df.map_filtered_data
      
    }, ignoreNULL = FALSE)
  })
}

### concentric diagrams and venn diagrams ----
output$cyar_risk_circle_highlight <- renderUI({
  input$cyar_param_refresh
  
  isolate({
    vt.param_age <- input$cyar_param_age
    vt.param_year = input$cyar_param_year
  })
  
  
  vt.output_main <- paste0(
    "<h4 style='text-align-last: center;'>",
    "Size of risk groups - ",
    ifelse(vt.param_age %in% c("0-5 years", "6-14 years"), "Children aged ", "Youth aged "),
    vt.param_age,
    ", ",
    vt.param_year,
    "</h4>"
  )
  
  vt.output <- HTML(paste0(
    vt.output_main
  ))
  
  return(vt.output)
})

output$cyar_risk_circle <- renderImage({
  df.base_data <- cyar_panel$national_filtered_data
  
  vt.param_risk_ind <- unique(df.base_data$RISK_DESC)
  vt.param_age <- unique(df.base_data$AGE)
  vt.param_year <- unique(df.base_data$YEAR)
  
  vt.filename <- paste0(vt.param_age, " (", tolower(vt.param_risk_ind), ")-", vt.param_year,".png")
  # vt.width <- ifelse(vt.param_age %in% c("0-5 years", "6-14 years"), "800", "700")
  list(src = file.path(dir.cyar_circles, vt.filename),
       contentType = 'image/png',
       # width = vt.width,
       alt = "This is alternate text")
  
}, deleteFile = FALSE)
