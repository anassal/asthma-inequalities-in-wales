exportIRR_table = function(coef0, cohort_version = '') {
	for (outcome in outcomes$code)
		names(coef0[[outcome]]) = gsub(outcome, '', names(coef0[[outcome]]))

	tbl = list()
	round0 = 3

	for (outcome in outcomes$code){
		tbl[[outcome]] =
		  coef0[[outcome]][,
				list(
					round(Estimate, round0) %>% format(nsmall = round0),
					paste0(P %>% round.d(3), '  ', sig),
					paste0('(', round(LCL,round0) %>% format(nsmall = round0), ', ', round(UCL,round0) %>% format(nsmall = round0), ')')
					)]

		# reorder
		tbl[[outcome]] = rbind(
			tbl[[outcome]][2:7],
			tbl[[outcome]][1  ]
		) %>% t %>% matrix(nrow = 1) %>% as.data.table

	}

	tbl2 = tbl %>% do.call(what = 'rbind')

	outcomes.colm = list(Outcome = tbl %>% names %>% paste0('')) %>% as.data.table

	tbl3.a =
	  outcomes.colm %>%
	  cbind(tbl2[,  1:12, with=F]) %>%
	  mutate(Outcome = outcomes %>% filter(code == Outcome) %>% extract2('label')) %>%
	  setnames(-1,
						 rbind(coef0[[1]][c(2:5), IV],
						 						 rep('', 4),
						 						 rep('', 4)) %>% c
						 )

	tbl3.b =
	  outcomes.colm %>%
	  cbind(tbl2[, 13:21, with=F]) %>%
	  mutate(Outcome = outcomes %>% filter(code == Outcome) %>% extract2('label')) %>%
	  setnames(-1,
						 rbind(coef0[[1]][c(6,7,1), IV],
						 						 rep('', 3),
						 						 rep('', 3)) %>% c
						 )

	#---

	tbl3.a %>%
	  kable(format = 'markdown') %>%
	  print

  cat('\n\n')

	tbl3.b %>%
	  kable(format = 'markdown') %>%
	  print
}
