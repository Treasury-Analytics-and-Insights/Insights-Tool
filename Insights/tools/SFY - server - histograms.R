#=====================================================================#
# About this programme
# Programme: "SFY - server - histograms.R"
# Objective: Server script for updating histograms and venn diagram in SFY panel
#
# Key data:
#          1.sfy_panel$base_data
#          2.df.meta_control
#
# Author: Ethan Li Created on 13/03/2017
# ====================================================================#

### histogram - service group distribution ----
## plot ----
output$sfy_hist_serv <- renderHighchart({
  input$sfy_hist_serv_reset
  vt.param_sd_loc <- input$sfy_hist_sd_loc
    
  df.base <- sfy_panel$base_data
  
  vt.age = df.base %>%
    .[["AGE"]] %>%
    unique() %>%
    .[1]
  
  vt.risk_grps = df.sfy_mapping_risk %>%
    filter(AGE == vt.age, TOTAL_COLUMN) %>%
    .[["RISK_DESC"]]
  
  df.plot_data <- df.base %>% 
    filter(METRIC_TYPE == "Service") %>% 
    filter(RISK_DESC %in% vt.risk_grps) %>% 
    select(SERV_IND, RISK_DESC, COUNT) %>% 
    # mutate(SERV_IND = gsub("\\Services", "", x = SERV_IND)) %>%
    mutate(RISK_DESC = plyr::mapvalues(RISK_DESC, vt.risk_grps, c("METRIC_1", "METRIC_2"))) %>% 
    spread(RISK_DESC, COUNT, fill = 0) %>% 
    mutate(PC_RISK = ifelse((METRIC_1 + METRIC_2) == 0, 0, METRIC_1/ (METRIC_1 + METRIC_2))) %>% 
    mutate(PC_RISK = round(PC_RISK * 100, 2)) %>%
    mutate(TOTAL = METRIC_1 + METRIC_2)
  
  # vt.select = df.plot_data %>%
  #   arrange(desc(TOTAL)) %>%
  #   .[["SERV_IND"]] %>%
  #   unique() %>%
  #   .[1]
   vt.select = sfy_panel$param_serv_ind 
   vt.select.ind = match(vt.select, df.plot_data$SERV_IND) - 1
    
  
  
  # vt.title_serv_type <- unique(df.base$SERV_TYPE)
  # 
  # 
  # vt.sub_title_age <- tolower(unique(df.base$AGE))
  # vt.sub_title_other_ind <- ifelse(unique(df.base$OTHER_IND) == "No", "not", "")
  # vt.sub_title_other_type <- tolower(gsub("\\?", "", unique(df.base$OTHER_TYPE)))
  
  # vt.subtitle <- paste("CYAR between", vt.sub_title_age, vt.sub_title_other_ind, vt.sub_title_other_type)
  
  # vt.title <- paste(vt.title_serv_type, "Services to Children/Youth At Risk (CYAR)")
  hc_hist(
    x = "SERV_IND", 
    y = "TOTAL", 
    # title = vt.title, 
    # subtitle = vt.subtitle, 
    xaxis = "Service", 
    yaxis = "Service users (#)", 
    col = vt.sfy_col_orange_light, 
    col_highlight = vt.sfy_col_orange, 
    df = df.plot_data, 
    tooltip = "Services to CYAR",
    pointFormat = ": <b>{point.y:.0f}</b>",
    pre_selected=vt.select.ind)
  
  
  # if (vt.param_sd_loc) {
  #   vt.title <- paste("% of", vt.title_serv_type, "Services to Children/Youth At Risk (CYAR)")
  #   hc_hist(
  #     x = "SERV_IND", 
  #     y = "PC_RISK", 
  #     title = vt.title, 
  #     subtitle = vt.subtitle, 
  #     xaxis = "Service Group", 
  #     yaxis = "% of Services to CYAR", 
  #     col = vt.sfy_col_light, 
  #     col_highlight = vt.sfy_col_mile, 
  #     df = df.plot_data, 
  #     tooltip = "Services to CYAR",
  #     pre_selected=3)
  # }
  # else {
  #   vt.title <- paste(vt.title_serv_type, "Services to Children/Youth (At Risk vs. No Risk)")
  #   hc_hist_comp(
  #     x = "SERV_IND", 
  #     y1 = 'METRIC_1', 
  #     y2= "METRIC_2", 
  #     "At Risk", 
  #     "No Risk",
  #     title = vt.title, 
  #     subtitle = vt.subtitle, 
  #     xaxis = "Service Group", 
  #     yaxis = "Services Provided (#)", 
  #     col_n = vt.sfy_col_light, 
  #     col_y = vt.sfy_col_mile, 
  #     df = df.plot_data,
  #     pre_selected=3)
  # }
}) 

