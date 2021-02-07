set.seed(0)

gamnb0 = list()
gamnb1 = list()
gamnbteOnlyByGender = list()
gamnbDomainsSeperate = list()

#------------------

# simple nb GAMs

for (outcome_var in outcomes$code) {
   cat(paste0('fit_gam_nb_simple: ', outcome_var, '\n'))
   gamnb0[[outcome_var]] = fit_gam_nb_simple(
     .data = cohort.dt %>% filter(GPREG == 1 & ASTHMA_RX == 1), outcome_var = outcome_var
   )
}
saveRDS(gamnb0, paste0('data/rds/gamnb0.Rds' ))

#------------------

# used for difference smooths (by gender), HRU_predicted_count_by_WIMDS_and_gender
for (outcome_var in outcomes$code) {
   cat(paste0('fit_gam_nb_by_gender: ', outcome_var, '\n'))
   gamnb1[[outcome_var]] = fit_gam_nb_by_gender(
     .data = cohort.dt %>% filter(GPREG == 1 & ASTHMA_RX == 1), outcome_var = outcome_var
   )
}
saveRDS(gamnb1 , paste0('data/rds/gamnb1.Rds' ))

#------------------

# interaction
for (outcome_var in outcomes$code) {
   cat(paste0('fit_gam_nb_teOnly_age_by_Gender: ', outcome_var, '\n'))
   gamnbteOnlyByGender[[outcome_var]] = fit_gam_nb_teOnly_age_by_Gender(
       .data = cohort.dt %>% filter(GPREG == 1 & ASTHMA_RX == 1), outcome_var = outcome_var
   )
}
saveRDS(gamnbteOnlyByGender, paste0('data/rds/gamnbteOnlyByGender.Rds'))

#------------------

# Separate nb gams by WIMD domains
for (outcome_var in outcomes$code) {
   gamnbDomainsSeperate[[outcome_var]] = list()
   for(domain in c('INCS', 'EMPS', 'HLTS', 'EDUS', 'ACCS', 'HOSS', 'ENVS', 'SAFS')){
      print(paste0(outcome_var, ' ', domain))
      gamnbDomainsSeperate[[outcome_var]][[domain]] = mgcv::bam(
        formula = paste0(outcome_var, '~ s(', domain , ') + s(age) + GNDR_CD') %>% as.formula,
        data =  cohort.dt %>% filter(GPREG == 1 & ASTHMA_RX == 1),
        method = 'fREML', family = mgcv::nb(), cluster = cpu_cluster, chunk.size = 20000
     )
   }
}
saveRDS(gamnbDomainsSeperate, paste0('data/rds/gamnbDomainsSeperate.Rds'))

#------------------

# theming functions

facet_by_HRUoutcome = function(scale = 'fixed'){
  lemon::facet_rep_wrap(
    facets = '.outcome',
    repeat.tick.labels = T,
    labeller = as_labeller(outcomes$label %>% stringr::str_wrap(21) %>% set_names(outcomes$code)),
    scales = scale
  )
}

theme_HRU_outcomes = function(){
  theme(
    panel.spacing.y = unit(2, 'lines'),
    strip.text = element_text(margin = margin(b = 0), vjust = 1, size = 9)
  )
}

re_order_HRU = function(.tbl){
  .tbl %>% mutate(.outcome = factor(.outcome, levels = outcomes$code))
}

#### global WIMDS smooths --------------------------------

(
  outcomes$code %>%
    lapply(function(.outcome){
      gamnb0[[.outcome]] %>%
        gratia::evaluate_smooth(smooth = 's(WIMDS)') %>%
        mutate(lcl = est - 1.96 * se, ucl = est + 1.96 * se) %>%
        mutate(.outcome = .outcome)
    }) %>%
    reduce(bind_rows) %>%
    re_order_HRU %>%
    ggplot(aes(x = WIMDS, y = est)) +
      hline0 +
      geom_ribbon(aes(ymax = ucl, ymin = lcl), alpha = 0.2) +
      geom_line() +
      ggpmisc::geom_text_npc(
        data = data.frame(
          p_value =
            outcomes$code %>%
              lapply(function(.outcome){
                gamnb0[[.outcome]] %>% get_p_value_of_smooth(sm = 's(WIMDS)', 3)
              }) %>% reduce(c),
           .outcome = outcomes$code
         ) %>% re_order_HRU,
        npcx = 'right', npcy = 'bottom', size = 3,
        aes(label = paste0('p-value ', p_value)),
      ) +
      coord_cartesian(xlim = c(-1, NA), expand = F) +
      facet_by_HRUoutcome() +
      labs(x = 'WIMD 2011 score', y = 'Effect') +
      theme_minimal() +
      theme1() +
      theme(axis.line.y = element_line(), axis.ticks.y = element_line()) +
      theme_HRU_outcomes()
) %>%
  egg::set_panel_size(width = unit(eggPanelSize$w, 'cm'), height = unit(eggPanelSize$h, 'cm')) -> g0
