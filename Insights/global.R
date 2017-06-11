#### Section 01: Setup ----
### libraries control
# require(checkpoint)
# ## comment on the your own checkpoint eval when finished
# dir.lib_checkpoint <- "D:/R" # local
# 
# checkpoint("2017-03-10", R.version = "3.3.1",
#            checkpointLocation = dir.lib_checkpoint)

### libraries
## data managements
require(tidyverse)
require(lubridate)
require(stringr)

## dashboard framework
require(shiny)
require(shinydashboard)
require(shinyBS)

## charts
require(leaflet)
require(DT)
require(highcharter)
require(VennDiagram)
require(treemap)

## TYO plotly charts
require(plotly)
require(scales)

## spatial
require(sp)
require(rgdal)

rm(list = ls()); gc()

### directories
dir.input <- "data"
dir.src <- "scripts"
dir.tools <- "tools"
dir.cyar_circles <- "data/venn diagrams"

### utility functions
source(file.path(dir.src, "utility functions.R"))
source(file.path(dir.src, "treasury style.R"))

### dashboard components
source(file.path(dir.tools, "treasury-styles.R"))
source(file.path(dir.tools, "intro-pages.R"))
source(file.path(dir.tools, "SFY - ui.R"))
source(file.path(dir.tools, "TYO - ui.R"))
source(file.path(dir.tools, "CYAR - ui.R"))

### data 
load(file.path(dir.input, "CYAR Dashboard Data - SFY.rda"))
load(file.path(dir.input, "CYAR Dashboard Data - TYO.rda"))
load(file.path(dir.input, "CYAR Dashboard Data - CYAR.rda"))
load(file.path(dir.input, "CYAR Dashboard Data - Shapefiles.rda"))
df.meta_control <- read_csv(file.path(dir.input, "meta - control.csv"))
df.treasury_color <- read_csv(file.path(dir.input, "Treasury Colour Patterns.csv"))

### initial reactive values ----
source(file.path(dir.tools, "SFY - global.R"))
source(file.path(dir.tools, "TYO - global.R"))
source(file.path(dir.tools, "CYAR - global.R"))