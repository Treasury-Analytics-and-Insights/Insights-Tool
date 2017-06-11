panel_intro <- function() {
  tabPanel(
    "Home",
    icon = icon("home"),
    fluidPage(
      column(
        width = 2
      ),
      column(
        width = 5,
        h1("Welcome to Insights"),
        column(
          width = 10,
          h2("Informing policies and services through better information.")
        ),
        column(
          width = 11,
          h3(strong("Insights")," provides information drawn from a range of public sector agencies and presents it in an easy to use interactive format which includes data visualisation and mapping tools.")
        ),
        column(
          width = 12,
          tags$p(tags$span("This work is part of the Treasury's commitment to higher living standards
                           and a more prosperous, inclusive New Zealand. Insights enables the
                           analysis and understanding needed to improve social and economic
                           outcomes for all New Zealanders. All information is anonymous - no
                           individuals are identified through this analysis."))
        ),
        column(
          width = 12,
          tags$p(tags$span("For more detailed information about Insights and the data behind it see ",
          tags$a(
            href = "http://www.treasury.govt.nz/publications/research-policy/ap/2017/17-02",
            "Insights - informing policies and services for at-risk children and youth"),
	  "."))
        )
      ),
      column(
        width = 5,
        id = "aoa_links",
        h1("Areas of Analysis"),
        br(),
        tags$a(
          href = "#",
          h3(
            "Children and youth at risk",
            style = "background-color: #00BCE2; padding: 20px; width: 65%;"
          )
        ),
        tags$a(
          href = "#",
          h3(
            "Youth transitions to adulthood", 
            style = "background-color: #24994B; padding: 20px; width: 65%;"
          )
        ),
        tags$a(
          href = "#",
          h3(
            "Services for children and youth", 
            style = "background-color: #F1A42D; padding: 20px; width: 65%;"
          
          )
        )
        
      )
    )
  )
}