### cohort selection model #


# fetch the cohort selection specs
modelw = model2sql.web(model.nid = 101)
alfTable                  = paste0('(SELECT DISTINCT ', alf, ' FROM ', DS$GPREG, ')')
modelw$model.constants$STUDY_STARTDATE                   = NULL
modelw$model.constants$STUDY_ENDDATE      $constantValue = as.character(as_date(followup[1]) - days(1))
modelw$model.constants$FOLLOWUP_START_DATE$constantValue = followup[1]

# add ASTHMA_RX_12M_[2:5]

for (i in 2:5){
	# copy ASTHMA_RX_12M_1
	modelw$model.vars[[paste0("ASTHMA_RX_12M_", i)]] = modelw$model.vars$ASTHMA_RX_12M_1

	# change variableName
	modelw$model.vars[[paste0("ASTHMA_RX_12M_", i)]]$variableName = paste0("ASTHMA_RX_12M_", i)

	# change date From and To
	modelw$model.vars[[paste0("ASTHMA_RX_12M_", i)]]$dateFrom     = paste0("FOLLOWUP_START_DATE + ", i - 1, " YEAR")

  modelw$model.vars[[paste0("ASTHMA_RX_12M_", i)]]$dateTo       = paste0("FOLLOWUP_START_DATE + ", i, " YEAR - 1 DAY")
}

cohortselection.sqlmodel = model2sql(
  model.source         = modelw,
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

cohortselection.sqlmodel$model.SQL %>% runSQL

###############

# add 'REGISTERED' (follow-up in WLGP):

runSQL(paste0("
	ALTER TABLE ", cohortSelectionTable, " ADD GPREG SMALLINT DEFAULT 0;
"))

runSQL(paste0("
	UPDATE ", cohortSelectionTable, " SET GPREG = 0;
"))

#### flag GPREG = 1 -------------------

runSQL(paste0("
	MERGE INTO  ", cohortSelectionTable ," a
	USING (
				SELECT   ", alf, "
				FROM     (
									SELECT   ", alf, ",
									         SUM(GPREG_LENGTH) AS SUM_GPREG_LENGTH
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

#### add columns for LSOA and WIMD -----------------

runSQL("
	ALTER TABLE ", cohortSelectionTable, " ADD LSOA_CD CHAR(9);
	ALTER TABLE ", cohortSelectionTable, " ADD WIMDQ SMALLINT; -- quintile
	ALTER TABLE ", cohortSelectionTable, " ADD WIMDR SMALLINT; -- rank
	ALTER TABLE ", cohortSelectionTable, " ADD WIMDS DECIMAL(12,8); -- score

  ALTER TABLE ", cohortSelectionTable, " ADD INCS  DECIMAL(12,8);
  ALTER TABLE ", cohortSelectionTable, " ADD EMPS  DECIMAL(12,8);
  ALTER TABLE ", cohortSelectionTable, " ADD HLTS  DECIMAL(12,8);
  ALTER TABLE ", cohortSelectionTable, " ADD EDUS  DECIMAL(12,8);
  ALTER TABLE ", cohortSelectionTable, " ADD ACCS  DECIMAL(12,8);
  ALTER TABLE ", cohortSelectionTable, " ADD HOSS  DECIMAL(12,8);
  ALTER TABLE ", cohortSelectionTable, " ADD ENVS  DECIMAL(12,8);
  ALTER TABLE ", cohortSelectionTable, " ADD SAFS  DECIMAL(12,8);
")

#### LSOA_CD of longest address during the followup ------------

paste0("
	MERGE INTO  ", cohortSelectionTable, " A
	USING
	(
		SELECT     ", alf, ",
		           ADD_END_DATE,
		           ADD_START_DATE,
		           LSOA_CD

		FROM
		(
			SELECT CHRT.", alf, ",
			       ADD.START_DATE AS ADD_START_DATE,
			       ADD.END_DATE   AS ADD_END_DATE,
			       ADD.LSOA_CD,

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
		)

		WHERE    ADD_LENGTH_ORDER = 1
	) B

	ON   A.", alf, " = B.", alf, "

	WHEN MATCHED THEN UPDATE SET A.LSOA_CD = B.LSOA_CD;

") %>% runSQL



# add WIMD

paste0("

	MERGE INTO  ", cohortSelectionTable, " A
	USING
	(
          SELECT  CHRT.ALF_PE,
                  OVR.QUINTILE AS WIMDQ,
                  OVR.RANK     AS WIMDR,
                  CAST(OVR.SCORE AS DECIMAL(12, 8))    AS WIMDS,
                  CAST(INC.SCORE AS DECIMAL(12, 8))    AS INCS,
                  CAST(EMP.SCORE AS DECIMAL(12, 8))    AS EMPS,
                  CAST(HLT.SCORE AS DECIMAL(12, 8))    AS HLTS,
                  CAST(EDU.SCORE AS DECIMAL(12, 8))    AS EDUS,
                  CAST(ACC.SCORE AS DECIMAL(12, 8))    AS ACCS,
                  CAST(HOS.SCORE AS DECIMAL(12, 8))    AS HOSS,
                  CAST(ENV.SCORE AS DECIMAL(12, 8))    AS ENVS,
                  CAST(SAF.SCORE AS DECIMAL(12, 8))    AS SAFS

          FROM	  ", cohortSelectionTable,"	 CHRT

          JOIN    SAILREFRV.WIMD2011_OVERALL_INDEX                 OVR
             ON   CHRT.LSOA_CD = OVR.LSOA_CD

          JOIN    SAILREFRV.WIMD2011_INCOME_DOMAIN                 INC
             ON   CHRT.LSOA_CD = INC.LSOA_CD

          JOIN    SAILREFRV.WIMD2011_EMPLOYMENT_DOMAIN             EMP
             ON   CHRT.LSOA_CD = EMP.LSOA_CD

          JOIN    SAILREFRV.WIMD2011_HEALTH_DOMAIN                 HLT
             ON   CHRT.LSOA_CD = HLT.LSOA_CD

          JOIN    SAILREFRV.WIMD2011_EDUCATION_DOMAIN              EDU
             ON   CHRT.LSOA_CD = EDU.LSOA_CD

          JOIN    SAILREFRV.WIMD2011_ACCESSTOSERVICES_DOMAIN       ACC
             ON   CHRT.LSOA_CD = ACC.LSOA_CD

          JOIN    SAILREFRV.WIMD2011_HOUSING_DOMAIN                HOS
             ON   CHRT.LSOA_CD = HOS.LSOA_CD

          JOIN    SAILREFRV.WIMD2011_PHYSICALENV_DOMAIN            ENV
             ON   CHRT.LSOA_CD = ENV.LSOA_CD

          JOIN    SAILREFRV.WIMD2011_COMMUNITYSAFETY_DOMAIN        SAF
             ON   CHRT.LSOA_CD = SAF.LSOA_CD

  ) B

	ON   A.", alf, " = B.", alf, "
	WHEN MATCHED THEN UPDATE SET
	   A.WIMDQ = B.WIMDQ,
     A.WIMDR = B.WIMDR,
     A.WIMDS = B.WIMDS,

     A.INCS  = B.INCS,
     A.EMPS  = B.EMPS,
     A.HLTS  = B.HLTS,
     A.EDUS  = B.EDUS,
     A.ACCS  = B.ACCS,
     A.HOSS  = B.HOSS,
     A.ENVS  = B.ENVS,
     A.SAFS  = B.SAFS

") %>% runSQL
