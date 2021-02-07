facet_wrap_by_death_defs = function(str_with = 18) {
  facet_wrap(
    'def',
    labeller = as_labeller(
      deaths_def$label %>% sapply(strwrap_at, str_with) %>% set_names(deaths_def$code)
    )
  )
}

theme_deaths_defs = function(){
  theme(
    panel.spacing.y = unit(2, 'lines'),
    strip.text = element_text(margin = margin(b = 0), vjust = 1, size = 9)
  )
}

# combined plots

#### simple WIMDS smooths ####

(
  bind_rows(
    (
      ma0$any %>%
        gratia::evaluate_smooth(smooth = 's(WIMDS)') %>%
        mutate(lcl = est - 1.96 * se, ucl = est + 1.96 * se) %>%
        mutate(def = 'any')
    ),
    (
      ma0$und %>%
        gratia::evaluate_smooth(smooth = 's(WIMDS)') %>%
        mutate(lcl = est - 1.96 * se, ucl = est + 1.96 * se) %>%
        mutate(def = 'und')
    )
  ) %>%
    ggplot(aes(x = WIMDS, y = est)) +
    hline0 +
    geom_ribbon(aes(ymax = ucl, ymin = lcl), alpha = 0.2) +
    geom_line() +
    coord_cartesian(xlim = c(-1, NA), expand = F) +
    ggpmisc::geom_text_npc(
      data = data.frame(
        p_value = c(
          get_p_value_of_smooth(ma0$any, sm = 's(WIMDS)', roundTo = 3),
          get_p_value_of_smooth(ma0$und, sm = 's(WIMDS)', roundTo = 3)
        ),
        def     = c('any', 'und')
      ), npcx = 'right', npcy = 'bottom', hjust = 'right', size = 3,
      aes(label = paste0('p-value ', p_value)), inherit.aes = F
    ) +

    facet_wrap_by_death_defs() +
    labs(x = 'WIMD 2011 score', y = 'Effect') +
    theme_minimal() +
    theme1() +
    theme(axis.line.y = element_line(), axis.ticks.y = element_line()) +
    theme_deaths_defs()
) %>%
  egg::set_panel_size(width = unit(eggPanelSize$w, 'cm'), height = unit(eggPanelSize$h, 'cm')) -> g0
ggsave(plot = g0, filename = 'output/results/deaths/deaths_gam_simple_smooths.pdf', height = pdfPlotDim$h, width = pdfPlotDim$w, device = 'pdf')


#### separate smooths by gender ####

(
  bind_rows(
    (
      ma1$any %>%
        gratia::evaluate_smooth(smooth = 's(WIMDS)') %>%
        mutate(lcl = est - 1.96 * se, ucl = est + 1.96 * se) %>%
        mutate(def = 'any')
    ),
    (
      ma1$und %>%
        gratia::evaluate_smooth(smooth = 's(WIMDS)') %>%
        mutate(lcl = est - 1.96 * se, ucl = est + 1.96 * se) %>%
        mutate(def = 'und')
    )
  ) %>%
    mutate(GNDR_CD = GNDR_CD %>% factor(levels = gender_info$code, labels = gender_info$label)) %>%
    ggplot(aes(x = WIMDS, y = est, colour = GNDR_CD)) +
    hline0 +
    geom_ribbon(aes(ymax = ucl, ymin = lcl, fill = GNDR_CD), alpha = 0.2, colour = NA, show.legend = T) +

    scale_colour_manual(
      labels = gender_info$label %>% set_names(gender_info$code),
      values = gender_info$colour) +

    scale_fill_manual(
      labels = gender_info$label %>% set_names(gender_info$code),
      values = gender_info$colour) +

    geom_line() +

    coord_cartesian(xlim = c(-1, NA), expand = F) +

    # p-values

    ggpmisc::geom_text_npc(
      data = data.frame(
        p_value = c(
                    paste0(
                      'p-value\n',
                      'Males       '   , get_p_value_of_smooth(ma1$any, sm = 's(WIMDS):GNDR_CDM', roundTo = 3),
                      '\n    ',
                      'Females    ' , get_p_value_of_smooth(ma1$any, sm = 's(WIMDS):GNDR_CDF', roundTo = 3)
                    ),
                    paste0(
                      'p-value\n',
                      'Males       '   , get_p_value_of_smooth(ma1$und, sm = 's(WIMDS):GNDR_CDM', roundTo = 3),
                      '\n    ',

                      'Females       ' , get_p_value_of_smooth(ma1$und, sm = 's(WIMDS):GNDR_CDF', roundTo = 3)
                    )
                  ),
        def     = c('any', 'und')
      ), npcx = 'right', npcy = 'bottom', hjust = 'right', size = 2.3,
      aes(label = paste0(p_value)), inherit.aes = F
    ) +

    facet_wrap_by_death_defs() +
    labs(x = 'WIMD 2011 score', y = 'Effect') +
    theme_minimal() +
    theme1() +
    theme(axis.line.y = element_line(), axis.ticks.y = element_line()) +
    theme_deaths_defs()
  ) %>%
