# add PEDW_ASTHMA (by admission type)
# see NHS Wales Data Dictionary / admissionmethod
ADMIS_MTHD_CD.list = list(
	PEDW_ASTHMA        = c(),
	PEDW_ASTHMA_EMERG  = c(21, 22, 23, 24, 25, 27, 28),
	PEDW_ASTHMA_ELECT  = c(11, 12, 13, 14, 15),
	PEDW_ASTHMA_MATRN  = c(31, 32),
	PEDW_ASTHMA_OTHER  = c(81, 82, 83, 98, 99)
) %>% lapply(as.character)

for (.i. in seq_along(ADMIS_MTHD_CD.list)){
  colname..	= names(ADMIS_MTHD_CD.list)[.i.]
  ADMIS_MTHD_CD = ADMIS_MTHD_CD.list[[.i.]]
	source('cohorts_characterisation/PEDW_ASTHMA_base.r')
  sql.extraction %<>% c(PEDW.sql)
}
