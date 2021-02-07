fit_gam_nb_simple = function(.data, outcome_var) {
  mgcv::bam(
    formula = paste0(outcome_var, ' ~ s(WIMDS) + s(age) + GNDR_CD') %>% as.formula,
    data = .data,
    method  = 'fREML', family = mgcv::nb(), cluster = cpu_cluster, chunk.size = 20000
  )
}

fit_gam_nb_by_gender = function(.data, outcome_var) {
  mgcv::bam(
    formula = paste0(outcome_var, ' ~ s(WIMDS, by = GNDR_CD) + s(age) + GNDR_CD') %>% as.formula,
    data = .data,
    method  = 'fREML', family = mgcv::nb(), cluster = cpu_cluster, chunk.size = 20000
  )
}

fit_gam_nb_teOnly_age_by_Gender = function(.data, outcome_var) {
  mgcv::bam(
    formula = paste0(outcome_var, ' ~ te(WIMDS, age, by = GNDR_CD) + GNDR_CD') %>% as.formula,
    data = .data,
    method  = 'fREML', family = mgcv::nb(), cluster = cpu_cluster, chunk.size = 20000
  )
}

fit_gam_nb_by_domains = function(.data, outcome_var) {
  mgcv::bam(
    formula = paste0(outcome_var, ' ~ s(INCS) + s(EMPS) + s(HLTS) + s(EDUS) + s(ACCS) + s(HOSS) + s(ENVS) + s(SAFS) + s(age) + GNDR_CD') %>% as.formula,
    data = .data,
    method  = 'fREML', family = mgcv::nb(), cluster = cpu_cluster, chunk.size = 20000
  )
}

diff_sm = function(mby){
  mby %>% gratia::difference_smooths(smooth = 's(WIMDS)') %>%
      mutate_at(vars(c('diff', 'lower', 'upper')), .funs = function(x) - x)
}


get_p_value_of_smooth = function(m, sm, roundTo = NA) { # m=mgcv_gam
  .tbl = as.data.frame(summary(m)$s.table)
  .tbl$term = row.names(.tbl)
  p = .tbl %>% filter(term == sm) %>% pull(`p-value`)
  if(!is.na(roundTo)){
    ret = ifelse(p < 10 ^ -roundTo, paste0('< ', 10 ^ -roundTo), round.d(p, roundTo))
  } else {
    ret = p
  }
  ret
}

get_p_value_of_smooth_by = function(m, sm, byVarName, byVarLevels, roundTo = NA) { # m=mgcv_gam
  .tbl = as.data.frame(summary(m)$s.table)
  .tbl$term = row.names(.tbl)
  p = .tbl %>%
    filter(term %in% paste0(sm, ':', byVarName, byVarLevels)) %>%
    pull(`p-value`) %>% as.list %>% set_names(paste0(byVarLevels))
  if(!is.na(roundTo)){
    ret = p %>%
      lapply(function(.p){
        ifelse(.p < 10 ^ -roundTo, paste0('< ', 10 ^ -roundTo), round.d(.p, roundTo))
      })
  } else {
     ret = p
  }
  ret
}
