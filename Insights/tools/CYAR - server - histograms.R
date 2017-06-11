### outcome histogram ----
output$cyar_hist_oc <- renderHighchart({
  df.base <- cyar_panel$filtered_data
  
  df.plot_data <- df.base %>%
    filter(IND_METRIC %in% "percent") %>%  
    select(AGE, RISK_DESC, METRIC, VALUE)
  
  vt.title <- "Projected future outcomes for selected risk group"
  vt.subtitle <- paste0(ifelse(unique(df.plot_data$AGE) %in% c("0-5 years", "6-14 years"), "Children aged ", "Youth aged "), unique(df.plot_data$AGE), " (", unique(df.plot_data$RISK_DESC), ", ", unique(cyar_panel$national_filtered_data$YEAR), ")")
  
  # hc_hist(x = "METRIC", y = "VALUE", title = vt.title, subtitle = vt.subtitle, 
  #         xaxis = "Outcomes", yaxis = "Outcome Likelihood (%)", 
  #         col = vt.cyar_col_mile, col_highlight = vt.cyar_col_mile, 
  #         df = df.plot_data, tooltip = "Outcome Likelihood (%)", id = "CYAR_", pointFormat = ": <b>{point.y:.1f}</b>")
  vt.max = min(max(df.plot_data$VALUE)*1.15,100)
  vt.yaxis = "Outcome Likelihood (%)"
    
  hc<- df.plot_data %>%
    hchart(
      type = "column",
      hcaes(
        x = METRIC, 
        y = VALUE
      )
    ) %>%
    hc_title(text = vt.title) %>%
    hc_subtitle(text = vt.subtitle) %>%
    hc_xAxis(title = list(text = "Outcomes"),
             categories = df.plot_data$METRIC) %>%
    hc_yAxis(title = list(text = vt.yaxis),
             labels = list(
               format =  '{value}%'
             ),
             min = 0,
             max = vt.max,
             allowDecimals = FALSE
    ) %>%
    hc_colors(vt.cyar_col_mile) %>%
    hc_tooltip(
      headerFormat = "<b>{point.x}</b> <br>",
      pointFormat = paste0(vt.yaxis, ": <b>{point.y:.1f}%</b>")
    )
  
  hc
})

### ethnicity histogram ----
output$cyar_hist_eth <- renderHighchart({
  df.base <- cyar_panel$national_filtered_data
  # df.base <- df.db_cyar_national

  df.plot_data <- df.base %>%
    # filter(YEAR %in% input$cyar_param_year) %>%
    filter(GENDER %in% input$cyar_param_natinal_gender_ind) %>%
    select(YEAR, AGE, GENDER, ETHNICITY, RISK_DESC, PC)
  
  vt.title <- "Proportion in selected risk group by ethnicity"
  vt.subtitle <- paste0(ifelse(unique(df.plot_data$AGE) %in% c("0-5 years", "6-14 years"), "Children aged ", "Youth aged "), unique(df.plot_data$AGE), " (", unique(df.plot_data$RISK_DESC), ", ", unique(df.plot_data$YEAR), ")")
  #vt.yaxis <- paste0(unique(df.plot_data$RISK_DESC), " (%)")
  vt.yaxis <- "Selected Risk Group (%)"
  # vt.max = round(max(df.plot_data$PC)+5,-1)
  vt.max = min(max(df.plot_data$PC)*1.15,100)
  
  hc<- df.plot_data %>%
    hchart(
      type = "column",
      hcaes(
        x = ETHNICITY, 
        y = PC
      )
    ) %>%
    # hc_chart(type = "column") %>%
    hc_title(text = vt.title) %>%
    hc_subtitle(text = vt.subtitle) %>%
    hc_xAxis(title = list(text = "Ethnicity"),
             categories = df.plot_data$ETHNICITY) %>%
    hc_yAxis(title = list(text = vt.yaxis),
             labels = list(
               format =  '{value}%'
             ),
             min = 0,
             max = vt.max,
             allowDecimals = FALSE
    ) %>%
    hc_colors(vt.cyar_col_mile) %>%
    hc_tooltip(
      headerFormat = "<b>{point.x}</b> <br>",
      pointFormat = paste0(vt.yaxis, ": <b>{point.y:.1f}%</b>")
    )
  
  hc
})





