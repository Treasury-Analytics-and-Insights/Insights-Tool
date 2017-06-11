#=====================================================================#
# About this programme
# Programme: "SFY - server - map.R"
# Objective: Server script for updating the map and related features in SFY panel
#
# Key data:
#          1.sfy_panel$map_data
#          2.sfy_panel$map
#          3.df.meta_control
#
# Author: Ethan Li Created on 13/03/2017
# ====================================================================#

### map data ----
df.sfy_map <- df.meta_control %>%
  filter(PROC %in% "sfy_map")

for (i in df.sfy_map$NAME) {
  local({
    vt.name_cur <- i
    vt.group_cur <- df.sfy_map %>%
      filter(NAME %in% vt.name_cur) %>%
      .[["GROUP"]]
    
    vt.trigger <- paste(vt.group_cur, vt.name_cur, sep = "$")
    
    observeEvent(eval(parse(text = vt.trigger)), {
      
      vt.param_risk_ind <- ifelse(is.null(sfy_panel$param_risk_ind), "All", sfy_panel$param_risk_ind)
      vt.param_serv_ind <- sfy_panel$param_serv_ind
      vt.param_sd_loc <- input$sfy_hist_sd_loc
      vt.param_risk_serv_switch <- input$sfy_map_risk_serv_switch
      vt.param_zoom_ind <- sfy_panel$param_zoom_ind
      vt.param_area_ind <- sfy_panel$param_area_ind
      df.map_data <- sfy_panel$map_data
      
      
      withProgress(message = 'Making plot', value = 0, {
        
        #browser()
        if (is.null(vt.param_area_ind)) {
          df.tmp_map_attr <- df.map_data %>%
            filter(AREA_TYPE %in% "Region")
          
          spldf.sfy_map <- spldf.nz_region
        } else {
          vt.area_select <- df.db_area_mapping %>% 
            filter(REGION %in% vt.param_area_ind) %>% 
            .[["TA"]] %>% 
            unique()
          
          df.tmp_map_attr <- df.map_data %>% 
            filter(AREA_CODE %in% vt.area_select)
          spldf.sfy_map <- spldf.nz_ta[spldf.nz_ta@data$AREA_CODE %in% vt.area_select, ]
          
        }
        
        if(vt.param_risk_serv_switch %in% "% of services users in risk group") {
          df.tmp_map_attr <- df.tmp_map_attr %>% 
            filter(RISK_DESC %in% vt.param_risk_ind) %>%
            mutate(COL_VAR  = PC_SERV)
        } else {
          df.tmp_map_attr <- df.tmp_map_attr %>% 
            filter(RISK_DESC %in% vt.param_risk_ind) %>%
            mutate(COL_VAR  = PC_RISK)
        }
        
        
        if (is.null(vt.param_serv_ind)) {
          df.tmp_map_attr <- df.tmp_map_attr %>%
            group_by(AREA_CODE) %>%
            summarise(COL_VAR = mean(COL_VAR, na.rm = TRUE))
        }
        else {
          df.tmp_map_attr <- df.tmp_map_attr %>%
            filter(SERV_IND %in% vt.param_serv_ind) %>%
            group_by(AREA_CODE) %>%
            summarise(COL_VAR = mean(COL_VAR, na.rm = TRUE))
        }
        
        spldf.sfy_map@data <- spldf.sfy_map@data %>%
          left_join(df.tmp_map_attr, by = "AREA_CODE")
        
        sfy_panel$test_data <- df.tmp_map_attr
        sfy_panel$map <- spldf.sfy_map
        
      })
      
      
    }, ignoreNULL = FALSE)
  })
}

### base map ----
output$sfy_map <- renderLeaflet({
  spldf.plot <- spldf.init_sfy_map
  #browser()
  vt.param_risk_serv_switch <- input$sfy_map_risk_serv_switch

  pal.vals = spldf.plot@data %>%
    filter(COL_VAR>0) %>%
    .[['COL_VAR']]
  pal.map <- colorNumeric(c(vt.sfy_col_blue_lightest, vt.sfy_col_blue_dark), pal.vals) 
  
  spldf.plot@data = spldf.plot@data %>%
    mutate(COLOUR = pal.map(COL_VAR)) %>%
    mutate(COLOUR = ifelse(!is.na(COLOUR), COLOUR, "#808080"))
  
  spldf.plot@data <- spldf.plot@data %>%
    mutate(LABEL = ifelse(COL_VAR>0,paste0(AREA_CODE, ' ', signif(COL_VAR, digits = 2), "%"), paste0(AREA_CODE, ' S' )))
  
  withProgress(message = 'Making plot', value = 0, {
    leaflet() %>%
      addProviderTiles(
        providers$Stamen.TonerLite,
        options = providerTileOptions(noWrap = TRUE)
      ) %>%
      addPolygons(
        data = spldf.sfy_map_ov,
        stroke = TRUE,
        color = "black",
        weight = 1,
        dashArray = c(5, 5),
        smoothFactor = 0.2,
        fillOpacity = 0,
        fillColor = "white",
        highlightOptions = highlightOptions(
          color='#ff0000',
          opacity = 1,
          weight = 2,
          fillOpacity = 1,
          sendToBack = TRUE
        ),
        label = ~AREA_CODE,
        layerId = ~paste0("base", AREA_CODE)
      ) %>%
      addPolygons(
        data = spldf.plot,
        fillColor = ~COLOUR,
        fillOpacity = 0.9,
        stroke = TRUE,
        weight = 1,
        color = "black",
        dashArray = c(5, 5),
        smoothFactor = 0.2,
        highlightOptions = highlightOptions(
          color='#ff0000',
          opacity = 1,
          weight = 2,
          fillOpacity = 1,
          sendToBack = FALSE
        ),
        label = ~LABEL,
        layerId = ~AREA_CODE
      ) %>%
      addLegend(position = "bottomright", 
                pal = pal.map,
                values = pal.vals,
                title = vt.param_risk_serv_switch, 
                layerId = "Legend")
  })


})

