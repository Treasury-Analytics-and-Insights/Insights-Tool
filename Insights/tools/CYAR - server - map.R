#=====================================================================#
# About this programme
# Programme: "CYAR - server - map.R"
# Objective: Server script for updating the map and related features in CYAR panel
#
# Key data:
#          1.cyar_panel$map_filtered_data
#          2.cyar_panel$map
#          3.df.meta_control
#
# Author: Ethan Li Created on 19/03/2017
# ====================================================================#

### map data ----
df.cyar_map <- df.meta_control %>%
  filter(PROC %in% "cyar_map")

for (i in df.cyar_map$NAME) {
  local({
    vt.name_cur <- i
    vt.group_cur <- df.cyar_map %>%
      filter(NAME %in% vt.name_cur) %>%
      .[["GROUP"]]
    
    vt.trigger <- paste(vt.group_cur, vt.name_cur, sep = "$")
    
    observeEvent(eval(parse(text = vt.trigger)), {
      
      df.map_data <- cyar_panel$map_filtered_data
      vt.param_gender_ind <- input$cyar_param_gender_ind
      vt.param_sd_loc <- input$cyar_param_sd_loc
      vt.param_area_ind <- cyar_panel$param_area_ind
      
      
      if (is.null(vt.param_area_ind)) {
        vt.param_zoom_ind <- "Region"
        df.tmp_map_attr <- df.map_data %>% 
          filter(AREA_TYPE %in% vt.param_zoom_ind)
        
        spldf.cyar_map <- spldf.nz_region
      }
      else {
        vt.param_zoom_ind_curr <- df.map_data %>% 
          filter(AREA_CODE %in% vt.param_area_ind) %>% 
          .[["AREA_TYPE"]] %>% 
          unique() %>% 
          toupper()
        
        vt.param_zoom_ind <- switch(vt.param_zoom_ind_curr, "REGION" = "TA", "TA" = "AU", "AU" = "")
        
        # no more zoom-in when it gets to AU level
        validate(
          need(
            vt.param_zoom_ind != "",
            "No data update"
          )
        )
        
        df.tmp_map_attr <- df.db_au_mapping %>% 
          change_names(c(vt.param_zoom_ind_curr, vt.param_zoom_ind), 
                       c("AREA_CURR", "AREA_ZOOM"), 
                       reminder = FALSE) %>% 
          filter(AREA_CURR %in% vt.param_area_ind) %>% 
          select(AREA_CURR, AREA_ZOOM) %>% 
          unique() %>% 
          right_join(df.map_data, ., by = c("AREA_CODE" = "AREA_ZOOM")) %>% 
          replace_na(list(COUNT = 0))
        
        
        spldf.cyar_map <- vt.param_zoom_ind %>% 
          tolower() %>% 
          paste0("spldf.nz_", .) %>% 
          get()
        
        spldf.cyar_map <- spldf.cyar_map[spldf.cyar_map@data$AREA_CODE %in% df.tmp_map_attr$AREA_CODE, ]
        
      }
    
      df.tmp_map_attr <- df.tmp_map_attr %>% 
        filter(GENDER %in% vt.param_gender_ind) %>% 
        mutate(PC = ifelse(TOTAL == 0, 0, 100*COUNT/TOTAL)) %>% 
        mutate(PC = ifelse(PC < 100, PC, 100)) %>% 
        mutate(FLAG_SD = vt.param_sd_loc) %>% 
        mutate(COL_VAR = ifelse(FLAG_SD, PC, COUNT))
      
      spldf.cyar_map@data <- spldf.cyar_map@data %>%
        left_join(df.tmp_map_attr, by = "AREA_CODE") %>%
        unique()
      
      cyar_panel$map <- spldf.cyar_map
      cyar_panel$test_data <- df.tmp_map_attr
      
    }, ignoreNULL = FALSE)
  })
}

## map reset ----
df.cyar_map_reset <- df.meta_control %>%
  filter(PROC %in% "cyar_map_reset")

for (i in df.cyar_map_reset$NAME) {
  local({
    vt.name_cur <- i
    vt.group_cur <- df.cyar_map_reset %>%
      filter(NAME %in% vt.name_cur) %>%
      .[["GROUP"]]
    
    vt.trigger <- paste(vt.group_cur, vt.name_cur, sep = "$")
    
    observeEvent(eval(parse(text = vt.trigger)), {
      
      cyar_panel$param_area_ind <- NULL
      
    }, ignoreNULL = FALSE)
  })
}


observeEvent(input$cyar_map_shape_click, {
  vt.param_shape_click <- gsub("base", "", input$cyar_map_shape_click$id)
  
  if (vt.param_shape_click %in% c(df.db_au_mapping$REGION, df.db_au_mapping$TA)) {
    cyar_panel$param_area_ind <- vt.param_shape_click
  }
  
})


