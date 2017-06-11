#=====================================================================#
# About this programme
# Programme: "TYO - server - map.R"
# Objective: Server script for updating the map and related features in TYO panel
#
# Key data:
#          1.tyo_panel$map_filtered_data
#          2.tyo_panel$map
#          3.df.meta_control
#
# Author: Danny Wu Created on 19/03/2017
# ====================================================================#

### test & debug ----
# output$tyo_test <- renderPrint({
#   tyo_panel$bubble_chart
# })


### map data ----
df.tyo_map <- df.meta_control %>%
  filter(PROC %in% "tyo_map")

for (i in df.tyo_map$NAME) {
  local({
    vt.name_cur <- i
    vt.group_cur <- df.tyo_map %>%
      filter(NAME %in% vt.name_cur) %>%
      .[["GROUP"]]
    
    vt.trigger <- paste(vt.group_cur, vt.name_cur, sep = "$")
    
    observeEvent(eval(parse(text = vt.trigger)), {
      
      df.map_data <- df.db_tyo_sp
      vt.param_area_ind <- tyo_panel$param_area_ind
      vt.param_gender <- input$tyo_param_gender
      vt.param_metric <- input$tyo_param_map_metric
      vt.param_trac_ind <- input$tyo_param_map_trac_ind
      vt.param_age_group <- input$tyo_param_map_age_group
      vt.param_risk <- input$tyo_param_map_risk
      vt.param_year <- input$tyo_param_year
      
      if (is.null(vt.param_area_ind)) {
        vt.param_zoom_ind <- "Region"
        df.tmp_map_attr <- df.map_data %>% 
          filter(AREA_TYPE %in% vt.param_zoom_ind)
        
        spldf.tyo_map <- spldf.nz_region
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
          replace_na(list(PEOPLE = 0))
        
        
        spldf.tyo_map <- vt.param_zoom_ind %>% 
          tolower() %>% 
          paste0("spldf.nz_", .) %>% 
          get()
        
        spldf.tyo_map <- spldf.tyo_map[spldf.tyo_map@data$AREA_CODE %in% df.tmp_map_attr$AREA_CODE, ]
        
      }
      
      df.tmp_map_attr <- df.tmp_map_attr %>% 
        filter(TRAC_IND %in% vt.param_trac_ind) %>% 
        filter(AGE %in% vt.param_age_group) %>% 
        filter(RISK_FACTOR %in% vt.param_risk) %>%
        filter(YEAR %in% vt.param_year) %>%
        mutate(FLAG_SD = vt.param_metric) %>% 
        mutate(COL_VAR = ifelse(FLAG_SD, PERCENT, PEOPLE))
      
      df.bubble_chart <- df.tmp_map_attr %>%
        filter(GENDER != "All")
        
      df.tmp_map_attr <- df.tmp_map_attr %>%
        filter(GENDER %in% vt.param_gender)
      
      spldf.tyo_map@data <- spldf.tyo_map@data %>%
        left_join(df.tmp_map_attr, by = "AREA_CODE")
      
      tyo_panel$map <- spldf.tyo_map
      tyo_panel$bubble_chart <- df.bubble_chart
      
      
    }, ignoreNULL = FALSE)
  })
}

## map reset ----
df.tyo_map_reset <- df.meta_control %>%
  filter(PROC %in% "tyo_param_map_refresh")

for (i in df.tyo_map_reset$NAME) {
  local({
    vt.name_cur <- i
    vt.group_cur <- df.tyo_map_reset %>%
      filter(NAME %in% vt.name_cur) %>%
      .[["GROUP"]]
    
    vt.trigger <- paste(vt.group_cur, vt.name_cur, sep = "$")
    
    observeEvent(eval(parse(text = vt.trigger)), {
      
      tyo_panel$param_area_ind <- NULL
      
    }, ignoreNULL = FALSE)
  })
}


observeEvent(input$tyo_map_shape_click, {
  vt.param_shape_click <- gsub("base", "", input$tyo_map_shape_click$id)
  
  if (vt.param_shape_click %in% c(df.db_au_mapping$REGION, df.db_au_mapping$TA)) {
    tyo_panel$param_area_ind <- vt.param_shape_click
  }
  
})


