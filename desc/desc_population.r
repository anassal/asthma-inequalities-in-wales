

# source populatin GNDR and age

	pop.age.perWIMD = paste0("
	select WIMD, AVG(age) mean_AGE, STDDEV(age) sd_AGE from (		
		SELECT 	WIMD, 
				(DAYS('2010-01-01') - DAYS(WOB))/365.25 AS AGE
				
		FROM 	SAILW0317V.T44C_EQUITY_cohort_selection_JUN2019
		WHERE 	WOB <  '2010-01-01' AND WOB IS NOT NULL
		AND   (DOD > '2010-12-31' OR DOD IS NULL)
		AND   GPREG IN (1)
	)
	group by WIMD
					
	") %>% SQL2dt	
	
  pop.age.perWIMD =	pop.age.perWIMD[, list(WIMD)] %>% cbind(pop.age.perWIMD[, round(.SD, 1), .SDcol = 2:3])
	
	
	pop.gndr.perWIMD = paste0("
	
	select WIMD, GNDR_CD, COUNT(GNDR_CD) AS N from (		
		SELECT 	WIMD, 
				GNDR_CD
				
		FROM 	SAILW0317V.T44C_EQUITY_cohort_selection_JUN2019
		WHERE 	WOB <  '2010-01-01' AND WOB IS NOT NULL
		AND   (DOD > '2014-12-31' OR DOD IS NULL)
		AND   GPREG IN (1)
	
	)
	group by WIMD, GNDR_CD
	ORDER BY WIMD, GNDR_CD
										 					 
				 ") %>% SQL2dt
	
	(pop.gndr.perWIMD[GNDR_CD == 2, sum(N)]            / pop.gndr.perWIMD[, sum(N)] * 100) %>% round(1)
	
	pop.gndr.perWIMD.2 = (merge(pop.gndr.perWIMD[GNDR_CD == 2, list(nFemale = sum(N)), by = WIMD],
															pop.gndr.perWIMD[, list(N = sum(N)), by = WIMD], by = 'WIMD')
												   [, propFemale := round(nFemale/N*100, 1)]) %>%
		                    mutate(WIMD_prop = N/sum(N)) %>% setDT

	pop.gndr.perWIMD.2[!is.na(WIMD), WIMD_prop.notNA := N/sum(N)]
	
	pop.gndr.perWIMD.2[, nFemale := nFemale %>% formatC(big.mark = ',')]
	pop.gndr.perWIMD.2[, N       := N       %>% formatC(big.mark = ',')]
	 
	pop.gndr.perWIMD.2 %>% merge(pop.age.perWIMD, by = 'WIMD') %>%
		write.table(file = paste0(outputPath.results, 'source_population_age_GNDR_stats_', timeNow(), '.txt'), quote = F, sep = '\t&\t', row.names = F)


  # WIMD% in cohort.dt
		cohort.dt[GPREG == 1 & asthmarx == 1]$WIMD %>% table / cohort.dt[GPREG == 1 & asthmarx == 1, .N]