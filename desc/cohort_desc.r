 # general characteristics of the cohorts (Table 1)

cohort_desc_table_dt = list()

create_cohort_desc_table = function(dt0, gpreg, asthmarx) {

	# cohort version
	cv = paste0("gpreg", paste0(gpreg, collapse = ''), "_", "asthmarx", paste0(asthmarx, collapse = ''))
	cv %>% print
	data0 = dt0 %>% filter(GPREG %in% gpreg & ASTHMA_RX %in% asthmarx)

	######################################################

	# N and % of WIMDQs

	WIMDQ_N_0 =
	  data0 %>%
	  group_by(WIMDQ) %>%
	  summarise(N = n()) %>%
	  ungroup %>%
	  arrange(WIMDQ %>% as.vector)	%>%
	  mutate(pc  = (N / sum(N)) %>% format_pc)

	WIMDQ_N_0 %<>%
	  rbind(
	    cbind(
	      WIMDQ = 'All',
	      WIMDQ_N_0 %>%
	      summarise(N = sum(N), pc = '100.0')
	    )
	  )

	WIMDQ_N = cbind(
	  rowid = c('WIMDQ_N', 'WIMDQ_pc'),
	  'N_patients',
	  c('N', '%'),
	  WIMDQ_N_0[-1] %>% mutate(N = N %>% format_count) %>% t
	)

	######################################################

	# age  per WIMDQ

	age_stats_fncs = c('mean', 'SD', 'median', 'IQR')

  age.stats =
    cbind(
      rowid = paste0('age_', age_stats_fncs),
      'age',
      age_stats_fncs,
      rbind(
        data0 %>%
          group_by(WIMDQ) %>%
          summarise(
            mean   = mean(age)                    %>% round.d(1),
            SD     = sd(age)                      %>% round.d(1),
            median = summary(age)['Median']       %>% round.d(1),
            IQR    = summary(age)[c(2,5)]         %>% round.d(1) %>% paste0(collapse = ', ')
          ) %>%
          ungroup %>%
          arrange(WIMDQ %>% as.vector)
        ,
        cbind(
          WIMDQ = 'All',
          data0 %>%
            summarise(
              mean   = mean(age)                  %>% round.d(1),
              SD     = sd(age)                    %>% round.d(1),
              median = summary(age)['Median']     %>% round.d(1),
              IQR    = summary(age)[c(2,5)]       %>% round.d(1) %>% paste0(collapse = ', ')
              )
        )
      ) %>%
      select(-WIMDQ) %>%
      t
    )

	######################################################

	# current asthma Rx

  ASTHMA_RX_SUM_stats.byWIMDQ.0 =
      data0 %>%
      select(ASTHMA_RX_SUM, WIMDQ) %>%
      group_by(WIMDQ, ASTHMA_RX_SUM) %>%
      summarise(N = n()) %>%
      ungroup %>%
      spread(ASTHMA_RX_SUM, N) %>%
      arrange(WIMDQ %>% as.vector)

  ASTHMA_RX_SUM_stats.byWIMDQ =
    list(WIMDQ = 1:5 %>% as.character) %>%
    cbind.data.frame(
  		ASTHMA_RX_SUM_stats.byWIMDQ.0 %>%
  		  select(-'WIMDQ') %>%
  		  divide_by(ASTHMA_RX_SUM_stats.byWIMDQ.0 %>% select(-'WIMDQ') %>% rowSums) %>%
  		  format_pc,
      stringsAsFactors = F
    )

  ASTHMA_RX_SUM_stats.AllWIMDQs.0 =
    data0 %>%
    select(ASTHMA_RX_SUM, WIMDQ) %>%
    group_by(ASTHMA_RX_SUM) %>%
    summarise(N = n()) %>%
    ungroup

  ASTHMA_RX_SUM_stats.AllWIMDQs =
    'All' %>%
    c(
      ASTHMA_RX_SUM_stats.AllWIMDQs.0 %>%
        extract2('N') %>%
        divide_by(ASTHMA_RX_SUM_stats.AllWIMDQs.0 %>% extract2('N') %>% sum) %>%
        format_pc
    )

  ASTHMA_RX_SUM_stats =
    cbind(
      'rowid' = paste0('pcYrWRx_', ASTHMA_RX_SUM_stats.byWIMDQ[-1] %>% names),
  		'Lbl'   = 'pcYrWRx',
  		'Years' = c((ASTHMA_RX_SUM_stats.byWIMDQ %>% colnames)[-1]),
  	  ASTHMA_RX_SUM_stats.byWIMDQ %>%
  	    rbind(ASTHMA_RX_SUM_stats.AllWIMDQs) %>%
        select(-WIMDQ) %>%
        t
    )

  ######################################################

  mean_median_Q1Q3 = function(x, method, dec){
    if(method == 'integer') x %<>% divide_by(5)
    paste0(
      x %>% mean(na.rm = T)                    %>% round.d(dec),
      ', ',
      x %>% median(na.rm = T)                  %>%       (function(x){ifelse(method == 'integer', x, round.d(x, dec))}),
      ' (',
      x %>% quantile(c(0.25, 0.75), na.rm = T) %>% lapply(function(x){ifelse(method == 'integer', x, round.d(x, dec))}) %>% paste0(collapse = '-'),
      ')'
    )
  }

  ######################################################
  # summary of other variables

	summary0 = list()         # per WIMDQ
	summary.allWIMDQ = list()  # all-WIMDQ

	data0 %<>%
	  mutate(GNDR = as.numeric(GNDR_CD %>% as.character) - 1)

	vars_ = vars %>% filter(method %in% c('integer', 'decimal'))

	for (io in  1:nrow(vars_))		{
		var0      = vars_[io,'var']
		summary0[[var0]] =
		  data0 %>%
		  group_by(WIMDQ) %>%
		  summarise(
		    mean_median_Q1Q3  = mean_median_Q1Q3(!!as.name(var0), vars_[io,'method'], vars_[io,'dec']),
		    pcNotZero         = sum(!!as.name(var0) > 0, na.rm = T) %>%
		      divide_by(n()) %>%
		      format_pc
		  ) %>%
		  ungroup %>%
		  arrange(WIMDQ %>% as.vector)

		summary.allWIMDQ[[var0]] =
		  data0 %>%
		  summarise(
		    mean_median_Q1Q3  = mean_median_Q1Q3(!!as.name(var0), vars_[io,'method'], vars_[io,'dec']),
		    pcNotZero        = sum(!!as.name(var0) > 0, na.rm = T) %>%
		      divide_by(n()) %>%
		      format_pc
			 )
	}

	vars.summuries.fncs = summary0[[1]] %>% select(-WIMDQ) %>% names

	# merge

	vars.summuries.dt =
	  cbind(
	    rowid = paste0_2(vars_[,'var'], vars.summuries.fncs),
		  rep(vars_[,'var'], each = 2),
		  vars.summuries.fncs,
		  cbind(
        summary0 %>%
        lapply(select, -WIMDQ) %>%
        lapply(t) %>%
        do.call(what = rbind)
        ,
    	  summary.allWIMDQ %>%
        lapply(t) %>%
        do.call(what = rbind)
      )
		)

	###

  final_table =
    WIMDQ_N %>%
    rbind(vars.summuries.dt %>% as.matrix)

	if(0 %in% asthmarx)
	  final_table %<>%
    rbind(ASTHMA_RX_SUM_stats %>% as.matrix)

	final_table %<>%
	  rbind(age.stats %>% as.matrix) %>%
	  as_tibble(.name_repair='minimal') %>%
	  set_colnames(c('rowid', 'var', 'statistic', WIMDQ_info$code , 'all')) %>%
	  set_rownames(value=c())

	# clean rows
	final_table %<>%
	  filter(!rowid %in% c(
	    'GNDR_mean_median_Q1A3',
	    'AMR_pcNotZero',
	    'ASTHMA_LOS_pcNotZero'
	    ))

	# arrange rows
	final_table %<>%
	  arrange(
	    match(
	      final_table$rowid,
	      c(
	        'WIMDQ_N', 'WIMDQ_pc',
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

  ") %>% sqlQuery2 %>% unlist %>% as.vector %>% divide_by(3082412) # publicly available number obtained from statswales.gov.wales



# distribution of WIMD overall score across WIMD overall quintiles

(
  cohort.dt %>% filter(ASTHMA_RX == 1 & GPREG == 1) %>%
  pull(WIMDS) %>%
    density(bw = 3) %>%
    as.data.frame %>%
    mutate(WIMDQ = cut(x, breaks = c(0, WIMDQ_info$WIMDS_max), right = F, labels = WIMDQ_info$code) %>%
             factor(levels = WIMDQ_info$code %>% rev)) %>%
    filter(x %>% between(WIMDQ_info$WIMDS_min %>% min, WIMDQ_info$WIMDS_max %>% max)) %>%
    ggplot(aes(x = x, y = y, fill = WIMDQ)) +
    geom_area() +
  coord_cartesian(expand = T) +
    labs(x = 'WIMD 2011 score', y = 'Density', subtitle = 'WIMD 2011 score quintiles')+
    scale_fill_manual(
      values = WIMDQ.colr %>% rev,
      breaks = WIMDQ_info$code,
      labels = WIMDQ_info$label %>% stringr::str_wrap(10) %>% rev,
      guide = guide_legend(label.position = 'top')
    )+
  theme_minimal() +
  theme1() +
    theme(plot.subtitle = element_text(hjust = 0.5),
          legend.position = 'top', legend.key.width = unit(1, 'cm'), legend.text = element_text(size = 9),
          axis.line.y = element_line(),
          axis.ticks.y = element_line(),
          )
) %>%
  egg::set_panel_size(width = unit(eggPanelSize$w * 2.7, 'cm'), height = unit(eggPanelSize$h * 1, 'cm')) -> g0
ggsave(plot = g0, filename = 'output/results/WIMDQ_vs_WIMDS.pdf', height = pdfPlotDim$h * 1.2, width = pdfPlotDim$w * 1, device = 'pdf')

