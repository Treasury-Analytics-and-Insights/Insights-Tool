#=====================================================================#
# About this programme
# Programme: "ui - TYO.R"
# Objective: ui script for TYO panel
#
# Key components:
#          1.panel_tyo()
#          2.tyo_xxx()
#
# Author: Danny Wu Created on 14/03/2017
# ====================================================================#

panel_tyo <- function() {
  
  tabPanel(
    "Youth transitions to adulthood",
    value = "Youth transitions to adulthood",
    
    fluidPage(
      fluidRow(
        column(
          width = 2,
          tyo_master_control()
        ),
        column(
          width = 10,
          tags$p(
            "This page shows outcomes for ",
            strong("youth as they transition to adulthood."),
            "It shows where they are doing well, where they may need additional support, and the parts of the country where the need is greatest."
          ),
          tabBox(
            width = 12,
            id="green_tabBox",
            tyo_analysis(),
            tyo_comparison(),
            tyo_map(),
            tyo_background()
          )
        )
      )
    ) 
  )
}

### analysis panel ----
tyo_analysis <- function() {
  tabPanel("Youth transitions",
           value = "comp_tyo_analysis",
           fluidPage(
               column(
                 width = 6,
                 tabBox(
                   width = 12,
                   id = "green_tabBox",
                   tabPanel(title = "Main activities at ages 15 to 24",
                            radioButtons(
                              inputId = 'tyo_param_an_risk',
                              label = "Number of risk indicators at age 15:",
                              choices = vt.init_tyo_param_an_risk_list,
                              selected = vt.init_tyo_param_an_risk,
                              inline = TRUE
                            ),
                            selectInput(
                              inputId = "tyo_param_an_eth", 
                              label = "Ethnicity:",
                              choices = vt.init_tyo_param_eth_list,
                              selected = vt.init_tyo_param_eth
                            ),
                            highchartOutput("tyo_stacked_chart_main", height = "600px"))
                 )
               ),
               column(
                 width = 6,
                 tabBox(
                   width = 12,
                   id = "green_tabBox",
                   tabPanel(
                     title = "Employment and benefit outcomes",
                     highchartOutput("tyo_bar_chart", height = "700px")
                   )
                 ))
             )
    )
}

### master control -----
tyo_master_control <- function() {  
  box(
    title = "User Inputs:",
    status = "success",
    id = "green_box",
    width = 12,
    selectInput(
      inputId = "tyo_param_year",
      label = "Year of Interest",
      choices = vt.init_tyo_param_year_select,
      selected = vt.init_tyo_param_year
    ),
    radioButtons(
      inputId = "tyo_param_gender",
      label = "Gender",
      choices = vt.init_tyo_param_gender_list,
      selected = vt.init_tyo_param_gender,
      inline = TRUE
    )
    # actionButton(
    #   "tyo_param_refresh",
    #   "Refresh",
    #   icon = icon("refresh")
    # )
  )
}

### map ----
tyo_map <- function() {
  tabPanel(
    "Outcomes map",
    value = "comp_tyo_map",
    fluidRow(
      column(
        width = 7,
        leafletOutput(
          "tyo_map", 
          width = "100%", 
          height = "850px"
        ),
        absolutePanel(
          top = 10, 
          left = 50,
          column(
            width = 8,
            selectInput(
              inputId = "tyo_param_map_trac_ind",
              label = "Select Outcome:",
              choices = vt.init_tyo_param_map_trac_ind_list,
              selected = vt.init_tyo_param_map_trac_ind
            ),
            radioButtons(
              inputId = "tyo_param_map_age_group", 
              label = "Select Age Group:",
              choices = vt.init_tyo_param_map_age_group_list,
              selected = vt.init_tyo_param_map_age_group
            ),
            radioButtons(
              inputId = 'tyo_param_map_risk',
              label = "At Risk? ",
              choices = vt.init_tyo_param_map_risk_list,
              selected = vt.init_tyo_param_map_risk
            ),
            checkboxInput(
              inputId = "tyo_param_map_metric",
              label = "Percentage?",
              value = vt.init_tyo_param_map_metric
            ),
            actionButton(
              "tyo_param_map_refresh",
              "Reset Map",
              icon = icon("refresh")
            ),
            br(),
            downloadButton(
              "tyo_map_download", 
              "Download Data"
            )
          )
        )
      ),
      column(
        width = 5,
        fluidRow(
          width = 12,
          box(
            style='padding:0px;',
            width = 12,
            status = "success",
            title = "Selected outcome by area",
            plotOutput("tyo_map_bar_chart", height = "500px")
          )
        ),
        fluidRow(
          width = 12,
          box(
            width = 12,
            status = "success",
            title = "Gender comparison across areas",
            plotOutput("tyo_map_bubble_chart", height = "200px"),
            h6(textOutput("tyo_map_footer"), align = "center")
            #footer = h6(textOutput("tyo_map_footer"), align = "center")
          )
          
        )
      )
    )
  )
}