egg::set_panel_size(width = unit(eggPanelSize$w, 'cm'), height = unit(eggPanelSize$h, 'cm')) -> g0
ggsave(plot = g0, filename = 'output/results/deaths/deaths_gam_WimdsSmoothsByGender.pdf', height = pdfPlotDim$h + 0.4, width = pdfPlotDim$w, device = 'pdf')

#### death_risk_by_WIMDS_by_gender ####

death_risk_by_WIMDS_by_gender =
  c('any', 'und') %>%
  lapply(
    (function(death_pos_bin) {
      c('F', 'M') %>%
        lapply(function(.g) {
          submodel = ma1[[death_pos_bin]]$model %>% filter(GNDR_CD == .g)
          rand_ids = sample.int(submodel %>% nrow, 1000, replace = F)
          tibble(
            WIMDS   = submodel %>% pull(WIMDS),
            GNDR_CD = .g
          ) %>%
            bind_cols(
              ma1[[death_pos_bin]] %>% predict(newdata = data.frame(
                WIMDS   = submodel %>% pull(WIMDS),
                age     = submodel %>% pull(age) %>% median,
                GNDR_CD = .g
              ), type = 'link', se.fit = T) %>%
                as_tibble() %>%
                mutate(
                  ucl = (fit + 1.96 * se.fit) %>% (ma1[[death_pos_bin]]$family$linkinv),
                  lcl = (fit - 1.96 * se.fit) %>% (ma1[[death_pos_bin]]$family$linkinv),
                  fit = fit                   %>% (ma1[[death_pos_bin]]$family$linkinv)
                )
            ) %>%
            arrange(WIMDS) %>%
            slice(c(
              rand_ids,
              (1:n()) %>% (function(x) {c(head(x,50), tail(x, 50))})
            ))
        }) %>%
        do.call(what = bind_rows) %>%
        mutate(def = death_pos_bin)
    })
  )%>%
  do.call(what = bind_rows)

(death_risk_by_WIMDS_by_gender %>%
  mutate(GNDR_CD = GNDR_CD %>% factor(levels = gender_info$code, labels = gender_info$label)) %>%
  ggplot(aes(x = WIMDS, y = fit, color = GNDR_CD)) +
    geom_ribbon(aes(ymin = lcl, ymax = ucl, fill = GNDR_CD), alpha = 0.2, color = NA) +
    geom_line() +
    scale_colour_manual(
      labels = gender_info$label %>% set_names(gender_info$code),
      values = gender_info$colour) +
    scale_fill_manual(
      labels = gender_info$label %>% set_names(gender_info$code),
      values = gender_info$colour) +
    coord_cartesian(xlim = c(-1, NA), ylim = c(NA, 0.0012), expand = F) +
    labs(y = 'Risk of asthma death', x = 'WIMD 2011 score') +
    facet_wrap_by_death_defs() +
    theme_minimal() +
    theme1() +
    theme(axis.line.y = element_line(), axis.ticks.y = element_line()) +
    theme_deaths_defs()
) %>%
egg::set_panel_size(width = unit(eggPanelSize$w, 'cm'), height = unit(eggPanelSize$h, 'cm')) -> g0
ggsave(plot = g0, filename = 'output/results/deaths/death_risk_by_WIMDS_and_gender.pdf', height = pdfPlotDim$h + 0.4, width = pdfPlotDim$w, device = 'pdf')

