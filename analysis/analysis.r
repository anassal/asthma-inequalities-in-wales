#------- glm.nb(DV ~ WIMD)
run_model = F # i.e. load saved model instead
source('analysis/HRU_vs_WIMD/glm_nb.r')
source('analysis/HRU_vs_WIMD/export_glm_nb_output.r')
source('analysis/HRU_vs_WIMD/goodnessoffit/qqplot.r')
source('analysis/HRU_vs_WIMD/goodnessoffit/rootogram.r')

#------- AMR ~ WIMD
source('analysis/AMR_vs_WIMD/AMR_vs_WIMD.r')

#------- emergency-to-total admissions ~ WIMD
source('analysis/emerg_to_total_admissions_vs_WIMD/emerg_to_total_admissions_vs_WIMD.r')

#------- asthma deaths ~ WIMD and Gender
source('analysis/death_vs_WIMD/death_vs_WIMD.r')

#-----------------------------

# adjusting for AMR 
MASS::glm.nb(
  			  as.formula(paste0(" PEDW_ASTHMA_EMERG ~ WIMD + AMR + age + GNDR_CD")),
  			  data = cohort.dt %>%
  			    filter(GPREG %in% 1 & ASTHMA_RX %in% 1)  #%>% sample_n(size = 800, replace = F)
  			) %>% broom::tidy(conf.int = T, exponentiate = T)


MASS::glm.nb(
  			  as.formula(paste0(" EDDS_ASTHMA ~ WIMD + AMR + age + GNDR_CD")),
  			  data = cohort.dt %>%
  			    filter(GPREG %in% 1 & ASTHMA_RX %in% 1)  #%>% sample_n(size = 800, replace = F)
  			) %>% broom::tidy(conf.int = T, exponentiate = T)

#-----------------------------------

# SABA >= 12 per year vs WIMD

SABA12_vs_WIMD = glm((SABA >= 12*5) ~ WIMD + age + GNDR_CD,
    data =
      cohort.dt %>%
      filter(GPREG %in% 1 & ASTHMA_RX %in% 1),
    family = binomial()
    )

SABA12_vs_WIMD %>% broom::tidy(conf.int = T, exponentiate = T)


sjstats_odds_to_rr_simple_CI(SABA12_vs_WIMD)

