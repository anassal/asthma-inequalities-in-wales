sql.extraction %<>% c(paste0("

		UPDATE  ", cohort.table, " SET ASTHMA_LOS = 0 WHERE 1 = 1;

MERGE INTO  	", cohort.table, " A
USING				(

		SELECT	ALF_PE,
		        COUNT(DISTINCT DT) AS ASTHMA_LOS
		FROM
		(
			SELECT	DISTINCT
					    C.ALF_PE,
					    DT.DATE DT

			FROM    ", cohort.table, "	       C

			JOIN		", DS$PEDW_SP, "               SP
			  ON      C.ALF_PE = SP.ALF_PE

			JOIN		", DS$PEDW_EP, "               EP

			  ON    EP.SPELL_NUM_PE = SP.SPELL_NUM_PE
			  AND   EP.PROV_UNIT_CD = SP.PROV_UNIT_CD

			  AND   EP.EPI_STR_DT BETWEEN '", followup[1], "' AND '", followup[2], "'
			  AND   EP.EPI_END_DT BETWEEN '", followup[1], "' AND '", followup[2], "'

			  AND		EP.DIAG_CD_123 IN ('J45', 'J46') -- dx in first position only

			JOIN    SAILW0317V.DATES_1990_2020	 DT

				ON    DT.DATE BETWEEN EP.EPI_STR_DT AND EP.EPI_END_DT
		)
		GROUP BY  ALF_PE
) Q

ON					A.", alf, " = Q.", alf, "
WHEN MATCHED THEN	UPDATE SET A.ASTHMA_LOS = Q.ASTHMA_LOS;
"))