### base map ----
output$tyo_map <- renderLeaflet({
  spldf.plot <- tyo_panel$map
  
  pal.map <- colorNumeric(c(vt.tyo_col_green_d1, vt.tyo_col_green_d3), spldf.plot@data$COL_VAR)
  
  spldf.plot@data <- spldf.plot@data %>%
    mutate(COL = pal.map(COL_VAR)) %>%
    mutate(COL = replace(COL, COL_VAR == 0, "#808080"))
  
  if(input$tyo_param_map_metric){
    spldf.plot@data <- spldf.plot@data %>% 
      mutate(LABEL = ifelse(COL_VAR>0, paste0(AREA_CODE, ' ', signif(COL_VAR, digits = 2), "%"), paste0(AREA_CODE, ' S' )))
  } else {
    spldf.plot@data <- spldf.plot@data %>% 
      mutate(LABEL = ifelse(COL_VAR > 0, paste0(AREA_CODE, ' ', round(COL_VAR, digits = 0)), paste0(AREA_CODE, ' S' )))
  }

  withProgress(message = 'Making plot', value = 0, {
    leaflet() %>%
      addProviderTiles(
        providers$Stamen.TonerLite,
        options = providerTileOptions(noWrap = TRUE)
      ) %>%
      addPolygons(
        data = spldf.tyo_map_ov,
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
        fillColor = ~COL,
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
      )
  })
  
  
})

### map update ----
observeEvent(tyo_panel$map, {
  spldf.plot <- tyo_panel$map
  vt.param_map_metric <- input$tyo_param_map_metric
  
  vt.label_legend <- ifelse(vt.param_map_metric, "(%)", "(#)")
  
  vt.shape_id_prev <- tyo_panel$prev_shape_id
  vt.shape_id <- unique(spldf.plot@data$AREA_CODE)
  
  mat.bbox <- bbox(spldf.plot)
  
  if (nrow(spldf.plot@data) > 0) {
    pal.map <- colorNumeric(c(vt.tyo_col_green_d1, vt.tyo_col_green_d3), spldf.plot@data$COL_VAR)
    
    spldf.plot@data <- spldf.plot@data %>%
      mutate(COL = pal.map(COL_VAR)) %>%
      mutate(COL = replace(COL, COL_VAR == 0, "#808080"))
    
    if(input$tyo_param_map_metric){
      spldf.plot@data <- spldf.plot@data %>% 
        mutate(LABEL = ifelse(COL_VAR>0,paste0(AREA_CODE, ' ', signif(COL_VAR, digits = 2), "%"), paste0(AREA_CODE, ' S' )))
    } else {
      spldf.plot@data <- spldf.plot@data %>% 
        mutate(LABEL = ifelse(COL_VAR > 0, paste0(AREA_CODE, ' ', round(COL_VAR, digits = 0)), paste0(AREA_CODE, ' S' )))
    }
    
    leafletProxy("tyo_map") %>%
      removeShape(layerId = vt.shape_id_prev) %>%
      fitBounds(mat.bbox[1], mat.bbox[2], mat.bbox[3], mat.bbox[4]) %>%
      addPolygons(
        data = spldf.plot,
        fillColor = ~COL,
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
      )
    
    tyo_panel$prev_shape_id <- vt.shape_id
  }
})

debounced_over <- debounce(input$tyo_map_shape_mouseover$id, 500)
#debounced_out <- debounce(input$tyo_map_shape_mouseout$id, 800)
#debounce = debounce(input$tyo_map_shape_mouseover, 500)

# observeEvent(debounce(), {
#   print('hi')
#   print(debounce())
# },
# ignoreNULL = FALSE)
# 
# observeEvent(debounced_over(), {
#   print(debounced_over())
#   print(tyo_panel$is_hover)
#   },
#   ignoreNULL = FALSE)

# observeEvent(debounced_out(), {
#   tyo_panel$is_hover <- FALSE
# }, ignoreNULL = FALSE)

observeEvent(debounced_over(), {
  tyo_panel$is_hover <- TRUE
}, ignoreNULL = FALSE)



# observeEvent(input$tyo_map_shape_mouseout$id, {
#   tyo_panel$is_hover <- FALSE
# }, ignoreNULL = FALSE)
# 
# observeEvent(input$tyo_map_shape_mouseover$id, {
#   tyo_panel$is_hover <- TRUE
# }, ignoreNULL = FALSE)


