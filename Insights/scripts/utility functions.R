alignCenter <- function(el) {
  htmltools::tagAppendAttributes(el,
                                 style="margin-left:auto;margin-right:auto;"
  )
}


debounce <- function(expr, millis, env = parent.frame(), quoted = FALSE,
                     domain = getDefaultReactiveDomain()) {
  
  force(millis)
  
  f <- exprToFunction(expr, env, quoted)
  label <- sprintf("debounce(%s)", paste(deparse(body(f)), collapse = "\n"))
  
  v <- reactiveValues(
    trigger = NULL,
    when = NULL # the deadline for the timer to fire; NULL if not scheduled
  )  
  
  # Responsible for tracking when f() changes.
  observeEvent(f(), {
    # The value changed. Start or reset the timer.
    v$when <- Sys.time() + millis/1000
  }, ignoreNULL = FALSE)
  
  # This observer is the timer. It rests until v$when elapses, then touches
  # v$trigger.
  observe({
    if (is.null(v$when))
      return()
    
    now <- Sys.time()
    if (now >= v$when) {
      v$trigger <- runif(1)
      v$when <- NULL
    } else {
      invalidateLater((v$when - now) * 1000, domain)
    }
  })
  
  # This is the actual reactive that is returned to the user. It returns the
  # value of f(), but only invalidates/updates when v$trigger is touched.
  eventReactive(v$trigger, {
    f()
  }, ignoreNULL = FALSE)
}


get_palette <- function(..., n, alpha) {
  colors <- colorRampPalette(...)(n)
  paste(colors, sprintf("%x", ceiling(255*alpha)), sep="")
}


change_names <- function(df, from, to, reminder = TRUE) {
  
  ## error checking
  # check if from exist in df
  
  if (!all(from %in% colnames(df))) {
    stop ("undefined column names selected")
  }
  
  # check if the length of the mapping match
  len.from <- length(from)
  len.to <- length(to)
  
  if (len.from != len.to) {
    stop("argument imply differing length of vectors:", len.from, ",", len.to)
  }
  
  org.from <- from
  org.to <- to
  
  ## process to modify the specified names
  field.names <- names(df)
  field.names <- field.names[!(field.names %in% from)]
  
  to <- c(to, field.names)
  from <- c(from, field.names)
  
  names(to) <- from
  names(df) <- to[names(df)]
  
  if (reminder) {
    cat("the column name(s) have been modified:\n")
    indicator <- paste(org.from, " to ", org.to, "\n", sep = "")
    indicator[1] <- paste(" ", indicator[1], sep = "")
    cat(indicator)
  }  
  
  return(df)
  
}

hc_hist <- function(x, y, title = NULL, subtitle = NULL, xaxis, yaxis,
                    col, col_highlight, df, tooltip, id = "", 
                    pointFormat = NULL, valueFormat = NULL, pre_selected = 0) {
  highchart() %>%
    hc_chart(
      type = "column",
      events = list(
        load = JS(
          paste0(
            "function() {
              this.series[0].data[",pre_selected,"].update({ color: '", col_highlight, "' }, true, false)}"
          )
        )
      )
    ) %>%
    hc_title(text = title) %>%
    hc_subtitle(text = subtitle) %>%
    hc_xAxis(title = list(text = xaxis),
             categories = df[[x]]) %>%
    hc_yAxis(title = list(text = yaxis)#,
             # labels = list(
             #   format = ifelse(is.null(valueFormat), '{value}%', valueFormat)
             # )
    ) %>%
    hc_add_series(data = df[[y]], color = col) %>%
    hc_tooltip(
      headerFormat = "<b>{point.x}</b> <br>",
      pointFormat = ifelse(is.null(pointFormat), paste0(tooltip, ": <b>{point.y:.1f}</b>"), paste0(tooltip, pointFormat))
    ) %>%
    hc_plotOptions(
      column = list(
        borderColor = col_highlight,
        borderWidth = 2,
        cursor = "pointer",
        point = list(
          events = list(
            click = JS(
              paste0(
                "function() {
                Shiny.onInputChange('", id, "click', {", x, ": this.category});

                for (var i = 0; i < this.series.data.length; i++) {
                this.series.data[i].update({ color: '", col, "' }, true, false);
                }
                this.update({ color: '", col_highlight, "' }, true, false)}"
              )
            )
          )
        )
      ),
      series = list(
        showInLegend = FALSE,
        pointPadding = 0,
        groupPadding = 0.05
      ))
}