## map reset ----
df.sfy_map_reset <- df.meta_control %>%
  filter(PROC %in% "sfy_map_reset")


for (i in df.sfy_map_reset$NAME) {
  local({
    vt.name_cur <- i
    vt.group_cur <- df.sfy_map_reset %>%
      filter(NAME %in% vt.name_cur) %>%
      .[["GROUP"]]

    vt.trigger <- paste(vt.group_cur, vt.name_cur, sep = "$")

    observeEvent(eval(parse(text = vt.trigger)), {

      sfy_panel$param_zoom_ind <- "Region"
      sfy_panel$param_area_ind <- NULL

    }, ignoreNULL = FALSE)
  })
}


observeEvent(input$sfy_map_shape_click, {
  vt.param_shape_click <- gsub("base", "", input$sfy_map_shape_click$id)

  if (vt.param_shape_click %in% df.db_area_mapping$REGION) {
    sfy_panel$param_area_ind <- vt.param_shape_click
  }

})

### map update ----
observeEvent(sfy_panel$map, {
  
  spldf.plot <- sfy_panel$map

  vt.param_risk_serv_switch <- input$sfy_map_risk_serv_switch
  vt.shape_id_prev <- sfy_panel$prev_shape_id
  vt.shape_id <- unique(spldf.plot@data$AREA_CODE)

  mat.bbox <- bbox(spldf.plot)
  
  pal.vals = spldf.plot@data %>%
    filter(COL_VAR>0) %>%
    .[['COL_VAR']]
  
  pal.map <- colorNumeric(c(vt.sfy_col_blue_lightest, vt.sfy_col_blue_dark), pal.vals) 
  
  spldf.plot@data = spldf.plot@data %>%
    mutate(COLOUR = pal.map(COL_VAR)) %>%
    mutate(COLOUR = ifelse(!is.na(COLOUR), COLOUR, "#808080"))

  spldf.plot@data <- spldf.plot@data %>%
    mutate(LABEL = ifelse(COL_VAR>0,paste0(AREA_CODE, ' ', signif(COL_VAR, digits = 2), "%"), paste0(AREA_CODE, ' S' )))

  leafletProxy("sfy_map") %>%
    removeControl(layerId = "Legend") %>%
    removeShape(layerId = vt.shape_id_prev) %>%
    fitBounds(mat.bbox[1], mat.bbox[2], mat.bbox[3], mat.bbox[4]) %>%
    addPolygons(
      data = spldf.plot,
      fillColor = ~COLOUR,
      fillOpacity = 0.9,
      stroke = TRUE,
      weight = 1,
      color = "black",
      dashArray = c(5, 5),
      smoothFactor = 0.2,
      highlightOptions = highlightOptions(
        color='#ff0000',
        opacity = 1,
        weight = 2,
        fillOpacity = 1,
        sendToBack = FALSE
      ),
      label = ~LABEL,
      layerId = ~AREA_CODE
    ) %>%
    addLegend(position = "bottomright", 
              pal = pal.map,
              values = pal.vals,
              title = vt.param_risk_serv_switch, 
              layerId = "Legend")

  sfy_panel$prev_shape_id <- vt.shape_id
})

output$sfy_map_download <- downloadHandler(
  filename = function() {
    paste0("SFYmapdata_", format(Sys.time(), "%x_%H:%M"), ".csv")
    #paste('SFY_Map', sfy_panel$param_area_ind, sfy_panel$param_risk_ind, , ".csv", sep = "_")
    # Age_Readable <- names(age.list)[sapply(age.list, FUN=function(X) Get_Selected_Age() %in% X)]
    # paste0('Output', Get_Selected_Risk(), Age_Readable,  Get_Selected_Area(), input$mapsex, '.csv') 
  },
  content = function(file) {
    spdf <- sfy_panel$map
    df = spdf@data
    write.csv(df, file, row.names = F) 
  }
)

### histogram on map ----
# output$sfy_map_hist <- renderPlot({
#   spldf.plot <- sfy_panel$map
#   
#   pal.map <- colorNumeric(c("#843432", "#F1A42D"), (spldf.plot@data$COL_VAR))
#   
#   df.plot <- spldf.plot@data %>% 
#     mutate(COL = pal.map(COL_VAR)) %>% 
#     arrange(desc(COL_VAR)) %>% 
#     mutate(LABEL = paste0(round(COL_VAR, digits = 2), "%")) %>% 
#     mutate(INDEX = 1:n()) %>% 
#     filter(INDEX <= 5) %>% 
#     arrange(COL_VAR) %>% 
#     mutate(AREA_CODE = factor(AREA_CODE, levels = AREA_CODE))
#   
#   
#   vt.limit = c(0,max(df.plot$COL_VAR)*1.1)
#   
#   
#   p <- df.plot %>% 
#     ggplot(aes(x = AREA_CODE, y = COL_VAR)) +
#     geom_bar(stat = "identity", fill = df.plot$COL) +
#     theme_classic() +
#     geom_text(aes(label=LABEL), hjust = -0.1) +
#     scale_y_continuous(position = "right", limits = vt.limit) +
#     coord_flip() +
#     theme(legend.position="none",
#           axis.line.x = element_blank(),
#           axis.line.y = element_blank(),
#           axis.text.x = element_blank(),
#           axis.ticks = element_blank(),
#           axis.title.y = element_blank(),
#           axis.title.x = element_blank(),
#           axis.text.y = element_text(hjust = 0, size = 10)
#     )
#   
#   p
#   
# }, bg = "transparent")