#### difference smooth by gender for WIMDS ####

(
  bind_rows(
    ma1$any %>%
      gratia::difference_smooths(smooth = 's(WIMDS)') %>%
      mutate_at(vars(c('diff', 'lower', 'upper')), .funs = function(x) - x) %>%
      mutate(def = 'any'),

    ma1$und %>%
      gratia::difference_smooths(smooth = 's(WIMDS)') %>%
      mutate_at(vars(c('diff', 'lower', 'upper')), .funs = function(x) - x) %>%
      mutate(def = 'und')
  ) %>%

  ggplot(aes(x = WIMDS, y = diff)) +
  hline0 +
  geom_ribbon(aes(ymin = lower, ymax = upper), alpha = 0.2) +
  geom_line() +
  facet_wrap_by_death_defs() +
  labs(x = 'WIMD 2011 score', y = 'Difference in effect') +
  theme_minimal() +
  theme1() +
  theme(axis.line.y = element_line(), axis.ticks.y = element_line()) +
  theme_deaths_defs()
)  %>%
egg::set_panel_size(width = unit(eggPanelSize$w, 'cm'), height = unit(eggPanelSize$h, 'cm')) -> g0
ggsave(plot = g0, filename = 'output/results/deaths/death_WIMDS_difference_smooth_for_gender.pdf', height = pdfPlotDim$h, width = pdfPlotDim$w, device = 'pdf')

#### te(WIMDS, age, by GNDR_CD) ----

(
  bind_rows(
    ma_WIMDS_x_age_bygender_teOnly$any %>% gratia::evaluate_smooth(smooth = 'te(WIMDS,age)') %>%
      mutate(def = 'any'),
    ma_WIMDS_x_age_bygender_teOnly$und %>% gratia::evaluate_smooth(smooth = 'te(WIMDS,age)') %>%
      mutate(def = 'und')
  ) %>%
    ggplot(aes(x = WIMDS, y = age, z = est)) +
    geom_raster(aes(fill = est)) +
    scale_fill_distiller(palette = 'RdBu', name = 'Effect') +
    geom_contour(aes(colour = after_stat(level)), colour = 'black', size = .1) +
    ggpmisc::geom_text_npc(
      data = data.frame(
        c('any', 'und') %>%
          lapply(function(.def){
            ma_WIMDS_x_age_bygender_teOnly[[.def]] %>%
              get_p_value_of_smooth_by(sm = 'te(WIMDS,age)', byVarName = 'GNDR_CD', byVarLevels = c('M', 'F'), roundTo = 3) %>%
              as.data.frame %>%
              mutate(def = .def)
          }) %>%
          do.call(what = bind_rows) %>%
          pivot_longer(cols = c('F', 'M'), names_to = 'GNDR_CD', values_to = 'p_value')
      ),
      npcx = 'right', npcy = 'bottom', size = 3,
      aes(label = paste0('p-value ', p_value)),
    ) +
    labs(x = 'WIMD 2011 score', y = 'Age (years)', z = 'Effect') +
    coord_cartesian(expand = F, xlim = c(-0.1, NA)) +

    lemon::facet_rep_grid(
      rows = vars(GNDR_CD),
      cols = vars(def),
      repeat.tick.labels = T,
      labeller = as_labeller(
        c(
          gender_info$label %>% stringr::str_wrap(23) %>% set_names(gender_info$code),
          deaths_def$label %>% stringr::str_wrap(23) %>% set_names(deaths_def$code)
        )
      )
    ) +

    theme1() +
    theme_deaths_defs() +
    theme(
      legend.title = element_text(vjust = 0.5),
      strip.background = element_blank(),
      legend.position = 'right',
      panel.spacing.y = unit(.5, 'lines'),
      strip.text = element_text(margin = margin(b = 6, l = 6)),
    )
) %>%
egg::set_panel_size(width = unit(eggPanelSize$w, 'cm'), height = unit(eggPanelSize$h, 'cm')) -> g0
ggsave(plot = g0, filename = 'output/results/deaths/death_WIMDS_age_interaction_withinGender.pdf', height = pdfPlotDim$h * 1.5, width = pdfPlotDim$w * 1.1, device = 'pdf')

