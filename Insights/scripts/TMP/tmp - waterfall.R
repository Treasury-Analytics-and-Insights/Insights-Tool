cbbPalette <- c("#000000", "#00B0F0", "#AEE934", "#5E36F2", "#fefe00", "#FF5B51", 
                "#173F17", "#c8021c", "#090F6B", "#FF399D", "#59879b", "#fe9ba2",
                "#FF9C51")

df.test <- df.test %>% 
  filter(RISK_DESC %in% c("2+ Risk Indicators", "3+ Risk Indicators", "All 4 Risk Indicators")) %>% 
  mutate(DIFF = POP - lead(POP)) %>% 
  mutate(DIFF = ifelse(is.na(DIFF), POP, DIFF)) %>% 
  mutate(POP = DIFF)


highchart() %>% 
  hc_chart(type = "waterfall") %>% 
  hc_xAxis(type = "category") %>% 
  hc_series(
    list(
      data = list(
        list(
          name = "All 4 Risk Indicators",
          y = df.test %>% 
            filter(RISK_DESC %in% "All 4 Risk Indicators") %>% 
            .[["POP"]],
          z = 500
          
        ),
        list(
          name = "3+ Risk Indicators",
          y = df.test %>% 
            filter(RISK_DESC %in% "3+ Risk Indicators") %>% 
            .[["POP"]],
          z = 200
        ),
        list(
          name = "2+ Risk Indicators",
          y = df.test %>% 
            filter(RISK_DESC %in% "2+ Risk Indicators") %>% 
            .[["POP"]],
          z = 500
        )
        # list(
        #   name = "Total Population",
        #   y = df.test %>% 
        #     filter(RISK_DESC %in% "Total Population") %>% 
        #     .[["POP"]]
        # )
        
      )
    )
  ) %>% 
  hc_tooltip(pointFormat = "y: {point.y} <br> group: {point.z} <br> cluster: {point.name}") %>% 
  hc_plotOptions(
    column = list(
      cursor = "pointer",
      point = list(
        events = list(
          click = JS(
            paste0(
              "function() {
              Shiny.onInputChange('click', {SERV_IND: this.category});
              
              for (var i = 0; i < this.series.data.length; i++) {
              this.series.data[i].update({ color: '#F1A42D' }, true, false);
              }
              this.update({ color: '#843432' }, true, false)}"
            )
            )
            )
            )
            ),
    series = list(
      showInLegend = FALSE
    ))


highchart() %>% 
  hc_chart(type = "waterfall") %>% 
  hc_title(text = "Higcharts Waterfall") %>% 
  hc_xAxis(type = 'Category') %>% 
  hc_yAxis(title=list(text='USD')) %>% 
  hc_legend(enabled=FALSE)%>%
  hc_tooltip(pointFormat="<b>${point.y:,.2f}</b> USD")%>%
  hc_series(list(upColor=cbbPalette[1],
                 color=cbbPalette[2],
                 data=
                   list(
                     list(
                       name = "Start",
                       y = 120000,
                       z = 5000
                     ),
                     list(
                       name = "Product Reveneu",
                       y= 569000,
                       z = 2000
                     ),
                     list(
                       name="Service Revenue",
                       y=231000,
                       z = 5000),
                     list(
                       name='Positive Balance',
                       isIntermediateSum=TRUE,
                       color=cbbPalette[3]
                     ),
                     list(
                       name="Fixed Costs",
                       y=-342000,
                       z = 5000
                     ),
                     list(
                       name='Variable Costs',
                       y=-233000,
                       z = 5000
                     ),
                     list(
                       name='Balance',
                       isSum=TRUE,
                       color=cbbPalette[3]
                     ))
                 ,
                 dataLabels=list(
                   enabled=TRUE,
                   formatter=JS("function(){ return Highcharts.numberFormat((this.y + this.z), 0, ',') + 'k';}"),
                   style=list(
                     color="#FFFFFF",
                     fontWeight="bold",
                     textShadow="0px 0px 3px black"
                   )
                 ),
                 pointPadding=0
  )) %>% 
  hc_tooltip(pointFormat = "y: {point.y} <br> group: {point.z} <br> cluster: {point.name}")
