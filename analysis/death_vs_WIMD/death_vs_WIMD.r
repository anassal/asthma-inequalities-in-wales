# extract asthma-related deaths
#   among people with WOB < '2013-01-01' AND WIMD IS NOT NULL AND ASTHMA_DX_CURRENT = 1

paste0("
	SELECT CS.WIMDQ,
	       CS.WIMDS,
	       CS.WIMDR,

	       CS.INCS,
	       CS.EMPS,
	       CS.HLTS,
	       CS.EDUS,
	       CS.ACCS,
	       CS.HOSS,
	       CS.ENVS,
	       CS.SAFS,

	       CS.ALF_PE,
	       CS.GNDR_CD,
         CS.WOB,
	       CS.DOD,

	       DATE(D.DEATH_DT) ASTHMA_DEATH_DT,

	       CASE WHEN  LEFT(D.DEATHCAUSE_DIAG_UNDERLYING_CD, 3) IN ('J45', 'J46') THEN 0
	            WHEN  LEFT(D.DEATHCAUSE_DIAG_1_CD,          3) IN ('J45', 'J46') THEN 1
	            WHEN  LEFT(D.DEATHCAUSE_DIAG_2_CD,          3) IN ('J45', 'J46') THEN 2
	            WHEN  LEFT(D.DEATHCAUSE_DIAG_3_CD,          3) IN ('J45', 'J46') THEN 3
	            WHEN  LEFT(D.DEATHCAUSE_DIAG_4_CD,          3) IN ('J45', 'J46') THEN 4
	            WHEN  LEFT(D.DEATHCAUSE_DIAG_5_CD,          3) IN ('J45', 'J46') THEN 5
	            WHEN  LEFT(D.DEATHCAUSE_DIAG_6_CD,          3) IN ('J45', 'J46') THEN 6
	            WHEN  LEFT(D.DEATHCAUSE_DIAG_7_CD,          3) IN ('J45', 'J46') THEN 7
	            WHEN  LEFT(D.DEATHCAUSE_DIAG_8_CD,          3) IN ('J45', 'J46') THEN 8
	            ELSE                                                                  10 -- error
	       END AS POS

	FROM   ", cohortSelectionTable, "    CS

	LEFT JOIN  ", DS$DEATHS, "           D

	  ON   D.ALF_PE = CS.ALF_PE
	  AND  D.DEATH_DT  IS NOT NULL
	  AND  (
	            LEFT(D.DEATHCAUSE_DIAG_UNDERLYING_CD, 3) IN ('J45', 'J46')
	         OR LEFT(D.DEATHCAUSE_DIAG_1_CD, 3) IN ('J45', 'J46')
	         OR LEFT(D.DEATHCAUSE_DIAG_2_CD, 3) IN ('J45', 'J46')
	         OR LEFT(D.DEATHCAUSE_DIAG_3_CD, 3) IN ('J45', 'J46')
	         OR LEFT(D.DEATHCAUSE_DIAG_4_CD, 3) IN ('J45', 'J46')
	         OR LEFT(D.DEATHCAUSE_DIAG_5_CD, 3) IN ('J45', 'J46')
	         OR LEFT(D.DEATHCAUSE_DIAG_6_CD, 3) IN ('J45', 'J46')
	         OR LEFT(D.DEATHCAUSE_DIAG_7_CD, 3) IN ('J45', 'J46')
	         OR LEFT(D.DEATHCAUSE_DIAG_8_CD, 3) IN ('J45', 'J46')
	       )

  WHERE ",
    sql.flowchart.where[(c("none", "WOB", "WIMDQ", "ASTHMA"))] %>%
      lapply(extract2, 'sql') %>% unlist %>% paste0(collapse = ' AND '), "
") %>% SQL2dt -> asthma_deaths

asthma_deaths %<>%
  mutate(
    ASTHMA_DEATH =
      (
           (ASTHMA_DEATH_DT %>% is.na %>% not) %>%
        and(ASTHMA_DEATH_DT %>% between(followup[1] %>% as.Date, followup[2] %>% as.Date))
      )*1,
    POSf = case_when(
      POS == 10 | ASTHMA_DEATH == 0 ~ 'none',
      POS == 0  & ASTHMA_DEATH == 1 ~ 'und',
      POS %>% between(1,8) & ASTHMA_DEATH == 1~ '1_8'
    ),
    age = lubridate::interval(WOB, as.Date(followup[1]))/lubridate::years(1),
    WIMDQ   = WIMDQ %>% factor %>% relevel(ref = 5),
    WIMDS, INCS, EMPS, HLTS, EDUS, ACCS, HOSS, ENVS, SAFS,
    GNDR_CD = GNDR_CD %>% factor(levels = 1:2, labels = c('M', 'F')),
    followup = interval(as_date(followup[1]), ifelse(DOD %>% is.na, as_date(followup[2]), as_date(DOD)) %>% as_date)/years(1)
  )

#---------------------------------

source('analysis/death_vs_WIMD/deaths_fnc.r')

ggplot_facet_labels = WIMD_domains_lables$label %>% set_names(WIMD_domains_lables$code) %>% c(age = 'Age') %>% lapply(function(x){strwrap(x, width = 20) %>% paste0(collapse = '\n')}) %>% unlist

death_glm_WIMDQ = list()
death_glm_WIMDQ_OR_with_RR = list()
subgroup_logreg = list()
subgroup_logreg_output = list()
subgroup_logreg_OR_with_RR__raw_table = list()
ma0        = list() # GAM with global WIMDS smooth
ma1        = list() # GAM with per-gender WIMDS smooths
ma_WIMDS_x_age_bygender_teOnly  = list() # GAM for WIMDS x age interaction
gam_deaths_domains = list() # GAM for each WIMD domain

#-----------------------------------

for(death_pos in list(
  any = list(pos = c('und', '1_8'), bin = 'any'),
  und = list(pos = c('und'       ), bin = 'und')
)){

  death_glm_WIMDQ[[death_pos$bin]] = glm(
    ASTHMA_DEATH ~ WIMDQ + GNDR_CD + age,
    data = asthma_deaths %>% mutate(ASTHMA_DEATH = (POSf %in% death_pos$pos)*1),
    family = 'binomial')


  # Asthma_Death_vs_Gender_within_WIMD_quintiles --------------------------

  subgroup_logreg_raw = list()

  for (WIMD.i in 1:5) {
    subgroup_logreg[[death_pos$bin]][[WIMD.i]] = glm(
      ASTHMA_DEATH ~ GNDR_CD + age,
      data = asthma_deaths %>% filter(WIMDQ == WIMD.i) %>%
        mutate(ASTHMA_DEATH = (POSf %in% death_pos$pos)*1),
      family = 'binomial'
    )

    subgroup_logreg_output[[death_pos$bin]][[WIMD.i]] =
      rbind(
        c('', '', '', ''),
        c(WIMDQ_info %>% filter(code == 'WIMDQ' %>% paste0(WIMD.i)) %>% select(label), '', '', ''),
        subgroup_logreg[[death_pos$bin]][[WIMD.i]] %>%
          print_OR_with_RR(.labels = 'Intercept' %>% c('Gender (female)', 'Age (years)')) %>%
          as.matrix
      )

    subgroup_logreg_OR_with_RR__raw_table[[death_pos$bin]][[WIMD.i]] =
      subgroup_logreg[[death_pos$bin]][[WIMD.i]] %>%
      print_OR_with_RR__raw_table(
        .labels = 'Intercept' %>% c('Gender (female)', 'Age (years)'),
        .rowid = paste0('in_WIMDQ', WIMD.i, '_') %>%
          paste0(subgroup_logreg[[death_pos$bin]][[WIMD.i]]$coefficients %>% names)
      )

    subgroup_logreg_raw[[WIMD.i]] =
      rbind(
        subgroup_logreg_OR_with_RR__raw_table[[death_pos$bin]][[WIMD.i]] %>%
          as.matrix
      )
  }


  sink(paste0('output/results/deaths_subgroup_logistic_regression_models__', death_pos$bin,' .txt'))

  subgroup_logreg_raw %>%
    do.call(what = rbind) %>%
    as_tibble (.name_repair = 'minimal') %>%
    kable %>%
    print

  sink()


  ### GAMs -----------------------

  # global

  ma0[[death_pos$bin]] = mgcv::bam(
    formula = ASTHMA_DEATH ~ s(WIMDS) + s(age) + GNDR_CD,
    data    = asthma_deaths %>% mutate(ASTHMA_DEATH = (POSf %in% death_pos$pos)*1),
    method  = 'fREML', family = 'binomial', cluster = cpu_cluster, chunk.size = 20000
  )

  # separate smooths for males and females

  ma1[[death_pos$bin]] = mgcv::bam(
    formula = ASTHMA_DEATH ~ s(WIMDS, by = GNDR_CD) + s(age) + GNDR_CD,
    data =  asthma_deaths %>% mutate(ASTHMA_DEATH = (POSf %in% death_pos$pos)*1),
    method = 'fREML', family = 'binomial', cluster = cpu_cluster, chunk.size = 20000
  )

  ma_WIMDS_x_age_bygender_teOnly[[death_pos$bin]] = mgcv::bam(
    formula = ASTHMA_DEATH ~ te(WIMDS, age, by = GNDR_CD) + GNDR_CD,
    data =  asthma_deaths %>% mutate(ASTHMA_DEATH = (POSf %in% death_pos$pos)*1),
    method = 'fREML', family = 'binomial', cluster = cpu_cluster, chunk.size = 20000
  )

  gam_deaths_domains[[death_pos$bin]] = list()
  for(domain in c('INCS', 'EMPS', 'HLTS', 'EDUS', 'ACCS', 'HOSS', 'ENVS', 'SAFS')){
    gam_deaths_domains[[death_pos$bin]][[domain]] = mgcv::bam(
      formula = paste0('ASTHMA_DEATH ~ s(', domain , ') + s(age) + GNDR_CD') %>% as.formula,
      data =  asthma_deaths %>% mutate(ASTHMA_DEATH = (POSf %in% death_pos$pos)*1),
      method = 'fREML', family = 'binomial', cluster = cpu_cluster, chunk.size = 20000
    )
  }
}

saveRDS(object = asthma_deaths                 , file = 'data/rds/deaths/asthma_deaths.Rds')
saveRDS(object = death_glm_WIMDQ               , file = 'data/rds/deaths/death_glm_WIMDQ.Rds')
saveRDS(object = subgroup_logreg               , file = 'data/rds/deaths/subgroup_logreg.Rds')
saveRDS(object = ma0                           , file = 'data/rds/deaths/ma0.Rds')
saveRDS(object = ma1                           , file = 'data/rds/deaths/ma1.Rds')
saveRDS(object = ma_WIMDS_x_age_bygender_teOnly, file = 'data/rds/deaths/ma_WIMDS_x_age_bygender_teOnly.Rds')
saveRDS(object = gam_deaths_domains            , file = 'data/rds/deaths/gam_deaths_domains.Rds')

#-----------------------------------------------

for (death_pos_bin in c('any', 'und')){
  print(death_pos_bin)
  death_glm_WIMDQ_OR_with_RR[[death_pos_bin]] =
      death_glm_WIMDQ[[death_pos_bin]] %>%
        print_OR_with_RR__raw_table(
          .labels = 'Intercept' %>% c(WIMDQ_info$label[1:4], 'Gender (female)', 'Age (years)'),
          .rowid = death_glm_WIMDQ[[death_pos_bin]]$coefficients %>% names
        )
}

#-----------------------------------------------

source('analysis/death_vs_WIMD/plots.r')

#-----------------------------------------------

sink('output/results/deaths_GLM_sun.txt')
  death_glm_WIMDQ_OR_with_RR %>% print
  subgroup_logreg_output %>%
    lapply(function(o){
      lapply(o, as.data.frame) %>%
      lapply((function(u){lapply(u, unlist, recursive = T)})) %>%
      lapply(as_tibble) %>%
      do.call(what = rbind) %>%
      as_tibble (.name_repair = 'minimal') %>%
      set_names(c('var', 'OR (95% CI)', 'RR (95% CI)', 'p value')) %>%
      select(-c('OR (95% CI)')) %>%
      kable %>%
      print
    })
sink()

#-----------------------------------------------