ggsave(plot = g0, filename = 'output/results/HRU_gam_global_WIMDS_smooths.pdf', height = pdfPlotDim$h * 1.7, width = pdfPlotDim$w * 1.4, device = 'pdf')

#### global age smooths --------------------------------

(
  outcomes$code %>%
    lapply(function(.outcome){
      gamnb0[[.outcome]] %>%
        gratia::evaluate_smooth(smooth = 's(age)') %>%
        mutate(lcl = est - 1.96 * se, ucl = est + 1.96 * se) %>%
        mutate(.outcome = .outcome)
    }) %>%
    reduce(bind_rows) %>%
    re_order_HRU %>%
    ggplot(aes(x = age, y = est)) +
      hline0 +
      geom_ribbon(aes(ymax = ucl, ymin = lcl), alpha = 0.2) +
      geom_line() +

      ggpmisc::geom_text_npc(
        data = data.frame(
          p_value =
            outcomes$code %>%
              lapply(function(.outcome){
                gamnb0[[.outcome]] %>% get_p_value_of_smooth(sm = 's(age)', 3)
              }) %>% reduce(c),
           .outcome  = outcomes$code
        ) %>% re_order_HRU,
        npcx = 'right', npcy = 'bottom', size = 3,
        aes(label = paste0('p-value ', p_value)),
      ) +

      coord_cartesian(xlim = c(-1, NA), expand = F) +
      facet_by_HRUoutcome(scale = 'fixed') +
      labs(x = 'Age (years)', y = 'Effect') +
      theme_minimal() +
      theme1() +
      theme(axis.line.y = element_line(), axis.ticks.y = element_line()) +
      theme_HRU_outcomes()
) %>%
  egg::set_panel_size(width = unit(eggPanelSize$w, 'cm'), height = unit(eggPanelSize$h, 'cm')) -> g0
ggsave(plot = g0, filename = 'output/results/HRU_gam_global_age_smooths.pdf', height = pdfPlotDim$h * 1.7, width = pdfPlotDim$w * 1.4, device = 'pdf')

#### gender difference smooths ---------------------------

(
  outcomes$code %>%
  lapply(function(x){
     gamnb1[[x]] %>% diff_sm %>% mutate(.outcome = x)
  }) %>%
  reduce(bind_rows) %>%
  re_order_HRU %>%
  ggplot(aes(x = WIMDS, y = diff)) +
    hline0 +
    geom_ribbon(aes(ymin = lower, ymax = upper), alpha = 0.2) +
    geom_line() +
    coord_cartesian(expand = F, xlim = c(-.1, NA)) +
    facet_by_HRUoutcome() +
    labs(x = 'WIMD 2011 score', y = 'Difference in effect') +
    theme_minimal() +
    theme1() +
    theme(axis.line.y = element_line(), axis.ticks.y = element_line()) +
    theme_HRU_outcomes()
) %>%
  egg::set_panel_size(width = unit(eggPanelSize$w, 'cm'), height = unit(eggPanelSize$h, 'cm')) -> g0
ggsave(plot = g0, filename = 'output/results/HRU_diff_smooths_by_gender.pdf', height = pdfPlotDim$h * 1.7, width = pdfPlotDim$w * 1.4, device = 'pdf')

#### HRU_risk_by_WIMDS_by_gender -----------------------------

HRU_risk_by_WIMDS_by_gender =
  outcomes$code %>%
  lapply(
    (function(.outcome) {
      c('1', '2') %>%
        lapply(function(.g) {
          submodel = gamnb1[[.outcome]]$model %>% filter(GNDR_CD == .g)
          rand_ids = sample.int(submodel %>% nrow, 1000, replace = F)

          tibble(
            WIMDS   = submodel %>% pull(WIMDS),
            GNDR_CD = .g
          ) %>%
            bind_cols(
              gamnb1[[.outcome]] %>% predict(newdata = data.frame(
                WIMDS   = submodel %>% pull(WIMDS),
                age     = submodel %>% pull(age) %>% median,
                GNDR_CD = .g
              ), type = 'link', se.fit = T) %>%
                as_tibble() %>%
                mutate(
                  ucl = (fit + 1.96 * se.fit) %>% (gamnb1[[.outcome]]$family$linkinv),
                  lcl = (fit - 1.96 * se.fit) %>% (gamnb1[[.outcome]]$family$linkinv),
                  fit = fit                   %>% (gamnb1[[.outcome]]$family$linkinv)
                )
            ) %>%
            arrange(WIMDS) %>%
            slice(c(
              rand_ids,
              (1:n()) %>% (function(x) {c(head(x,50), tail(x, 50))})
            ))
        }) %>%
        do.call(what = bind_rows) %>%
        mutate(.outcome = .outcome)
    })
  )%>%
  do.call(what = bind_rows)

