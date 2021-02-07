# PLOT IRR

IRR.plot = function(data0, IV.label, pdf.height = NA, pdf.width = NA, max.y = 5, cohort_version){
	if(is.na(pdf.height)) pdf.height = 7
	if(is.na(pdf.width))  pdf.width  = data0[,IV] %>% unique %>% length + 2
	data0$expr = ''; data0[UCL > max.y, expr := 'x']; data0[UCL > max.y, UCL := max.y]
	outcome_labeller = ggplot2::as_labeller(
	  outcomes$label %>% factor %>%
	    sapply(
	      FUN = function(x){stringi::stri_wrap(x, width = 14) %>%
	          paste0(collapse = '\n')},
	      USE.NAMES = F) %>%
	    set_names(outcomes$code)
  )

	gg_plot =
	  (
      data0 %>%
  	  mutate(
  	    Outcome = Outcome %>% factor(
  	      levels = outcomes$code %>% rev,
  	      labels = outcomes$label %>% rev %>%
            stringr::str_wrap(18)
  	    )) %>%

      ggplot(aes(x = Outcome, y = Estimate,  colour = IV)) +
        geom_hline(yintercept = 1, size = 0.4) +
      	geom_hline(yintercept = 2, size = 0.1) +
        geom_errorbar(aes(ymin = LCL, ymax = UCL),  width = 0, size = .3, position = position_dodge(width = .6)) +
    	  geom_point(size = 1.3, position = position_dodge(width = .6)) +
  	    scale_color_manual(
  	      values = WIMDQ.colr %>% rev,
  	      breaks = paste0('WIMDQ', WIMDQ_info$WIMDQ %>% rev),
  	      labels = WIMDQ_info$label %>% rev
  	    ) +

  	    coord_flip() +
  	    labs(x = element_blank(), y = 'Incidence rate ratio') +
  	  theme_minimal() +
  	  theme(
  	    panel.grid = element_blank(),
  	    axis.ticks.x = element_line(),
  	    axis.line.x = element_line(),
        legend.title = element_blank(),
        axis.title.x = element_text(margin = margin(t = 15))
	  )
	) %>%
  egg::set_panel_size(width = unit(eggPanelSize$w * 2.1, 'cm'), height = unit(eggPanelSize$h * 2.2, 'cm'))

	ggplot2::ggsave(filename = paste0(outputPath.results,
										'IRR_', "Outcome-vs-", gsub(" ", "_", IV.label),
										"-", cohort_version, '-',
										".pdf"),
									plot = gg_plot,
									width  = pdf.width,
									height = pdf.height,
									device = 'pdf'
									)

}


# WIMDQ IRR

bind.outcomes.coef = function(model.coef, IV.rownames, ref.level, levels.order, cohort_version){
	coef.dt.outcomes = list()
	for (outcomeX in as.vector(names(model.coef))) {
	  coef.dt.outcomes[[outcomeX]] = model.coef[[outcomeX]][IV %in% IV.rownames]
	  coef.dt.outcomes[[outcomeX]][, outcomeX := outcomeX]
	  setnames(coef.dt.outcomes[[outcomeX]], c('IV', 'Estimate', 'LCL', 'UCL', 'P', 'sig', 'Outcome'))
	  ref.row = data.frame(ref.level, 1, NA, NA, NA, '', outcomeX) %>% setDT %>% setnames(coef.dt.outcomes[[outcomeX]] %>% names)
	  coef.dt.outcomes[[outcomeX]] = rbindlist(list(coef.dt.outcomes[[outcomeX]], ref.row), use.names = T, fill = F)
	}
	coef.dt.outcomes = do.call(rbind, coef.dt.outcomes)
  coef.dt.outcomes$Outcome %<>% factor(levels = outcomes$code)
  coef.dt.outcomes$IV      %<>% factor(levels = levels.order)
	return(coef.dt.outcomes)
}

print_IRR_plots = function() {
  for (cv0 in names(nb.coef)) {
    IV.rownames = c('WIMDQ1', 'WIMDQ2', 'WIMDQ3', 'WIMDQ4')
  	levels.order = c(IV.rownames, 'WIMDQ5') %>% factor
  	IRR.plot(data0 =
  					 	bind.outcomes.coef(
  					 		model.coef = nb.coef[[cv0]],
  					 		IV.rownames = IV.rownames,
  					 		ref.level = 'WIMDQ5',
  					 		levels.order = levels.order,
  					 		cv0),
  					 IV.label = 'WIMD Quintile',
  					 cohort_version = cv0,
  					 pdf.height = 4.3,
  					 pdf.width  = 6.8)
  }
}
