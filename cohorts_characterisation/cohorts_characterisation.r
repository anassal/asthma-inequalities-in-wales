criteria.cohortSelection = c('none', 'WOB', 'WIMD', 'ASTHMA', 'DOD') # not including GPREG because it will be used later

sql.flowchart.where.SQL =
  sql.flowchart.where %>% lapply(extract2, 'sql') %>% magrittr::extract(criteria.cohortSelection) %>%
  unlist %>% paste(collapse = ' AND ')

runSQL("call fnc.drop_if_exists('", cohort.table, "');
	 CREATE TABLE ", cohort.table, " AS (SELECT * FROM ", cohortSelectionTable, " WHERE ", sql.flowchart.where.SQL, ") WITH NO DATA;
   INSERT INTO  ", cohort.table, "    (SELECT * FROM ", cohortSelectionTable, " WHERE ", sql.flowchart.where.SQL, ")             ;
")


# create WLGP subset
paste0("
  call fnc.drop_if_exists('", DS$WLGP_subset, "');

  CREATE TABLE             ", DS$WLGP_subset, " AS
          ( SELECT    G.ALF_PE, G.EVENT_CD, G.EVENT_DT, G.EVENT_VAL
            FROM      ", DS$WLGP, " G

          	JOIN      (
          					SELECT      DISTINCT A.ALF_PE
          					FROM        ", cohort.table, " A
          					WHERE       A.ALF_PE IS NOT NULL
          	) T

          	ON      T.ALF_PE = G.ALF_PE

          	AND     T.ALF_PE IS NOT NULL
  ) WITH NO DATA;

  INSERT INTO              ", DS$WLGP_subset, "
          ( SELECT    G.ALF_PE, G.EVENT_CD, G.EVENT_DT, G.EVENT_VAL
            FROM      ", DS$WLGP, " G

          	JOIN      (
          					SELECT      DISTINCT A.ALF_PE
          					FROM        ", cohort.table, " A
          					WHERE       A.ALF_PE IS NOT NULL
          	) T

          	ON      T.ALF_PE = G.ALF_PE

          	AND     T.ALF_PE IS NOT NULL
          )
  ;
") # %>% runSQL



GP_characterisation.sqlmodel = gpact::model2sql(
	  page.id = 102,
		outputPath = path.SQL,
		model.SQLTable = cohort.table,
		append_to_table = T,
		drop.existingColumns = T,
		appendGNDRWOBDOD = F,
		alfTable = cohort.table,
		AR_PERS = DS$WDS_PERS,
		GP.table = DS$WLGP_subset,
		alf = alf,
	  id.cols = c(alf),
	  id.cols.types = c('BIGINT'),
		REORG = F
)

# add SQL queries to sql.extraction

sql.extraction = GP_characterisation.sqlmodel$model.SQL

#
source('cohorts_characterisation/ASTHMA_LOS.r')

#
source('cohorts_characterisation/PEDW_ASTHMA.r')

#
source('cohorts_characterisation/EDDS_ASTHMA.r')


# run the SQL queries
sql.extraction %>% paste0(collapse = ' \n\n ') %>% runSQL