(HRU_risk_by_WIMDS_by_gender %>%
  mutate(GNDR_CD = GNDR_CD %>% factor(levels = 1:2, labels = gender_info$label)) %>%
  re_order_HRU %>%
  ggplot(aes(x = WIMDS, y = fit, color = GNDR_CD)) +
    geom_ribbon(aes(ymin = lcl, ymax = ucl, fill = GNDR_CD), alpha = 0.2, color = NA) +
    geom_line() +
    scale_colour_manual(
      labels = gender_info$label %>% set_names(1:2),
      values = gender_info$colour) +
    scale_fill_manual(
      labels = gender_info$label %>% set_names(1:2),
      values = gender_info$colour) +
    coord_cartesian(xlim = c(-1, NA), ylim = c(NA, NA), expand = F) +
    labs(y = 'Predicted count', x = 'WIMD 2011 score') +
    facet_by_HRUoutcome(scale = 'free_y') +
    theme_minimal() +
    theme1() +
    theme(axis.line.y = element_line(), axis.ticks.y = element_line()) +
    theme_HRU_outcomes()
) %>%
  egg::set_panel_size(width = unit(eggPanelSize$w, 'cm'), height = unit(eggPanelSize$h, 'cm')) -> g0
ggsave(plot = g0, filename = 'output/results/HRU_predicted_count_by_WIMDS_and_gender.pdf', height = pdfPlotDim$h * 1.9, width = pdfPlotDim$w * 1.4, device = 'pdf')

#### te(WIMDS, age, by GNDR_CD) ----

gamnbteOnlyByGenderSmooths =
  gamnbteOnlyByGender %>% names %>%
    lapply(function(.outcome){
      gratia::evaluate_smooth(gamnbteOnlyByGender[[.outcome]], smooth = 'te(WIMDS,age)') %>%
        mutate(.outcome = .outcome)
    }) %>%
    reduce(bind_rows) %>%
    mutate(GNDR_CD = recode(GNDR_CD, '1' = 'M', '2' = 'F') %>% relevel('F'))

gamnbteOnlyByGenderPlots =
  gamnbteOnlyByGender %>% names %>%
      lapply(function(..outcome){
        gamnbteOnlyByGenderSmooths %>%
          filter(.outcome == ..outcome) %>%
          ggplot(aes(x = WIMDS, y = age, z = est)) +
              geom_raster(aes(fill = est)) +
              scale_fill_distiller(palette = 'RdBu', name = 'Effect') +
              geom_contour(aes(colour = after_stat(level)), colour = 'black', size = .1) +
              labs(title =
                     outcomes %>% filter(code == ..outcome) %>% pull(label) %>% str_pad(width = 100, side = 'right') %>% stringr::str_wrap(15),
                x = element_blank(), y = element_blank(), z = element_blank()) +
              coord_cartesian(expand = F, xlim = c(-0.1, NA)) +
              facet_grid(
                rows = vars(GNDR_CD),
                labeller = as_labeller(
                  c(
                    gender_info$label %>% stringr::str_wrap(23) %>% set_names(gender_info$code),
                    outcomes %>% filter(code == ..outcome) %>% pull(label) %>% stringr::str_wrap(23) %>% set_names(outcomes %>% filter(code == ..outcome) %>% pull(code))
                  )
                )
              ) +
              theme1() +
              theme(
                axis.ticks.y = element_blank(),
                plot.title = element_text(hjust = 0.5, size = 11, vjust = 1),
                axis.line.y = element_blank(),
                axis.line.x = element_blank(),
                axis.text.y = element_blank(),
                strip.background = element_blank(),
                legend.position = 'top',
                panel.spacing.y = unit(.5, 'lines'),
                strip.text = element_blank(),
              ) +
              guides(fill = guide_colorbar(
                title.position = 'top',
                title.vjust = 0,
                label.theme = element_text(size = 5),
                barwidth = 5, barheight = 0.5,
              ))
      })

