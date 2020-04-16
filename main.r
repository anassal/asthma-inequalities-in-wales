rm(list = ls())

# equity of asthma care in Wales
taskid = 'ASTINEQ_V5'

source('settings/settings.r')

source('specs/project_specs.r')

source('settings/functions.r')

source('settings/data_sources.r')

#---------------------

# create cohortSelectionTable
# source("cohort_creation.r")

# patient selection criteria aflowchart
source("desc/flowchart.r")

#- cohorts_characterisation --------------------

#source("cohorts_characterisation/cohorts_characterisation.r")

# cleaning, transfomration
source('data_prep/data_prep.r')

#- desc ----------------------------------------

source('desc/prevalences_per_WIMD.r')

source('desc/cohort_desc.r') # Cohort 'Table 1'

#---------------------

source('analysis/analysis.r')

#------- export a custom set of variables for use in the paper
source('analysis/custom_output/custom_output.r')

#-------------------
## codesets
library(openxlsx); export_Readcodesets_to_xlsx(codeset.ids = c(164, 83, 86, 92, 104, 105, 107, 191, 89, 302, 283), outputPath = outputPath.results, outputFile = 'Chapter5.readcodes.xls')
