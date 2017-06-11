#=====================================================================#
# About this programme
# Programme: "TYO - server - highcharts.R"
# Objective: highchart plot for TYO panel
#
# Key components:
#          1.output$tyo_stacked_chart_main
#          2.output$tyo_bar_chart
#
# Author: Danny Wu Created on 15/03/2017
# ====================================================================#

### stacked area chart   ----
## plot ----
output$tyo_stacked_chart_main <- renderHighchart({
  
  hc <- df.db_tyo %>%
    filter(
      YEAR == input$tyo_param_year, 
      GENDER == input$tyo_param_gender, 
      RISK_FACTOR == input$tyo_param_an_risk,
      ETHNICITY %in% input$tyo_param_an_eth,
      !TRAC_IND %in% c("On Benefit", "In Employment")
    ) %>%
    mutate(TRAC_IND = replace(TRAC_IND, TRAC_IND %in% 'Long term neets (6+ Months)', 'Long term NEET (6+ Months)')) %>%
    mutate(TRAC_IND = replace(TRAC_IND, TRAC_IND %in% 'Short term neets (<6 Months)', 'Short term NEET (<6 Months)')) %>%
    mutate(TRAC_IND = factor(TRAC_IND, 
                             levels = c('In Custody', 
                                        'Long term NEET (6+ Months)', 
                                        'Short term NEET (<6 Months)', 
                                        'In Limited Employment', 
                                        'In Substantial Employment (without industry training)',
                                        'In Substantial Employment (with industry training)', 
                                        'In Tertiary Education',
                                        'In School'
                             ), 
                             ordered = TRUE)) %>%
    hchart(
      type = "area",
      hcaes(
        x = AGE, 
        y = COUNT, 
        group = TRAC_IND
      )
    ) %>%
    # hc_title(text = "Outcomes' percentage against each age") %>%
    hc_colors(c(vt.tyo_col_orange_d3, 
                vt.tyo_col_orange_d2, 
                vt.tyo_col_orange_d1, 
                vt.tyo_col_green_d3, 
                vt.tyo_col_green_d2, 
                vt.tyo_col_green_d1, 
                vt.tyo_col_blue_d3, 
                vt.tyo_col_blue_d2)) %>%
    hc_yAxis(title = list(text = "Proportion of Months"),
             labels = list(format = '{value}%'),
             min = 0,
             max = 100) %>%
    hc_xAxis(title = list(text = paste0("Age as at December ", input$tyo_param_year)),
             allowDecimals = FALSE) %>%
    hc_tooltip(
      headerFormat = "<b>Age: {point.x}</b> <br>",
      pointFormat = "{series.name}: <b>{point.y:.1f}%</b><br>"
    ) %>% 
    hc_plotOptions(
      series = list(stacking = "normal")
    ) %>%
    hc_exporting(enabled = TRUE)

  hc
})


### bar chart   ----
## plot ----
output$tyo_bar_chart <- renderHighchart({
  hc <- df.db_tyo %>%
    filter(
      YEAR == input$tyo_param_year, 
      GENDER == input$tyo_param_gender, 
      RISK_FACTOR == input$tyo_param_an_risk,
      ETHNICITY %in% input$tyo_param_an_eth,
      TRAC_IND %in% c("On Benefit", "In Employment")
    ) %>%
    hchart(
      type = "column",
      hcaes(
        x = AGE, 
        y = COUNT, 
        group = TRAC_IND
      )
    ) %>%
    hc_xAxis(allowDecimals = FALSE) %>%
    # hc_title(text = "Employment v.s. Benefit") %>%
    hc_colors(c(vt.tyo_col_green_d2, 
                vt.tyo_col_green_d3)) %>%
    hc_yAxis(title = list(text = "Propotion of Months"),
             labels = list(format = '{value}%')) %>%
    hc_xAxis(title = list(text = paste0("Age as at December ", input$tyo_param_year))) %>%
    hc_tooltip(
      headerFormat = "<b>Age: {point.x}</b> <br>",
      pointFormat = "{series.name}: <b>{point.y:.1f}%</b><br>"
    ) %>% 
    hc_exporting(enabled = TRUE)
  
  hc
})
