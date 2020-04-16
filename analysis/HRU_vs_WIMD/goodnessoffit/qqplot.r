print_qqplots = function() {

  subcohort = 'gpreg1_asthmarx1'

  qq.list = list()

  for (DV in nb[[subcohort]] %>% names) {
    qres. = countreg::qresiduals(nb[[subcohort]][[DV]], type = "random", nsim = 1L, prob = 0.5)
    if (is.null(dim(qres.))) qres. <- matrix(qres., ncol = 1L)
    qnor. = apply(qres., 2L, function(y) qnorm(ppoints(length(y)))[order(order(y))])

    qq.list[[DV]] =
    	data.table(
    		 DV = DV,
    		 qres = qres. %>% as.vector,
    		 qnor = qnor. %>% as.vector
    		)
  }
  qq.dt = do.call(rbind, qq.list)

  qq.dt$DV %<>% factor(levels = outcomes$code)

  qq.dt %<>%
    group_by(DV) %>%
    mutate(density_ = approxfun(density(qres), rule = 2)(qres)) %>%
    ungroup


  gg_qq = ggplot(
    qq.dt #%>% sample_n(1000)
    ,
    aes(x = qnor, y = qres, alpha = density_)) +
  		#geom_point(size = .7, alpha = 0.2) +
  		geom_line(size = 1) +
      #scale_colour_gradient(low = '#cecece',high= '#000000') +
      scale_alpha_continuous(range = c(0.05, 1)) +
  		geom_abline(intercept = 0, slope = 1, linetype = 'dashed', size = .2) +
  		coord_fixed() +

  	  facet_wrap(DV ~ .,
  							 labeller = ggplot2::as_labeller(
  							 	outcomes$label %>%
  							 	 	sapply(
  							 	 		FUN = function(x){stringi::stri_wrap(x, width = 20) %>%
  							 	 				              paste0(collapse = '\n')},
  							 	 		USE.NAMES = F) %>%
  							 	 	set_names(outcomes$code))) +

  		theme(
  		  panel.grid.major = element_blank(),
  		  panel.grid.minor = element_blank(),
  		  panel.spacing.y = unit(1.6, 'lines'),
  		  plot.title = element_text(hjust = 0.5),
  		  strip.text = element_text(size = 8),
  		  legend.position = 'none'
      ) +
  		labs(x = '\nTheoretical quantiles',
  				 y = 'Quantile residuals\n',
  				 title = 'Q-Q residuals plot')

  gg_qq %>% ggsave(file = paste0(outputPath.results, 'qqplot_', subcohort, '_', timeNow(),'.png'),
  								 width = 5,
  								 height = 5,
  								 dpi = 200
  )

}

print_qqplots()