## subset index reset ----
observeEvent(input$click$SERV_IND, {
  sfy_panel$param_serv_ind <- input$click$SERV_IND$name
})

df.sfy_hist_serv_reset <- df.meta_control %>% 
  filter(PROC %in% "sfy_hist_serv_reset")

for (i in df.sfy_hist_serv_reset$NAME) {
  local({
    vt.name_cur <- i
    vt.group_cur <- df.sfy_hist_serv_reset %>% 
      filter(NAME %in% vt.name_cur) %>% 
      .[["GROUP"]]
    
    vt.trigger <- paste(vt.group_cur, vt.name_cur, sep = "$")
    
    observeEvent(eval(parse(text = vt.trigger)), {
      #sfy_panel$param_serv_ind <- vt.init_sfy_param_serv_ind
    }, ignoreNULL = FALSE)
  })
}


### histogram - risk group distribution  ----
## plot ----
output$sfy_hist_risk <- renderHighchart({
  input$sfy_hist_risk_reset
  vt.param_sd_loc <- input$sfy_hist_sd_loc
  vt.param_serv_ind <- sfy_panel$param_serv_ind
  df.base <- sfy_panel$base_data
  
  
  if (!is.null(vt.param_serv_ind)) {
    df.base <- filter(df.base, SERV_IND %in% vt.param_serv_ind | METRIC_TYPE == "People")
    vt.title_serv_ind <- vt.param_serv_ind
  } 
  else {
    vt.param_serv_type <- unique(df.base$SERV_TYPE)
    vt.title_serv_ind <- paste("Any", vt.param_serv_type, "Services")
  }
  vt.age = df.base %>%
    .[["AGE"]] %>%
    unique() %>%
    .[1]
  
  vt.risk_grps = df.sfy_mapping_risk %>%
    filter(AGE == vt.age, DISPLAY_FLAG) %>%
    .[["RISK_DESC"]]
  
  
  df.tmp_base1 <- df.base %>% 
    filter(RISK_DESC %in% vt.risk_grps) %>% 
    group_by(SERV_IND, RISK_DESC, METRIC_TYPE) %>% 
    summarise(COUNT = sum(COUNT, na.rm = TRUE)) %>% 
    ungroup()
  
  df.plot_data <- df.tmp_base1 %>% 
    filter(METRIC_TYPE == "People") %>% 
    select(RISK_DESC, COUNT) %>% 
    change_names("COUNT", "COUNT_PPL", reminder = FALSE) %>%
    left_join(
      df.tmp_base1 %>% 
        filter(METRIC_TYPE == "Service") %>% 
        select(RISK_DESC, SERV_IND, COUNT) %>% 
        change_names("COUNT", "COUNT_SERV", reminder = FALSE),
      by = "RISK_DESC"
    ) %>% 
    replace_na(list(COUNT_SERV = 0)) %>%
    mutate(PPL_ADDR = COUNT_SERV/COUNT_PPL) %>% 
    group_by(RISK_DESC) %>% 
    summarise(COUNT_PPL = unique(COUNT_PPL),
              PC_PPL_SERV = mean(PPL_ADDR, na.rm = TRUE)) %>% 
    mutate(COUNT_PPL_SERV = COUNT_PPL * PC_PPL_SERV) %>% 
    mutate(COUNT_PPL_SERV_NOT = COUNT_PPL - COUNT_PPL_SERV) %>% 
    mutate(PC_PPL_SERV = round(100 * PC_PPL_SERV, 2))
    
  # vt.select = df.plot_data %>%
  #   arrange(desc(COUNT_PPL)) %>%
  #   .[["RISK_DESC"]] %>%
  #   unique() %>%
  #   .[1]
  vt.select = sfy_panel$param_risk_ind
  vt.select.ind = match(vt.select, df.plot_data$RISK_DESC) - 1
  
  # vt.sub_title_age <- tolower(unique(df.base$AGE))
  # vt.sub_title_other_ind <- ifelse(unique(df.base$OTHER_IND) == "No", "not", "")
  # vt.sub_title_other_type <- tolower(gsub("\\?", "", unique(df.base$OTHER_TYPE)))
  # vt.subtitle <- paste("CYAR between", vt.sub_title_age, vt.sub_title_other_ind, vt.sub_title_other_type)
  # 
  # vt.title <- "Children/Youth at Risk (CYAR) Receiving Services"
  hc_hist(
    x = "RISK_DESC", 
    y = 'COUNT_PPL', 
    # title = vt.title, 
    # subtitle = vt.subtitle, 
    xaxis = "Risk Group", 
    yaxis = "Children/Youth at Risk (#)", 
    col = vt.sfy_col_blue_light, 
    col_highlight = vt.sfy_col_blue, 
    df = df.plot_data, 
    tooltip = "CYAR Receving Services",
    pointFormat = ": <b>{point.y:.0f}</b>",
    pre_selected = vt.select.ind
  )
  
  # if (vt.param_sd_loc) {
  #   vt.title <- paste("% of Children/Youth at Risk (CYAR) Receiving", vt.title_serv_ind)
  #   hc_hist("RISK_DESC", "PC_PPL_SERV", vt.title, vt.subtitle, xaxis = "Risk Group", yaxis = "% of CYAR Receiving Services", 
  #           col = vt.sfy_col_light, col_highlight = vt.sfy_col_mile, df.plot_data, tooltip = "CYAR Receving Services (%)")
  # }
  # else {
  #   vt.title <- "Children/Youth at Risk (Service Received vs.No Service Received)"
  #   hc_hist_comp(x = "RISK_DESC", y1 = 'COUNT_PPL_SERV_NOT', y2= "COUNT_PPL_SERV", "No Service Received", "Service Received",
  #                title = vt.title, subtitle = vt.subtitle, xaxis = "Risk Groups", 
  #                yaxis = "Children/Youth at Risk (#)", col_n = vt.sfy_col_dark, col_y = vt.sfy_col_mile, 
  #                df = df.plot_data)
  # }
  
  
})

