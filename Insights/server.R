
# This is the server logic for a Shiny web application.
# You can find out more about building applications with Shiny here:
#
# http://shiny.rstudio.com
#


shinyServer(function(input, output, session) {
  
  ### SFY Panel ----
  source(file.path(dir.tools, "SFY - server - misc.R"), local = TRUE)
  source(file.path(dir.tools, "SFY - server - master control.R"), local = TRUE)
  source(file.path(dir.tools, "SFY - server - histograms.R"), local = TRUE)
  source(file.path(dir.tools, "SFY - server - map.R"), local = TRUE)
  source(file.path(dir.tools, "SFY - server - headlines.R"), local = TRUE)
  
  ### TYO Panel ----
  source(file.path(dir.tools, "TYO - server - misc.R"), local = TRUE)
  source(file.path(dir.tools, "TYO - server - map.R"), local = TRUE)
  source(file.path(dir.tools, "TYO - server - plotly.R"), local = TRUE)
  source(file.path(dir.tools, "TYO - server - highcharts.R"), local = TRUE)
  
  ### CYAR Panel ----
  source(file.path(dir.tools, "CYAR - server - misc.R"), local = TRUE)
  source(file.path(dir.tools, "CYAR - server - headlines.R"), local = TRUE)
  source(file.path(dir.tools, "CYAR - server - map.R"), local = TRUE)
  source(file.path(dir.tools, "CYAR - server - histograms.R"), local = TRUE)

})
