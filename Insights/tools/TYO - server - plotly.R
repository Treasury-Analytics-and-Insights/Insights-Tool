#=====================================================================#
# About this programme
# Programme: "TYO - server - plotly.R"
# Objective: plotly plot for TYO panel
#
# Key components:
#          1.tyo_facet_chart
#
# Author: Danny Wu Created on 15/03/2017
# ====================================================================#

output$tyo_facet_chart = renderPlotly({
  p = df.db_tyo %>%
    filter(
      YEAR == input$tyo_param_year, 
      GENDER == input$tyo_param_gender,
      ETHNICITY %in% input$tyo_param_com_eth#,
      # !TRAC_IND %in% c("On Benefit", "Earning Wage/Salary")
    ) %>%
    filter(
      RISK_FACTOR %in% c("<2 Risk Indicators", "2+ Risk Indicators")
    ) %>%
    # mutate(RISK_FACTOR = ifelse(RISK_FACTOR=="<2 Risk Factors", "No At Risk", "At Risk")) %>%
    mutate(TRAC_IND = replace(TRAC_IND, TRAC_IND %in% 'Long term neets (6+ Months)', 'Long term NEET (6+ Months)')) %>%
    mutate(TRAC_IND = replace(TRAC_IND, TRAC_IND %in% 'Short term neets (<6 Months)', 'Short term NEET (<6 Months)')) %>%
    mutate(TRAC_IND = factor(TRAC_IND, 
                             levels = c('In Custody', 
                                        'Long term NEET (6+ Months)', 
                                        'Short term NEET (<6 Months)', 
                                        'In Substantial Employment (with industry training)', 
                                        'In Substantial Employment (without industry training)', 
                                        'In Limited Employment', 
                                        'In Tertiary Education',
                                        'In School',
                                        "On Benefit", 
                                        "In Employment"
                             ), 
                             ordered = TRUE)) %>%
    mutate(Proportion=sprintf("%1.1f%%<br>%s<br>%s Years", COUNT, RISK_FACTOR, AGE)) %>%
    ggplot(aes(x = AGE, y = COUNT, fill = RISK_FACTOR, label = Proportion)) +
    geom_area(position = "identity", alpha = 0.4) +
    scale_fill_manual(
      values = c(
        vt.tyo_col_green_d2,
        vt.tyo_col_green_d3)
    ) +
    facet_wrap(~TRAC_IND, nrow = 3, ncol = 4, scales = "free") +
    scale_x_continuous(breaks = c(15:24), expand = c(0, 0)) +
    scale_y_continuous(labels = x_percent, expand = c(0, 0)) +
    geom_vline(xintercept = c(15:24), color="white", size=0.5) +
    ylab(" ") +
    xlab(paste0("Age as at December ", input$tyo_param_year)) +
    theme(
      panel.background = element_rect(fill = "white"),
      legend.position = "top",
      legend.title = element_blank(),
      strip.text = element_text(size = 6)
    )

  ggplotly(p, height = 650,
           tooltip = 'label'
  ) %>%
    layout(
      legend = list(orientation = 'h', x = 0.35, y = 1.10),
      hovermode="compare")
})
