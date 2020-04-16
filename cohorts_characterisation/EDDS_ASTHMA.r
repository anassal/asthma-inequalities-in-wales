	# add EDDS_ASTHMA
	sql.extraction %<>% c(paste0("
		UPDATE  ", cohort.table, " SET EDDS_ASTHMA = 0 WHERE 1 = 1;

		MERGE INTO  		", cohort.table, " A
		USING				(
								SELECT		A.", alf, ",
											COUNT(DISTINCT E.ADMIN_ARR_DT) AS EDDS_ASTHMA

								FROM		", cohort.table, "			A
								JOIN		", DS$EDDS, "  	E
								  ON		E.", alf, " = A.", alf, "
		                          AND       (
		                                            LEFT(E.DIAG_CD_1, 3) IN ('14A')
		                                        OR  LEFT(E.DIAG_CD_2, 3) IN ('14A')
		                                        OR  LEFT(E.DIAG_CD_3, 3) IN ('14A')
		                                        OR  LEFT(E.DIAG_CD_4, 3) IN ('14A')
		                                        OR  LEFT(E.DIAG_CD_5, 3) IN ('14A')
		                                        OR  LEFT(E.DIAG_CD_6, 3) IN ('14A')
		                                    )

								  AND       E.ADMIN_ARR_DT BETWEEN '", followup[1], "' AND '", followup[2], "'
		                        GROUP BY    A.", alf, "
							) Q
		ON					A.", alf, " = Q.", alf, "
		WHEN MATCHED THEN	UPDATE SET A.EDDS_ASTHMA = Q.EDDS_ASTHMA;
	"))