################################################################################################
output$tyo_map_bubble_chart <- renderPlot({
  
  plot.df <- tyo_panel$bubble_chart
  
  pal.map <- colorNumeric(c(vt.tyo_col_green_d1, vt.tyo_col_green_d3), plot.df$COL_VAR)
  
  plot.df <- plot.df %>%
    mutate(COL = pal.map(COL_VAR))
  #print(debounced())
  if (tyo_panel$is_hover) {

    hover = debounced_over()

    if (any(plot.df$AREA_CODE == hover)) {
      plot.df <- plot.df %>%
        mutate(COL = replace(COL, AREA_CODE == hover, vt.tyo_col_orange_d3))
    }
  }
  
  set.seed(22)
  p = ggplot(data = plot.df, aes(y = GENDER, x = PERCENT, size = PEOPLE)) +
    geom_jitter(colour = plot.df$COL, width = 0, height = 0.3) +
    scale_alpha_manual(guide='none', values = list(Y = 0.9, N = 0.3)) +
    scale_size_continuous(range = c(1, 12)) +
    theme_classic() +
    labs(x = paste0(input$tyo_param_map_trac_ind, " (%)")) +
    scale_x_continuous(labels=x_percent) +
    theme(legend.position="none",
          axis.line.x = element_blank(),
          axis.line.y = element_blank(),
          axis.title.y = element_blank(),
          axis.ticks = element_blank(),
          axis.title.x = element_text(size = 24),
          axis.text.y = element_text(size = 14, hjust = 0),
          axis.text.x = element_text(size = 14)
    )
  print(p)
})

output$tyo_map_bar_chart <- renderPlot({
  
  plot.df <- tyo_panel$map@data %>%
    filter(!is.na(COL_VAR))
  
  pal.map <- colorNumeric(c(vt.tyo_col_green_d1, vt.tyo_col_green_d3), plot.df$COL_VAR)
  
  if (input$tyo_param_map_metric) {
    plot.df <- plot.df %>%
      arrange(COL_VAR) %>%
      mutate(LABEL = ifelse(COL_VAR > 0, paste0(signif(COL_VAR, digits = 2), "%"), "S"))
  } else {
    plot.df <- plot.df %>%
      arrange(COL_VAR) %>%
      mutate(LABEL = ifelse(COL_VAR > 0, round(COL_VAR, digits = 0), "S"))
  }
  
  limit.vec = c(0,max(plot.df$COL_VAR)*1.15)
  
  plot.df <- plot.df %>%
    mutate(COL = pal.map(COL_VAR))
  
  if (tyo_panel$is_hover) {
    
    hover = debounced_over()
    
    if (any(plot.df$AREA_CODE == hover)) {
      plot.df <- plot.df %>%
        mutate(COL = replace(COL, AREA_CODE == hover, vt.tyo_col_orange_d3))
    }
  }
  
  vt.text_size = ifelse(nrow(plot.df) > 25, 12, 14)
  
  p <- ggplot(plot.df, aes(x = reorder(AREA_CODE, COL_VAR), y = COL_VAR)) +
    geom_bar(stat = "identity", fill = plot.df$COL) +
    theme_classic() +
    geom_text(aes(label=LABEL), hjust=-0.1) +
    scale_y_continuous(position = "right", limits = limit.vec, expand = c(0,0)) +
    #scale_x_continuous(expand = c(0,0)) +
    scale_x_discrete(expand = c(0,0)) +
    coord_flip() +
    theme(legend.position="none",
          axis.line.x = element_blank(),
          axis.line.y = element_blank(),
          axis.text.x = element_blank(),
          axis.ticks = element_blank(),
          axis.title.y = element_blank(),
          axis.title.x = element_blank(),
          #axis.text.y = element_text(hjust = 0),
          axis.text.y = element_text(hjust = 0, size = vt.text_size),
          text = element_text(size = vt.text_size))
  print(p)
})

output$tyo_map_download <- downloadHandler(
  filename = function() {
    paste0("TYO_mapdata_", format(Sys.time(), "%x_%H:%M"), ".csv")
  },
  content = function(file) {
    spdf <- tyo_panel$map
    df = spdf@data
    write.csv(df, file, row.names = F) 
  }
)

output$tyo_map_footer = renderText({
  paste0("Bubble size = ", gsub('.{1}$', '', input$tyo_param_map_age_group), " olds in ", input$tyo_param_map_risk, " risk group")
})

# output$tyo_test <- renderText({
#   tbl_df(tyo_panel$map@data)
# })