## subset index reset ----
observeEvent(input$click$RISK_DESC, {
  sfy_panel$param_risk_ind <- input$click$RISK_DESC$name
})

df.sfy_hist_risk_reset <- df.meta_control %>% 
  filter(PROC %in% "sfy_hist_risk_reset")

for (i in df.sfy_hist_risk_reset$NAME) {
  local({
    vt.name_cur <- i
    vt.group_cur <- df.sfy_hist_risk_reset %>% 
      filter(NAME %in% vt.name_cur) %>% 
      .[["GROUP"]]
    
    vt.trigger <- paste(vt.group_cur, vt.name_cur, sep = "$")
    
    observeEvent(eval(parse(text = vt.trigger)), {
      #sfy_panel$param_risk_ind <- vt.init_sfy_param_risk_ind
    }, ignoreNULL = FALSE)
  })
}




### venn diagrams ----
## plot ----
output$sfy_venn <- renderPlot({
  
  df.base <- sfy_panel$base_data
  vt.param_risk_ind <- ifelse(is.null(sfy_panel$param_risk_ind), "All", sfy_panel$param_risk_ind)
  vt.param_serv_ind <- sfy_panel$param_serv_ind
  
  
  if (is.null(vt.param_serv_ind)) return(NULL)
  vt.age = df.base %>%
    .[["AGE"]] %>%
    unique() %>%
    .[1]
  
  vt.risk_grps = df.sfy_mapping_risk %>%
    filter(AGE == vt.age, TOTAL_COLUMN) %>%
    .[["RISK_DESC"]]
  
  vt.serv <- df.base %>% 
    filter(SERV_IND %in% vt.param_serv_ind) %>% 
    filter(RISK_DESC %in% vt.risk_grps) %>% 
    summarise(COUNT = sum(COUNT, na.rm = TRUE)) %>% 
    .[["COUNT"]]
  
  vt.cyar <- df.base %>% 
    filter(RISK_DESC %in% vt.param_risk_ind) %>% 
    filter(SERV_IND %in% "Total") %>% 
    summarise(COUNT = sum(COUNT, na.rm = TRUE)) %>% 
    .[["COUNT"]]
  
  vt.cyar_serv <- df.base %>% 
    filter(SERV_IND %in% vt.param_serv_ind) %>% 
    filter(RISK_DESC %in% vt.param_risk_ind) %>% 
    .[["COUNT"]]

  if (vt.cyar > vt.serv) {
    grid.newpage()

    chart.venn <- draw.pairwise.venn(
      area1 = vt.serv,
      area2 = vt.cyar,
      cross.area = vt.cyar_serv,
      # category = c("Service", "Children & Youth at Risk"),
      fill = c(vt.sfy_col_orange, vt.sfy_col_blue),
      col = c(vt.sfy_col_orange, vt.sfy_col_blue),
      label.col = c(vt.sfy_col_orange, vt.sfy_col_orange, vt.sfy_col_blue),
      rotation.degree = 180,
      alpha = c(0.3, 0.8),
      # cex = 1.5,
      cex = 0,
      cat.cex = 0,
      # cat.pos = c(160, -160),
      ext.text = FALSE,
      scaled = TRUE,
      ind = FALSE#,
      # fontfamily = rep('mono',3)
    )
  } else {
    grid.newpage()
    
    chart.venn <- draw.pairwise.venn(
      area1 = vt.serv,
      area2 = vt.cyar,
      cross.area = vt.cyar_serv,
      # category = c("Service", "Children & Youth at Risk"),
      fill = c(vt.sfy_col_orange, vt.sfy_col_blue),
      col = c(vt.sfy_col_orange, vt.sfy_col_blue),
      label.col = c(vt.sfy_col_orange, vt.sfy_col_orange, vt.sfy_col_blue),
      ind = FALSE,
      alpha = c(0.8, 0.5),
      # cex = 1.5,
      cex = 0,
      cat.cex = 0,
      # cat.pos = c(-160, 160),
      ext.text = FALSE,
      # fontfamily = rep('mono',3),
      scaled = TRUE,
      width = "500px", height = "500px"
    )  
  }
  
  grid.draw(chart.venn)
  
})