#### deaths by separate WIMD domains ----

(
  c('any', 'und') %>%
    lapply(function(def){
      WIMD_domains_lables$code %>%
        lapply(function(..var){
          gam_deaths_domains[[def]][[..var]] %>%
            gratia::evaluate_smooth(smooth = paste0('s(', ..var, ')')) %>%
            mutate(
              lcl  = est - 1.96 * se, ucl = est + 1.96 * se,
              .var = ..var,
              def = def
            ) %>%
            rename(X = as.name(..var))
        }) %>% Reduce(f = 'bind_rows')
    }) %>% do.call(what = 'bind_rows') %>%
    mutate(.var = .var %>% factor(levels = WIMD_domains_lables$code)) %>%
    ggplot(aes(x = X, y = est)) +
    hline0 +

    theme(
      panel.grid = element_blank(),
      strip.background = element_blank(),
      panel.background =element_rect(fill = NA, colour = 'black', size = 0.1),
      panel.spacing = unit(1, 'lines'),
      panel.spacing.y = unit(.2, 'lines'),
      strip.text.y = element_text(angle = 0, hjust = 0),
      strip.text = element_text(size = 7.4),
      axis.text = element_text(size = 7.4),
      axis.title = element_text(size = 9),
      axis.title.x = element_text(margin = margin(t = 8)),
      axis.title.y = element_text(margin = margin(r = 8))
    )+

    geom_ribbon(aes(ymin = lcl, ymax = ucl), alpha=0.15) +
    geom_line() +

    facet_grid(rows = vars(.var), cols = vars(def),
               labeller = as_labeller(
                 WIMD_domains_lables$label %>% set_names(WIMD_domains_lables$code) %>% sapply(strwrap_at, 11) %>%
                   c(deaths_def$label %>% set_names(deaths_def$code) %>% sapply(strwrap_at, 17))
               )
    ) +

    coord_cartesian(xlim = c(-1, NA), expand = F) +
    geom_line() +

    ggpmisc::geom_text_npc(
      data = data.frame(
        .var    = WIMD_domains_lables$code %>% factor(levels = WIMD_domains_lables$code) %>% rep(2),
        p_value = c('any', 'und') %>%
          map(function(def..) {
            WIMD_domains_lables$code %>%
              map(function(.var) {
                gam_deaths_domains[[def..]][[.var]] %>% summary %>% extract2('s.table') %>% row.names %>%
                  head(-1) %>% # remove s(age)
                  map_chr(function(x){get_p_value_of_smooth(gam_deaths_domains[[def..]][[.var]], sm = x, roundTo = 3)})
              }) %>% unlist
            })  %>% unlist,
        def   = c('any', 'und') %>% rep(each = 8)
      ), npcx = 'right', npcy = 'bottom', size = 2,
      aes(label = paste0('p-value ', p_value)),
      inherit.aes = F
    ) +
    labs(x = 'WIMD 2011 domain score', y = 'Effect')
) %>%
egg::set_panel_size(width = unit(eggPanelSize$w * 0.6, 'cm'), height = unit(eggPanelSize$h * 0.6, 'cm')) -> g0
ggsave(plot = g0, filename = 'output/results/deaths/death_vs_WIMDS_domains_seperate_models.pdf', height = pdfPlotDim$h * 2.7, width = pdfPlotDim$w * 0.78, device = 'pdf')