### base map ----
output$cyar_map <- renderLeaflet({
  spldf.plot <- spldf.init_cyar_map
  
  pal.vals = spldf.plot@data %>%
    filter(COL_VAR>0) %>%
    .[['COL_VAR']]
  pal.map <- colorNumeric(c(vt.cyar_col_lighter, vt.cyar_col_mile), pal.vals) 
  
  spldf.plot@data = spldf.plot@data %>%
    mutate(COLOUR = pal.map(COL_VAR)) %>%
    mutate(COLOUR = ifelse(!is.na(COLOUR), COLOUR, "#808080"))
  
  if(input$cyar_param_sd_loc){
    spldf.plot@data <- spldf.plot@data %>% 
      mutate(LABEL = ifelse(COL_VAR>0,paste0(AREA_CODE, ' ', signif(COL_VAR, digits = 2), "%"), paste0(AREA_CODE, ' S' )))
  }else{
    spldf.plot@data <- spldf.plot@data %>% 
      mutate(LABEL = ifelse(COL_VAR>0,paste0(AREA_CODE, ' ', formatC(COL_VAR, format="d", big.mark =","), ""), paste0(AREA_CODE, ' S' )))
  }
  
  withProgress(message = 'Making plot', value = 0, {
    leaflet() %>%
      addProviderTiles(
        providers$Stamen.TonerLite,
        options = providerTileOptions(noWrap = TRUE)
      ) %>%
      addPolygons(
        data = spldf.cyar_map_ov,
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
                title = "(%)", 
                layerId = "Legend",
                na.label = "S")
  })
  
  
})

### map update ----
observeEvent(cyar_panel$map, {
  spldf.plot <- cyar_panel$map
  vt.param_sd_loc <- input$cyar_param_sd_loc
  
  vt.label_xaxis <- ifelse(vt.param_sd_loc, "%", "")
  vt.label_legend <- ifelse(vt.param_sd_loc, "(%)", "(#)")
  
  vt.shape_id_prev <- cyar_panel$prev_shape_id
  vt.shape_id <- unique(spldf.plot@data$AREA_CODE)
  
  mat.bbox <- bbox(spldf.plot)
  
  if (nrow(spldf.plot@data) > 0) {
    #pal.map = colorNumeric(c(vt.cyar_col_lighter, vt.cyar_col_mile), spldf.plot@data$COL_VAR)
    pal.vals = spldf.plot@data %>%
                filter(COL_VAR>0) %>%
                .[['COL_VAR']]
    pal.map <- colorNumeric(c(vt.cyar_col_lighter, vt.cyar_col_mile), pal.vals) 
    
    spldf.plot@data = spldf.plot@data %>%
      mutate(COLOUR = pal.map(COL_VAR)) %>%
      mutate(COLOUR = ifelse(!is.na(COLOUR), COLOUR, "#808080"))
      
    if(input$cyar_param_sd_loc){
      spldf.plot@data <- spldf.plot@data %>% 
        mutate(LABEL = ifelse(COL_VAR>0,paste0(AREA_CODE, ' ', signif(COL_VAR, digits = 2), "%"), paste0(AREA_CODE, ' S' )))
    }else{
      spldf.plot@data <- spldf.plot@data %>% 
        mutate(LABEL = ifelse(COL_VAR>0,paste0(AREA_CODE, ' ', formatC(COL_VAR, format="d", big.mark =","), ""), paste0(AREA_CODE, ' S' )))
    }
    
    leafletProxy("cyar_map") %>%
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
                title = "(%)", 
                layerId = "Legend",
                na.label = "S")
    
    cyar_panel$prev_shape_id <- vt.shape_id
  }
 
})

output$cyar_map_download <- downloadHandler(
  filename = function() {
    paste0("CYARmapdata_", format(Sys.time(), "%x_%H:%M"), ".csv")
    #paste('SFY_Map', sfy_panel$param_area_ind, sfy_panel$param_risk_ind, , ".csv", sep = "_")
    # Age_Readable <- names(age.list)[sapply(age.list, FUN=function(X) Get_Selected_Age() %in% X)]
    # paste0('Output', Get_Selected_Risk(), Age_Readable,  Get_Selected_Area(), input$mapsex, '.csv') 
  },
  content = function(file) {
    spdf <- cyar_panel$map
    df = spdf@data
    write.csv(df, file, row.names = F) 
  }
)

output$cyar_map_title <- renderText({
  input$cyar_param_refresh
  isolate({
    vt.param_age = input$cyar_param_age
    vt.param_year = input$cyar_param_year
  })
  vt.param_zoom_ind_curr <- cyar_panel$map %>%
    .[["AREA_TYPE"]] %>% 
    unique() %>%
    .[1]
  
  vt.param_prev_shape = ifelse(vt.param_zoom_ind_curr == "Region", "", paste0(" in ", cyar_panel$param_area_ind))
  paste0(vt.param_age, " old with ", input$cyar_param_risk_ind, " by ", vt.param_zoom_ind_curr, vt.param_prev_shape, ", ", vt.param_year)

})

