WIMD2011 = SQL2dt(DS$WIMD2011)

WIMDQ_info = (
  read.table(header=T, sep = ',', strip.white = T, as.is = T, text = '
    WIMDQ, code     , label
    1    , WIMDQ1   , Most deprived
    2    , WIMDQ2   , Next most deprived
    3    , WIMDQ3   , Middle deprivation
    4    , WIMDQ4   , Next least deprived
    5    , WIMDQ5   , Least deprived
  ') %>%
    inner_join(
      WIMD2011 %>%
        group_by(QUINTILE) %>%
        summarise(WIMDS_min = min(SCORE), WIMDS_max = max(SCORE)) %>%
        rename(WIMDQ = QUINTILE) %>%
        mutate(ymin = -Inf, ymax = Inf, fill = ((3:7)/20) %>% lapply(function(x){alpha('#000000', x)}) %>% unlist %>% rgba2rgb),
      by = 'WIMDQ'
    ) %>%
    arrange(WIMDQ)
)

WIMDQ.colr = c('#F37B5C', '#D5BB52', '#757575', '#4BC1C3', '#72B652')
