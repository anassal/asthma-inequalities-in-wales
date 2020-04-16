cat('\n\n--------------\nemerge_to_total_admissions ..\n\n')

emerge_to_total_admissions_vs_WIMD_dt =
  cohort.dt %>%
  filter(GPREG == 1 & ASTHMA_RX == 1) %>%
  mutate(WIMD = WIMD %>% factor(levels = 1:5)) %>%
  group_by(WIMD) %>%
  summarise(
		other = sum(PEDW_ASTHMA) - sum(PEDW_ASTHMA_EMERG),
		emerg = sum(PEDW_ASTHMA_EMERG)
  ) %>%
  ungroup %>%
	tidyr::gather('key', 'value', 2:3) %>%
	group_by(WIMD) %>%
	mutate(label. = (value/sum(value)*100) %>%
				 	        format(digits = 1, nsmall = 1) %>% paste0('%')) %>%
	mutate(key = key %>% factor(labels = c('Emergency','Non-emergency'))) %>%
  ungroup

emerge_to_total_admissions_vs_WIMD_plot = function() {
  emerge_to_total_admissions_vs_WIMD_dt %>%
    ggplot(aes(x = WIMD, y = value, fill = relevel(key, 2))) +
  	  geom_bar(stat = 'identity', position = 'stack') +
  	  scale_fill_manual(values = c('#CCCCCC', '#BB9999')) +
  	  geom_text(aes(x = WIMD,
  	  							y = value,
  	  				    	label = label.),
  	  					size = 3,
  	  					color = '#444444',
  	  					position = position_stack(vjust = 0.5)
  	  					) +
  	  scale_x_discrete(labels = WIMD.labels$label %>% gsub(pattern = ' ', replacement = '\n')) +
  	  labs(fill = element_blank(),
  	  		 x = element_blank(),
  	  		 y = 'Count of admissions') +
  	  theme_minimal() +
  	  theme(panel.grid.major = element_blank(),
  	  			panel.grid.minor = element_blank(),
  	  			axis.title.y = element_text(margin = margin(r = 10)),
  	  			axis.ticks.y = element_line(size = 0.5),
  	  			legend.position = c(.8,.9)
  	   ) -> PEDW_ASTHMA_EMERG_vs_total.gg

  	ggsave(
  	  plot = PEDW_ASTHMA_EMERG_vs_total.gg,
  	  filename = paste0(outputPath.results, 'PEDW_ASTHMA_EMERG_vs_total_', timeNow(), '.pdf'),
  	  scale = .48, width = 10, height = 7)
}

emerge_to_total_admissions_vs_WIMD_plot()
