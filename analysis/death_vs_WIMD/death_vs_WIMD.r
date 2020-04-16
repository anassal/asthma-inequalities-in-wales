cat('\n\n--------------\nasthma deaths ..\n\n')

asthma_death_models = function () {
  # extract asthma-related deaths
  #   among people with WOB < '2013-01-01' AND WIMD IS NOT NULL AND ASTHMA_DX_CURRENT = 1

  paste0("
  	SELECT CS.WIMD,
  	       CS.ALF_PE,
  	       CS.GNDR_CD,
           CS.WOB,
  	       CS.DOD,
  	       DATE(D.DEATH_DT) ASTHMA_DEATH_DT

  	FROM   ", cohortSelectionTable, "    CS


  	LEFT JOIN  ", DS$DEATHS, "           D

  	  ON   D.ALF_PE = CS.ALF_PE
  	  AND  D.DEATH_DT  IS NOT NULL
  	  AND  (
  	            LEFT(D.DEATHCAUSE_DIAG_1_CD, 3) IN ('J45', 'J46')
  	         OR LEFT(D.DEATHCAUSE_DIAG_2_CD, 3) IN ('J45', 'J46')
  	         OR LEFT(D.DEATHCAUSE_DIAG_3_CD, 3) IN ('J45', 'J46')
  	         OR LEFT(D.DEATHCAUSE_DIAG_4_CD, 3) IN ('J45', 'J46')
  	         OR LEFT(D.DEATHCAUSE_DIAG_5_CD, 3) IN ('J45', 'J46')
  	         OR LEFT(D.DEATHCAUSE_DIAG_6_CD, 3) IN ('J45', 'J46')
  	         OR LEFT(D.DEATHCAUSE_DIAG_7_CD, 3) IN ('J45', 'J46')
  	         OR LEFT(D.DEATHCAUSE_DIAG_8_CD, 3) IN ('J45', 'J46')
  	         OR LEFT(D.DEATHCAUSE_DIAG_UNDERLYING_CD, 3) IN ('J45', 'J46')
  	       )

    WHERE ",

      sql.flowchart.where[(c("none", "WOB", "WIMD", "ASTHMA"))] %>%
        lapply(extract2, 'sql') %>% unlist %>% paste0(collapse = ' AND '), "

  ") %>% SQL2dt -> asthma_deaths # ~10 sec



  asthma_deaths %<>%
    mutate(
      ASTHMA_DEATH = # Boolean
        ASTHMA_DEATH_DT %>% is.na %>% not %>%
        and(ASTHMA_DEATH_DT %>%
            between(followup[1] %>% as.Date, followup[2] %>% as.Date)),

      age = lubridate::interval(WOB, as.Date(followup[1]))/lubridate::years(1),

      WIMD    = WIMD %>% factor %>% relevel(ref = 5),
      GNDR_CD = GNDR_CD %>% factor,
    )


  #---------------

  print_OR_with_RR = function(logit, .labels) {
    rr = sjstats_odds_to_rr_simple_CI(logit)

    logit %>%
      glm.summ(dec=2) %>%
        transmute(
          var = .labels,
          OR = paste0(estimate, ' (', LCL, ', ', UCL, ')'),
          p_value
        ) %>%
      cbind(
        rr %>%
          transmute(
            RR = paste0(
              RR     = `Risk Ratio` %>% round.d(2),
              ' (',
              RR_LCL = CI_low       %>% round.d(2),
              ', ',
              RR_UCL = CI_high      %>% round.d(2),
              ')'
            )
          )
      ) %>%
      select(var, OR, RR, p_value)
  }

  print_OR_with_RR__raw_table = function(logit, .labels, .rowid) {
    rr = sjstats_odds_to_rr_simple_CI(logit)

    cbind(
      .rowid
      ,
      logit %>%
      glm.summ(dec=2) %>%
      transmute(
        var   = .labels,
        OR    = estimate,
        OR_CI = paste0(LCL, ', ', UCL),
        p_value
      ) %>%
      cbind(
        rr %>%
          transmute(
            RR     = `Risk Ratio` %>% round.d(2),
            RR_CI  = paste0(CI_low %>% round.d(2), ', ', CI_high %>% round.d(2))
          )
      )
    )

  }

  #---------------
  # logistic regression

  deaths.glm = glm(ASTHMA_DEATH ~ WIMD + GNDR_CD + age,
  																	data = asthma_deaths, family = 'binomial')


  sink(file = paste0(outputPath.results, 'Asthma_Death_vs_WIMD_glm_raw_', timeNow(), '.txt'))
    deaths.glm %>% summary %>% print
    deaths.glm %>% broom::glance() %>% print
    cat('deviance/null.deviance = ', 1-(deaths.glm$deviance/deaths.glm$null.deviance))
  sink()

  sink(file = paste0(outputPath.results, 'Asthma_Death_vs_WIMD_glm_', timeNow(), '.txt'))
    deaths.glm %>%
      print_OR_with_RR(.labels = 'Intercept' %>% c(WIMD.labels$label[1:4], 'Gender (female)', 'Age (years)')) %>%
      kable %>%
      print
  sink()

  deaths_OR_with_RR__raw_table =
    deaths.glm %>%
      print_OR_with_RR__raw_table(
        .labels = 'Intercept' %>% c(WIMD.labels$label[1:4], 'Gender (female)', 'Age (years)'),
        .rowid = deaths.glm$coefficients %>% names
      )

  sink(file = paste0(outputPath.results, 'Asthma_Death_vs_WIMD_glm_data_', timeNow(), '.txt'))
    deaths_OR_with_RR__raw_table %>%
      kable %>%
      print
  sink()


  # Asthma_Death_vs_Gender_within_WIMD_quintiles --------------------------

  subgroup_logit = list()
  subgroup_logit_output = list()
  subgroup_logit_raw = list()
  subgroup_logit_OR_with_RR__raw_table = list()

  for (WIMD.i in 1:5) {

    subgroup_logit[[WIMD.i]] = glm(
      ASTHMA_DEATH ~ GNDR_CD + age,
      data = asthma_deaths %>% filter(WIMD == WIMD.i), family = 'binomial'
    )

    subgroup_logit_output[[WIMD.i]] =
      rbind(
        c('', '', '', ''),
        c(WIMD.labels %>% filter(code == 'WIMD' %>% paste0(WIMD.i)) %>% select(label), '', '', ''),
        subgroup_logit[[WIMD.i]] %>%
          print_OR_with_RR(.labels = 'Intercept' %>% c('Gender (female)', 'Age (years)')) %>%
          as.matrix
      )

    subgroup_logit_OR_with_RR__raw_table[[WIMD.i]] =
      subgroup_logit[[WIMD.i]] %>%
      print_OR_with_RR__raw_table(
        .labels = 'Intercept' %>% c('Gender (female)', 'Age (years)'),
        .rowid = paste0('in_WIMD', WIMD.i, '_') %>% paste0(subgroup_logit[[WIMD.i]]$coefficients %>% names)
      )

    subgroup_logit_raw[[WIMD.i]] =
      rbind(
        subgroup_logit_OR_with_RR__raw_table[[WIMD.i]] %>%
          as.matrix
      )
  }

  sink(file = paste0(outputPath.results, 'Asthma_Death_vs_Gender_within_WIMD_quintiles_', timeNow(), '.txt'))
    subgroup_logit_output %>%
      do.call(what = rbind) %>%
      as_tibble (.name_repair = 'minimal') %>%
      set_names(c('var', 'OR (95% CI)', 'RR (95% CI)', 'p value')) %>%
      kable %>%
      print
  sink()

  sink(file = paste0(outputPath.results, 'Asthma_Death_vs_Gender_within_WIMD_quintiles_data', timeNow(), '.txt'))
    subgroup_logit_raw %>%
      do.call(what = rbind) %>%
      as_tibble (.name_repair = 'minimal') %>%
      kable %>%
      print
  sink()

  #--------------------------
  asthma_death_models = list(deaths.glm, subgroup_logit)
  save(asthma_death_models, file = paste0('data/Asthma_Death_vs_WIMD_glm_', timeNow(), '.Rdata'))


  #- fill values in the custom output (co) list ---------------

  deathsPercentChange = function(.glm, IV)
    .glm %>% coef %>% exp %>% .[[IV]] %>% subtract(1) %*% 100 %>% round.d(1) %>% paste0('%')

  deaths_OR_CI = function(.glm, IV)
    .glm %>% coef %>% exp %>% .[[IV]] %>% round.d(2) %>%
      paste0(
        ' [',
        .glm %>% confint.default %>% exp %>% .[IV, ] %>% round.d(2) %>% paste0(collapse = ', '),
        ']')


  deaths_RR_CI = function(IV)
    deaths_OR_with_RR__raw_table %>% filter(.rowid == IV) %>% transmute(RR %>% paste0(' [', RR_CI, ']')) %>% unlist %>% as.vector

  deaths_RR    = function(IV)
    deaths_OR_with_RR__raw_table %>% filter(.rowid == IV) %>% transmute(RR                             ) %>% unlist %>% as.vector


  deaths_in_WIMD_RR_CI = function(.WIMD, IV)
    subgroup_logit_OR_with_RR__raw_table[[.WIMD]] %>% filter(.rowid == IV) %>% transmute(RR %>% paste0(' [', RR_CI, ']')) %>% unlist %>% as.vector


  co$DeathAsthmaPopN                 <<- asthma_deaths %>% nrow %>% format_count

  co$DeathAsthmaDeathN               <<- asthma_deaths %>% filter(ASTHMA_DEATH == T) %>% nrow %>% format_count

  co$DeathWimdOnePcChange            <<- deathsPercentChange(deaths.glm, 'WIMD1')

  co$DeathWimdOneOrCI                <<- deaths_OR_CI(deaths.glm, 'WIMD1')

  co$DeathWimdOneOr                  <<- deaths.glm %>% coef %>% exp %>% .[['WIMD1']] %>% round.d(2)

  co$DeathWimdOneRrCI                <<- deaths_RR_CI('WIMD1')

  co$DeathWimdOneRr                  <<- deaths_RR('WIMD1')

  co$DeathFemalePcChange             <<- deathsPercentChange(deaths.glm, 'GNDR_CD2')

  co$DeathFemaleOrCI                 <<- deaths_OR_CI(deaths.glm, 'GNDR_CD2')

  co$DeathFemaleRrCI                 <<- deaths_RR_CI('GNDR_CD2')

  co$DeathFemaleRr                   <<- deaths_RR('GNDR_CD2')

  co$DeathWimdOneFemalePcChange      <<- deathsPercentChange(subgroup_logit[[1]], 'GNDR_CD2')

  co$DeathWimdOneFemaleOrCI          <<- deaths_OR_CI(subgroup_logit[[1]], 'GNDR_CD2')

  co$DeathWimdOneFemaleRrCI          <<- deaths_in_WIMD_RR_CI(1, 'in_WIMD1_GNDR_CD2')

  co$DeathWimdFiveFemalePcChange     <<- deathsPercentChange(subgroup_logit[[5]], 'GNDR_CD2')

  co$DeathWimdFiveFemaleOrCI         <<- deaths_OR_CI(subgroup_logit[[5]], 'GNDR_CD2')

  co$DeathWimdFiveFemaleRrCI         <<- deaths_in_WIMD_RR_CI(5, 'in_WIMD5_GNDR_CD2')

}

asthma_death_models()
