# export glm_nb output

source('analysis/HRU_vs_WIMD/export_tables.r')
sink(file = paste0(outputPath.results, 'NB_coef_table_', timeNow(), '.txt'))
for (cv0 in names(nb.coef)) {
	paste0('\n\n', cv0, '\n\n') %>% cat
	exportIRR_table(nb.coef[[cv0]], cv0)
}
sink()

# export all models in one table
source('analysis/HRU_vs_WIMD/export_tables_raw.r')

# IRR plots
source('analysis/HRU_vs_WIMD/export_plots.r')
print_IRR_plots()

sink(file = paste0(outputPath.results, 'NB_coef_table_rounded_to_3d', timeNow(), '.txt'))
nb.coef$gpreg1_asthmarx1 %>%
  lapply(function(m){
    m %>%
    transmute(IV,
              Est = Estimate %>% round.d(3),
              CI = paste0(
                ' (',
                LCL %>% round.d(3),
                ', ',
                UCL %>% round.d(3),
                ') '
              ),
              P. = ifelse(P >= 0.001, P %>% round.d(3), '<0.001'),
              P
    ) %>%
      slice(c(2:7, 1))
  })
sink()
