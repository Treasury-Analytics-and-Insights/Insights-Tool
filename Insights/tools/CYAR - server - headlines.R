#=====================================================================#
# About this programme
# Programme: "CYAR - server - headlines.R"
# Objective: Server script for updating headlines data in CYAR panel
#
# Key data:
#          1.cyar_panel$hl_\d
#          2.cyar_panel$hl_title_\d
#          3.cyar_panel$filtered_data
#
# Author: Ethan Li Created on 19/03/2017
# ====================================================================#

### headlines data creation ----
observeEvent(cyar_panel$national_filtered_data, {
  df.base_data <- cyar_panel$filtered_data
  df.hl_01_base_data <- cyar_panel$national_base_data %>%
    filter(GENDER == "All") %>%
    filter(ETHNICITY == "ALL") 
  
  df.hl_01_filtered_data <- cyar_panel$national_filtered_data %>%
    filter(GENDER == "All") %>%
    filter(ETHNICITY == "ALL") 
  
  vt.hl_01 <- df.hl_01_filtered_data %>%
    .[['COUNT']] %>%
    sum() %>%
    format(big.mark = ",")
  
  vt.h1_risk <- df.hl_01_filtered_data %>% 
    .[["RISK_DESC"]] %>% 
    unique() %>% 
    .[1]
  
  vt.h1_pc <- df.hl_01_filtered_data %>% 
    .[["PC"]] %>% 
    unique() %>% 
    .[1]
  
  vt.h1_age <- df.hl_01_filtered_data %>% 
    .[["AGE"]] %>% 
    unique() %>% 
    .[1]
  
  vt.hl_title_01 <- paste0(vt.h1_risk, " (", strong(signif(vt.h1_pc, digits = 2)), strong("%")," of ",ifelse(vt.h1_age %in% c("0-5 years", "6-14 years"), "Children aged ", "Youth aged "), vt.h1_age, ")")
  
  vt.hl_title_02 <- "Average projected benefit, corrections and childhood CYF costs by age 35"
  vt.hl_title_02_val = "Average projected costs by age 35"
  
  vt.hl_02 <- df.base_data %>% 
    filter(IND_METRIC %in% "cost", METRIC %in% vt.hl_title_02_val) %>% 
    .[["VALUE"]] %>% 
    unique() %>% 
    round() %>% 
    format(big.mark = ",")
  
  cyar_panel$hl_01 <- vt.hl_01
  cyar_panel$hl_title_01 <- vt.hl_title_01
  cyar_panel$hl_02 <- paste0("$",vt.hl_02)
  cyar_panel$hl_title_02 <- vt.hl_title_02
  
})

### value box information creation ----
output$cyar_hl_01 <- renderValueBox({
  valueBox(
    cyar_panel$hl_01, 
    HTML(cyar_panel$hl_title_01), 
    # color = "purple",
    color = "blue",
    width = NULL,
    # icon = icon("male", class = "fa fa-male fa-inverse")
    icon = icon("male", class = "fa fa-male")
  )
})

output$cyar_hl_02 <- renderValueBox({
  valueBox(
    cyar_panel$hl_02,
    cyar_panel$hl_title_02, 
    # color = "purple",
    color = "blue",
    width = NULL,
    #icon = icon("dollar", class = "fa fa-dollar fa-inverse")
    icon = icon("dollar", class = "fa fa-dollar")
    #icon = icon("fa-money", class = "fa fa-money")
    #icon = icon("fa-database", class = "fa fa-database")
  )
})
