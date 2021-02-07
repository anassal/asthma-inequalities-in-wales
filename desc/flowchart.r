 # flowchart

sql.flowchart.base = paste0("SELECT count(*) FROM ", cohortSelectionTable, " WHERE ")

sql.flowchart.where = list();

sql.flowchart.where[['none'  ]] = list(sql = "1 = 1",
															label = 'had records in WLGP/GPREG')

sql.flowchart.where[['WOB'   ]] = list(sql = paste0("WOB < '", followup[1], "'"),
															label = 'Was born before' %>% paste0(followup[1]))

sql.flowchart.where[['WIMDQ'  ]] = list(sql = paste0("WIMDQ IS NOT NULL "),
															label = 'had a valid WIMDQ')

sql.flowchart.where[['DOD'   ]] = list(sql = paste0("(DOD IS NULL OR DOD > '", followup[2], "')"),
															label = 'where alive at least after ' %>% paste0(followup[1]))

sql.flowchart.where[['GPREG' ]] = list(sql = paste0("GPREG = 1 "),
															label = 'continuous GP registration between ' %>% paste0(followup[1], ' and ', followup[2]))

sql.flowchart.where[['ASTHMA']] = list(sql = paste0("ASTHMA_DX_CURRENT = 1 "),
															label = 'asthma diagnosis before ' %>% paste0(followup[1]))

sql.flowchart.where[['RX'    ]] = list(sql = paste0(
															paste0("ASTHMA_RX_12M_", 1:5," > 0") %>% paste0(collapse = '\nAND\n')
															),
															label = 'asthma prescriptions every year between ' %>% paste0(followup[1], ' and ', followup[2]))

list.of.criteria = sql.flowchart.where %>% names

population.n = c()

for (cirt.i in list.of.criteria %>% seq_along) {
  population.n[cirt.i] =
	  sqlQuery2(sql.flowchart.base,
	  					sql.flowchart.where[list.of.criteria[1:cirt.i]] %>%
	  						lapply(extract2, 'sql') %>%
	  						paste0(collapse = ' AND ')
	  					) %>%
	unlist %>%
	  formatC(big.mark = ',')
}

cohortselection.flowchart =
  rbind(
    list('', 'Population in WDS', sqlQuery2("SELECT COUNT(DISTINCT ", alf, ") FROM ", DS$WDS_PERS) %>%
      unlist	%>% formatC(big.mark = ',')),
    data.frame(
      SQL   = sql.flowchart.where[list.of.criteria] %>% lapply(extract2, 'sql'  )  %>% unlist %>% as.vector,
      Label = sql.flowchart.where[list.of.criteria] %>% lapply(extract2, 'label')  %>% unlist %>% as.vector,
      N     = population.n
    ) %>% as.matrix
  ) %>%
  as.data.frame %>%
  mutate(id = c('WDSPOP', list.of.criteria)) %>%
  mutate(N  = N %>% unlist %>% as.vector)

sink(paste0(outputPath.results, 'cohort_selection_flowchart_', timeNow(),'.txt'))
  cohortselection.flowchart %>%
    select(id, SQL, Label, N) %>%
    pander::pandoc.table(split.cells = c(7, 30, 30, 10), justify = c('left', 'left', 'left', 'right'))
sink()


