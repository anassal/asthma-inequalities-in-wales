PEDW.sql = paste0("

		UPDATE  ", cohort.table, " SET ", colname.., " = 0 WHERE 1 = 1;

		MERGE INTO  	", cohort.table, " A
		USING				(
		                  SELECT    B.", alf, "
														  , COUNT(DISTINCT S.SPELL_NUM_PE) AS ", colname.., "

											FROM		", cohort.table, " 			B

											JOIN		", DS$PEDW_SP, " 	S

												ON		B.", alf, " = S.", alf, "

                        ", ifelse(ADMIS_MTHD_CD %>% length > 1,
                                  "AND S.ADMIS_MTHD_CD IN ('" %>% paste0(ADMIS_MTHD_CD %>% paste0(collapse = "', '")) %>% paste0("')"),
                                  ""), "

											JOIN		", DS$PEDW_EP ," 	E

												ON		S.SPELL_NUM_PE  = E.SPELL_NUM_PE
												AND		S.PROV_UNIT_CD = E.PROV_UNIT_CD

											  AND		E.DIAG_CD_123 IN ('J45', 'J46')
										    AND   S.ADMIS_DT BETWEEN '", followup[1], "' AND '", followup[2], "'

											GROUP BY	B.", alf, "
		            ) Q

		ON					A.", alf, " = Q.", alf, "

		WHEN MATCHED THEN	UPDATE SET A.", colname.., " = Q.", colname.., ";
	")
