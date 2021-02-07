#------- glm.nb(DV ~ WIMDQ)

run_model = T # i.e. run model vs load from file

source('analysis/HRU_vs_WIMD/glm_nb.r')
source('analysis/HRU_vs_WIMD/export_glm_nb_output.r')
source('analysis/HRU_vs_WIMD/goodnessoffit/qqplot.r')
source('analysis/HRU_vs_WIMD/goodnessoffit/rootogram.r')
source('analysis/gam_fnc.r')
source('analysis/HRU_vs_WIMD/HRU_vs_WIMDS_gamnb.r')

#------- AMR ~ WIMDQ

source('analysis/AMR_vs_WIMD/AMR_vs_WIMD.r')

#------- emergency-to-total admissions ~ WIMDQ

source('analysis/emerg_to_total_admissions_vs_WIMD/emerg_to_total_admissions_vs_WIMDQ.r')

#------- asthma deaths ~ WIMDQ and Gender

source('analysis/death_vs_WIMD/death_vs_WIMD.r')
