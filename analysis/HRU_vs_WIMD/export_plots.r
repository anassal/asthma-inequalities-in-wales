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
		ggplot(data = data0, aes(x = IV, y = Estimate)) +
	  geom_hline(yintercept = 1, alpha = 0.4) +
		geom_hline(yintercept = 2, alpha = 0.1) +
    geom_errorbar(aes(ymin = LCL, ymax = UCL), width = .1, size = .1) +
	  geom_point(size = .7, position = 'dodge') +
    scale_y_continuous(breaks = c(1, 2)) +
    scale_x_discrete(labels =
        WIMD.labels$label %>%
				sapply(
	 	 				FUN = function(x){stringi::stri_wrap(x, width = 12) %>% paste0(collapse = '\n')},
	 	 				USE.NAMES = F
				) %>%
        paste0(c('', '', '', '', '\n(reference)'))
    ) +
		xlab(element_blank()) + ylab('Incidence rate ratio') +
		coord_flip() +
		facet_wrap(
		  Outcome ~ ., nrow = 1, labeller = outcome_labeller
		  ) +
	  theme_minimal() +
		theme(
			    axis.text.x = element_text(angle = 0, hjust = 0.5, vjust = 0, debug = F, margin = margin(6,1,1,1)),
					strip.background = element_blank(),
					strip.text.x = element_text(size = 9, vjust = 1, hjust = 0),
					axis.line   = element_line(),
					axis.line.y = element_blank(),
					axis.ticks.y = element_blank(),
					panel.grid.major.y = element_blank(),
					panel.grid.major.x = element_blank(),
					panel.grid.minor.x = element_blank(),
					panel.spacing = unit(.3, 'lines'),
					panel.background = element_rect(fill = '#F4F4F4', size = 0, color = NA)
		)

	if (data0[expr != '', .N] > 0)
		gg_plot = gg_plot +
		      geom_text(data = data0[expr != ''],
		      					aes(x = IV, y = max.y, label = expr),
		      					size = 5, nudge_y = -.02, nudge_x = -0.005)

	ggplot2::ggsave(filename = paste0(outputPath.results,
										'IRR_', "Outcome-vs-", gsub(" ", "_", IV.label),
										"-", cohort_version, '-', timeNow(), ".pdf"),
									plot = gg_plot,
									width  = pdf.width,
									height = pdf.height
									)
}

# WIMD IRR

bind.outcomes.coef = function(model.coef, IV.rownames, ref.level, levels.order, cohort_version){
	coef.dt.outcomes = list()
	for (outcomeX in as.vector(names(model.coef))) {
	  coef.dt.outcomes[[outcomeX]] = model.coef[[outcomeX]][IV %in% IV.rownames]
	  coef.dt.outcomes[[outcomeX]][, outcomeX := outcomeX]
	  setnames(coef.dt.outcomes[[outcomeX]], c('IV', 'Estimate', 'LCL', 'UCL', 'P', 'sig', 'Outcome'))
	  ref.row = data.frame(ref.level, 1, NA, NA, NA, '', outcomeX) %>% setDT %>% setnames(coef.dt.outcomes[[outcomeX]] %>% names)
	  #print(ref.row)
	  coef.dt.outcomes[[outcomeX]] = rbindlist(list(coef.dt.outcomes[[outcomeX]], ref.row), use.names = T, fill = F)
	  #coef.dt.outcomes[[outcomeX]] %>% print
	}
	coef.dt.outcomes = do.call(rbind, coef.dt.outcomes)
  coef.dt.outcomes$Outcome %<>% factor(levels = outcomes$code)
  coef.dt.outcomes$IV      %<>% factor(levels = levels.order)

	return(coef.dt.outcomes)
}


print_IRR_plots = function() {
  for (cv0 in names(nb.coef)) {
  	# IRR outcomes vs WIMD

    IV.rownames = c('WIMD1', 'WIMD2', 'WIMD3', 'WIMD4')
  	levels.order = c(IV.rownames, 'WIMD5') %>% factor
  	IRR.plot(data0 =
  					 	bind.outcomes.coef(
  					 		model.coef = nb.coef[[cv0]],
  					 		IV.rownames = IV.rownames,
  					 		ref.level = 'WIMD5',
  					 		levels.order = levels.order,
  					 		cv0),
  					 IV.label = 'WIMD Quintile',
  					 cohort_version = cv0,
  					 pdf.height = 4,
  					 pdf.width  = 7)
  }

}
