#=====================================================================#
# About this programme
# Programme: "CYAR - ui.R"
# Objective: ui script for CYAR panel
#
# Key components:
#          1.panel_cyar()
#          2.cyar_xxx()
#
# Author: Ethan Li Created on 19/03/2017
# ====================================================================#

### panel ui ----
panel_cyar <- function() {
  tabPanel("Children and youth at risk",
           value = "Children and youth at risk",
           
           fluidPage(
             fluidRow(
               column(id = "blue_column",
                      width = 2,
                      cyar_control()),
               column(width = 10,
                      tags$p(
                        "This page describes different groups of ",
                        strong("children and youth at risk,"),
                        "shows the outcomes they are projected to achieve without additional support, and maps their location so services can be better targeted to meet their needs."
                      ),
                      tabBox(
                        width = 12,
                        id = "blue_tabBox",
                        cyar_analysis(),
                        cyar_background()
                      ))
            )
           )
  )
}

### analysis panel ----
cyar_analysis <- function() {
  tabPanel("Analysis",
           value = "comp_cyar_analysis",
           fluidPage(
             column(
               id = "blue_column",
               width = 5,
               cyar_ov()
             ),
             column(
               width = 7,
               fluidRow(
                 cyar_headlines()
               ),
               tabBox(
                 width = 12,
                 id="blue_tabBox",
                 tabPanel(
                   "Ethnicity Comparision",
                   cyar_ethic()
                 ),
                 tabPanel(
                   "Projected outcomes",
                   cyar_hist()
                 ),
                 tabPanel(
                   "Risk map",
                   cyar_map()
                 )
               )
             )
           )
  )
}


### master control ----
cyar_control <- function() {
  box(
    title = "User Inputs:",
    id = "blue_box",
    width = 12,
    selectInput(
      inputId = "cyar_param_year",
      label = "Year of Interest",
      choices = vt.init_cyar_param_year_select,
      selected = vt.init_cyar_param_year
    ),
    radioButtons(
      inputId = "cyar_param_age",
      label = "Age Group",
      choices = unique(vt.init_cyar_param_age_select),
      selected = vt.init_cyar_param_age,
      inline = FALSE
    ),
    actionButton(
      inputId = "cyar_param_refresh",
      "Refresh",
      icon = icon("refresh")
    )
  )
}

### venn diagram & histogram ----
cyar_ov <- function() {
  fluidPage(
    
    fluidRow(
      column(
        width = 12,
        selectInput(
          inputId = "cyar_param_risk_ind",
          label = "Risk Group",
          choices = vt.init_cyar_param_risk_ind_select,
          selected = vt.init_cyar_param_risk_ind, 
          width = "70%"
        )
      )
    ),
    br(),
    br(),
    br(),
    uiOutput("cyar_risk_circle_highlight"),
    br(),
    fluidRow(
      column(
        width = 12,
        div(
          align = "center",
          imageOutput('cyar_risk_circle')  
        )
      )
    )
  )
}

### headlines ----
cyar_headlines <- function() {
  fluidRow(
    column(
      width = 6,
      valueBoxOutput("cyar_hl_01", width = 12)
    ),
    column(
      width = 6,
      valueBoxOutput("cyar_hl_02", width = 12)
    )
  )
}

### map ----
cyar_map <- function() {
  fluidRow(
    column(
      width = 12,
      id = "blue_column",
      h4(textOutput("cyar_map_title"), align = "center"),
      leafletOutput("cyar_map", height = "800px"),
      absolutePanel(
        top = 50, 
        left = 60,
        radioButtons(
          inputId = "cyar_param_gender_ind",
          label = "Gender:",
          choices = vt.init_cyar_param_gender_select,
          selected = vt.init_cyar_param_gender
        ),
        checkboxInput(
          inputId = "cyar_param_sd_loc",
          label = "Percentage?",
          value = TRUE
        ),
        actionButton(
          "cyar_map_reset",
          "Reset Map",
          icon = icon("refresh")
        ),
        downloadButton(
          "cyar_map_download", 
          "Download Data"
        )
      )
    )
  )
}


