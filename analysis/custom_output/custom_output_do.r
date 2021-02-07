# custom output data to be used on LaTeX
co_dt = readxl::read_xlsx(path = 'specs/specs.xlsx', sheet = 'custom_output_def')
co = list()
co %<>% (function(x){
  for(i in 1:(co_dt %>% nrow)){
    x[[co_dt %>% slice(i) %>% pull(varName)]] = ''
  }
  x
})

fill_custom_output(load_HRU_model_Rdata = F)

co_dt %>%
  inner_join(
    cbind.data.frame(
      co %>% names,
      co %>% unlist  %>% as_tibble(.name_repair = "minimal"),
      stringsAsFactors = F
    ) %>%
    set_colnames(c('varName', 'value'))
  ) %>%
  writexl::write_xlsx(path = paste0(outputPath.results, 'misc_output.xlsx'))
