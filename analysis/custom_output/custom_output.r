cat('\n\n--------------\nmisc output ..\n\n')

load_HRU_model_Rdata = F

fill_custom_output = function() {

  if (load_HRU_model_Rdata == T) {
    load(file = paste0('data/HRU_vs_WIMD_nb',      ".Rdata"))
    load(file = paste0('data/HRU_vs_WIMD_nb_coef', ".Rdata"))
  }

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

  # predict a dependent variable (DV) in a WIMD group
  WIMD_DV_pred = function(DV, wimd) {
    .pred = c()
    for (gndr in 1:2)
      .pred[gndr] = nb$gpreg1_asthmarx1[[DV]] %>% predict(newdata = data.frame(WIMD=wimd, age = mean(nb$gpreg1_asthmarx1[[DV]]$model$age), GNDR_CD = gndr %>% as.character)) %>% exp

    gndr_tab = nb$gpreg1_asthmarx1[[DV]]$model$GNDR_CD %>% table
    (.pred * gndr_tab) %>% sum %>% divide_by(gndr_tab %>% sum) %>% return
  }


  #- co = list() already defined -----------------

  co$sourcePopN                     <<- SQL2dt(
                                        "SELECT COUNT(*) FROM ", cohortSelectionTable, "
                                         WHERE ", sql.flowchart.where %>% lapply(extract2, 'sql') %>%
                                                   magrittr::extract(c('NONE', 'WOB', 'WIMD')) %>%
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

  co$mainCohortFemalePcWimdOne      <<- get_from_desc_table('GNDR_pcNotZero', 'WIMD1') %>% paste0('%')

  co$mainCohortFemalePcWimdFive     <<- get_from_desc_table('GNDR_pcNotZero', 'WIMD5') %>% paste0('%')

  #-------------

  co$mainCohortWimdOnePc            <<- get_from_desc_table('WIMD_pc'      , 'WIMD1') %>% paste0('%')

  co$mainCohortWimdOneAgeMean       <<- get_from_desc_table('age_mean'      , 'WIMD1')

  co$mainCohortWimdOneAgeSd         <<- get_from_desc_table('age_SD'        , 'WIMD1')

  co$mainCohortWimdFiveAgeMean      <<- get_from_desc_table('age_mean'      , 'WIMD5')

  co$mainCohortWimdFiveAgeSd        <<- get_from_desc_table('age_SD'        , 'WIMD5')

  #-------------
  co$prevEverDx                     <<- prevalence_table %>% filter(.rowid == 'everDx_prevalence')        %>% extract2('all')    %>% paste0('%')
  co$prevEverDxWimdOne              <<- prevalence_table %>% filter(.rowid == 'everDx_prevalence')        %>% extract2('WIMD 1') %>% paste0('%')
  co$prevEverDxWimdFive             <<- prevalence_table %>% filter(.rowid == 'everDx_prevalence')        %>% extract2('WIMD 5') %>% paste0('%')
  co$prevEverDxCurrRx               <<- prevalence_table %>% filter(.rowid == 'everdx_currRx_prevalence') %>% extract2('all')    %>% paste0('%')
  co$prevEverDxCurrRxWimdOne        <<- prevalence_table %>% filter(.rowid == 'everdx_currRx_prevalence') %>% extract2('WIMD 1') %>% paste0('%')
  co$prevEverDxCurrRxWimdFive       <<- prevalence_table %>% filter(.rowid == 'everdx_currRx_prevalence') %>% extract2('WIMD 5') %>% paste0('%')

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

  co$GpVisitsWimdOnePcChange        <<- 'ASTHMA_GP_VISITS'  %>% pcChange('WIMD1'   , 'gpreg1_asthmarx1')

  co$GpVisitsWimdOneIrrCI           <<- 'ASTHMA_GP_VISITS'  %>% IrrCI(   'WIMD1'   , 'gpreg1_asthmarx1')

  co$GpVisitsWimdOneIrrCILong       <<- gsub('\\[', '[95% CI = ', co$GpVisitsWimdOneIrrCI)

  co$GpReviewsWimdOnePcChange       <<- 'ASTHMA_REVIEW'     %>% pcChange('WIMD1'   , 'gpreg1_asthmarx1')

  co$GpReviewsWimdOneIrrCI          <<- 'ASTHMA_REVIEW'     %>% IrrCI(   'WIMD1'   , 'gpreg1_asthmarx1')

  #-------------

  co$RxAnyPerYearWimdOne            <<- cohort.dt %>% filter(GPREG == 1 & ASTHMA_RX == 1) %>%
                                     group_by(WIMD) %>% summarise(
                                       (ASTHMA_RX_12M_1 + ASTHMA_RX_12M_2 + ASTHMA_RX_12M_3 + ASTHMA_RX_12M_4 + ASTHMA_RX_12M_5)
                                       %>% mean) %>% ungroup %>%
                                     filter(WIMD == '1') %>% extract2(2) %>% divide_by(5) %>% round.d(1)

  co$RxAnyPerYearWimdFive           <<- cohort.dt %>% filter(GPREG == 1 & ASTHMA_RX == 1) %>%
                                     group_by(WIMD) %>% summarise(
                                       (ASTHMA_RX_12M_1 + ASTHMA_RX_12M_2 + ASTHMA_RX_12M_3 + ASTHMA_RX_12M_4 + ASTHMA_RX_12M_5)
                                       %>% mean) %>% ungroup %>%
                                     filter(WIMD == '5') %>% extract2(2) %>% divide_by(5) %>% round.d(1)


  co$RxRelieverPerYearWimdOne       <<- cohort.dt %>% filter(GPREG == 1 & ASTHMA_RX == 1) %>%
                                     group_by(WIMD) %>% summarise(SABA %>% mean) %>% ungroup %>%
                                     filter(WIMD == '1') %>% extract2(2) %>% divide_by(5) %>% round.d(1)

  co$RxRelieverPerYearWimdFive      <<- cohort.dt %>% filter(GPREG == 1 & ASTHMA_RX == 1) %>%
                                     group_by(WIMD) %>% summarise(SABA %>% mean) %>% ungroup %>%
                                     filter(WIMD == '5') %>% extract2(2) %>% divide_by(5) %>% round.d(1)

  co$RxControllerPerYearWimdOne     <<- cohort.dt %>% filter(GPREG == 1 & ASTHMA_RX == 1) %>%
                                     group_by(WIMD) %>% summarise((ICS + ICS_LABA + THEO + LTRA + OCS) %>% mean) %>% ungroup %>%
                                     filter(WIMD == '1') %>% extract2(2) %>% divide_by(5) %>% round.d(1)

  co$RxControllerPerYearWimdFive    <<- cohort.dt %>% filter(GPREG == 1 & ASTHMA_RX == 1) %>%
                                     group_by(WIMD) %>% summarise((ICS + ICS_LABA + THEO + LTRA + OCS) %>% mean) %>% ungroup %>%
                                     filter(WIMD == '5') %>% extract2(2) %>% divide_by(5) %>% round.d(1)

  #-------------

  co$AmrMeanWimdOne                 <<- get_from_desc_table('AMR_mean', 'WIMD1')

  co$AmrMeanWimdFive                <<- get_from_desc_table('AMR_mean', 'WIMD5')

  co$AmrMeanAbDiffCI                <<- AMR_vs_WIMD15_ttest$estimate %>%
                                     rev %>% diff %>% as.vector %>% round.d(3) %>%
                                     paste0(' [', AMR_vs_WIMD15_ttest$conf.int %>% round.d(3) %>% paste0(collapse = ', '), ']')

  co$AmrMeanRatioCI                 <<- AMR_vs_WIMD15_ttest$estimate[2:1] %>% (function(x) x[1]/x[2]*100) %>% round.d(1) %>%
                                     paste0('% [',
                                             (100 - rev(AMR_vs_WIMD15_ttest$conf.int)/AMR_vs_WIMD15_ttest$estimate[1]*100) %>%
                                              round.d(1) %>% paste0('%') %>% paste0(collapse = ', '),
                                            ']')

  #-------------

  co$AmrVsWimdKwchi                 <<- paste0(
                                       AMR_vs_WIMD_KWtest$statistic %>% names, ' = ',
                                         AMR_vs_WIMD_KWtest$statistic %>% round.d(1), ', ',
                                       'degrees of freedom = ', AMR_vs_WIMD_KWtest$parameter, ', ',
                                       'p value < 0.00001'
                                     )

  #-------------

  co$EdWimdOnePcChange              <<- 'EDDS_ASTHMA'       %>% pcChange('WIMD1'   , 'gpreg1_asthmarx1')

  co$EdWimdOneIrrCI                 <<- 'EDDS_ASTHMA'       %>% IrrCI(   'WIMD1'   , 'gpreg1_asthmarx1')

  co$EdWimdOnePred                  <<- WIMD_DV_pred('EDDS_ASTHMA', '1') %>% round.d(3)

  co$EdWimdFivePred                 <<- WIMD_DV_pred('EDDS_ASTHMA', '5') %>% round.d(3)

  #-------------

  co$EdFemalePcChange               <<- 'EDDS_ASTHMA'       %>% pcChange('GNDR_CD2', 'gpreg1_asthmarx1')
  co$EdFemaleIrrCI                  <<- 'EDDS_ASTHMA'       %>% IrrCI(   'GNDR_CD2', 'gpreg1_asthmarx1')

  #-------------

  co$HospEmergWimdOnePcChange       <<- 'PEDW_ASTHMA_EMERG' %>% pcChange('WIMD1'   , 'gpreg1_asthmarx1')

  co$HospEmergWimdOneIrrCI          <<- 'PEDW_ASTHMA_EMERG' %>% IrrCI(   'WIMD1'   , 'gpreg1_asthmarx1')

  co$HospEmergWimdOneIrr            <<- base::sub(' .*', '', co$HospEmergWimdOneIrrCI)

  co$HospAllWimdOnePcChange         <<- 'PEDW_ASTHMA'       %>% pcChange('WIMD1'   , 'gpreg1_asthmarx1')

  co$HospAllWimdOneIrrCI            <<- 'PEDW_ASTHMA'       %>% IrrCI(   'WIMD1'   , 'gpreg1_asthmarx1')

  #-------------

  co$LosWimdOnePcChange             <<- 'ASTHMA_LOS'        %>% pcChange('WIMD1'   , 'gpreg1_asthmarx1')

  co$LosWimdOneIrrCI                <<- 'ASTHMA_LOS'        %>% IrrCI(   'WIMD1'   , 'gpreg1_asthmarx1')

  co$LosWimdOnePred                 <<- WIMD_DV_pred('ASTHMA_LOS', '1') %>% round.d(2)

  co$LosWimdFivePred                <<- WIMD_DV_pred('ASTHMA_LOS', '5') %>% round.d(2)

  #-------------

  co$HospEmergToTotalPcWimdOne     <<- emerge_to_total_admissions_vs_WIMD_dt %>% filter(WIMD == '1' & key == 'Emergency') %>% extract2('label.')
  co$HospEmergToTotalPcWimdFive    <<- emerge_to_total_admissions_vs_WIMD_dt %>% filter(WIMD == '5' & key == 'Emergency') %>% extract2('label.')

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


  co$AnyRxGpVisitsWimdOneIrrCI      <<- 'ASTHMA_GP_VISITS'  %>% IrrCI(   'WIMD1'   , 'gpreg1_asthmarx01')

  co$AnyRxGpReviewsWimdOneIrrCI     <<- 'ASTHMA_REVIEW'     %>% IrrCI(   'WIMD1'   , 'gpreg1_asthmarx01')

  co$AnyRxEdWimdOneIrrCI            <<- 'EDDS_ASTHMA'       %>% IrrCI(   'WIMD1'   , 'gpreg1_asthmarx01')

  co$AnyRxHospEmergWimdOneIrrCI     <<- 'PEDW_ASTHMA_EMERG' %>% IrrCI(   'WIMD1'   , 'gpreg1_asthmarx01')

  co$AnyRxHospAllWimdOneIrrCI       <<- 'PEDW_ASTHMA'       %>% IrrCI(   'WIMD1'   , 'gpreg1_asthmarx01')

  co$AnyRxLosWimdOneIrrCI           <<- 'ASTHMA_LOS'        %>% IrrCI(   'WIMD1'   , 'gpreg1_asthmarx01')

  #- Sensitivity Analysis: Any GPREG ------------

  co$AnyGpregCohortN                <<- cohort.dt %>% filter(             ASTHMA_RX == 1) %>% nrow %>% format_count

  co$AnyGpregCohortPcOfNonContReg   <<- cohort.dt %>% filter(GPREG == 0 & ASTHMA_RX == 1) %>% nrow %>%
                                     divide_by(cohort.dt %>% filter(   ASTHMA_RX == 1) %>% nrow) %>%
                                     format_pc %>% paste0('%')

  co$AnyGpregGpVisitsWimdOneIrrCI   <<- 'ASTHMA_GP_VISITS'  %>% IrrCI(   'WIMD1'   , 'gpreg01_asthmarx1')

  co$AnyGpregGpReviewsWimdOneIrrCI  <<- 'ASTHMA_REVIEW'     %>% IrrCI(   'WIMD1'   , 'gpreg01_asthmarx1')

  co$AnyGpregEdWimdOneIrrCI         <<- 'EDDS_ASTHMA'       %>% IrrCI(   'WIMD1'   , 'gpreg01_asthmarx1')

  co$AnyGpregHospEmergWimdOneIrrCI  <<- 'PEDW_ASTHMA_EMERG' %>% IrrCI(   'WIMD1'   , 'gpreg01_asthmarx1')

  co$AnyGpregHospAllWimdOneIrrCI    <<- 'PEDW_ASTHMA'       %>% IrrCI(   'WIMD1'   , 'gpreg01_asthmarx1')

  co$AnyGpregLosWimdOneIrrCI        <<- 'ASTHMA_LOS'        %>% IrrCI(   'WIMD1'   , 'gpreg01_asthmarx1')

  #-----------

  co$CohortSelectionWdsPop   <<- SQL2dt('SELECT COUNT(DISTINCT ALF_PE) FROM ', DS$WDS_PERS) %>% unlist %>% as.vector %>% str_replace_all(',', '') #%>% format_count
  co$CohortSelectionGpregAny <<- cohortselection.flowchart %>% filter(id == "none")   %>% extract2('N')              %>% str_replace_all(',', '') #%>% format_count
  co$CohortSelectionWob      <<- cohortselection.flowchart %>% filter(id == "WOB")    %>% extract2('N')              %>% str_replace_all(',', '') #%>% format_count
  co$CohortSelectionWimd     <<- cohortselection.flowchart %>% filter(id == "WIMD")   %>% extract2('N')              %>% str_replace_all(',', '') #%>% format_count
  co$CohortSelectionDod      <<- cohortselection.flowchart %>% filter(id == "DOD")    %>% extract2('N')              %>% str_replace_all(',', '') #%>% format_count
  co$CohortSelectionGpreg    <<- cohortselection.flowchart %>% filter(id == "GPREG")  %>% extract2('N')              %>% str_replace_all(',', '') #%>% format_count
  co$CohortSelectionDx       <<- cohortselection.flowchart %>% filter(id == "ASTHMA") %>% extract2('N')              %>% str_replace_all(',', '') #%>% format_count
  co$CohortSelectionRx       <<- cohortselection.flowchart %>% filter(id == "RX")     %>% extract2('N')              %>% str_replace_all(',', '') #%>% format_count

  co$CohortSelectionDeathDx  <<- sqlQuery2(sql.flowchart.base,
                                         sql.flowchart.where[c('none', 'WOB', 'WIMD', 'ASTHMA')] %>%
                                           lapply(extract2, 'sql') %>% paste0(collapse = ' AND ')
	  					                          ) %>% unlist %>% as.vector %>% str_replace_all(',', '') #%>% format_count
  co$CohortSelectionSensGpregDx  <<- sqlQuery2(sql.flowchart.base,
                                         sql.flowchart.where[c('none', 'WOB', 'WIMD', 'DOD', 'ASTHMA')] %>%
                                           lapply(extract2, 'sql') %>% paste0(collapse = ' AND ')
	  					                          ) %>% unlist %>% as.vector %>% str_replace_all(',', '') #%>% format_count
  co$CohortSelectionSensGpregRx  <<- sqlQuery2(sql.flowchart.base,
                                         sql.flowchart.where[c('none', 'WOB', 'WIMD', 'DOD', 'ASTHMA', 'RX')] %>%
                                           lapply(extract2, 'sql') %>% paste0(collapse = ' AND ')
	  					                          ) %>% unlist %>% as.vector %>% str_replace_all(',', '') #%>% format_count
}

fill_custom_output()

co_dt %>%
  inner_join(
    cbind.data.frame(
      co %>% names,
      co %>% as.data.frame %>% t %>% as_tibble(.name_repair = "minimal"),
      stringsAsFactors = F
    ) %>%
    set_colnames(c('varName', 'value'))
  ) %>%
  openxlsx::write.xlsx(file = paste0(outputPath.results, 'misc_output.xlsx'))



