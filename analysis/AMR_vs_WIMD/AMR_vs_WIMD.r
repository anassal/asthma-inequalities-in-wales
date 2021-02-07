print_ECDF_plots = function(tb) {

  AMR_WIMDQ_ecdf =

    ggplot(tb) +

  	stat_ecdf(geom ='step', aes(x=AMR, colour = WIMDQ), size = 0.4, pad = F) +

  		scale_colour_manual(values = c('1' = WIMDQ.colr[1],
  																	 '2' = WIMDQ.colr[2],
  																	 '3' = WIMDQ.colr[3],
  																	 '4' = WIMDQ.colr[4],
  																	 '5' = WIMDQ.colr[5]),
  												labels = WIMDQ_info$label) +

  	labs(y = 'Cumulative proportion\nof individuals\n',
  			 x = '\nAsthma Medication Ratio') +

  	coord_fixed(xlim = c(0, 1)) +

  	theme_minimal() +

  	theme(panel.grid.major = element_blank(),
  				panel.grid.minor = element_blank(),
  				axis.ticks = element_line(),
  				axis.line = element_line(),
  				legend.title =  element_blank()
  				)

  AMR_WIMDQ_ecdf %<>% egg::set_panel_size(width = unit(eggPanelSize$w * 1.4, 'cm'), height = unit(eggPanelSize$h * 1.4, 'cm'))

  AMR_WIMDQ_ecdf %>% ggsave(filename = paste0(outputPath.results, 'AMR_ecdf.pdf')
                            , width = pdfPlotDim$w * 1.1, height = pdfPlotDim$h * 1.1)

}

print_beanplots  = function (tb) {
  pdf(file = paste0(outputPath.results, 'amr_WIMDQ_beanplot', timeNow(),'.pdf'), width = 7, height = 6)
  par(mar = c(5, 9, 1, 1))
  beanplot::beanplot(AMR ~ WIMDQ,
  									 data = tb %>% mutate(WIMDQ = WIMDQ %>% factor(levels = 5:1)),
  									 what = c(T,T,T,F),
  									 col  = c(1,2,3,4),
  									 horizontal = T,
  									 cutmin = 0, cutmax = 1,
  									 side = 'second',
  									 boxwex = 1.7,
  									 axes = F,
  									 xlab = 'Asthma Medication Ratio',
  									 names = WIMDQ_info$label,
  									 las = 1,
  									 bty = 'n'
  )
  axis(side = 1)
  axis(side = 2, labels = WIMDQ_info$label, at = 5:1, las = 1, lwd = 0)
  dev.off()
}

# print beanplot and ECDF

cohort.dt %>%
  filter(GPREG == 1 & ASTHMA_RX == 1 & !is.na(AMR)) %>%
  transmute(
    AMR,
    WIMDQ = WIMDQ %>% factor(levels = 1:5), #reorder WIMDQ levels
    colr = alpha(WIMDQ %>% as.character %>% as.numeric, 1-0.5/(WIMDQ %>% as.character %>% as.numeric))
  ) %>%
  (function(x) {print_ECDF_plots(x); print_beanplots(x);})

AMR_vs_WIMDQ15_ttest =
  cohort.dt %>%
  filter(GPREG == 1 & ASTHMA_RX == 1 & !is.na(AMR) & WIMDQ %in% c('1', '5')) %>%
  mutate(WIMDQ = WIMDQ %>% as.character %>% factor(levels = c(5,1))) %>%
  t.test(formula = AMR ~ WIMDQ, data = .)


# SABA >= 12 per year vs WIMDQ

SABA12_vs_WIMDQ = glm((SABA >= 12*5) ~ WIMDQ + age + GNDR_CD,
    data =
      cohort.dt %>%
      filter(GPREG %in% 1 & ASTHMA_RX %in% 1),
    family = binomial()
    )

SABA12_vs_WIMDQ %>% broom::tidy(conf.int = T, exponentiate = T)

sjstats_odds_to_rr_simple_CI(SABA12_vs_WIMDQ)

#---------------------

adjust0sand1s = function(x){x[x == 0] <- 1e-5; x[x == 1] <- 1 - 1e-5; x}

bam_amr_wimds = mgcv::bam(
   formula = AMR ~ s(WIMDS) + s(age) + GNDR_CD,
   data =  cohort.dt %>% filter(GPREG == 1 & ASTHMA_RX == 1 & !is.na(AMR)) %>% mutate(AMR = AMR %>% adjust0sand1s),
   method = 'fREML', family = mgcv::betar(link = 'logit'), cluster = cpu_cluster, chunk.size = 20000
)

bam_amr_wimds %>% summary
bam_amr_wimds %>% mgcv::plot.gam(pages = 1)
bam_amr_wimds %>% saveRDS('data/rds/bam_amr_wimds.rds' %>% timeNow.before.ext)

(
  bind_rows(
    (
      bam_amr_wimds %>%
        gratia::evaluate_smooth(smooth = 's(WIMDS)') %>%
        mutate(lcl = est - 2 * se, ucl = est + 2 * se) %>%
        rename(x = WIMDS)
    ),
    (
      bam_amr_wimds %>%
        gratia::evaluate_smooth(smooth = 's(age)') %>%
        mutate(lcl = est - 2 * se, ucl = est + 2 * se) %>%
        rename(x = age)
    )
  ) %>%
    mutate(
      smooth = smooth %>% factor(levels = c('s(WIMDS)', 's(age)'))
    ) %>%

    ggplot(aes(x = x, y = est)) +
    hline0 +
    geom_ribbon(aes(ymax = ucl, ymin = lcl), alpha = 0.2) +
    geom_line() +
    coord_cartesian(xlim = c(0, NA), expand = F) +
    ggpmisc::geom_text_npc(
      data = data.frame(
        p_value = c(
          get_p_value_of_smooth(bam_amr_wimds, sm = 's(WIMDS)', roundTo = 3),
          get_p_value_of_smooth(bam_amr_wimds, sm = 's(age)'  , roundTo = 3)
        ),
        .var     = c('WIMDS', 'age')
      ), npcx = 'right', npcy = 'bottom', hjust = 'right', size = 3,
      aes(label = paste0('p-value ', p_value)), inherit.aes = F

    ) +



    facet_wrap(
      'smooth',
      labeller = as_labeller(
        c('WIMDS 2011 score', 'Age') %>% sapply(strwrap_at, 22) %>% set_names(c('s(WIMDS)', 's(age)'))
      ),
      strip.position = 'bottom',
      scales = 'free_x'
    ) +

    labs(y = 'Effect', x = element_blank()) +
    theme_minimal() +
    theme1() +
    theme(axis.line.y = element_line(), axis.ticks.y = element_line()) +
    theme(
      strip.placement = 'outside'
    )
) %>%

egg::set_panel_size(width = unit(eggPanelSize$w, 'cm'), height = unit(eggPanelSize$w, 'cm')) -> g0
ggsave(plot = g0, filename = 'output/results/gam_AMR_vs_WIMDS_and_age.pdf', height = pdfPlotDim$h * 0.9, width = pdfPlotDim$w, device = 'pdf')