tyo_comparison <- function() {
  tabPanel(
    title = "Outcomes by risk",
    fluidRow(
      alignCenter(selectInput(
              width = '200px',
              inputId = "tyo_param_com_eth", 
              label = "Ethnicity:",
              choices = vt.init_tyo_param_eth_list,
              selected = vt.init_tyo_param_eth
            )),
            plotlyOutput('tyo_facet_chart', height = "650px")
        )
      )
}

tyo_background <- function() {
  tabPanel(
    "Background",
    value = "comp_tyo_background",
    div(
      column(
        width = 1
      ),
      column(
        width = 10,
        fluidRow(
          br(),
          tags$p(
            strong("Youth transitions to adulthood"),
            " provides information about the activities and outcomes of young people aged 15 to 24 in New Zealand. It shows the main activities they are undertaking as they transition to adulthood, how many are in employment, and how many are receiving benefits. Results are presented for different risk groups and are mapped down to area unit level (the equivalent of a city suburb).",
            p(),
            "Activities and outcomes are tracked across time by looking at the interactions that young people have with government agencies. School and tertiary enrolment information from the Ministry of Education tells us whether a young person is in education, tax data from Inland Revenue tells us whether they are working, and data from the Department of Corrections tells us if they are in prison.",
            p(),
            "Young people can be engaged in many different activities in a particular year. We look at the activities they were undertaking each month and average these across the year. Where someone is overseas in a particular month that month is excluded.",
            p(),
            "The ",
            strong("main activity"),
            " being undertaken is derived using a prioritised list. If a young person is doing multiple activities, the one that is highest in the list is used. Apart from being in custody (which has the highest priority), the lower an activity is in the graph the higher priority it is given. For example, if a young person is in school and in limited employment in a particular month, they are only counted as being at school. ",
            p(),
            tags$ul(
              tags$li("If a person spent more than 15 days in a particular month in custody or overseas, that is considered to be their main activity for the month."),
              tags$li("Education and employment activities are defined where a person spent at least 1 day of a month enrolled in school or in a tertiary course that equates to more than half of an Equivalent Fulltime Student (EFTS), or they earned at least $10 in the month."),
              tags$li("Where a young person had self-employment income in a tax year, it is not possible to determine in which months it was earned. The earnings are distributed across the year, while negative values are treated as zero income."),
              tags$li("Substantial employment is where a young person earned more than a person working 30 hours at the adult minimum wage would have earned in a month, while limited employment is where they earned less than that amount in a month."),
              tags$li("NEET means a young person is 'Not in Employment, Education or Training'. They may or may not be receiving a benefit, but there is no information to suggest they are in employment, education or training. In some cases they may be in an unpaid caring role, or another unpaid role. A young person is considered to be long-term NEET if their main activity is NEET for six months or more at a time.")
            ),
            "Separate measures of youth ",
            strong("on benefit"),
            " and ",
            strong("in employment"),
            " are also reported. These are not prioritised. A young person's main activity in a month may be tertiary education, but if they also have earnings and are on benefit they will be counted as being both ",
            strong("on benefit"),
            " and ",
            strong("in employment"),
            ".",
            p(),
            "Data can be mapped as either the percentage of months spent engaged in each activity over the year, or as the number of person-years spent engaged in the activity (calculated by dividing the total number of months by 12)."
            )
        )
      )
    )
  )
}
