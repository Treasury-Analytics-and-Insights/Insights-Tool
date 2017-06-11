df.test <- df.db_cyar %>% 
  filter(AGE %in% "0-5 years") %>% 
  select(AGE, RISK_DESC, POP) %>% 
  unique()

df.test <- df.test %>% 
  filter(RISK_DESC %in% c("In any of the above groups", "No Risk")) %>% 
  group_by(AGE) %>% 
  summarise(POP = sum(POP)) %>% 
  mutate(RISK_DESC = "Total Population") %>% 
  bind_rows(
    df.test %>% 
      filter(!RISK_DESC %in% c("No Risk", "In any of the above groups"))
  ) %>% 
  mutate(RISK_DESC = plyr::mapvalues(RISK_DESC,  c("All 4 Risk Indicators", "3+ Risk Indicators", 
                                                   "2+ Risk Indicators", "Total Population"),
                                     c("a.All 4 Risk Indicators", "b.3+ Risk Indicators", 
                                       "c.2+ Risk Indicators", "d.Total Population")))


df.test

df

highchart() %>% 
  hc_chart(type = "waterfall") %>% 
  hc_xAxis(categories = df.test$RISK_DESC) %>% 
  hc_add_series(df.test$POP)
