#=====================================================================#
# About this programme
# Programme: "ui - SFY.R"
# Objective: ui script for SFY panel
#
# Key components:
#          1.panel_sfy()
#          2.sfy_xxx()
#
# Author: Ethan Li Created on 13/03/2017
# ====================================================================#


### panel ui ----
panel_sfy <- function() {
  
  tabPanel(
    "Services for children and youth",
    value = "Services for children and youth",
    
    fluidPage(
      fluidRow(
        column(
          width = 2,
          sfy_control()
        ),
        column(
          width = 10,
          tags$p(
            "This page shows information about the use of ",
            strong("services by children and youth"),
            " at risk, and how this varies across the country. It presents a selection of education and employment services, but will expand into other areas in future."
          ),
          tabBox(
            width = 12,
            id="orange_tabBox",
            tabPanel(
              "Service use by risk group",
              sfy_analysis()
            ),
            sfy_background()
          )
        )
      )
    )
  ) 
}


### ----
sfy_analysis <- function() {
  fluidRow(
    column(
      width = 6,
      uiOutput("sfy_param_serv_highlight"),
      sfy_ov()
    ),
    column(
      width = 6,
      fluidRow(
        column(
          width = 4,
          valueBoxOutput("sfy_hl_01", width = 12)
        ),
        column(
          width = 4,
          valueBoxOutput("sfy_hl_05", width = 12)
        ),
        column(
          width = 4,
          valueBoxOutput("sfy_hl_03", width = 12)
        )
      ),
      # fluidRow(
      #   column(
      #     width = 6,
      #     valueBoxOutput("sfy_hl_02", width = 12)
      #   ),
      #   column(
      #     width = 6,
      #     valueBoxOutput("sfy_hl_04", width = 12)
      #   )
      # ),
      tabBox(
        width = 12,
        id="orange_tabBox",
        sfy_venn(),
        sfy_map()
      )
    )
  )
}

### master control ----
sfy_control <- function() {
  box(
    title = "User Inputs:",
    status = "warning",
    id = "orange_box",
    width = 12,
 
    selectInput(
      inputId = "sfy_param_year", 
      label = "Year of Interest",
      choices = unique(vt.init_sfy_param_year_select),
      selected = vt.init_sfy_param_year
    ),
    
    selectInput(
      inputId = "sfy_param_serv_type", 
      label = "Service Type",
      choices = vt.init_sfy_param_serv_type_select,
      selected = vt.init_sfy_param_serv_type
    ),
    
    selectInput(
      inputId = "sfy_param_age", 
      label = "Age Group",
      choices = vt.init_sfy_param_age_select,
      selected = vt.init_sfy_param_age
    ),
    
    selectInput(
      inputId = "sfy_param_other_ind", 
      label = vt.init_sfy_param_other_ind_title,
      choices = vt.init_sfy_param_other_ind_select,
      selected = vt.init_sfy_param_other_ind
    ),
    
    radioButtons(
      inputId = "sfy_param_period", 
      label = "Time Period",
      choices = vt.init_sfy_param_period_select,
      selected = vt.init_sfy_param_period,
      inline = TRUE
    ),
    actionButton(
      inputId = "sfy_param_refresh",
      "Refresh",
      icon = icon("refresh")
    )
  )
}

### histograms ----
sfy_ov <- function() {
  fluidRow(
    column(
      width = 12,
      br(),
      fluidRow(
        column(
          width = 12,
          highchartOutput("sfy_hist_serv", height = "500px")#,
        )
      ),
      uiOutput("sfy_param_risk_highlight"),
      fluidRow(
        column(
          width = 12,
          highchartOutput("sfy_hist_risk", height = "300px")#,
        )
      ) 
    )
  )
}



### map ----
sfy_map <- function() {
  tabPanel(
    "Map of service and risk group overlap",
    value = "comp_sfy_map",
    leafletOutput("sfy_map", height = "650px"),
    absolutePanel(
      top = 70, 
      left = 70,
      radioButtons(
        inputId = 'sfy_map_risk_serv_switch',
        label = "Proportion in Risk or Services: ",
        choices = vt.init_sfy_param_switch_risk_serv_list,
        selected = vt.init_sfy_param_switch_risk_serv
      ),
      actionButton(
        "sfy_map_reset",
        "Reset Map",
        icon = icon("refresh")
      ),
      downloadButton(
        "sfy_map_download", 
        "Download Data"
      )
    )
  )
}

### venn diagram ----
sfy_venn <- function() {
  tabPanel(
    "Venn Diagram",
    value = "comp_sfy_venn",
    uiOutput("sfy_venn_title"),
    div(
      align = "center",

      conditionalPanel(
        condition = "output.sfy_venn_warn == 'pass'",
        plotOutput("sfy_venn", height = "650px")
      ),
      conditionalPanel(
        condition = "output.sfy_venn_warn != 'pass'",
        div(
          style = "display:table-cell; text-align: center; vertical-align: middle; height: 700px;",
          h1(strong(textOutput("sfy_venn_warn")))

        )
      )
    )
  )
}

### Bar Venn diagram ----
sfy_bar_venn <- function() {
  tabPanel(
    "Bar Venn Diagram",
    value = "comp_sfy_bar_venn",
    highchartOutput("sfy_bar_venn", height = "650px")
  )
}