gamnbteOnlyByGenderPlots[[1]] = gamnbteOnlyByGenderPlots[[1]] + labs(y = 'Ages (years)') + theme(axis.ticks.y = element_line(), axis.text.y = element_text())

gamnbteOnlyByGenderPlots[[6]] = gamnbteOnlyByGenderPlots[[6]] + theme(strip.text = element_text())

g0 =
  gamnbteOnlyByGenderPlots[[1]] +
  gamnbteOnlyByGenderPlots[[2]] +
  gamnbteOnlyByGenderPlots[[3]] +
  gamnbteOnlyByGenderPlots[[4]] +
  gamnbteOnlyByGenderPlots[[5]] +
  gamnbteOnlyByGenderPlots[[6]] +
  patchwork::plot_layout(nrow = 1) +
  patchwork::plot_annotation(caption = 'WIMD 2011 score') +
  theme(plot.margin = unit(c(0,0,0,0), 'pt'))

ggsave(plot = g0, filename = 'output/results/HRU_WIMDS_age_interaction_withinGender.pdf', height = pdfPlotDim$h * 1.5, width = pdfPlotDim$w * 1.9, device = 'pdf')

#### HRU by WIMD domains -----

(
  outcomes$code %>%
    lapply(function(.outcome){
      WIMD_domains_lables$code %>%
        lapply(function(..var){
          gamnbDomainsSeperate[[.outcome]][[..var]] %>%
            gratia::evaluate_smooth(smooth = paste0('s(', ..var, ')')) %>%
            mutate(
              lcl  = est - 1.96 * se, ucl = est + 1.96 * se,
              .var = ..var,
              .outcome = .outcome
            ) %>%
            rename(X = as.name(..var))
        }) %>% Reduce(f = 'bind_rows')
    }) %>% do.call(what = 'bind_rows') %>%
    mutate(
      .var    = .var %>% factor(levels = WIMD_domains_lables$code),
      .outcome = .outcome %>% factor(levels = outcomes$code)
    ) %>%
    ggplot(aes(x = X, y = est)) +
    hline0 +
  theme(
    panel.grid = element_blank(),
    strip.background = element_blank(),
    panel.background =element_rect(fill = NA, colour = 'black', size = 0.1),
    panel.spacing = unit(1, 'lines'),
    panel.spacing.y = unit(.2, 'lines'),
    strip.text.y = element_text(angle = 0, hjust = 0),
    strip.text = element_text(size = 8.5),
    axis.text = element_text(size = 7.5),
    axis.title = element_text(size = 9),
    axis.title.x = element_text(margin = margin(t = 8)),
    axis.title.y = element_text(margin = margin(r = 8))
  )+
    geom_ribbon(aes(ymin = lcl, ymax = ucl), alpha=0.15) +
    geom_line() +
    facet_grid(rows = vars(.var), cols = vars(.outcome),
               labeller = as_labeller(
                 WIMD_domains_lables$label %>% set_names(WIMD_domains_lables$code) %>% sapply(strwrap_at, 11) %>%
                   c(outcomes$label %>% set_names(outcomes$code) %>% sapply(strwrap_at, 17))
               )
    ) +
    coord_cartesian(xlim = c(-1, NA), expand = F) +
    geom_line() +

    ggpmisc::geom_text_npc(
      data = data.frame(
        .var    = WIMD_domains_lables$code %>% factor(levels = WIMD_domains_lables$code) %>% rep(2),
        p_value = outcomes$code %>%
          map(function(.outcome) {
            WIMD_domains_lables$code %>%
              map(function(.var) {
                gamnbDomainsSeperate[[.outcome]][[.var]] %>% summary %>% extract2('s.table') %>% row.names %>%
                  head(-1) %>% # remove s(age)
                  map_chr(function(x){get_p_value_of_smooth(gamnbDomainsSeperate[[.outcome]][[.var]], sm = x, roundTo = 3)})
              }) %>% unlist
            })  %>% unlist,
        .outcome   = outcomes$code %>% rep(each = 8) %>% factor(levels = outcomes$code)
      ), npcx = 'right', npcy = 'bottom', size = 2,

      aes(label = paste0('p-value ', p_value)),
      inherit.aes = F
    ) +
    labs(x = 'WIMD 2011 domain score', y = 'Effect')
) %>%
egg::set_panel_size(width = unit(eggPanelSize$w * 0.6, 'cm'), height = unit(eggPanelSize$h * 0.6, 'cm')) -> g0
ggsave(plot = g0, filename = 'output/results/HRU_vs_WIMDS_domains_seperate_models.pdf', height = pdfPlotDim$h * 2.8, width = pdfPlotDim$w * 1.8, device = 'pdf')
