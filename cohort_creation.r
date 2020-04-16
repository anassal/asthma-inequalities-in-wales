### cohort selection model ######################################################################################
# criteria are all with asthma.dx code on or before 2013-01-01,
# not followed by asthma.resolved code

# fetch the cohort selection specs
modelweb = gpact::model2sql.web(model.nid = 101)

alfTable                  = paste0('(SELECT DISTINCT ', alf, ' FROM ', DS$GPREG, ')')

# add ASTHMA_RX_12M_[2:5]
for (i in 2:5){
	# copy ASTHMA_RX_12M_1
	modelweb$model.vars[[paste0("ASTHMA_RX_12M_", i)]] = modelweb$model.vars$ASTHMA_RX_12M_1
	# change variableName
	modelweb$model.vars[[paste0("ASTHMA_RX_12M_", i)]]$variableName = paste0("ASTHMA_RX_12M_", i)
	# change date From and To
	modelweb$model.vars[[paste0("ASTHMA_RX_12M_", i)]]$dateFrom     = paste0("FOLLOWUP_START_DATE + ", i - 1, " YEAR")
  modelweb$model.vars[[paste0("ASTHMA_RX_12M_", i)]]$dateTo       = paste0("FOLLOWUP_START_DATE + ", i, " YEAR - 1 DAY")
}

cohortselection.sqlmodel = gpact::model2sql(
  model.source         = modelweb,
	outputPath           = path.SQL,
	model.SQLTable       = cohortSelectionTable,
  append_to_table      = F,
  appendGNDRWOBDOD     = T,
  alfTable             = alfTable,
  AR_PERS              = DS$WDS_PERS,
  GP.table             = DS$WLGP,
  alf                  = alf,
  id.cols              = c(alf),
  id.cols.types        = c('BIGINT'),
  drop.existingColumns = T
)

#cohortselection.sqlmodel$model.SQL %>% runSQL # few min

###############

# add REGISTERED:
DONRUNrunSQL(paste0("
	ALTER TABLE ", cohortSelectionTable, " ADD GPREG SMALLINT DEFAULT 0;
"))

DONRUNrunSQL(paste0("
	UPDATE ", cohortSelectionTable, " SET GPREG = 0;
"))

# flag GPREG = 1
DONRUNrunSQL(paste0("
	MERGE INTO  ", cohortSelectionTable ," a
	USING (


				SELECT   ", alf, "
				FROM     (
									SELECT   ", alf, ",
									         SUM(GPREG_LENGTH) AS SUM_GPREG_LENGTH -- not needed since GPREG was grouped on SAIL not practices
									FROM (
									         SELECT  C.", alf, ",
                                   GPREG.START_DATE,
                                   GPREG.END_DATE,
									                 DAYS(CASE WHEN GPREG.END_DATE     > '", followup[2], "' THEN '", followup[2], "' ELSE GPREG.END_DATE   END)
														         -
														         DAYS(CASE WHEN GPREG.START_DATE < '", followup[1], "' THEN '", followup[1], "' ELSE GPREG.START_DATE END)
														         AS GPREG_LENGTH


											     FROM    ", cohortSelectionTable," C

											     JOIN    ", DS$GPREG, "        GPREG
											       ON    C.", alf, " = GPREG.", alf, "
											       AND   GPREG.START_DATE <= '", followup[1], "'
										         AND   GPREG.END_DATE   >= '", followup[2],"'
									      )

									 GROUP BY ", alf, "
								  )
				 WHERE SUM_GPREG_LENGTH >= 1825 -- or just = 1825 (5 years)

		  ) b
	ON a.", alf, " = b.", alf, "
	WHEN MATCHED THEN UPDATE SET GPREG = 1
"))

# add columns for LSOA and WIMD
DONTRUNrunSQL("
	ALTER TABLE ", cohortSelectionTable, " ADD WIMD SMALLINT;
	ALTER TABLE ", cohortSelectionTable, " ADD LSOA_CD CHAR(9);
")

DONTRUNrunSQL("
	UPDATE ", cohortSelectionTable, " SET WIMD  = NULL, LSOA_CD = NULL;
")


# WIMD of longest address during WIMD
# should we also require full addresses coverge of followup?
paste0("
	MERGE INTO  ", cohortSelectionTable, " A
	USING

	(
		SELECT     ", alf, ",
		           ADD_END_DATE,
		           ADD_START_DATE,
		           LSOA_CD,
		           WIMD

		FROM

		(
			SELECT CHRT.", alf, ",
			       ADD.START_DATE AS ADD_START_DATE,
			       ADD.END_DATE   AS ADD_END_DATE,
			       ADD.LSOA_CD,
			       WIMD.QUINTILE AS WIMD,
			       ROW_NUMBER() OVER (
			         PARTITION BY CHRT.", alf, "
			         ORDER BY     DAYS(CASE WHEN ADD.END_DATE   > '", followup[2], "' THEN '", followup[2], "' ELSE ADD.END_DATE   END)
			                      -
			                      DAYS(CASE WHEN ADD.START_DATE < '", followup[1], "' THEN '", followup[1], "' ELSE ADD.START_DATE END)
		               DESC
		           ) AS ADD_LENGTH_ORDER

		 	FROM		", cohortSelectionTable,"			CHRT

		   JOIN	  ", DS$WDS_PERS, "         	 				PERS
		 	   ON	  CHRT.", alf, " = PERS.", alf, "

		   JOIN	  ", DS$WDS_ADDR_LSOA_CLN,"   				      ADD
		 	  ON	PERS.", alf, " = ADD.", alf, "

		 	   AND	ADD.START_DATE <= '", followup[2] ,"'
		 	   AND 	ADD.END_DATE   >= '", followup[1] ,"'

		 	   AND  ADD.LSOA_CD      IS NOT NULL
		 	   AND  ADD.START_DATE   IS NOT NULL
		 	   AND  ADD.END_DATE     IS NOT NULL
		 	   AND  ADD.", alf, "    IS NOT NULL

		   JOIN   ", DS$WIMD2011, " WIMD
		     ON   ADD.LSOA_CD = WIMD.LSOA_CD

		)
		WHERE    ADD_LENGTH_ORDER = 1

	) B

	ON   A.", alf, " = B.", alf, "
	WHEN MATCHED THEN UPDATE SET A.WIMD = B.WIMD, A.LSOA_CD = B.LSOA_CD;

") %>% runSQL





##########################