cyar_hist <- function() {
  tabPanel(
    title = "Projected outcomes",
    fluidRow(
      column(
        width = 12,
        highchartOutput("cyar_hist_oc", height = "800px")
      )
    )
  )
}

cyar_ethic <- function() {
  tabPanel(
    title = "Ethnicity Comparison",
    fluidRow(
      box(
        title = "User Input:",
        width = 12,
        status = "info",
        id = "blue_box",
        column(
          width = 6,
          radioButtons(
            inputId = "cyar_param_natinal_gender_ind",
            label = "Gender:",
            choices = vt.init_cyar_param_gender_select,
            selected = vt.init_cyar_param_gender,
            inline = TRUE
          )
        )
      )
    ),
    fluidRow(
      highchartOutput("cyar_hist_eth", height = "620px")
    )
  )
}

cyar_background <- function() {
  tabPanel(
    "Background",
    value = "comp_cyar_background",
    div(
      column(
        width = 1
      ),
      column(
        width = 10,
        fluidRow(
          br(),
          tags$p(
            strong("Children and youth at risk "),
            "provides information about children and youth at risk of poor future outcomes. It shows the different outcomes at-risk children and youth are expected to achieve without additional support, and maps the location of different risk groups down to area unit level (the equivalent of a city suburb).",
            p(),
            strong("Children at risk "),
            "are identified using four risk indicators:",
            tags$ul(
              tags$li("Having a Child Youth & Family finding of abuse or neglect "),
              tags$li("Being mostly supported by benefits since birth "),
              tags$li("Having a parent with a prison or community sentence "),
              tags$li("Having a mother with no formal qualifications ")
	      ),
            br(),
            "Children who have these indicators are more likely to leave school with no qualifications, to spend time on benefit, and to receive a prison or community sentence when they grow up. The greater the number of indicators a child has, the more likely this will happen. ",
            p(),
            "Children aged 0 to 5 and aged 6 to 14 are represented separately, according to whether they have two or more risk indicators, three or more risk indicators, or all four risk indicators. More information about these risk indicators can be found in ", 
            a(href = "http://www.treasury.govt.nz/publications/research-policy/ap/2016/16-01/", "Characteristics of Children at Greater Risk of Poor Outcomes as Adults."),
            p(),
            strong("Youth at risk"),
            " are identified as being in one or more of ten target populations: ",
            br()
          ),
          column(
            width = 6,
            tags$p(
              strong("15 to 19 year olds "),
              tags$ul(
                tags$li("Teenage boys with Youth Justice or Corrections history"),
                tags$li("Teenagers with health, disability issues or special needs"),
                tags$li("Teenage girls supported by benefits"),
                tags$li("Mental health service users with stand-down or CYF history"),
                tags$li("Experienced significant childhood disadvantage")
              )
            )
          ),
          column(
            width = 6,
            tags$p(
              strong("20 to 24 year olds "),
              tags$ul(
                tags$li("Young offenders with a custodial sentence"),
                tags$li("Young offenders with a community sentence and CYF history"),
                tags$li("Jobseekers in poor health with CYF history"),
                tags$li("Sole parents not in fulltime employment with CYF history"),
                tags$li("Long-term disability beneficiaries")
              )
            )
          ),
          tags$p(
            "Youth in target populations are more likely than other young people to not achieve a level 2 qualification, to be on benefit long-term, to receive a prison or community sentence, or to need mental health services. Different target populations are likely to have different needs, and require different services to meet those needs. Some young people may be in more than one target population. More information about how these target populations are identified can be found in",
            a(href = "http://www.treasury.govt.nz/publications/research-policy/ap/2015/15-02/", "Using Integrated Administrative Data to Identify Youth Who Are at Risk of Poor Outcomes as Adults."),
            p(),
            "The methods used to estimate future outcomes and costs are designed to provide a comparative picture of future outcomes and costs for different population subgroups, but they have some significant limitations. These estimates should be viewed as indicative, and not as forecasts of the actual outcomes and costs that will be incurred in the future.",
            p(),
            "Projected costs are in 2013 dollars and cover benefit payments, costs associated with serving sentences administered by the Department of Corrections, and costs associated with the services provided by CYF in childhood."
          )
        )
      )
    )
  )
}