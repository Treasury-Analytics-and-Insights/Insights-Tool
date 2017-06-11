#=====================================================================#
# About this programme
# Programme: "SFY - server - headlines.R"
# Objective: Server script for updating headlines data in SFY panel
#
# Key data:
#          1.sfy_panel$hl_\d
#          2.sfy_panel$hl_title_\d
#          3.df.sfy_hl_data - Control Meta
#
# Author: Ethan Li Created on 13/03/2017
# ====================================================================#


### headlines data creation ----
df.sfy_hl_data <- df.meta_control %>%
  filter(PROC %in% "sfy_hl_data")

for (i in df.sfy_hl_data$NAME) {
  local({
    vt.name_cur <- i
    vt.group_cur <- df.sfy_hl_data %>%
      filter(NAME %in% vt.name_cur) %>%
      .[["GROUP"]]
    
    vt.trigger <- paste(vt.group_cur, vt.name_cur, sep = "$")
    
    observeEvent(eval(parse(text = vt.trigger)), {
      df.base <- sfy_panel$base_data
      vt.param_risk_ind <- ifelse(is.null(sfy_panel$param_risk_ind), "All", sfy_panel$param_risk_ind)
      vt.param_serv_ind <- sfy_panel$param_serv_ind
      vt.param_serv_type <- input$sfy_param_serv_type
      
      vt.age = df.base %>%
        .[["AGE"]] %>%
        unique() %>%
        .[1]
      
      vt.risk_grps = df.sfy_mapping_risk %>%
        filter(AGE == vt.age, TOTAL_COLUMN) %>%
        .[["RISK_DESC"]]
      
      vt.total_service = df.base %>% 
        filter(SERV_IND %in% vt.param_serv_ind) %>% 
        filter(RISK_DESC %in% vt.risk_grps) %>% 
        summarise(COUNT = sum(COUNT, na.rm = TRUE)) %>% 
        .[["COUNT"]]
      
      vt.total_risk = df.base %>%
        filter(SERV_IND %in% "Total") %>% 
        filter(RISK_DESC %in% vt.param_risk_ind) %>% 
        summarise(COUNT = sum(COUNT, na.rm = TRUE)) %>% 
        .[["COUNT"]]
      
      vt.overlap = df.base %>%
        filter(RISK_DESC %in% vt.param_risk_ind) %>% 
        filter(SERV_IND %in% vt.param_serv_ind) %>% 
        summarise(COUNT = sum(COUNT, na.rm = TRUE)) %>% 
        .[["COUNT"]]
      
      
      ## format headlines data ----
      vt.hl_content_01 <- vt.total_service %>%
        signif(2) %>%
        format(big.mark = ",")
      
      vt.hl_title_01 <- paste0(
        gsub('.{1}$', '', input$sfy_param_age),
        " olds have used ",
        vt.param_serv_ind,
        " in the ",
        input$sfy_param_period
      )
      
      vt.hl_content_02 <- signif(100*vt.overlap/vt.total_service, 2) %>%
        as.character() %>%
        paste0("%")
      
      vt.hl_title_02 <- paste0(
        "of service users"
      )
      
      vt.hl_content_03 <- vt.total_risk %>%
        signif(2) %>%
        format(big.mark = ",")
      
      vt.hl_verb = ifelse(vt.param_risk_ind %in% vt.sfy_risk_verbs, "are", "have")
      
      vt.hl_title_03 <- paste0(
        gsub('.{1}$', '', input$sfy_param_age),
        " olds ", vt.hl_verb, " ",
        vt.param_risk_ind
      )
      
      vt.hl_content_04 <- signif(100*vt.overlap/vt.total_risk, 2) %>%
        as.character() %>%
        paste0("%")
        
      vt.hl_title_04 <- paste0(
        "of those with ",
        vt.param_risk_ind
      )
      
      
      vt.hl_content_05 <- vt.overlap %>%
        signif(2) %>%
        format(big.mark = ",")
      
      vt.hl_title_05 <- paste0(
        sfy_panel$param_serv_ind,
        " users also ",
        vt.hl_verb, " ",
        vt.param_risk_ind,
        " (",
        strong(vt.hl_content_02),
        " of service users / ",
        strong(vt.hl_content_04),
        " of risk group)"
        
      )
      
      ## update reactive values ----
      sfy_panel$hl_01 <- vt.hl_content_01
      sfy_panel$hl_title_01 <- vt.hl_title_01
      
      sfy_panel$hl_02 <- vt.hl_content_02
      sfy_panel$hl_title_02 <- vt.hl_title_02
      
      sfy_panel$hl_03 <- vt.hl_content_03
      sfy_panel$hl_title_03 <- vt.hl_title_03
      
      sfy_panel$hl_04 <- vt.hl_content_04
      sfy_panel$hl_title_04 <- vt.hl_title_04
      
      sfy_panel$hl_05 <- vt.hl_content_05
      sfy_panel$hl_title_05 <- vt.hl_title_05
   
    }, ignoreNULL = FALSE)
  })
}

### value box information creation ----
output$sfy_hl_01 <- renderValueBox({
  valueBox(
    sfy_panel$hl_01, 
    sfy_panel$hl_title_01, 
    # color = "yellow",
    width = NULL#,
    # icon = icon("male", class = "fa fa-male fa-inverse fa-2")
  )
})

output$sfy_hl_02 <- renderValueBox({
  valueBox(
    sfy_panel$hl_02, 
    sfy_panel$hl_title_02, 
    # color = "yellow",
    width = NULL#,
    # icon = icon("percent", class = "fa fa-percent fa-inverse fa-2")
  )
})

output$sfy_hl_03 <- renderValueBox({
  valueBox(
    sfy_panel$hl_03, 
    sfy_panel$hl_title_03, 
    # color = "yellow",
    width = NULL#,
    # icon = icon("male", class = "fa fa-male fa-inverse fa-2")
  )
})

output$sfy_hl_04 <- renderValueBox({
  valueBox(
    sfy_panel$hl_04, 
    sfy_panel$hl_title_04, 
    # color = "yellow",
    width = NULL#,
    # icon = icon("percent", class = "fa fa-percent fa-inverse fa-2")
  )
})

output$sfy_hl_05 <- renderValueBox({
  valueBox(
    sfy_panel$hl_05, 
    HTML(sfy_panel$hl_title_05), 
    # color = "yellow",
    width = NULL#,
    # icon = icon("percent", class = "fa fa-percent fa-inverse fa-2")
  )
})
