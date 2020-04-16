prevalence_start_date = followup[1]
prevalence_end_date   = as.Date(followup[1]) + lubridate::years(1) - lubridate::days(1)
prevalence_table = tibble()

print_prevalence = function() {

  ASTHMA_DX_CURRENT.xtab = paste0("

  			SELECT WIMD,
  			 		GNDR_CD,
  			 		AGE_GRP,
  			 		ASTHMA_DX_CURRENT,
  			 		COUNT(ASTHMA_DX_CURRENT) AS N

  			 FROM   (
  					 	SELECT 	WIMD,
  					 			    GNDR_CD,
  					 			    CEILING((DAYS('", prevalence_start_date, "')-DAYS(WOB))/365.25/5) AS AGE_GRP,
  					 			    ASTHMA_DX_CURRENT

  						FROM    ", cohortSelectionTable, "  CS
  						JOIN    ", DS$GPREG, "               GPREG
  						   ON   GPREG.ALF_PE = CS.ALF_PE
                 AND  START_DATE <= '", prevalence_start_date, "' AND END_DATE >= '", prevalence_end_date, "'
  						   AND 	WOB <  '", prevalence_start_date, "'
  						   AND  (DOD > '", prevalence_end_date, "'
  						         OR DOD IS NULL)
  				    )

  			 GROUP BY
  			 		WIMD,
  			 		GNDR_CD,
  			 		AGE_GRP,
  			 		ASTHMA_DX_CURRENT

  			 ORDER BY
  			 		WIMD,
  			 		GNDR_CD,
  			 		AGE_GRP,
  			 		ASTHMA_DX_CURRENT
  	") %>% SQL2dt %>% filter(!WIMD %>% is.na) %>% setDT

  ASTHMA_DX_RX.xtab = paste0("
  		SELECT WIMD,
  			 		GNDR_CD,
  			 		AGE_GRP,
  			 		ASTHMA_DX_RX,
  			 		COUNT(ASTHMA_DX_RX) AS N

  			 FROM   (
  					 	SELECT 	WIMD,
  					 			    GNDR_CD,
  					 			    CEILING((DAYS('", prevalence_start_date, "')-DAYS(WOB))/365.25/5) AS AGE_GRP,
  					 			    ASTHMA_DX_CURRENT > 0 AND ASTHMA_RX_12M_1 > 0 AS ASTHMA_DX_RX

              FROM    ", cohortSelectionTable, "  CS
  						JOIN    ", DS$GPREG, "               GPREG
  						   ON   GPREG.ALF_PE = CS.ALF_PE
                 AND  START_DATE <= '", prevalence_start_date, "' AND END_DATE >= '", prevalence_end_date, "'
  						   AND 	WOB <  '", prevalence_start_date, "'
  						   AND  (DOD > '", prevalence_end_date, "' OR DOD IS NULL)
  				    )

  			 GROUP BY
  			 		WIMD,
  			 		GNDR_CD,
  			 		AGE_GRP,
  			 		ASTHMA_DX_RX

  			 ORDER BY
  			 		WIMD,
  			 		GNDR_CD,
  			 		AGE_GRP,
  			 		ASTHMA_DX_RX
  		 		") %>% SQL2dt %>% filter(!WIMD %>% is.na) %>% setDT

  #--------------  n/N

  prev.tables = list()

  prev.tables[['ASTHMA_DX_CURRENT']] = rbind(
    (
      merge(
        ASTHMA_DX_CURRENT.xtab[ASTHMA_DX_CURRENT == 1, list(n = sum(N)),by = WIMD],
        ASTHMA_DX_CURRENT.xtab[                      , list(N = sum(N)),by = WIMD],
        by = 'WIMD'
      )
    )[, prev := n/N]
    ,
  	list(
  	  'All',
  	  ASTHMA_DX_CURRENT.xtab[ASTHMA_DX_CURRENT == 1, sum(N)],
  	  ASTHMA_DX_CURRENT.xtab[                      , sum(N)],
  	  ASTHMA_DX_CURRENT.xtab[ASTHMA_DX_CURRENT == 1, sum(N)] /
  	  ASTHMA_DX_CURRENT.xtab[                      , sum(N)]
  	)
  ) %>%
  as_tibble %>%
  rowwise() %>%
  mutate(LCL = prop.test(n, N) %>% extract2('conf.int') %>% .[1]) %>%
  mutate(UCL = prop.test(n, N) %>% extract2('conf.int') %>% .[2]) %>%
  setDT

  prev.tables[['ASTHMA_DX_RX']] = rbind(
    (
      merge(
        ASTHMA_DX_RX.xtab[ASTHMA_DX_RX == 1, list(n = sum(N)),by = WIMD],
        ASTHMA_DX_RX.xtab[                 , list(N = sum(N)),by = WIMD],
        by = 'WIMD'
        )
    )[, prev := n/N]
  	,
  	list('All',
  		ASTHMA_DX_RX.xtab[ASTHMA_DX_RX == 1, sum(N)],
  		ASTHMA_DX_RX.xtab[                 , sum(N)],
  		ASTHMA_DX_RX.xtab[ASTHMA_DX_RX == 1, sum(N)] /
  	  ASTHMA_DX_RX.xtab[                 , sum(N)]
  	)
  ) %>%
  as_tibble %>%
  rowwise() %>%
  mutate(LCL = prop.test(n, N) %>% extract2('conf.int') %>% .[1]) %>%
  mutate(UCL = prop.test(n, N) %>% extract2('conf.int') %>% .[2]) %>%
  setDT


  # format numbers

  for (pt in seq_along(prev.tables)) {
  	prev.tables[[pt]][, (c('n', 'N'))             := lapply(.SD, formatC, big.mark = ',') ,.SDcols = c('n', 'N')]
  	prev.tables[[pt]][, (c('prev', 'LCL', 'UCL')) := lapply(.SD, function(x) x %>% multiply_by(100) %>% round(digits = 1) %>% format(nsmall = 1)), .SDcols = c('prev', 'LCL', 'UCL')]
  }

  #

  output = cbind(
    c(
      'Denominator',
      '\\textit{Ever-diagnosed asthma}',
      'N',
      'Prevalence',
      '\\textit{Ever-diagnosed, currently-treated asthma}',
      'N',
      'Prevalence'
    )
    ,
    rbind(
      'N' = prev.tables[[1]] %>% extract2('N'),
      rep('', 6),
      prev.tables$ASTHMA_DX_CURRENT %>% transmute(n, prev = paste0(prev, ' (', LCL, ', ', UCL, ')')) %>% t,
      rep('', 6),
      prev.tables$ASTHMA_DX_RX      %>% transmute(n, prev = paste0(prev, ' (', LCL, ', ', UCL, ')')) %>% t
    )
  ) %>%
  as_tibble(.name_repair =  'minimal') %>%
  set_colnames(c('', 'WIMD' %>% paste(1:5), 'all'))

  prevalence_table <<-
    cbind(
      .rowid = c('denom', '', 'everDx_numerator', 'everDx_prevalence', '', 'everdx_currRx_numerator', 'everdx_currRx_prevalence'),
      output
  )


  #----------
  sink(file = paste0(
    outputPath.results,
    'prevalence_between_', prevalence_start_date, '_', prevalence_start_date,
    '.txt') %>% timeNow.before.ext
  )


  output %>%
    kable %>%
    print %>%

  sink()
  #----------
}

print_prevalence()
