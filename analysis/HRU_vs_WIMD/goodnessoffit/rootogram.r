print_rootograms = function(min_count = 5) {
  subcohort = 'gpreg1_asthmarx1'
  rootogram.list = list()
  for (DV in outcomes$code) {
    print(paste('rootogram ', DV))
  	mode.count. = nb[[subcohort]][[DV]] %>% model.frame %>% model.response
  	tab.        = mode.count. %>% factor(levels = 0:max(mode.count.)) %>% table
  	pred        = nb[[subcohort]][[DV]] %>% pscl::predprob() %>% colSums
  	rootogram.list[[DV]] = data.table(
  		DV         = DV,
  		count      = union(tab. %>% names, pred %>% names) %>% as.numeric %>% sort,
  		frq.pred   = pred %>% as.vector %>% round,
  		frq.obs    = tab. %>% as.vector
  	)	%>% mutate(
  		point.y    = frq.pred %>% sqrt,
  		rect.ymin  = frq.pred %>% sqrt - frq.obs %>% sqrt,
  		rect.ymax  = frq.pred %>% sqrt,
  		rect.x     = tab. %>% names %>% as.numeric
  	) %>% setDT

  	xmax = min(rootogram.list[[DV]][which(frq.pred >= min_count), max(count)],
  						 rootogram.list[[DV]][which(frq.obs  >= min_count), max(count)])

  	rootogram.list[[DV]] = rootogram.list[[DV]][count <= xmax]

  }

  rootogram.dt = do.call(rbind, rootogram.list)
  rootogram.dt$DV %<>% factor(levels = outcomes$code)

  rect.width = .8

  rootogram.dt %>%
  		ggplot +
    	geom_rect(aes(xmin = rect.x - rect.width/2,
    								xmax = rect.x + rect.width/2,
    								ymin = rect.ymin,
    								ymax = rect.ymax),
    						alpha = 0.5
    						) +
  		geom_point(mapping = aes(x = count, y = point.y), size = 0.8) +
  		geom_line (mapping = aes(x = count, y = point.y)) +
  		geom_abline (slope = 0, intercept = 0) +

  		theme_minimal() +
  	  theme(  aspect.ratio = 1
  				    , panel.grid.major = element_blank()
  						, panel.grid.minor = element_blank()
  						, strip.text.x = element_text()
  						, axis.line.y = element_line()
  						, axis.ticks.y = element_line()
  						) +

  		labs(x = '\nCount',
  				 y = 'Frequency square root\n'
  		) +

  		facet_wrap(DV ~ ., scales = c('free'),
  							 labeller = ggplot2::as_labeller(
  							 	outcomes$label %>%
  							 	 	sapply(
  							 	 		FUN = function(x){stringi::stri_wrap(x, width = 20) %>%
  							 	 				              paste0(collapse = '\n')},

  							 	 		USE.NAMES = F) %>%
  							 	 	set_names(outcomes$code))
  							 ) -> rootogram.gg

  rootogram.filename = paste0(outputPath.results, 'rootograms_', subcohort, timeNow(),'.pdf')

  rootogram.gg %>% ggsave(
  	filename = rootogram.filename,
  	width = 5,
  	height = 5,
  	dpi = 500
  )
}

print_rootograms(min_count = 5)
