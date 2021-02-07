deathsPercentChange = function(.glm, IV)
  .glm %>% coef %>% exp %>% .[[IV]] %>% subtract(1) %*% 100 %>% round.d(1) %>% paste0('%')

deaths_OR_CI = function(.glm, IV)
  .glm %>% coef %>% exp %>% .[[IV]] %>% round.d(2) %>%
    paste0(
      ' [',
      .glm %>% confint.default %>% exp %>% .[IV, ] %>% round.d(2) %>% paste0(collapse = ', '),
      ']')

deaths_RR_CI = function(RR_table, IV)
  RR_table %>% filter(.rowid == IV) %>% transmute(RR %>% paste0(' [', RR_CI, ']')) %>% unlist %>% as.vector

deaths_RR    = function(RR_table, IV)
  RR_table %>% filter(.rowid == IV) %>% transmute(RR                             ) %>% unlist %>% as.vector

deaths_in_WIMD_RR_CI = function(RR_table, .WIMD, IV)
  RR_table[[.WIMD]] %>% filter(.rowid == IV) %>% transmute(RR %>% paste0(' [', RR_CI, ']')) %>% unlist %>% as.vector

print_OR_with_RR = function(logreg, .labels) {
    rr = sjstats_odds_to_rr_simple_CI(logreg)
    logreg %>%
      glm.summ(dec=2) %>%
        transmute(
          var = .labels,
          OR = paste0(estimate, ' (', LCL, ', ', UCL, ')'),
          p_value
        ) %>%
      cbind(
        rr %>%
          transmute(
            RR = paste0(
              RR     = `Risk Ratio` %>% round.d(2),
              ' (',
              RR_LCL = CI_low       %>% round.d(2),
              ', ',
              RR_UCL = CI_high      %>% round.d(2),
              ')'
            )
          )
      ) %>%
      select(var, OR, RR, p_value)
  }

print_OR_with_RR__raw_table = function(logit, .labels, .rowid) {
  rr = sjstats_odds_to_rr_simple_CI(logit)
  cbind(
    .rowid
    ,
    logit %>%
    glm.summ(dec=2) %>%
    transmute(
      var   = .labels,
      OR    = estimate,
      OR_CI = paste0(LCL, ', ', UCL),
      p_value
    ) %>%
    cbind(
      rr %>%
        transmute(
          RR     = `Risk Ratio` %>% round.d(2),
          RR_CI  = paste0(CI_low %>% round.d(2), ', ', CI_high %>% round.d(2))
        )
    )
  )
}