### background tab ----
sfy_background <- function() {
  tabPanel(
    "Background",
    value = "comp_sfy_background",
    div(
      column(
        width = 1
      ),
      column(
        width = 10,
        fluidRow(
          br(),
          tags$p(
            strong("Services for children and youth"),
            " provides information about education services used by young people aged 6 to 19 and employment services used by young people aged 15 to 24 in New Zealand.  It shows the extent to which at-risk children and youth are accessing these services, and maps the overlap between risk groups and service users in different parts of the country.",
            p(),
            "IDI data on the services people access is limited. Employment and education are two areas where a lot of data on government-funded services is available, but not all services are included. In many cases government agencies, such as the Ministry of Education, do not collect information about which individuals access which services. For example, schools may have access to a number of different services to meet the needs of a particular child.  Some of this service information is not provided to the Ministry and cannot be presented in ",
            strong("Insights."),
            strong("Insights"),
            "does not present information where services are not funded by government.",
            p(),
            strong("Education services"),
            " presented for 6-14 year olds are: ",
            tags$ul(
              tags$li("Correspondence School - Students who study by correspondence at Te Aho o Te Kura Pounamu (Correspondence school) instead of attending a physical school."),
              tags$li("Interim Response Fund - A fund that is available to keep students engaged in learning following a significantly challenging behavioural event. It gives funding for a short term response while a more comprehensive plan is developed."),
              tags$li("Reading Recovery - An early intervention for students making limited progress in reading and writing after their first year at school."),
              tags$li("Resource Teachers: Learning and Behaviour (RTLB) - RTLB teachers are funded to work with teachers and schools to find solutions to support students in Years 1-10 with learning and/or behaviour difficulties. This information is not available after 2013."),
              tags$li("Special Education - Children can access different Special Education services. Services include communication, behaviour, and early intervention services, the Ongoing and Reviewable Resourcing Scheme (ORRS), High Health, and where a child attends secondary school over age 19, or primary school over age 14."),
              tags$li("Truancy (Non-Attendance) - A student may be referred to truancy services when they are enrolled at a school but don't attend classes. This data is only available from 2013 onwards."),
              tags$li("Truancy (Non-Enrolment) - A student is referred to truancy services when they leave a school but aren't re-enrolled in another school within 20 school days.")
            ),
            p(),
            "Additional ",
            strong("Education services"),
            " presented for 15-19 year olds are: ",
            tags$ul(
              tags$li("Alternative Education - 15 year old students who cannot settle into the school environment are offered an alternative education outside the school."),
              tags$li("Gateway Programme - The Gateway service provides year 11+ school students with the opportunity to access learning opportunities in the workplace."),
              tags$li("Industry Training - Delivered to people in employment, helping support the development of skills that meet industry needs."),
              tags$li("Secondary-Tertiary Programme - Provide vocational education opportunities for secondary school students, such as through Trades Academies."),
              tags$li("Student Allowance - A weekly payment to help with living expenses while studying full-time. Eligibility is dependent on personal income, parental income, living situation, and having dependants."),
              tags$li("Youth Guarantee: Fees-Free - Provides fees-free tertiary education for students aged 16-19 years who have no or low prior qualification achievement.")
            ),
            strong("Employment services"),
            " are funded by the Ministry of Social Development, and often delivered by Work and Income. In most cases information is presented by the type of service, instead of for individual services:",
            tags$ul(
              tags$li("Information services - This includes careers guidance advice and seminars."),
              tags$li("Placement and matching services - Services that match people with jobs and help place them into job vacancies."),
              tags$li("Skills training services - Business training and advice, payments for course fees, industry partnerships, job-focussed training, and literacy/numeracy training."),
              tags$li("Wage subsidies - Payments to employers to incentivise them to hire, train, and retain disadvantaged jobseekers, including those with disabilities."),
              tags$li("Other employment services - This includes a range of services, including those that build work confidence, involve people in work in the community or conservation work, grants to help setting up businesses, and job search assistance."),
              tags$li("Youth Service: Youth Payment/Young Parent Payment (YP/YPP) - Youth Service provides mentoring services for young people. Young people aged 16 or 17 who do not have the support of a parent or guardian, and young parents aged 16 to 18, may be eligible to receive either YP or YPP respectively. Young people receiving YP or YPP must take part in Youth Service."),
              tags$li("Youth Service: NEET or Youth Transition Service - Mentoring service for 16 or 17 year old young people at risk of becoming NEET. Youth Transition Service was superseded by YS: NEET in mid-2012.")
            ),
            "Information on the use of education services by 15-19 year olds can be restricted to those who were enrolled in education in the year of interest by using the ",
            strong("Subset to"),
            " user input. Similarly, information on the use of employment services can be restricted to those young people who received a benefit in that year. Service use can be looked at over the last year (the year of interest) or over the last five years.",
            p(),
            "At-risk children and youth are more likely to need support to achieve good outcomes. Different services are targeted in different ways to meeting these needs. While some services are offered to a broad group of young people, others are targeted at a specific high-needs group, or are in reaction to a poor outcome occurring (such as non-attendance at school). As such, we would expect the extent of the overlap between risk groups and services to vary by service. The overlap could vary across the country for a number of different reasons, including access issues, differing local area needs, or different choices about the use of alternative services.",
            p(),
            "Information on other types of service, such as health services, will be added to ",
            strong("Insights"),
            " over time. As new service data is added to the IDI, the range of services covered will continue to expand, providing a more comprehensive picture about which young people are accessing which services, and where. "
          )
        )
      )
    )
  )
}