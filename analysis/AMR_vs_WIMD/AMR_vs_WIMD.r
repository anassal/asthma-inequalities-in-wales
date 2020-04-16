print_ECDF_plots = function(tb) {
  AMR_WIMD_ecdf =
    ggplot(tb) +
  	stat_ecdf(geom ='step', aes(x=AMR, colour = WIMD), size = 1.1) +
  		scale_colour_manual(values = c('1' = WIMD.colr[1],
  																	 '2' = WIMD.colr[2],
  																	 '3' = WIMD.colr[3],
  																	 '4' = WIMD.colr[4],
  																	 '5' = WIMD.colr[5]),
  												labels = WIMD.labels$label) +
  	labs(y = 'Cumulative proportion of individuals\n',
  			 x = '\nAsthma Medication Ratio') +
  	coord_fixed() +
  	theme_minimal() +
  	theme(panel.grid.major = element_blank(),
  				panel.grid.minor = element_blank(),
  				axis.line = element_line(),
  				legend.title =  element_blank()
  				)

  AMR_WIMD_ecdf %>% ggsave(filename = paste0(outputPath.results, 'AMR_ecdf.png') %>% timeNow.before.ext, width = 6, height = 6)
}


print_beanplots  = function (tb) {

  pdf(file = paste0(outputPath.results, 'amr_WIMD_beanplot', timeNow(),'.pdf'), width = 7, height = 6)
  par(mar = c(5, 9, 1, 1))
  beanplot::beanplot(AMR ~ WIMD,
  									 data = tb %>% mutate(WIMD = WIMD %>% factor(levels = 5:1)),
  									 what = c(T,T,T,F),
  									 col  = c(1,2,3,4),
  									 horizontal = T,
  									 #ylim = c(0,1)
  									 cutmin = 0, cutmax = 1,
  									 side = 'second',
  									 boxwex = 1.7,
  									 axes = F,
  									 xlab = 'Asthma Medication Ratio',
  									 names = WIMD.labels,
  									 las = 1,
  									 bty = 'n'
  )
  axis(side = 1)
  axis(side = 2, labels = WIMD.labels$label, at = 5:1, las = 1, lwd = 0)

  dev.off()

  #---------------------

}


WIMD.colr = colorRampPalette(c('#FF0000', '#2222FF', '#44EE11'))(5)

cohort.dt %>%
  filter(GPREG == 1 & ASTHMA_RX == 1 & !is.na(AMR)) %>%
  transmute(
    AMR,
    WIMD = WIMD %>% factor(levels = 1:5), #reorder WIMD levels
    colr = alpha(WIMD %>% as.character %>% as.numeric, 1-0.5/(WIMD %>% as.character %>% as.numeric))
  ) %>%
  (function(x) {print_ECDF_plots(x); print_beanplots(x);})

AMR_vs_WIMD15_ttest =
  cohort.dt %>%
  filter(GPREG == 1 & ASTHMA_RX == 1 & !is.na(AMR) & WIMD %in% c('1', '5')) %>%
  mutate(WIMD = WIMD %>% as.character %>% factor(levels = c(5,1))) %>%
  t.test(formula = AMR ~ WIMD, data = .)

AMR_vs_WIMD_KWtest =
  cohort.dt %>%
  filter(GPREG == 1 & ASTHMA_RX == 1 & !is.na(AMR)) %>%
  kruskal.test(AMR ~ WIMD, data = .)