hc_hist_comp <- function(x, y1, y2, y1_label, y2_label,
                         title, subtitle, xaxis, yaxis, 
                         col_n, col_y, df, id = "", 
                         pointFormat = NULL, valueFormat = NULL,pre_selected = 0) {
  highchart() %>%
    hc_chart(
      type = "column",
      events = list(
        load = JS(
          paste0(
            "function() {
            var chart = this.xAxis[0]
            chart.removePlotLine('plot-line-1');
            chart.addPlotLine({
            value: this.series[0].data[",pre_selected,"].x,
            color: '#FF0000',
            width: 2,
            id: 'plot-line-1'
            })
            console.log(this);
            }"
          )
          )
        )
    ) %>%
    hc_title(text = title) %>%
    hc_subtitle(text = subtitle) %>%
    hc_xAxis(title = list(text = xaxis),
             categories = df[[x]]) %>%
    hc_yAxis(title = list(text = yaxis),
             label = list(
               format = ifelse(is.null(valueFormat), "{value:,.0f}", valueFormat)
             )) %>%
    hc_add_series(name = y1_label, data = df[[y1]], color = col_n) %>%
    hc_add_series(name = y2_label, data = df[[y2]], color = col_y) %>%
    hc_tooltip(
      headerFormat = "<b>{point.x}</b> <br>",
      pointFormat = ifelse(is.null(pointFormat), "{series.name}: <b>{point.y:,.0f}</b><br>", pointFormat),
      shared = TRUE
    ) %>%
    hc_plotOptions(
      column = list(
        cursor = "pointer",
        point = list(
          events = list(
            click = JS(
              paste0(
                "function() {
                         Shiny.onInputChange('", id, "click', {", x, ": this.category});
                         var chart = this.series.chart.xAxis[0]
                         chart.removePlotLine('plot-line-1');
                         chart.addPlotLine({
                         value: this.x,
                         color: '#FF0000',
                         width: 2,
                         id: 'plot-line-1'
                         })}"
              )
            )
          )
        )
      ),
      series = list(
        pointPadding = 0,
        groupPadding = 0.1
      ))
}

# hc_hist <- function(x, y, title, subtitle, xaxis, yaxis, 
#                     col, col_highlight, df, tooltip, id = "", pointFormat = NULL, valueFormat = NULL) {
#   highchart() %>% 
#     hc_chart(type = "bar") %>% 
#     hc_title(text = title) %>%
#     hc_subtitle(text = subtitle) %>% 
#     hc_xAxis(title = list(text = xaxis), 
#              categories = df[[x]]) %>% 
#     hc_yAxis(title = list(text = yaxis),
#              labels = list(
#                format = ifelse(is.null(valueFormat), '{value}%', valueFormat)
#              )
#     ) %>% 
#     hc_add_series(data = df[[y]], color = col) %>% 
#     hc_tooltip(
#       headerFormat = "<b>{point.x}</b> <br>",
#       pointFormat = ifelse(is.null(pointFormat), paste0(tooltip, ": <b>{point.y}%</b>"), paste0(tooltip, pointFormat))
#     ) %>% 
#     hc_plotOptions(
#       column = list(
#         cursor = "pointer",
#         point = list(
#           events = list(
#             click = JS(
#               paste0(
#                 "function() {
#                 Shiny.onInputChange('", id, "click', {", x, ": this.category});
#                 
#                 for (var i = 0; i < this.series.data.length; i++) {
#                 this.series.data[i].update({ color: '", col, "' }, true, false);
#                 }
#                 this.update({ color: '", col_highlight, "' }, true, false)}"
#               )
#               )
#               )
#               )
#               ),
#       series = list(
#         showInLegend = FALSE,
#         pointPadding = 0,
#         groupPadding = 0.05
#       ))
#   }
# 
# hc_hist_comp <- function(x, y1, y2, y1_label, y2_label, 
#                          title, subtitle, xaxis, yaxis, col_n, col_y, df, id = "", pointFormat = NULL, valueFormat = NULL) {
#   highchart() %>% 
#     hc_chart(type = "bar") %>%
#     hc_title(text = title) %>% 
#     hc_subtitle(text = subtitle) %>% 
#     hc_xAxis(title = list(text = xaxis),
#              categories = df[[x]]) %>% 
#     hc_yAxis(title = list(text = yaxis),
#              label = list(
#                format = ifelse(is.null(valueFormat), "{value:,.0f}", valueFormat)
#              )) %>% 
#     hc_add_series(name = y1_label, data = df[[y1]], color = col_n) %>% 
#     hc_add_series(name = y2_label, data = df[[y2]], color = col_y) %>% 
#     hc_tooltip(
#       headerFormat = "<b>{point.x}</b> <br>",
#       pointFormat = ifelse(is.null(pointFormat), "{series.name}: <b>{point.y:,.0f}</b><br>", pointFormat),
#       shared = TRUE
#     ) %>% 
#     hc_plotOptions(
#       column = list(
#         cursor = "pointer",
#         point = list(
#           events = list(
#             click = JS(
#               paste0(
#                 "function() {
#                 Shiny.onInputChange('", id, "click', {", x, ": this.category});
#                 var chart = this.series.chart.xAxis[0]
#                 chart.removePlotLine('plot-line-1');
#                 chart.addPlotLine({
#                 value: this.x,
#                 color: '#FF0000',
#                 width: 2,
#                 id: 'plot-line-1'
#                 })}"
#               )
#               )
#               )
#               )
#               ),
#       series = list(
#         pointPadding = 0,
#         groupPadding = 0.1
#       ))
#   }