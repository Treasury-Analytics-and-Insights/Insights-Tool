
# This is the user-interface definition of a Shiny web application.
# You can find out more about building applications with Shiny here:
#
# http://shiny.rstudio.com
#

shinyUI(
  
  bootstrapPage(
    title = "Insights",
    thead = tagList(
      tags$head(
        includeCSS("www/css/treasury-fronts.css"),
        includeCSS("www/css/cost-header.css"),
        includeCSS("www/css/AdminLTE.css"),
        includeCSS("www/css/shinydashboard.css"),
        includeCSS("www/css/custom.css")
      ),
      div(class = "container-fluid", treasury_header())
    ),
    div(
      class = "container-fluid",
      navbarPage(
        title = "",
        # title = treasury_header(),
        # selected = "comp_cyar",
        selected = "Home",
        panel_intro(),
        panel_cyar(),
        panel_tyo(),
        panel_sfy(),
        treasury_about(),
        treasury_contact(),
        treasury_privacy()
      )
    ),
    tags$script(src = "js/intropage_clickable.js"),
    treasury_footer()
  )
)