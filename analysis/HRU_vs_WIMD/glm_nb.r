if (run_model == T) {
  I.var  = "WIMDQ"
  D.vars = outcomes$code

  # lists to store model outputs
  nb         = list()
  nb.coef    = list()
  nb.predict = list()

  for (gpreg      in list(1, c(0,1))) {
  	for (asthmarx in list(1, c(0,1))) {

  		# cohort version
  	  (cv = paste0("gpreg", paste0(gpreg, collapse = ''), "_", "asthmarx", paste0(asthmarx, collapse = ''))) %>% print

  	  nb[[cv]]      = list()
  		nb.coef[[cv]] = list()

  		data0 =
  		  cohort.dt %>%
  		  filter(GPREG %in% gpreg & ASTHMA_RX %in% asthmarx)


  		##################### do glm.nb for each of D.vars

  		for (D.var in D.vars) {
  			nb[[cv]][[D.var]] = MASS::glm.nb(
  			  as.formula(paste0(D.var, " ~ ", I.var, " + age + GNDR_CD")),
  			  data = data0
  			)

  			Estimate= nb[[cv]][[D.var]] %>% coef            %>% exp
  			confint = nb[[cv]][[D.var]] %>% confint.default %>% exp
  			P       = (nb[[cv]][[D.var]] %>% summary)$coefficients[,'Pr(>|z|)']

  			nb.coef[[cv]][[D.var]] = data.table(
  				IV = Estimate %>% names,
  				Estimate,
  				confint %>% `colnames<-`(c('LCL', 'UCL')),
  				P,
  				sig = P %>% sig)
  		}

		############ relative.diff between WIMDQ 1 and WIMDQ 5, represented as "% more"
  		df.i = list()
  		for (D.var in names(nb.coef[[cv]])){
  			df.i[[D.var]] =
  				data.table(D.var) %>%
  				cbind(nb.coef[[cv]][[D.var]][IV == 'WIMDQ1', 2:5, with = F]) %>%
  				mutate_at(.vars = c('Estimate', 'LCL', 'UCL'),
  									.funs = function(x) ((x-1) * 100) %>% format(digits = 2, nsmall = 1)) %>%
  				mutate_at(.vars = 'P', .funs = function(x)sprintf("%.4f", x))
  		}

  		relative.diff = do.call('rbind', df.i)

  		############
  	}
  }


  time_now = timeNow()
  save(nb,      file = paste0('data/HRU_vs_WIMDQ_nb.Rdata'))
  save(nb.coef, file = paste0('data/HRU_vs_WIMDQ_nb_coef.Rdata'))

} else {

  cat('Loading .Rdata ..\n\n')
  load(         file = paste0('data/HRU_vs_WIMDQ_nb.Rdata'))
  load(         file = paste0('data/HRU_vs_WIMDQ_nb_coef.Rdata'))
}


# adjusting for AMR

sink('output/results/glm_adjusting_for_AMR.txt')
MASS::glm.nb(
  			  as.formula(paste0(" EDDS_ASTHMA ~ WIMDQ + AMR + age + GNDR_CD")),
  			  data = cohort.dt %>%
  			    filter(GPREG %in% 1 & ASTHMA_RX %in% 1)
  			) %>% broom::tidy(conf.int = T, exponentiate = T)

MASS::glm.nb(
  			  as.formula(paste0(" PEDW_ASTHMA_EMERG ~ WIMDQ + AMR + age + GNDR_CD")),
  			  data = cohort.dt %>%
  			    filter(GPREG %in% 1 & ASTHMA_RX %in% 1)
  			) %>% broom::tidy(conf.int = T, exponentiate = T)
sink()
