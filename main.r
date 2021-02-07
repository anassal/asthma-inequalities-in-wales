rm(list = ls())

taskid = 'ASTINEQ_V7'

source('settings/settings.r')
source('specs/project_specs.r')
source('settings/data_sources.r')
source('specs/WIMD_info.r')
source('specs/plot_fnc.r')
source('settings/functions.r')


# create cohortSelectionTable
source("cohort_creation.r")

# patient selection criteria aflowchart
source("desc/flowchart.r")

#- cohorts_characterisation --------------------
source("cohorts_characterisation/cohorts_characterisation.r")

# fetch data from DB2
source('data_prep/data_prep.r')

#- desc ----------------------------------------
source('desc/prevalences_per_WIMDQ.r')

source('desc/cohort_desc.r')
#---------------------

source('analysis/analysis.r')

#------- export a custom set of variables for use in the paper

source('analysis/custom_output/custom_output.r')
source('analysis/custom_output/custom_output_do.r')

#-------------------

## codesets

library(openxlsx); export_Readcodesets_to_xlsx(codeset.ids = c(164, 83, 86, 92, 104, 105, 107, 191, 89, 302, 283), outputPath = outputPath.results, outputFile = 'codesets.xls')
