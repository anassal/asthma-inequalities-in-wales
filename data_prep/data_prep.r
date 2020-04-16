#read cohort.table from DB2
cohort.dt = SQL2dt(cohort.table)

cohort.dt[, age := (followup[1] %>% as.Date - WOB) %>% as.numeric / 365.25]
#cohort.dt[, age] %>% hist
cohort.dt[, age.cat := cut(age, breaks = c((0:4)*5, 35, 40, 65, 70, 75, 80, 85, 90, 120))]

cohort.dt[, GNDR_CD := GNDR_CD %>% as.factor]

cohort.dt[, AMR := (ICS + ICS_LABA)/(SABA + (ICS + ICS_LABA))] # 0/0 is common
cohort.dt[, AMR.cat := ceiling(AMR * 10)] # 0/0 is common

# make WIMD quintile factor, and WIMD5 the reference
#cohort.dt[, WIMD := WIMD %>% as.factor]
cohort.dt$WIMD = factor(cohort.dt$WIMD, levels = c(5,1,2,3,4))
#cohort.dt$WIMD = factor(cohort.dt$WIMD, levels = 1:5, labels = WIMD.labels)

cohort.dt[ASTHMA_LOS          %>% is.na, ASTHMA_LOS         := 0]
cohort.dt[PEDW_ASTHMA         %>% is.na, PEDW_ASTHMA        := 0]
cohort.dt[PEDW_ASTHMA_EMERG   %>% is.na, PEDW_ASTHMA_EMERG  := 0]


# had asthma Rx every calendar year between 2013 and 2017
cohort.dt[, ASTHMA_RX := (ASTHMA_RX_12M_1 > 0 &
						              ASTHMA_RX_12M_2 > 0 &
						              ASTHMA_RX_12M_3 > 0 &
						              ASTHMA_RX_12M_4 > 0 &
					                ASTHMA_RX_12M_5 > 0) * 1]

cohort.dt %<>%
  mutate(ASTHMA_RX_SUM =
      (ASTHMA_RX_12M_1 > 0) * 1 +
      (ASTHMA_RX_12M_2 > 0) * 1 +
      (ASTHMA_RX_12M_3 > 0) * 1 +
      (ASTHMA_RX_12M_4 > 0) * 1 +
      (ASTHMA_RX_12M_5 > 0) * 1
    )