### Bar venn ----
# output$sfy_bar_venn <- renderHighchart({
#   
#   df.base <- sfy_panel$base_data
#   vt.param_risk_ind <- ifelse(is.null(sfy_panel$param_risk_ind), "All", sfy_panel$param_risk_ind)
#   vt.param_serv_ind <- sfy_panel$param_serv_ind
#   
#   
#   if (is.null(vt.param_serv_ind)) return(NULL)
#   
#   vt.serv <- df.base %>% 
#     filter(SERV_IND %in% vt.param_serv_ind) %>% 
#     filter(RISK_DESC %in% c("All", "No Risk")) %>% 
#     summarise(COUNT = sum(COUNT, na.rm = TRUE)) %>% 
#     .[["COUNT"]]
#   
#   vt.cyar <- df.base %>% 
#     filter(RISK_DESC %in% vt.param_risk_ind) %>% 
#     filter(SERV_IND %in% "Total") %>% 
#     summarise(COUNT = sum(COUNT, na.rm = TRUE)) %>% 
#     .[["COUNT"]]
#   
#   vt.cyar_serv <- df.base %>% 
#     filter(SERV_IND %in% vt.param_serv_ind) %>% 
#     filter(RISK_DESC %in% vt.param_risk_ind) %>% 
#     .[["COUNT"]]
# 
#   hc <- highchart() %>%
#     hc_chart(type = "column") %>% 
#     hc_title(text = "Service Coverage") %>%
#     hc_yAxis(
#       visible = FALSE
#     ) %>%
#     hc_xAxis(
#       visible = FALSE
#     ) %>%
#     hc_tooltip(
#       headerFormat = ""
#     ) %>% 
#     hc_add_series(
#       index= 2,
#       name = "Services",
#       data = vt.serv - vt.cyar_serv, 
#       dataLabels = list(enabled = TRUE, format = "{series.name}:{y}"),
#       color = vt.sfy_col_light
#     ) %>% 
#     hc_add_series(
#       index= 1, 
#       name = "At risk recieved services",
#       data = vt.cyar_serv, 
#       dataLabels = list(enabled = TRUE, format = "{series.name}:{y}"),
#       color = vt.sfy_col_dark
#     ) %>% 
#     hc_add_series(
#       index= 0, 
#       name = "People At Risk",
#       data = vt.cyar - vt.cyar_serv, 
#       dataLabels = list(enabled = TRUE, format = "{series.name}:{y}"),
#       color = vt.sfy_col_mile
#     ) %>% 
#     hc_plotOptions(
#       # series = list(stacking = "normal")
#       series = list(stacking = "percent"),
#       allowPointSelect = TRUE
#     ) %>%
#     hc_exporting(enabled = TRUE)
#   
#   hc
#   
# })




## control flow indicator for venn ----
output$sfy_venn_warn <- renderText({
  
  input$sfy_param_refresh
  isolate({
    vt.param_serv_type <- input$sfy_param_serv_type
  })
  vt.param_serv_ind <- sfy_panel$param_serv_ind
  
  validate(
    need(
      !is.null(vt.param_serv_ind),
      paste("Please select a", tolower(vt.param_serv_type), 
            "service in the histogram......")
    )
  )
  
  return("pass")
  
  # vt.output <- ifelse(!is.null(vt.param_serv_ind), "pass", 
  #                     paste("Please select a", tolower(vt.param_serv_type), 
  #                           "service in the histogram......"))
  # return(vt.output)
})

outputOptions(output, "sfy_venn_warn", suspendWhenHidden = FALSE)





