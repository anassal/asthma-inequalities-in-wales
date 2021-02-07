cat('\n\n--------------\nmisc output ..\n\n')

fill_custom_output = function(load_HRU_model_Rdata = F) {

  if (load_HRU_model_Rdata == T) {
    load(file = paste0('data/HRU_vs_WIMDQ_nb',      ".Rdata"))
    load(file = paste0('data/HRU_vs_WIMDQ_nb_coef', ".Rdata"))
  }

  # % change between a level and the reference level (e.g., 5% more)
  pcChange = function(.DV, .IV, .model) {
    nb.coef[[.model]][[.DV]] %>%
    filter(IV == .IV) %>%
    extract2('Estimate') %>% subtract(1) %>%
    multiply_by(100) %>% round.d(1) %>% paste0('%') %>% return
  }

  IrrCI = function(.DV, .IV, .model) {
    nb.coef[[.model]][[.DV]] %>%
    filter(IV == .IV) %>%
    transmute(Estimate %>% round.d(2) %>%
        paste0(' [', LCL %>% round.d(2), ', ', UCL %>% round.d(2), ']')
    ) %>% unlist %>% as.vector
  }

  get_from_desc_table = function (.rowid, .colid){
    cohort_desc_table_dt$gpreg1_asthmarx1 %>% filter(rowid == .rowid) %>% extract2(.colid)
  }

  # predict a dependent variable (DV) in a WIMDQ group
  WIMDQ_DV_pred = function(DV, WIMDQ) {
    .pred = c()
    for (gndr in 1:2)
      .pred[gndr] = nb$gpreg1_asthmarx1[[DV]] %>% predict(newdata = data.frame(WIMDQ=WIMDQ, age = mean(nb$gpreg1_asthmarx1[[DV]]$model$age), GNDR_CD = gndr %>% as.character)) %>% exp
    gndr_tab = nb$gpreg1_asthmarx1[[DV]]$model$GNDR_CD %>% table
    (.pred * gndr_tab) %>% sum %>% divide_by(gndr_tab %>% sum) %>% return
  }


  co$sourcePopN                     <<- SQL2dt(
                                        "SELECT COUNT(*) FROM ", cohortSelectionTable, "
                                         WHERE ", sql.flowchart.where %>% lapply(extract2, 'sql') %>%
                                                   magrittr::extract(c('NONE', 'WOB', 'WIMDQ')) %>%
                                                   unlist %>% paste(collapse = ' AND ')
                                        ) %>%
                                        unlist %>% as.vector %>% format_count

  mainCohortN_int                   <<- cohort.dt %>% filter(GPREG == 1 & ASTHMA_RX == 1) %>% nrow

  co$mainCohortN                    <<- mainCohortN_int %>% format_count

  co$mainCohortPersonYear           <<- mainCohortN_int %>% multiply_by(5) %>% format_count # in years

  #-------------

  co$followupStartDate              <<- followup[1] %>% format.Date('%d %B, %Y') %>% gsub(pattern="^0", replacement="")

  co$followupStartYear              <<- followup[1] %>% format.Date('%Y')

  co$followupEndDate                <<- followup[2] %>% format.Date('%d %B, %Y') %>% gsub(pattern="^0", replacement="")

  co$followupEndYear                <<- followup[2] %>% format.Date('%Y')

  #-------------

  co$mainCohortAgeMean              <<- get_from_desc_table('age_mean'    , 'all')
  co$mainCohortAgeSd                <<- get_from_desc_table('age_SD'      , 'all')
  co$mainCohortFemalePc             <<- get_from_desc_table('GNDR_pcNotZero', 'all')   %>% paste0('%')
  co$mainCohortFemalePcWimdqOne     <<- get_from_desc_table('GNDR_pcNotZero', 'WIMDQ1') %>% paste0('%')
  co$mainCohortFemalePcWimdqFive    <<- get_from_desc_table('GNDR_pcNotZero', 'WIMDQ5') %>% paste0('%')

  #-------------

  co$mainCohortWimdqOnePc           <<- get_from_desc_table('WIMDQ_pc'      , 'WIMDQ1') %>% paste0('%')
  co$mainCohortWimdqOneAgeMean      <<- get_from_desc_table('age_mean'      , 'WIMDQ1')
  co$mainCohortWimdqOneAgeSd        <<- get_from_desc_table('age_SD'        , 'WIMDQ1')
  co$mainCohortWimdqFiveAgeMean     <<- get_from_desc_table('age_mean'      , 'WIMDQ5')
  co$mainCohortWimdqFiveAgeSd       <<- get_from_desc_table('age_SD'        , 'WIMDQ5')

  #-------------

  co$prevEverDx                     <<- prevalence_table %>% filter(.rowid == 'everDx_prevalence')        %>% extract2('all')    %>% paste0('%')

  co$prevEverDxWimdqOne             <<- prevalence_table %>% filter(.rowid == 'everDx_prevalence')        %>% extract2('WIMDQ 1') %>% paste0('%')

  co$prevEverDxWimdqFive            <<- prevalence_table %>% filter(.rowid == 'everDx_prevalence')        %>% extract2('WIMDQ 5') %>% paste0('%')

  co$prevEverDxCurrRx               <<- prevalence_table %>% filter(.rowid == 'everdx_currRx_prevalence') %>% extract2('all')    %>% paste0('%')

  co$prevEverDxCurrRxWimdqOne       <<- prevalence_table %>% filter(.rowid == 'everdx_currRx_prevalence') %>% extract2('WIMDQ 1') %>% paste0('%')

  co$prevEverDxCurrRxWimdqFive      <<- prevalence_table %>% filter(.rowid == 'everdx_currRx_prevalence') %>% extract2('WIMDQ 5') %>% paste0('%')

  #-------------

  co$GpVisitsPcNotZero             <<- get_from_desc_table('ASTHMA_GP_VISITS_pcNotZero', 'all') %>% paste0('%')
  co$GpReviewsPcNotZero            <<- get_from_desc_table('ASTHMA_REVIEW_pcNotZero'   , 'all') %>% paste0('%')
  co$EdPcNotZero                   <<- get_from_desc_table('EDDS_ASTHMA_pcNotZero'     , 'all') %>% paste0('%')
  co$HospPcNotZero                 <<- get_from_desc_table('PEDW_ASTHMA_pcNotZero'     , 'all') %>% paste0('%')

  #-------------

  co$GpVisitsFemalePcChange         <<- 'ASTHMA_GP_VISITS'  %>% pcChange('GNDR_CD2', 'gpreg1_asthmarx1')
  co$GpVisitsFemaleIrrCI            <<- 'ASTHMA_GP_VISITS'  %>% IrrCI(   'GNDR_CD2', 'gpreg1_asthmarx1')
  co$GpReviewFemalePcChange         <<- 'ASTHMA_REVIEW'     %>% pcChange('GNDR_CD2', 'gpreg1_asthmarx1')
  co$GpReviewFemaleIrrCI            <<- 'ASTHMA_REVIEW'     %>% IrrCI(   'GNDR_CD2', 'gpreg1_asthmarx1')

  #-------------

  co$GpVisitsWimdqOnePcChange        <<- 'ASTHMA_GP_VISITS'  %>% pcChange('WIMDQ1'   , 'gpreg1_asthmarx1')
  co$GpVisitsWimdqOneIrrCI           <<- 'ASTHMA_GP_VISITS'  %>% IrrCI(   'WIMDQ1'   , 'gpreg1_asthmarx1')
  co$GpVisitsWimdqOneIrrCILong       <<- gsub('\\[', '[95% CI = ', co$GpVisitsWimdqOneIrrCI)
  co$GpReviewsWimdqOnePcChange       <<- 'ASTHMA_REVIEW'     %>% pcChange('WIMDQ1'   , 'gpreg1_asthmarx1')
  co$GpReviewsWimdqOneIrrCI          <<- 'ASTHMA_REVIEW'     %>% IrrCI(   'WIMDQ1'   , 'gpreg1_asthmarx1')

  #-------------

  co$RxAnyPerYearWimdqOne            <<- cohort.dt %>% filter(GPREG == 1 & ASTHMA_RX == 1) %>%
                                     group_by(WIMDQ) %>% summarise(
                                       (ASTHMA_RX_12M_1 + ASTHMA_RX_12M_2 + ASTHMA_RX_12M_3 + ASTHMA_RX_12M_4 + ASTHMA_RX_12M_5)
                                       %>% mean) %>% ungroup %>%
                                     filter(WIMDQ == '1') %>% extract2(2) %>% divide_by(5) %>% round.d(1)

  co$RxAnyPerYearWimdqFive           <<- cohort.dt %>% filter(GPREG == 1 & ASTHMA_RX == 1) %>%
                                     group_by(WIMDQ) %>% summarise(
                                       (ASTHMA_RX_12M_1 + ASTHMA_RX_12M_2 + ASTHMA_RX_12M_3 + ASTHMA_RX_12M_4 + ASTHMA_RX_12M_5)
                                       %>% mean) %>% ungroup %>%
                                     filter(WIMDQ == '5') %>% extract2(2) %>% divide_by(5) %>% round.d(1)

  co$RxRelieverPerYearWimdqOne       <<- cohort.dt %>% filter(GPREG == 1 & ASTHMA_RX == 1) %>%
                                     group_by(WIMDQ) %>% summarise(SABA %>% mean) %>% ungroup %>%
                                     filter(WIMDQ == '1') %>% extract2(2) %>% divide_by(5) %>% round.d(1)

  co$RxRelieverPerYearWimdqFive      <<- cohort.dt %>% filter(GPREG == 1 & ASTHMA_RX == 1) %>%
                                     group_by(WIMDQ) %>% summarise(SABA %>% mean) %>% ungroup %>%
                                     filter(WIMDQ == '5') %>% extract2(2) %>% divide_by(5) %>% round.d(1)

  co$RxControllerPerYearWimdqOne     <<- cohort.dt %>% filter(GPREG == 1 & ASTHMA_RX == 1) %>%
                                     group_by(WIMDQ) %>% summarise((ICS + ICS_LABA +  NACROM + NEDOCROMIL) %>% mean) %>% ungroup %>%
                                     filter(WIMDQ == '1') %>% extract2(2) %>% divide_by(5) %>% round.d(1)

  co$RxControllerPerYearWimdqFive    <<- cohort.dt %>% filter(GPREG == 1 & ASTHMA_RX == 1) %>%
                                     group_by(WIMDQ) %>% summarise((ICS + ICS_LABA +  NACROM + NEDOCROMIL) %>% mean) %>% ungroup %>%
                                     filter(WIMDQ == '5') %>% extract2(2) %>% divide_by(5) %>% round.d(1)

  #-------------

  co$AmrMeanWimdqOne                 <<- get_from_desc_table('AMR_mean_median_Q1Q3', 'WIMDQ1')
  co$AmrMeanWimdqFive                <<- get_from_desc_table('AMR_mean_median_Q1Q3', 'WIMDQ5')
  co$AmrMeanAbDiffCI                 <<- AMR_vs_WIMDQ15_ttest$estimate %>%
                                     rev %>% diff %>% as.vector %>% round.d(3) %>%
                                     paste0(' [', AMR_vs_WIMDQ15_ttest$conf.int %>% round.d(3) %>% paste0(collapse = ', '), ']')

  co$AmrMeanRatioCI                 <<- AMR_vs_WIMDQ15_ttest$estimate[2:1] %>% (function(x) x[1]/x[2]*100) %>% round.d(1) %>%

                                     paste0('% [',
                                             (100 - rev(AMR_vs_WIMDQ15_ttest$conf.int)/AMR_vs_WIMDQ15_ttest$estimate[1]*100) %>%
                                              round.d(1) %>% paste0('%') %>% paste0(collapse = ', '),
                                            ']')

  #-------------



  co$AmrGamFemaleOrCi               <<-  bam_amr_wimds %>%
                                      gratia::evaluate_parametric_term(term = 'GNDR_CD') %>%
                                      filter(value == 2) %>%
                                      transmute(
                                        est_ci = paste0(
                                          partial %>% exp %>% round.d(3),
                                          ' [',
                                          (partial - qnorm(0.05/2, lower.tail = F) * se) %>% exp %>% round.d(3),
                                          ', ',
                                          (partial + qnorm(0.05/2, lower.tail = F) * se) %>% exp %>% round.d(3),
                                          ']'
                                        )
                                      ) %>% pull(est_ci)

  #-------------

  co$EdWimdqOnePcChange              <<- 'EDDS_ASTHMA'       %>% pcChange('WIMDQ1'   , 'gpreg1_asthmarx1')
  co$EdWimdqOneIrrCI                 <<- 'EDDS_ASTHMA'       %>% IrrCI(   'WIMDQ1'   , 'gpreg1_asthmarx1')
  co$EdWimdqOnePred                  <<- WIMDQ_DV_pred('EDDS_ASTHMA', '1') %>% round.d(3)
  co$EdWimdqFivePred                 <<- WIMDQ_DV_pred('EDDS_ASTHMA', '5') %>% round.d(3)

  #-------------

  co$EdFemalePcChange               <<- 'EDDS_ASTHMA'       %>% pcChange('GNDR_CD2', 'gpreg1_asthmarx1')
  co$EdFemaleIrrCI                  <<- 'EDDS_ASTHMA'       %>% IrrCI(   'GNDR_CD2', 'gpreg1_asthmarx1')

  #-------------

  co$HospEmergWimdqOnePcChange       <<- 'PEDW_ASTHMA_EMERG' %>% pcChange('WIMDQ1'   , 'gpreg1_asthmarx1')
  co$HospEmergWimdqOneIrrCI          <<- 'PEDW_ASTHMA_EMERG' %>% IrrCI(   'WIMDQ1'   , 'gpreg1_asthmarx1')
  co$HospEmergWimdqOneIrr            <<- base::sub(' .*', '', co$HospEmergWimdqOneIrrCI)
  co$HospAllWimdqOnePcChange         <<- 'PEDW_ASTHMA'       %>% pcChange('WIMDQ1'   , 'gpreg1_asthmarx1')
  co$HospAllWimdqOneIrrCI            <<- 'PEDW_ASTHMA'       %>% IrrCI(   'WIMDQ1'   , 'gpreg1_asthmarx1')

  #-------------

  co$LosWimdqOnePcChange             <<- 'ASTHMA_LOS'        %>% pcChange('WIMDQ1'   , 'gpreg1_asthmarx1')
  co$LosWimdqOneIrrCI                <<- 'ASTHMA_LOS'        %>% IrrCI(   'WIMDQ1'   , 'gpreg1_asthmarx1')
  co$LosWimdqOnePred                 <<- WIMDQ_DV_pred('ASTHMA_LOS', '1') %>% round.d(2)
  co$LosWimdqFivePred                <<- WIMDQ_DV_pred('ASTHMA_LOS', '5') %>% round.d(2)

  #-------------

  co$HospEmergToTotalPcWimdqOne     <<- emerge_to_total_admissions_vs_WIMDQ_dt %>% filter(WIMDQ == '1' & key == 'Emergency') %>% extract2('label.')

  co$HospEmergToTotalPcWimdqFive    <<- emerge_to_total_admissions_vs_WIMDQ_dt %>% filter(WIMDQ == '5' & key == 'Emergency') %>% extract2('label.')

  #-------------

  co$HospEmergFemalePcChange        <<- 'PEDW_ASTHMA_EMERG' %>% pcChange('GNDR_CD2', 'gpreg1_asthmarx1')
  co$HospEmergFemaleIrrCI           <<- 'PEDW_ASTHMA_EMERG' %>% IrrCI(   'GNDR_CD2', 'gpreg1_asthmarx1')
  co$HospTotalFemalePcChange        <<- 'PEDW_ASTHMA'       %>% pcChange('GNDR_CD2', 'gpreg1_asthmarx1')
  co$HospTotalFemaleIrrCI           <<- 'PEDW_ASTHMA'       %>% IrrCI(   'GNDR_CD2', 'gpreg1_asthmarx1')

  #-------------

  co$LosFemalePcChange              <<- 'ASTHMA_LOS'        %>% pcChange('GNDR_CD2', 'gpreg1_asthmarx1')

  co$LosFemaleIrrCI                 <<- 'ASTHMA_LOS'        %>% IrrCI(   'GNDR_CD2', 'gpreg1_asthmarx1')

  #- Sensitivity Analysis: Any Rx ------------

  co$cohortAnyRxN                   <<- cohort.dt %>% filter(GPREG == 1                 ) %>% nrow %>% format_count
  co$AnyRxGpVisitsWimdqOneIrrCI      <<- 'ASTHMA_GP_VISITS'  %>% IrrCI(   'WIMDQ1'   , 'gpreg1_asthmarx01')
  co$AnyRxGpReviewsWimdqOneIrrCI     <<- 'ASTHMA_REVIEW'     %>% IrrCI(   'WIMDQ1'   , 'gpreg1_asthmarx01')
  co$AnyRxEdWimdqOneIrrCI            <<- 'EDDS_ASTHMA'       %>% IrrCI(   'WIMDQ1'   , 'gpreg1_asthmarx01')
  co$AnyRxHospEmergWimdqOneIrrCI     <<- 'PEDW_ASTHMA_EMERG' %>% IrrCI(   'WIMDQ1'   , 'gpreg1_asthmarx01')
  co$AnyRxHospAllWimdqOneIrrCI       <<- 'PEDW_ASTHMA'       %>% IrrCI(   'WIMDQ1'   , 'gpreg1_asthmarx01')
  co$AnyRxLosWimdqOneIrrCI           <<- 'ASTHMA_LOS'        %>% IrrCI(   'WIMDQ1'   , 'gpreg1_asthmarx01')

  #- Sensitivity Analysis: Any GPREG ------------

  co$AnyGpregCohortN                <<- cohort.dt %>% filter(             ASTHMA_RX == 1) %>% nrow %>% format_count

  co$AnyGpregCohortPcOfNonContReg   <<- cohort.dt %>% filter(GPREG == 0 & ASTHMA_RX == 1) %>% nrow %>%
                                     divide_by(cohort.dt %>% filter(   ASTHMA_RX == 1) %>% nrow) %>%
                                     format_pc %>% paste0('%')

  co$AnyGpregGpVisitsWimdqOneIrrCI   <<- 'ASTHMA_GP_VISITS'  %>% IrrCI(   'WIMDQ1'   , 'gpreg01_asthmarx1')
  co$AnyGpregGpReviewsWimdqOneIrrCI  <<- 'ASTHMA_REVIEW'     %>% IrrCI(   'WIMDQ1'   , 'gpreg01_asthmarx1')
  co$AnyGpregEdWimdqOneIrrCI         <<- 'EDDS_ASTHMA'       %>% IrrCI(   'WIMDQ1'   , 'gpreg01_asthmarx1')
  co$AnyGpregHospEmergWimdqOneIrrCI  <<- 'PEDW_ASTHMA_EMERG' %>% IrrCI(   'WIMDQ1'   , 'gpreg01_asthmarx1')
  co$AnyGpregHospAllWimdqOneIrrCI    <<- 'PEDW_ASTHMA'       %>% IrrCI(   'WIMDQ1'   , 'gpreg01_asthmarx1')
  co$AnyGpregLosWimdqOneIrrCI        <<- 'ASTHMA_LOS'        %>% IrrCI(   'WIMDQ1'   , 'gpreg01_asthmarx1')

  #-----------

  co$CohortSelectionWdsPop   <<- SQL2dt('SELECT COUNT(DISTINCT ALF_PE) FROM ', DS$WDS_PERS) %>% unlist %>% as.vector %>% str_replace_all(',', '')

  co$CohortSelectionGpregAny <<- cohortselection.flowchart %>% filter(id == "none")   %>% extract2('N')              %>% str_replace_all(',', '')

  co$CohortSelectionWob      <<- cohortselection.flowchart %>% filter(id == "WOB")    %>% extract2('N')              %>% str_replace_all(',', '')

  co$CohortSelectionWimdq    <<- cohortselection.flowchart %>% filter(id == "WIMDQ")   %>% extract2('N')              %>% str_replace_all(',', '')

  co$CohortSelectionDod      <<- cohortselection.flowchart %>% filter(id == "DOD")    %>% extract2('N')              %>% str_replace_all(',', '')

  co$CohortSelectionGpreg    <<- cohortselection.flowchart %>% filter(id == "GPREG")  %>% extract2('N')              %>% str_replace_all(',', '')

  co$CohortSelectionDx       <<- cohortselection.flowchart %>% filter(id == "ASTHMA") %>% extract2('N')              %>% str_replace_all(',', '')

  co$CohortSelectionRx       <<- cohortselection.flowchart %>% filter(id == "RX")     %>% extract2('N')              %>% str_replace_all(',', '')

  co$CohortSelectionDeathDx  <<- sqlQuery2(sql.flowchart.base,
                                         sql.flowchart.where[c('none', 'WOB', 'WIMDQ', 'ASTHMA')] %>%
                                           lapply(extract2, 'sql') %>% paste0(collapse = ' AND ')
	  					                          ) %>% unlist %>% as.vector %>% str_replace_all(',', '')
  co$CohortSelectionSensGpregDx  <<- sqlQuery2(sql.flowchart.base,
                                         sql.flowchart.where[c('none', 'WOB', 'WIMDQ', 'DOD', 'ASTHMA')] %>%
                                           lapply(extract2, 'sql') %>% paste0(collapse = ' AND ')
	  					                          ) %>% unlist %>% as.vector %>% str_replace_all(',', '')

  co$CohortSelectionSensGpregRx  <<- sqlQuery2(sql.flowchart.base,
                                         sql.flowchart.where[c('none', 'WOB', 'WIMDQ', 'DOD', 'ASTHMA', 'RX')] %>%
                                           lapply(extract2, 'sql') %>% paste0(collapse = ' AND ')
	  					                          ) %>% unlist %>% as.vector %>% str_replace_all(',', '')

  source('analysis/death_vs_WIMD/deaths_fnc.r')

  co$DeathAsthmaPopN                        <<- asthma_deaths %>% filter(                            WIMDQ %>% is.na %>% not) %>% nrow %>% format_count

  co$DeathAnyN                              <<- asthma_deaths %>% filter(POSf %in% c('und', '1_8') & WIMDQ %>% is.na %>% not) %>% nrow %>% format_count

  co$DeathUndN                              <<- asthma_deaths %>% filter(POSf %in% c('und'       ) & WIMDQ %>% is.na %>% not) %>% nrow %>% format_count

  co$DeathAnyWimdqOneOrCI                   <<- death_glm_WIMDQ$any            %>% deaths_OR_CI('WIMDQ1')

  co$DeathAnyWimdqOnePcChange               <<- death_glm_WIMDQ$any            %>% deathsPercentChange('WIMDQ1')

  co$DeathAnyWimdqOneRrCI                   <<- death_glm_WIMDQ_OR_with_RR$any %>% deaths_RR_CI('WIMDQ1')

  co$DeathAnyWimdqOneFemaleOrCI             <<- subgroup_logreg$any[[1]] %>% deaths_OR_CI('GNDR_CDF')

  co$DeathAnyWimdqFiveFemaleOrCI            <<- subgroup_logreg$any[[5]] %>% deaths_OR_CI('GNDR_CDF')

  co$DeathAnyWimdqOneFemaleRrCI             <<- subgroup_logreg_OR_with_RR__raw_table$any %>% deaths_in_WIMD_RR_CI(1, 'in_WIMDQ1_GNDR_CDF')

  co$DeathAnyWimdqFiveFemaleRrCI            <<- subgroup_logreg_OR_with_RR__raw_table$any %>% deaths_in_WIMD_RR_CI(5, 'in_WIMDQ5_GNDR_CDF')

  co$DeathUndWimdqOneFemaleOrCI             <<- subgroup_logreg$und[[1]] %>% deaths_OR_CI('GNDR_CDF')

  co$DeathUndWimdqFiveFemaleOrCI            <<- subgroup_logreg$und[[5]] %>% deaths_OR_CI('GNDR_CDF')

  co$DeathUndWimdqOneFemaleRrCI             <<- subgroup_logreg_OR_with_RR__raw_table$und %>% deaths_in_WIMD_RR_CI(1, 'in_WIMDQ1_GNDR_CDF')

  co$DeathUndWimdqFiveFemaleRrCI            <<- subgroup_logreg_OR_with_RR__raw_table$und %>% deaths_in_WIMD_RR_CI(5, 'in_WIMDQ5_GNDR_CDF')

  co$DeathAnyFemaleOrCI                     <<- death_glm_WIMDQ$any            %>% deaths_OR_CI('GNDR_CDF')

  co$DeathAnyFemaleRrCI                     <<- death_glm_WIMDQ_OR_with_RR$any %>% deaths_RR_CI('GNDR_CDF')

  co$DeathAnyFemalePcChange                 <<- death_glm_WIMDQ$any            %>% deathsPercentChange('GNDR_CDF')

  co$DeathAnyFemaleRr                       <<- death_glm_WIMDQ_OR_with_RR$any %>% deaths_RR('GNDR_CDF')

  co$DeathAnyWimdqOneFemalePcChange         <<- subgroup_logreg$any[[1]]       %>% deathsPercentChange('GNDR_CDF')

  co$DeathAnyWimdqFiveFemalePcChange        <<- subgroup_logreg$any[[5]]       %>% deathsPercentChange('GNDR_CDF')

  co$DeathAnyWimdqFiveFemaleOrCI            <<- subgroup_logreg$any[[5]]       %>% deaths_OR_CI('GNDR_CDF')

}
