outputPath                = 'output/'
outputPath.results        = paste0(outputPath, 'results/')
path.SQL                  = paste0('SQL/')

project.working.schema    = 'SAILW0317V'

alf                       = "ALF_PE"

followup                  = c('2013-01-01', '2017-12-31')

cohortSelectionTable      = paste0(project.working.schema, '.', taskid, '_COHORT_SELECTION_DEC2019')

cohort.table = paste0(project.working.schema, '.', taskid, '_COHORT')

WIMD.labels = read.table(header=T, sep = ',', strip.white = T, as.is = T, text = '
  code    , label
  WIMD1   , Most deprived
  WIMD2   , Next most deprived
  WIMD3   , Middle deprivation
  WIMD4   , Next least deprived
  WIMD5   , Least deprived
')

outcomes = read.table(header=T, sep = ',', strip.white = T, as.is = T, text = '
  code              ,  label                                  , colour
  ASTHMA_GP_VISITS  ,  Asthma GP visits                       , 085f88
  ASTHMA_REVIEW     ,  Asthma reviews                         , 245418
  EDDS_ASTHMA       ,  Asthma A&E Visits                      , ff5e00
  PEDW_ASTHMA       ,  Asthma admissions (total)              , a70c0c
  PEDW_ASTHMA_EMERG ,  Asthma admissions (emergency)          , ff0000
  ASTHMA_LOS        ,  Asthma-related hospital length of stay , c37870
') %>% mutate(colour = '#' %>% paste0(colour))


vars = read.table(header=T, sep = ',', strip.white = T, as.is = T, text = '
  var                 , dec  , group, method     , title
  N_patients          , NA   , N    , N_patients , Number of patients
  GNDR                , 1    , gndr , integer    , Gender
  age                 , NA   , rx   , age        , Age
  ASTHMA_GP_VISITS    , 2    , HRU  , integer    , Asthma-related GP visits
  ASTHMA_REVIEW       , 2    , HRU  , integer    , Asthma reviews
  EDDS_ASTHMA         , 3    , HRU  , integer    , Asthma-related A&E visits
  PEDW_ASTHMA         , 3    , HRU  , integer    , Asthma-related hospitalisations (total)
  PEDW_ASTHMA_EMERG   , 3    , HRU  , integer    , Asthma-related hospitalisations (emergency)
  ASTHMA_LOS          , 3    , HRU  , integer    , Asthma-related length of stay
  SABA                , 1    , rx   , integer    , SABA inhalers
  ICS                 , 1    , rx   , integer    , ICS inhalers
  ICS_LABA            , 1    , rx   , integer    , ICS-LABA inhalers
  AMR                 , 2    , rx   , integer    , Asthma Medication Ratio
  LTRA                , 1    , rx   , integer    , Leukotriene receptor antagonists
  THEO                , 1    , rx   , integer    , Theophyllines
  OCS                 , 1    , rx   , integer    , Oral corticosteroids
  pcYrWRx             , NA   , rx   , pcYrWRx    , % patients with asthma prescriptions in N years
')

# custom output data to be used on LaTeX
co_dt = openxlsx::read.xlsx(xlsxFile = 'specs/specs.xlsx', sheet = 'custom_output_def')
co = list()
