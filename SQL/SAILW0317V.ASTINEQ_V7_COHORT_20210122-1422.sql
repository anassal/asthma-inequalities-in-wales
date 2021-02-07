 
CREATE OR REPLACE VARIABLE SAILW0317V.ASTINEQ_V7_COHORT_STUDY_STARTDATE DATE DEFAULT '2013-01-01';  -- NULL

CREATE OR REPLACE VARIABLE SAILW0317V.ASTINEQ_V7_COHORT_STUDY_ENDDATE DATE DEFAULT '2017-12-31';  -- NULL


ALTER TABLE SAILW0317V.ASTINEQ_V7_COHORT

	 ADD 	ASTHMA_GP_VISITS DECIMAL(12,6) DEFAULT 0

 ADD 	SABA DECIMAL(12,6) DEFAULT 0

 ADD 	ICS DECIMAL(12,6) DEFAULT 0

 ADD 	ASTHMA_REVIEW DECIMAL(12,6) DEFAULT 0

 ADD 	ICS_LABA SMALLINT DEFAULT 0

 ADD 	THEO SMALLINT DEFAULT 0

 ADD 	OCS SMALLINT DEFAULT 0

 ADD 	LTRA SMALLINT DEFAULT 0

 ADD 	ASTHMA_LOS SMALLINT DEFAULT 0

 ADD 	PEDW_ASTHMA SMALLINT DEFAULT 0

 ADD 	PEDW_ASTHMA_EMERG SMALLINT DEFAULT 0

 ADD 	EDDS_ASTHMA SMALLINT DEFAULT 0

 ADD 	NACROM SMALLINT DEFAULT 0

 ADD 	NEDOCROMIL INTEGER DEFAULT 0;



		 -- ASTHMA_GP_VISITS

		 -- COUNT_OF_DISTINCT_DATES_OF_EVENTS: COUNT occuerences of distinct dates of specific events in SAIL-GP occurred during a specified date range

		 -- Final value: count(DISTINCT G.EVENT_DT)



		 MERGE INTO			SAILW0317V.ASTINEQ_V7_COHORT A

		 USING				(





		 SELECT 		A1.ALF_PE,

		 count(DISTINCT G.EVENT_DT) AS	ASTHMA_GP_VISITS

		 FROM		SAILW0317V.ASTINEQ_V7_COHORT  A1

		 	   	   JOIN	SAILW0317V.ASTINEQ_V7_COHORT_WLGP_SUBSET  G

		 	   	   ON		A1.ALF_PE = G.ALF_PE

		 	   	   AND		(

										LEFT(G.EVENT_CD, 3) IN ('178')

										OR

										LEFT(G.EVENT_CD, 4) IN ('388t')

										OR

										G.EVENT_CD IN ('173A.', '173c.', '173d.', '1780.', '1781.', '1782.', '1783.', '1784.', '1785.', '1786.', '1787.', '1788.', '1789.', '178A.', '178B.', '1O2..', '388t.', '38DL.', '38DV.', '38QM.', '661M1', '661N1', '663N.', '663N0', '663N1', '663N2', '663O.', '663O0', '663P.', '663P0', '663P1', '663P2', '663Q.', '663U.', '663V.', '663V0', '663V1', '663V2', '663V3', '663W.', '663d.', '663e.', '663e0', '663e1', '663f.', '663h.', '663j.', '663m.', '663n.', '663p.', '663q.', '663r.', '663s.', '663t.', '663u.', '663v.', '663w.', '663x.', '663y.', '66Y5.', '66Y9.', '66YA.', '66YC.', '66YE.', '66YJ.', '66YK.', '66YP.', '66YQ.', '66YR.', '66YZ.', '66Yp.', '66Yq.', '66Yr.', '66Ys.', '66Yu.', '679J.', '679J0', '679J1', '679J2', '8791.', '8793.', '8794.', '8795.', '8796.', '8797.', '8798.', '8B3j.', '8CMA0', '8CR0.', '8H2P.', '8HTT.', '9N1d.', '9N1d0', '9NI8.', '9NNX.', '9OJ..', '9OJ1.', '9OJ2.', '9OJ3.', '9OJ4.', '9OJ5.', '9OJ6.', '9OJ7.', '9OJ8.', '9OJ9.', '9OJA.', '9OJB.', '9OJC.', '9OJZ.', '9Q21.', '9hA..', '9hA1.', 'SLF7.', 'SLF7z')

									)

						AND 		(G.EVENT_DT >= SAILW0317V.ASTINEQ_V7_COHORT_STUDY_STARTDATE AND G.EVENT_DT < SAILW0317V.ASTINEQ_V7_COHORT_STUDY_ENDDATE)

						GROUP BY A1.ALF_PE, ASTHMA_GP_VISITS





		 ) B



		 ON					A.ALF_PE = B.ALF_PE



		 WHEN MATCHED THEN	UPDATE SET A.ASTHMA_GP_VISITS = B.ASTHMA_GP_VISITS;







		 -- SABA

		 -- COUNT_OF_EVENTS: COUNT occuerences of events specified with Read codes in SAIL-GP during a specified date range

		 -- Final value: count(G.EVENT_CD)



		 MERGE INTO			SAILW0317V.ASTINEQ_V7_COHORT A

		 USING				(





		 SELECT 		A1.ALF_PE,

		 count(G.EVENT_CD) AS	SABA

		 FROM		SAILW0317V.ASTINEQ_V7_COHORT  A1

		 	   	   JOIN	SAILW0317V.ASTINEQ_V7_COHORT_WLGP_SUBSET  G

		 	   	   ON		A1.ALF_PE = G.ALF_PE

		 	   	   AND		(

										LEFT(G.EVENT_CD, 3) IN ('c11', 'c12', 'c13', 'c14', 'c15', 'c1E')

									)

						AND 		(G.EVENT_DT >= SAILW0317V.ASTINEQ_V7_COHORT_STUDY_STARTDATE AND G.EVENT_DT < SAILW0317V.ASTINEQ_V7_COHORT_STUDY_ENDDATE)

						GROUP BY A1.ALF_PE, SABA





		 ) B



		 ON					A.ALF_PE = B.ALF_PE



		 WHEN MATCHED THEN	UPDATE SET A.SABA = B.SABA;







		 -- ICS

		 -- COUNT_OF_EVENTS: COUNT occuerences of events specified with Read codes in SAIL-GP during a specified date range

		 -- Final value: count(G.EVENT_CD)



		 MERGE INTO			SAILW0317V.ASTINEQ_V7_COHORT A

		 USING				(





		 SELECT 		A1.ALF_PE,

		 count(G.EVENT_CD) AS	ICS

		 FROM		SAILW0317V.ASTINEQ_V7_COHORT  A1

		 	   	   JOIN	SAILW0317V.ASTINEQ_V7_COHORT_WLGP_SUBSET  G

		 	   	   ON		A1.ALF_PE = G.ALF_PE

		 	   	   AND		(

										G.EVENT_CD IN ('c6...', 'c61..', 'c611.', 'c612.', 'c613.', 'c614.', 'c615.', 'c616.', 'c617.', 'c618.', 'c619.', 'c61A.', 'c61B.', 'c61C.', 'c61E.', 'c61F.', 'c61G.', 'c61H.', 'c61J.', 'c61K.', 'c61L.', 'c61M.', 'c61N.', 'c61O.', 'c61P.', 'c61Q.', 'c61R.', 'c61S.', 'c61T.', 'c61U.', 'c61V.', 'c61W.', 'c61X.', 'c61Y.', 'c61Z.', 'c61a.', 'c61b.', 'c61c.', 'c61d.', 'c61e.', 'c61f.', 'c61g.', 'c61h.', 'c61i.', 'c61j.', 'c61k.', 'c61l.', 'c61m.', 'c61n.', 'c61p.', 'c61q.', 'c61r.', 'c61s.', 'c61u.', 'c61v.', 'c61w.', 'c61x.', 'c61y.', 'c61z.', 'c62..', 'c621.', 'c622.', 'c623.', 'c624.', 'c63..', 'c631.', 'c63z.', 'c64..', 'c641.', 'c642.', 'c643.', 'c644.', 'c645.', 'c646.', 'c647.', 'c649.', 'c64A.', 'c64B.', 'c64C.', 'c64D.', 'c64E.', 'c64F.', 'c64G.', 'c64H.', 'c64I.', 'c64J.', 'c64K.', 'c64a.', 'c64b.', 'c64c.', 'c64d.', 'c64e.', 'c64g.', 'c64h.', 'c64i.', 'c64j.', 'c64k.', 'c64l.', 'c64m.', 'c64n.', 'c64o.', 'c64p.', 'c64u.', 'c64v.', 'c64x.', 'c64y.', 'c64z.', 'c65..', 'c651.', 'c652.', 'c653.', 'c654.', 'c655.', 'c656.', 'c657.', 'c658.', 'c659.', 'c65A.', 'c65B.', 'c65C.', 'c65D.', 'c65E.', 'c65F.', 'c65G.', 'c65H.', 'c65I.', 'c65K.', 'c65L.', 'c65M.', 'c65N.', 'c65O.', 'c65P.', 'c65Q.', 'c65R.', 'c65S.', 'c65T.', 'c65U.', 'c65V.', 'c65W.', 'c65X.', 'c65Y.', 'c65Z.', 'c65a.', 'c65b.', 'c65c.', 'c65d.', 'c65e.', 'c65f.', 'c65g.', 'c66..', 'c661.', 'c662.', 'c663.', 'c664.', 'c665.', 'c666.', 'c667.', 'c668.', 'c669.', 'c66A.', 'c66B.', 'c66C.', 'c66D.', 'c66E.', 'c66F.', 'c66G.', 'c66H.', 'c66I.', 'c66J.', 'c66K.', 'c66L.', 'c66M.', 'c66N.', 'c66P.', 'c66Q.', 'c66R.', 'c66S.', 'c66T.', 'c66U.', 'c66V.', 'c66W.', 'c66X.', 'c66Y.', 'c66Z.', 'c66a.', 'c66c.', 'c66d.', 'c66e.', 'c66f.', 'c66g.', 'c66h.', 'c68..', 'c681.', 'c682.', 'c683.', 'c684.', 'c69..', 'c691.', 'c692.', 'c69y.', 'c69z.')

									)

						AND 		(G.EVENT_DT >= SAILW0317V.ASTINEQ_V7_COHORT_STUDY_STARTDATE AND G.EVENT_DT < SAILW0317V.ASTINEQ_V7_COHORT_STUDY_ENDDATE)

						GROUP BY A1.ALF_PE, ICS





		 ) B



		 ON					A.ALF_PE = B.ALF_PE



		 WHEN MATCHED THEN	UPDATE SET A.ICS = B.ICS;









		 -- ASTHMA_REVIEW

		 -- COUNT_OF_DISTINCT_DATES_OF_EVENTS: COUNT occuerences of distinct dates of specific events in SAIL-GP occurred during a specified date range

		 -- Final value: count(DISTINCT G.EVENT_DT)



		 MERGE INTO			SAILW0317V.ASTINEQ_V7_COHORT A

		 USING				(





		 SELECT 		A1.ALF_PE,

		 count(DISTINCT G.EVENT_DT) AS	ASTHMA_REVIEW

		 FROM		SAILW0317V.ASTINEQ_V7_COHORT  A1

		 	   	   JOIN	SAILW0317V.ASTINEQ_V7_COHORT_WLGP_SUBSET  G

		 	   	   ON		A1.ALF_PE = G.ALF_PE

		 	   	   AND		(

										G.EVENT_CD IN ('66YJ.', '66YK.', '66YQ.', '66Yp.', '8B3j.', '9OJA.')

									)

						AND 		(G.EVENT_DT >= SAILW0317V.ASTINEQ_V7_COHORT_STUDY_STARTDATE AND G.EVENT_DT < SAILW0317V.ASTINEQ_V7_COHORT_STUDY_ENDDATE)

						GROUP BY A1.ALF_PE, ASTHMA_REVIEW





		 ) B



		 ON					A.ALF_PE = B.ALF_PE



		 WHEN MATCHED THEN	UPDATE SET A.ASTHMA_REVIEW = B.ASTHMA_REVIEW;







		 -- ICS_LABA

		 -- COUNT_OF_EVENTS: COUNT occuerences of events specified with Read codes in SAIL-GP during a specified date range

		 -- Final value: count(G.EVENT_CD)



		 MERGE INTO			SAILW0317V.ASTINEQ_V7_COHORT A

		 USING				(





		 SELECT 		A1.ALF_PE,

		 count(G.EVENT_CD) AS	ICS_LABA

		 FROM		SAILW0317V.ASTINEQ_V7_COHORT  A1

		 	   	   JOIN	SAILW0317V.ASTINEQ_V7_COHORT_WLGP_SUBSET  G

		 	   	   ON		A1.ALF_PE = G.ALF_PE

		 	   	   AND		(

										G.EVENT_CD IN ('c1D..', 'c1D1.', 'c1D2.', 'c1D3.', 'c1D4.', 'c1D5.', 'c1D6.', 'c1D7.', 'c1D8.', 'c1Du.', 'c1Dv.', 'c1Dw.', 'c1Dx.', 'c1Dy.', 'c1Dz.', 'c1c..', 'c1c1.', 'c1c2.', 'c1c3.', 'c1cx.', 'c1cy.', 'c1cz.', 'c67..', 'c671.', 'c672.', 'c673.', 'c674.', 'c675.', 'c67x.', 'c67y.', 'c67z.', 'c6A..', 'c6A1.', 'c6A2.', 'c6Ay.', 'c6Az.', 'c6B..', 'c6B1.', 'c6B2.', 'c6B3.', 'c6B4.')

									)

						AND 		(G.EVENT_DT >= SAILW0317V.ASTINEQ_V7_COHORT_STUDY_STARTDATE AND G.EVENT_DT < SAILW0317V.ASTINEQ_V7_COHORT_STUDY_ENDDATE)

						GROUP BY A1.ALF_PE, ICS_LABA





		 ) B



		 ON					A.ALF_PE = B.ALF_PE



		 WHEN MATCHED THEN	UPDATE SET A.ICS_LABA = B.ICS_LABA;







		 -- THEO

		 -- COUNT_OF_EVENTS: COUNT occuerences of events specified with Read codes in SAIL-GP during a specified date range

		 -- Final value: count(G.EVENT_CD)



		 MERGE INTO			SAILW0317V.ASTINEQ_V7_COHORT A

		 USING				(





		 SELECT 		A1.ALF_PE,

		 count(G.EVENT_CD) AS	THEO

		 FROM		SAILW0317V.ASTINEQ_V7_COHORT  A1

		 	   	   JOIN	SAILW0317V.ASTINEQ_V7_COHORT_WLGP_SUBSET  G

		 	   	   ON		A1.ALF_PE = G.ALF_PE

		 	   	   AND		(

										G.EVENT_CD IN ('c41..', 'c411.', 'c412.', 'c413.', 'c414.', 'c415.', 'c416.', 'c417.', 'c418.', 'c419.', 'c41A.', 'c41B.', 'c41C.', 'c41a.', 'c41b.', 'c41c.', 'c41d.', 'c41e.', 'c41f.', 'c41g.', 'c41h.', 'c41i.', 'c41j.', 'c41k.', 'c41m.', 'c43..', 'c431.', 'c432.', 'c433.', 'c434.', 'c435.', 'c436.', 'c437.', 'c438.', 'c439.', 'c43A.', 'c43B.', 'c43a.', 'c43b.', 'c43c.', 'c43d.', 'c43e.', 'c43f.', 'c43g.', 'c43h.', 'c43i.', 'c43j.', 'c43k.', 'c43m.', 'c43n.', 'c43o.', 'c43p.', 'c43q.', 'c43r.', 'c43s.', 'c43t.', 'c43u.', 'c43v.', 'c43w.', 'c43x.', 'c43y.', 'c43z.')

									)

						AND 		(G.EVENT_DT >= SAILW0317V.ASTINEQ_V7_COHORT_STUDY_STARTDATE AND G.EVENT_DT < SAILW0317V.ASTINEQ_V7_COHORT_STUDY_ENDDATE)

						GROUP BY A1.ALF_PE, THEO





		 ) B



		 ON					A.ALF_PE = B.ALF_PE



		 WHEN MATCHED THEN	UPDATE SET A.THEO = B.THEO;







		 -- OCS

		 -- COUNT_OF_EVENTS: COUNT occuerences of events specified with Read codes in SAIL-GP during a specified date range

		 -- Final value: count(G.EVENT_CD)



		 MERGE INTO			SAILW0317V.ASTINEQ_V7_COHORT A

		 USING				(





		 SELECT 		A1.ALF_PE,

		 count(G.EVENT_CD) AS	OCS

		 FROM		SAILW0317V.ASTINEQ_V7_COHORT  A1

		 	   	   JOIN	SAILW0317V.ASTINEQ_V7_COHORT_WLGP_SUBSET  G

		 	   	   ON		A1.ALF_PE = G.ALF_PE

		 	   	   AND		(

										LEFT(G.EVENT_CD, 4) IN ('fe61', 'fe62', 'fe66', 'fe6i', 'fe6j', 'fe6k', 'fe6z')

									)

						AND 		(G.EVENT_DT >= SAILW0317V.ASTINEQ_V7_COHORT_STUDY_STARTDATE AND G.EVENT_DT < SAILW0317V.ASTINEQ_V7_COHORT_STUDY_ENDDATE)

						GROUP BY A1.ALF_PE, OCS





		 ) B



		 ON					A.ALF_PE = B.ALF_PE



		 WHEN MATCHED THEN	UPDATE SET A.OCS = B.OCS;







		 -- LTRA

		 -- COUNT_OF_EVENTS: COUNT occuerences of events specified with Read codes in SAIL-GP during a specified date range

		 -- Final value: count(G.EVENT_CD)



		 MERGE INTO			SAILW0317V.ASTINEQ_V7_COHORT A

		 USING				(





		 SELECT 		A1.ALF_PE,

		 count(G.EVENT_CD) AS	LTRA

		 FROM		SAILW0317V.ASTINEQ_V7_COHORT  A1

		 	   	   JOIN	SAILW0317V.ASTINEQ_V7_COHORT_WLGP_SUBSET  G

		 	   	   ON		A1.ALF_PE = G.ALF_PE

		 	   	   AND		(

										G.EVENT_CD IN ('cA...', 'cA1..', 'cA11.', 'cA12.', 'cA13.', 'cA14.', 'cA15.', 'cA16.', 'cA1y.', 'cA1z.', 'cA2..', 'cA21.', 'cA22.')

									)

						AND 		(G.EVENT_DT >= SAILW0317V.ASTINEQ_V7_COHORT_STUDY_STARTDATE AND G.EVENT_DT < SAILW0317V.ASTINEQ_V7_COHORT_STUDY_ENDDATE)

						GROUP BY A1.ALF_PE, LTRA





		 ) B



		 ON					A.ALF_PE = B.ALF_PE



		 WHEN MATCHED THEN	UPDATE SET A.LTRA = B.LTRA;







		 -- ASTHMA_LOS

		 -- COMPUTED_FROM_OTHER_VARIABLES: no date range is required

		 -- Final value: COMPUTED_FROM_OTHER_VARIABLES



		 MERGE INTO			SAILW0317V.ASTINEQ_V7_COHORT A

		 USING				(





		 SELECT 		ALF_PE,

		 NULL AS	ASTHMA_LOS

		 FROM		SAILW0317V.ASTINEQ_V7_COHORT





		 ) B



		 ON					A.ALF_PE = B.ALF_PE



		 WHEN MATCHED THEN	UPDATE SET A.ASTHMA_LOS = B.ASTHMA_LOS;







		 -- PEDW_ASTHMA

		 -- COMPUTED_FROM_OTHER_VARIABLES: no date range is required

		 -- Final value: COMPUTED_FROM_OTHER_VARIABLES



		 MERGE INTO			SAILW0317V.ASTINEQ_V7_COHORT A

		 USING				(





		 SELECT 		ALF_PE,

		 NULL AS	PEDW_ASTHMA

		 FROM		SAILW0317V.ASTINEQ_V7_COHORT





		 ) B



		 ON					A.ALF_PE = B.ALF_PE



		 WHEN MATCHED THEN	UPDATE SET A.PEDW_ASTHMA = B.PEDW_ASTHMA;







		 -- PEDW_ASTHMA_EMERG

		 -- COMPUTED_FROM_OTHER_VARIABLES: no date range is required

		 -- Final value: COMPUTED_FROM_OTHER_VARIABLES



		 MERGE INTO			SAILW0317V.ASTINEQ_V7_COHORT A

		 USING				(





		 SELECT 		ALF_PE,

		 NULL AS	PEDW_ASTHMA_EMERG

		 FROM		SAILW0317V.ASTINEQ_V7_COHORT





		 ) B



		 ON					A.ALF_PE = B.ALF_PE



		 WHEN MATCHED THEN	UPDATE SET A.PEDW_ASTHMA_EMERG = B.PEDW_ASTHMA_EMERG;








		 -- EDDS_ASTHMA

		 -- COMPUTED_FROM_OTHER_VARIABLES: no date range is required

		 -- Final value: COMPUTED_FROM_OTHER_VARIABLES



		 MERGE INTO			SAILW0317V.ASTINEQ_V7_COHORT A

		 USING				(





		 SELECT 		ALF_PE,

		 NULL AS	EDDS_ASTHMA

		 FROM		SAILW0317V.ASTINEQ_V7_COHORT





		 ) B



		 ON					A.ALF_PE = B.ALF_PE



		 WHEN MATCHED THEN	UPDATE SET A.EDDS_ASTHMA = B.EDDS_ASTHMA;







		 -- NACROM

		 -- SODIUM CROMOGLICATE

		 -- COUNT_OF_EVENTS: COUNT occuerences of events specified with Read codes in SAIL-GP during a specified date range

		 -- Final value: count(G.EVENT_CD)



		 MERGE INTO			SAILW0317V.ASTINEQ_V7_COHORT A

		 USING				(





		 SELECT 		A1.ALF_PE,

		 count(G.EVENT_CD) AS	NACROM

		 FROM		SAILW0317V.ASTINEQ_V7_COHORT  A1

		 	   	   JOIN	SAILW0317V.ASTINEQ_V7_COHORT_WLGP_SUBSET  G

		 	   	   ON		A1.ALF_PE = G.ALF_PE

		 	   	   AND		(

										LEFT(G.EVENT_CD, 4) IN ('c711', 'c712', 'c713', 'c714', 'c715', 'c716', 'c717', 'c718', 'c719', 'c71a', 'c71b', 'c71c', 'c71d', 'c71e', 'c71f', 'c71g', 'c71h', 'c71i', 'c71j', 'c71k', 'c721', 'c722', 'c723', 'c72y', 'c72z')

										OR

										G.EVENT_CD IN ('c71..', 'c72..')

									)

						AND 		(G.EVENT_DT >= SAILW0317V.ASTINEQ_V7_COHORT_STUDY_STARTDATE AND G.EVENT_DT < SAILW0317V.ASTINEQ_V7_COHORT_STUDY_ENDDATE)

						GROUP BY A1.ALF_PE, NACROM





		 ) B



		 ON					A.ALF_PE = B.ALF_PE



		 WHEN MATCHED THEN	UPDATE SET A.NACROM = B.NACROM;







		 -- NEDOCROMIL

		 -- COUNT_OF_EVENTS: COUNT occuerences of events specified with Read codes in SAIL-GP during a specified date range

		 -- Final value: count(G.EVENT_CD)



		 MERGE INTO			SAILW0317V.ASTINEQ_V7_COHORT A

		 USING				(





		 SELECT 		A1.ALF_PE,

		 count(G.EVENT_CD) AS	NEDOCROMIL

		 FROM		SAILW0317V.ASTINEQ_V7_COHORT  A1

		 	   	   JOIN	SAILW0317V.ASTINEQ_V7_COHORT_WLGP_SUBSET  G

		 	   	   ON		A1.ALF_PE = G.ALF_PE

		 	   	   AND		(

										LEFT(G.EVENT_CD, 4) IN ('c741', 'c742', 'c743', 'c744', 'c745', 'c746', 'c747')

										OR

										G.EVENT_CD IN ('c74..')

									)

						AND 		(G.EVENT_DT >= SAILW0317V.ASTINEQ_V7_COHORT_STUDY_STARTDATE AND G.EVENT_DT < SAILW0317V.ASTINEQ_V7_COHORT_STUDY_ENDDATE)

						GROUP BY A1.ALF_PE, NEDOCROMIL





		 ) B



		 ON					A.ALF_PE = B.ALF_PE



		 WHEN MATCHED THEN	UPDATE SET A.NEDOCROMIL = B.NEDOCROMIL;





