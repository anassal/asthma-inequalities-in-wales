# export models as single table

sink(file = paste0(outputPath.results, 'NB_coef_table_alldata_', timeNow(), '.txt'))

cbind(
  row_id =
    expand.grid(
      nb.coef %>% names,
      paste0('_'),
      outcomes$code,
      paste0('_'),
      nb.coef$gpreg1_asthmarx1$ASTHMA_GP_VISITS$IV
    ) %>%
    arrange(Var1, Var3) %>%
    do.call(what=paste0)
    ,

  nb.coef %>%
    lapply(
      (function(x){
        lapply(x,
          mutate,
          Estimate = Estimate %>% format(nsmall = 2, digits = 2),
          LCL      = LCL      %>% format(nsmall = 2, digits = 2),
          UCL      = LCL      %>% format(nsmall = 2, digits = 2)
        ) %>%
        do.call(what= rbind)
      })
  ) %>%
  do.call(what= rbind)
) %>%
set_rownames(value = NULL) %>%
  kable %>%
  print

sink()
