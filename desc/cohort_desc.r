##################
# general characteristics of the cohorts (Table 1)

cohort_desc_table_dt = list()

create_cohort_desc_table = function(dt0, gpreg, asthmarx) {

	#gpreg = 1; asthmarx = c(0,1)
  #gpreg = 1; asthmarx = c(1)

	# cohort version
	cv = paste0("gpreg", paste0(gpreg, collapse = ''), "_", "asthmarx", paste0(asthmarx, collapse = ''))
	cv %>% print
	data0 = dt0 %>% filter(GPREG %in% gpreg & ASTHMA_RX %in% asthmarx)


	######################################################
	# N and % of WIMDs

	WIMD_N_0 =
	  data0 %>%
	  group_by(WIMD) %>%
	  summarise(N = n()) %>%
	  ungroup %>%
	  arrange(WIMD %>% as.vector)	%>%
	  mutate(pc  = (N / sum(N)) %>% format_pc)

	WIMD_N_0 %<>%
	  rbind(
	    cbind(
	      WIMD = 'All',
	      WIMD_N_0 %>%
	      summarise(N = sum(N), pc = '100.0')
	    )
	  )

	WIMD_N = cbind(
	  rowid = c('WIMD_N', 'WIMD_pc'),
	  'N_patients',
	  c('N', '%'),
	  WIMD_N_0[-1] %>% mutate(N = N %>% format_count) %>% t
	)







	######################################################
	# age  per WIMD

	age_stats_fncs = c('mean', 'SD', 'median', 'IQR')

  age.stats =
    cbind(
      rowid = paste0('age_', age_stats_fncs),
      'age',
      age_stats_fncs,
      rbind(
        data0 %>%
          group_by(WIMD) %>%
          summarise(
            mean   = mean(age)                    %>% round.d(1),
            SD     = sd(age)                      %>% round.d(1),
            median = summary(age)['Median']       %>% round.d(1),
            IQR    = summary(age)[c(2,5)]         %>% round.d(1) %>% paste0(collapse = ', ')
          ) %>%
          ungroup %>%
          arrange(WIMD %>% as.vector)
        ,
        cbind(
          WIMD = 'All',
          data0 %>%
            summarise(
              mean   = mean(age)                  %>% round.d(1),
              SD     = sd(age)                    %>% round.d(1),
              median = summary(age)['Median']     %>% round.d(1),
              IQR    = summary(age)[c(2,5)]       %>% round.d(1) %>% paste0(collapse = ', ')
              )
        )
      ) %>%
      select(-WIMD) %>%
      t
    )

	######################################################
	# current asthma Rx

  ASTHMA_RX_SUM_stats.byWIMD.0 =
      data0 %>%
      select(ASTHMA_RX_SUM, WIMD) %>%
      group_by(WIMD, ASTHMA_RX_SUM) %>%
      summarise(N = n()) %>%
      ungroup %>%
      spread(ASTHMA_RX_SUM, N) %>%
      arrange(WIMD %>% as.vector)

  ASTHMA_RX_SUM_stats.byWIMD =
    list(WIMD = 1:5 %>% as.character) %>%
    cbind.data.frame(
  		ASTHMA_RX_SUM_stats.byWIMD.0 %>%
  		  select(-'WIMD') %>%
  		  divide_by(ASTHMA_RX_SUM_stats.byWIMD.0 %>% select(-'WIMD') %>% rowSums) %>%
  		  format_pc,
      stringsAsFactors = F
    )

  ASTHMA_RX_SUM_stats.AllWIMDs.0 =
    data0 %>%
    select(ASTHMA_RX_SUM, WIMD) %>%
    group_by(ASTHMA_RX_SUM) %>%
    summarise(N = n()) %>%
    ungroup

  ASTHMA_RX_SUM_stats.AllWIMDs =
    'All' %>%
    c(
      ASTHMA_RX_SUM_stats.AllWIMDs.0 %>%
        extract2('N') %>%
        divide_by(ASTHMA_RX_SUM_stats.AllWIMDs.0 %>% extract2('N') %>% sum) %>%
        format_pc
    )

  ASTHMA_RX_SUM_stats =
    cbind(
      'rowid' = paste0('pcYrWRx_', ASTHMA_RX_SUM_stats.byWIMD[-1] %>% names),
  		'Lbl'   = 'pcYrWRx',
  		'Years' = c((ASTHMA_RX_SUM_stats.byWIMD %>% colnames)[-1]),
  	  ASTHMA_RX_SUM_stats.byWIMD %>%
  	    rbind(ASTHMA_RX_SUM_stats.AllWIMDs) %>%
        select(-WIMD) %>%
        t
    )


  ######################################################


	summary0 = list()         # per WIMD
	summary.allWIMD = list()  # all-WIMD

	data0 %<>%
	  mutate(GNDR = as.numeric(GNDR_CD %>% as.character) - 1)

	vars_ = vars %>% filter(method == 'integer')
	for (io in  1:nrow(vars_))		{
		var0      = vars_[io,'var']
		format.io = vars_[io,'dec']

		summary0[[var0]] =
		  data0 %>%
		  group_by(WIMD) %>%
		  summarise(
		    mean        =  mean(!!as.name(var0), na.rm = T) %>% round.d(format.io),
		    pcNotZero   =  sum(!!as.name(var0) > 0, na.rm = T) %>%
		      divide_by(n()) %>%
		      format_pc
		  ) %>%
		  ungroup %>%
		  arrange(WIMD %>% as.vector)

		summary.allWIMD[[var0]] =
		  data0 %>%
		  summarise(
		    mean        =  mean(!!as.name(var0), na.rm = T) %>% round(digits = format.io) %>% format(nsmall = format.io),
		    pcNotZero   =  sum(!!as.name(var0) > 0, na.rm = T) %>%
		      divide_by(n()) %>%
		      format_pc
			 )
	}

	vars.summuries.fncs = summary0[[1]] %>% select(-WIMD) %>% names

	# merge
	vars.summuries.dt =
	  cbind(
	    rowid = paste0_2(vars_[,'var'], vars.summuries.fncs),
		  rep(vars_[,'var'], each = 2),
		  vars.summuries.fncs,
		  cbind(
        summary0 %>%
        lapply(select, -WIMD) %>%
        lapply(t) %>%
        do.call(what = rbind)
        ,
    	  summary.allWIMD %>%
        lapply(t) %>%
        do.call(what = rbind)
      )
		)

	###

  final_table =
    WIMD_N %>%
    rbind(vars.summuries.dt %>% as.matrix)

	if(0 %in% asthmarx)
	  final_table %<>%
    rbind(ASTHMA_RX_SUM_stats %>% as.matrix)

	final_table %<>%
	  rbind(age.stats %>% as.matrix) %>%
	  as_tibble(.name_repair='minimal') %>%
	  set_colnames(c('rowid', 'var', 'statistic', WIMD.labels$code , 'all')) %>%
	  set_rownames(value=c())

	# clean rows
	final_table %<>%
	  filter(!rowid %in% c(
	    'GNDR_mean',
	    'AMR_pcNotZero',
	    'ASTHMA_LOS_pcNotZero'
	    ))

	# arrange rows
	final_table %<>%
	  arrange(
	    match(
	      final_table$rowid,
	      c(
	        'WIMD_N', 'WIMD_pc',

	        'GNDR_pcNotZero',

	        'age_' %>% paste0(age_stats_fncs),

          vars %>% filter(group == 'HRU') %>% extract2('var') %>% paste0_2(vars.summuries.fncs),

          vars %>% filter(group == 'rx')  %>% extract2('var') %>% paste0_2(vars.summuries.fncs)
	      )
      )
	  )

	final_table %<>%
	  mutate(var =
	  (vars$title %>% set_names(vars$var))[final_table$var] %>%
	  as.vector %>%
	  replace(
	    list = final_table$var %>% duplicated %>% which,
	    values = ''
	  )
	) %>%

	mutate(statistic = statistic %>% replace(statistic == 'pcNotZero', '% count $\\geq$ 1'))

  cohort_desc_table_dt[[cv]] <<- final_table

  sink(file  = paste0(outputPath.results, 'descriptive_1_', cv, '.txt') %>% timeNow.before.ext)
  options(width = 200)

  final_table %<>%
    knitr::kable() %>%
	  print

	sink()

}


for (gpreg      in list(1, c(0,1)))
  for (asthmarx in list(1, c(0,1)))
    create_cohort_desc_table(cohort.dt, gpreg = gpreg, asthmarx = asthmarx)


#------------------------------------
# The cohort was identified from ##.#% of population:
  paste0("
    SELECT   count(distinct ALF_PE)
    FROM     ", DS$GPREG, "
    WHERE    START_DATE < '", followup[1], "'
       AND   END_DATE   > '", followup[1], "'
  ") %>% sqlQuery2 %>% unlist %>% as.vector %>% divide_by(3082412) # number obtained from statswales.gov.wales
#
# paste0("
#   SELECT   count(distinct ALF_PE)
#   FROM     ", DS$WDS_PERS, "
#   WHERE    WOB <= '", followup[1], "'
#     AND   (DOD  >= '", followup[2], "' OR DOD IS NULL)
# ") %>% sqlQuery2

#------------------------------------
