outputPath                = 'output/'
outputPath.results        = paste0(outputPath, 'results/')
path.SQL                  = paste0('SQL/')
project.working.schema    = 'SAILW0317V'
alf                       = "ALF_PE"
followup                  = c('2013-01-01', '2017-12-31')
cohortSelectionTable      = paste0(project.working.schema, '.', taskid, '_COHORT_SELECTION_JAN2021')
cohort.table = paste0(project.working.schema, '.', taskid, '_COHORT')

gender_info = read.table(header=T, sep = ',', strip.white = T, as.is = T, text = '
  code,  label  , colour
  M   ,  Males  , 41779A
  F   ,  Females, AB7293
') %>% mutate(colour = '#' %>% paste0(colour))

deaths_def = read.table(header=T, sep = ',', strip.white = T, as.is = T, text = '
  code,  label
  und ,  Death with asthma as the underlying cause
  any ,  Death with any mention of asthma
')


WIMD_domains_lables = read.table(header=T, sep = ',', strip.white = T, as.is = T, text = '
  code    , label
  INCS    , Income
  EMPS    , Employment
  HLTS    , Health
  EDUS    , Education
  ACCS    , Geographical access to services
  HOSS    , Housing
  ENVS    , Physical environment
  SAFS    , Community safety
')

outcomes = read.table(header=T, sep = ',', strip.white = T, as.is = T, text = '
  code              ,  label                                  , colour
  ASTHMA_GP_VISITS  ,  Asthma GP consultations                , 085f88
  ASTHMA_REVIEW     ,  Asthma reviews                         , 245418
  EDDS_ASTHMA       ,  Asthma A&E attendances                 , ff5e00
  PEDW_ASTHMA       ,  Asthma admissions (total)              , a70c0c
  PEDW_ASTHMA_EMERG ,  Asthma admissions (emergency)          , ff0000
  ASTHMA_LOS        ,  Asthma-related length of hospital stay , c37870
') %>% mutate(colour = '#' %>% paste0(colour))

vars = read.table(header=T, sep = ',', strip.white = T, as.is = T, text = '
  var                 , dec  , group, method     , title
  N_patients          , NA   , N    , N_patients , Number of patients
  GNDR                , 1    , gndr , integer    , Gender
  age                 , NA   , rx   , age        , Age
  ASTHMA_GP_VISITS    , 2    , HRU  , integer    , Asthma-related GP consultations
  ASTHMA_REVIEW       , 2    , HRU  , integer    , Asthma reviews
  EDDS_ASTHMA         , 3    , HRU  , integer    , Asthma-related A&E attendances
  PEDW_ASTHMA         , 3    , HRU  , integer    , Asthma-related hospitalisations (total)
  PEDW_ASTHMA_EMERG   , 3    , HRU  , integer    , Asthma-related hospitalisations (emergency)
  ASTHMA_LOS          , 3    , HRU  , integer    , Asthma-related length of hospital stay
  SABA                , 2    , rx   , integer    , SABA inhalers
  ICS                 , 2    , rx   , integer    , ICS inhalers
  ICS_LABA            , 2    , rx   , integer    , ICS-LABA inhalers
  NACROM              , 2    , rx   , integer    , Sodioum cromoglicate
  NEDOCROMIL          , 2    , rx   , integer    , Nedocromil
  AMR                 , 2    , rx   , decimal    , Asthma Medication Ratio
  LTRA                , 2    , rx   , integer    , Leukotriene receptor antagonists
  THEO                , 2    , rx   , integer    , Theophyllines
  OCS                 , 2    , rx   , integer    , Oral corticosteroids
')
