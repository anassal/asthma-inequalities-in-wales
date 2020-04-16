
CREATE OR REPLACE VARIABLE SAILW0317V.ASTINEQ_V5_COHORT_SELECTION_DEC2019_STUDY_STARTDATE DATE DEFAULT '2009-01-01';  -- NULL
CREATE OR REPLACE VARIABLE SAILW0317V.ASTINEQ_V5_COHORT_SELECTION_DEC2019_STUDY_ENDDATE DATE DEFAULT '2009-12-31';  -- NULL
CREATE OR REPLACE VARIABLE SAILW0317V.ASTINEQ_V5_COHORT_SELECTION_DEC2019_EVER DATE DEFAULT '1930-01-01';  -- NULL
CREATE OR REPLACE VARIABLE SAILW0317V.ASTINEQ_V5_COHORT_SELECTION_DEC2019_FOLLOWUP_START_DATE DATE DEFAULT '2010-01-01';  -- NULL

 call fnc.drop_if_exists('SAILW0317V.ASTINEQ_V5_COHORT_SELECTION_DEC2019');
CREATE TABLE SAILW0317V.ASTINEQ_V5_COHORT_SELECTION_DEC2019 (
	ALF_PE BIGINT,
	GNDR_CD DECIMAL(1,0) DEFAULT NULL,
	WOB DATE,
	DOD DATE,
	ASTHMA_DX_LATEST DATE DEFAULT NULL,
	ASTHMA_RESOLVED_DATE DATE DEFAULT NULL,
	ASTHMA_DX_CURRENT VARCHAR(20) DEFAULT 2,
	ASTHMA_RX_12M_1 SMALLINT DEFAULT 0,
	ASTHMA_RX_12M_2 SMALLINT DEFAULT 0,
	ASTHMA_RX_12M_3 SMALLINT DEFAULT 0,
	ASTHMA_RX_12M_4 SMALLINT DEFAULT 0,
	ASTHMA_RX_12M_5 SMALLINT DEFAULT 0
) ORGANIZE BY ROW;


	   -- Populate with ID columns

	   INSERT INTO    SAILW0317V.ASTINEQ_V5_COHORT_SELECTION_DEC2019(ALF_PE)
	   (
	   SELECT            DISTINCT A.ALF_PE
	   FROM              (SELECT DISTINCT ALF_PE FROM SAIL0317V.WLGP_CLEAN_GP_REG_MEDIAN_20180820) A
	   WHERE             A.ALF_PE IS NOT NULL
	   ORDER BY          A.ALF_PE ASC
	   );
	   


	-- Populate with GNDR_CD, WOB, DOD

	MERGE INTO    SAILW0317V.ASTINEQ_V5_COHORT_SELECTION_DEC2019 a
	USING   (
	SELECT            ALF_PE,
	GNDR_CD,
	WOB,
	DOD
	FROM              (SELECT P.ALF_PE, MAX(P.GNDR_CD) AS GNDR_CD, MAX(P.WOB) AS WOB, MAX(P.DOD) AS DOD FROM SAIL0317V.WDSD_AR_PERS_20181101 P JOIN SAILW0317V.ASTINEQ_V5_COHORT_SELECTION_DEC2019 A ON P.ALF_PE = A.ALF_PE GROUP BY P.ALF_PE)
	WHERE             ALF_PE IS NOT NULL
	) b
	ON a.ALF_PE = b.ALF_PE
	WHEN MATCHED THEN UPDATE SET a.GNDR_CD = b.GNDR_CD, a.WOB = b.WOB, a.DOD = b.DOD;
	



		 -- ASTHMA_DX_LATEST
		 -- FALSE
		 -- MOST_RECENT_EVENT__DATE: FIND the most recent occuerence of specified events in SAIL-GP WHERE it occurred during a specified date range THEN get the event_dt (event date)
		 -- Final value: G.EVENT_DT

		 MERGE INTO			SAILW0317V.ASTINEQ_V5_COHORT_SELECTION_DEC2019 A
		 USING				(
		 SELECT * FROM (


		 SELECT 		A1.ALF_PE,
		 G.EVENT_DT AS	ASTHMA_DX_LATEST,
		 	   	    ROW_NUMBER() OVER(PARTITION BY A1.ALF_PE ORDER BY G.EVENT_DT DESC) AS ROW_NUM
		 FROM		SAILW0317V.ASTINEQ_V5_COHORT_SELECTION_DEC2019  A1
		 	   	   JOIN	SAIL0317V.WLGP_GP_EVENT_ALF_CLEANSED_20180820  G
		 	   	   ON		A1.ALF_PE = G.ALF_PE
		 	   	   AND		(
										G.EVENT_CD IN ('173A.', 'H3120', 'H33..', 'H330.', 'H3300', 'H3301', 'H330z', 'H331.', 'H3310', 'H3311', 'H331z', 'H332.', 'H334.', 'H335.', 'H33z.', 'H33z0', 'H33z1', 'H33z2', 'H33zz')
									)
						AND 		(G.EVENT_DT >= SAILW0317V.ASTINEQ_V5_COHORT_SELECTION_DEC2019_EVER AND G.EVENT_DT < SAILW0317V.ASTINEQ_V5_COHORT_SELECTION_DEC2019_STUDY_ENDDATE)

		 ) WHERE		ROW_NUM = 1

		 ) B

		 ON					A.ALF_PE = B.ALF_PE

		 WHEN MATCHED THEN	UPDATE SET A.ASTHMA_DX_LATEST = B.ASTHMA_DX_LATEST;



		 -- ASTHMA_RESOLVED_DATE
		 -- FALSE
		 -- MOST_RECENT_EVENT__DATE: FIND the most recent occuerence of specified events in SAIL-GP WHERE it occurred during a specified date range THEN get the event_dt (event date)
		 -- Final value: G.EVENT_DT

		 MERGE INTO			SAILW0317V.ASTINEQ_V5_COHORT_SELECTION_DEC2019 A
		 USING				(
		 SELECT * FROM (


		 SELECT 		A1.ALF_PE,
		 G.EVENT_DT AS	ASTHMA_RESOLVED_DATE,
		 	   	    ROW_NUMBER() OVER(PARTITION BY A1.ALF_PE ORDER BY G.EVENT_DT DESC) AS ROW_NUM
		 FROM		SAILW0317V.ASTINEQ_V5_COHORT_SELECTION_DEC2019  A1
		 	   	   JOIN	SAIL0317V.WLGP_GP_EVENT_ALF_CLEANSED_20180820  G
		 	   	   ON		A1.ALF_PE = G.ALF_PE
		 	   	   AND		(
										G.EVENT_CD IN ('21262', '212G.')
									)
						AND 		(G.EVENT_DT >= SAILW0317V.ASTINEQ_V5_COHORT_SELECTION_DEC2019_EVER AND G.EVENT_DT < SAILW0317V.ASTINEQ_V5_COHORT_SELECTION_DEC2019_STUDY_ENDDATE)

		 ) WHERE		ROW_NUM = 1

		 ) B

		 ON					A.ALF_PE = B.ALF_PE

		 WHEN MATCHED THEN	UPDATE SET A.ASTHMA_RESOLVED_DATE = B.ASTHMA_RESOLVED_DATE;



		 -- ASTHMA_DX_CURRENT
		 -- check those with default value (should change to either 0 or 1)
		 -- COMPUTED_FROM_OTHER_VARIABLES: no date range is required
		 -- Final value: COMPUTED_FROM_OTHER_VARIABLES -- SQL CASE USED

		 MERGE INTO			SAILW0317V.ASTINEQ_V5_COHORT_SELECTION_DEC2019 A
		 USING				(
		 

		 SELECT 		ALF_PE,
		 CASE
										WHEN ASTHMA_DX_LATEST IS NULL OR (ASTHMA_RESOLVED_DATE IS NOT NULL AND ASTHMA_RESOLVED_DATE >= ASTHMA_DX_LATEST) THEN 0
										WHEN ASTHMA_DX_LATEST IS NOT NULL AND ( ASTHMA_RESOLVED_DATE IS NULL OR (ASTHMA_RESOLVED_DATE IS NOT NULL AND ASTHMA_RESOLVED_DATE < ASTHMA_DX_LATEST) ) THEN 1
										ELSE 2
									END AS	ASTHMA_DX_CURRENT
		 FROM		SAILW0317V.ASTINEQ_V5_COHORT_SELECTION_DEC2019

		 
		 ) B

		 ON					A.ALF_PE = B.ALF_PE

		 WHEN MATCHED THEN	UPDATE SET A.ASTHMA_DX_CURRENT = B.ASTHMA_DX_CURRENT;



		 -- ASTHMA_RX_12M_1
		 -- Asthma prescriptions in the last 12 months - year 1
		 -- COUNT_OF_EVENTS: COUNT occuerences of events specified with Read codes in SAIL-GP during a specified date range
		 -- Final value: count(G.EVENT_CD)

		 MERGE INTO			SAILW0317V.ASTINEQ_V5_COHORT_SELECTION_DEC2019 A
		 USING				(
		 

		 SELECT 		A1.ALF_PE,
		 count(G.EVENT_CD) AS	ASTHMA_RX_12M_1
		 FROM		SAILW0317V.ASTINEQ_V5_COHORT_SELECTION_DEC2019  A1
		 	   	   JOIN	SAIL0317V.WLGP_GP_EVENT_ALF_CLEANSED_20180820  G
		 	   	   ON		A1.ALF_PE = G.ALF_PE
		 	   	   AND		(
										G.EVENT_CD IN ('c111.', 'c112.', 'c113.', 'c114.', 'c115.', 'c116.', 'c117.', 'c118.', 'c119.', 'c11a.', 'c11A.', 'c11B.', 'c11b.', 'c11C.', 'c11c.', 'c11d.', 'c11D.', 'c11e.', 'c11f.', 'c11g.', 'c11h.', 'c11i.', 'c11j.', 'c11k.', 'c11m.', 'c11n.', 'c11o.', 'c11p.', 'c11q.', 'c11v.', 'c11w.', 'c11x.', 'c11y.', 'c11z.', 'c121.', 'c122.', 'c123.', 'c124.', 'c125.', 'c126.', 'c12w.', 'c12x.', 'c12y.', 'c12z.', 'c131.', 'c132.', 'c133.', 'c134.', 'c135.', 'c136.', 'c137.', 'c138.', 'c139.', 'c13a.', 'c13A.', 'c13b.', 'c13B.', 'c13c.', 'c13C.', 'c13D.', 'c13d.', 'c13E.', 'c13e.', 'c13F.', 'c13f.', 'c13G.', 'c13g.', 'c13H.', 'c13h.', 'c13I.', 'c13i.', 'c13J.', 'c13j.', 'c13k.', 'c13K.', 'c13l.', 'c13L.', 'c13M.', 'c13m.', 'c13n.', 'c13N.', 'c13o.', 'c13O.', 'c13p.', 'c13P.', 'c13q.', 'c13Q.', 'c13r.', 'c13R.', 'c13s.', 'c13S.', 'c13T.', 'c13U.', 'c13V.', 'c13v.', 'c13W.', 'c13w.', 'c13X.', 'c13x.', 'c13Y.', 'c13y.', 'c13Z.', 'c13z.', 'c141.', 'c142.', 'c143.', 'c144.', 'c145.', 'c146.', 'c147.', 'c148.', 'c149.', 'c14a.', 'c14b.', 'c14c.', 'c14d.', 'c14e.', 'c14f.', 'c14g.', 'c14h.', 'c14i.', 'c14j.', 'c14k.', 'c14r.', 'c14s.', 'c14t.', 'c14u.', 'c14v.', 'c14w.', 'c14x.', 'c14y.', 'c14z.', 'c151.', 'c152.', 'c153.', 'c154.', 'c15y.', 'c15z.', 'c191.', 'c192.', 'c193.', 'c194.', 'c195.', 'c196.', 'c197.', 'c198.', 'c199.', 'c19A.', 'c19B.', 'c19z.', 'c1B1.', 'c1B2.', 'c1B3.', 'c1B4.', 'c1c1.', 'c1C1.', 'c1c2.', 'c1C2.', 'c1c3.', 'c1C3.', 'c1C4.', 'c1C5.', 'c1C6.', 'c1C7.', 'c1C8.', 'c1cx.', 'c1cy.', 'c1Cy.', 'c1cz.', 'c1Cz.', 'c1D1.', 'c1D2.', 'c1D3.', 'c1D4.', 'c1D5.', 'c1D6.', 'c1D7.', 'c1D8.', 'c1Du.', 'c1Dv.', 'c1Dw.', 'c1Dx.', 'c1Dy.', 'c1Dz.', 'c1E1.', 'c1E2.', 'c1E3.', 'c1E4.', 'c1E5.', 'c1E6.', 'c1E7.', 'c1E8.', 'c1E9.', 'c1EA.', 'c1EB.', 'c1EC.', 'c1ED.', 'c1EE.', 'c211.', 'c212.', 'c213.', 'c214.', 'c215.', 'c216.', 'c221.', 'c222.', 'c223.', 'c224.', 'c225.', 'c226.', 'c227.', 'c251.', 'c252.', 'c253.', 'c254.', 'c255.', 'c25v.', 'c25w.', 'c25x.', 'c25y.', 'c25z.', 'c311.', 'c312.', 'c313.', 'c314.', 'c315.', 'c316.', 'c317.', 'c318.', 'c319.', 'c31A.', 'c31B.', 'c31C.', 'c31D.', 'c31E.', 'c31F.', 'c31G.', 'c31t.', 'c31u.', 'c31v.', 'c31w.', 'c31x.', 'c31y.', 'c31z.', 'c331.', 'c332.', 'c333.', 'c33x.', 'c33y.', 'c33z.', 'c341.', 'c342.', 'c351.', 'c352.', 'c411.', 'c412.', 'c413.', 'c414.', 'c415.', 'c416.', 'c417.', 'c418.', 'c419.', 'c41A.', 'c41a.', 'c41B.', 'c41b.', 'c41C.', 'c41c.', 'c41d.', 'c41e.', 'c41f.', 'c41g.', 'c41h.', 'c41i.', 'c41j.', 'c41k.', 'c41m.', 'c431.', 'c432.', 'c433.', 'c434.', 'c435.', 'c436.', 'c437.', 'c438.', 'c439.', 'c43a.', 'c43A.', 'c43b.', 'c43B.', 'c43c.', 'c43d.', 'c43e.', 'c43f.', 'c43g.', 'c43h.', 'c43i.', 'c43j.', 'c43k.', 'c43m.', 'c43n.', 'c43o.', 'c43p.', 'c43q.', 'c43r.', 'c43s.', 'c43t.', 'c43u.', 'c43v.', 'c43w.', 'c43x.', 'c43y.', 'c43z.', 'c511.', 'c512.', 'c513.', 'c514.', 'c515.', 'c516.', 'c517.', 'c518.', 'c519.', 'c51a.', 'c51A.', 'c51b.', 'c51B.', 'c51c.', 'c51C.', 'c51D.', 'c51d.', 'c51e.', 'c51E.', 'c51f.', 'c51F.', 'c51g.', 'c51G.', 'c51h.', 'c51H.', 'c51i.', 'c51I.', 'c51j.', 'c51J.', 'c51K.', 'c51k.', 'c51l.', 'c51L.', 'c51m.', 'c51n.', 'c51o.', 'c51p.', 'c51q.', 'c51r.', 'c51s.', 'c51t.', 'c51u.', 'c51v.', 'c51w.', 'c51x.', 'c51y.', 'c531.', 'c611.', 'c612.', 'c613.', 'c614.', 'c615.', 'c616.', 'c617.', 'c618.', 'c619.', 'c61A.', 'c61a.', 'c61B.', 'c61b.', 'c61C.', 'c61c.', 'c61D.', 'c61d.', 'c61E.', 'c61e.', 'c61F.', 'c61f.', 'c61G.', 'c61g.', 'c61H.', 'c61h.', 'c61i.', 'c61j.', 'c61J.', 'c61k.', 'c61K.', 'c61l.', 'c61L.', 'c61M.', 'c61m.', 'c61N.', 'c61n.', 'c61O.', 'c61P.', 'c61p.', 'c61Q.', 'c61q.', 'c61R.', 'c61r.', 'c61s.', 'c61S.', 'c61t.', 'c61T.', 'c61u.', 'c61U.', 'c61v.', 'c61V.', 'c61W.', 'c61w.', 'c61x.', 'c61X.', 'c61Y.', 'c61y.', 'c61z.', 'c61Z.', 'c621.', 'c622.', 'c623.', 'c624.', 'c631.', 'c63z.', 'c641.', 'c642.', 'c643.', 'c644.', 'c645.', 'c646.', 'c647.', 'c648.', 'c649.', 'c64A.', 'c64a.', 'c64B.', 'c64b.', 'c64c.', 'c64C.', 'c64d.', 'c64D.', 'c64e.', 'c64E.', 'c64F.', 'c64g.', 'c64G.', 'c64h.', 'c64H.', 'c64i.', 'c64I.', 'c64j.', 'c64J.', 'c64k.', 'c64K.', 'c64l.', 'c64L.', 'c64m.', 'c64M.', 'c64N.', 'c64n.', 'c64o.', 'c64p.', 'c64u.', 'c64v.', 'c64w.', 'c64x.', 'c64y.', 'c64z.', 'c651.', 'c652.', 'c653.', 'c654.', 'c655.', 'c656.', 'c657.', 'c658.', 'c659.', 'c65a.', 'c65A.', 'c65B.', 'c65b.', 'c65c.', 'c65C.', 'c65d.', 'c65D.', 'c65e.', 'c65E.', 'c65F.', 'c65f.', 'c65g.', 'c65G.', 'c65H.', 'c65I.', 'c65J.', 'c65K.', 'c65L.', 'c65M.', 'c65N.', 'c65O.', 'c65P.', 'c65Q.', 'c65R.', 'c65S.', 'c65T.', 'c65U.', 'c65V.', 'c65W.', 'c65X.', 'c65Y.', 'c65Z.', 'c661.', 'c662.', 'c663.', 'c664.', 'c665.', 'c666.', 'c667.', 'c668.', 'c669.', 'c66A.', 'c66a.', 'c66B.', 'c66b.', 'c66C.', 'c66c.', 'c66D.', 'c66d.', 'c66E.', 'c66e.', 'c66F.', 'c66f.', 'c66g.', 'c66G.', 'c66H.', 'c66h.', 'c66I.', 'c66J.', 'c66K.', 'c66L.', 'c66M.', 'c66N.', 'c66P.', 'c66Q.', 'c66R.', 'c66S.', 'c66T.', 'c66U.', 'c66V.', 'c66W.', 'c66X.', 'c66Y.', 'c66Z.', 'c671.', 'c672.', 'c673.', 'c674.', 'c675.', 'c67x.', 'c67y.', 'c67z.', 'c681.', 'c682.', 'c683.', 'c684.', 'c691.', 'c692.', 'c69y.', 'c69z.', 'c6A1.', 'c6A2.', 'c6Ay.', 'c6Az.', 'c6B1.', 'c6B2.', 'c6B3.', 'c6B4.', 'c711.', 'c712.', 'c713.', 'c714.', 'c715.', 'c716.', 'c717.', 'c718.', 'c719.', 'c71a.', 'c71b.', 'c71c.', 'c71d.', 'c71e.', 'c71f.', 'c71g.', 'c71h.', 'c71i.', 'c71j.', 'c71k.', 'c721.', 'c722.', 'c723.', 'c72y.', 'c72z.', 'c731.', 'c732.', 'c733.', 'c734.', 'c735.', 'c736.', 'c73x.', 'c73y.', 'c73z.', 'c741.', 'c742.', 'c743.', 'c744.', 'c745.', 'c746.', 'c747.', 'cA11.', 'cA12.', 'cA13.', 'cA14.', 'cA15.', 'cA16.', 'cA1y.', 'cA1z.', 'cA21.', 'cA22.', 'ck11.', 'ck12.', 'ck13.', 'ck14.', 'ck15.', 'ck16.')
									)
						AND 		(G.EVENT_DT >= SAILW0317V.ASTINEQ_V5_COHORT_SELECTION_DEC2019_FOLLOWUP_START_DATE AND G.EVENT_DT < SAILW0317V.ASTINEQ_V5_COHORT_SELECTION_DEC2019_FOLLOWUP_START_DATE + 1 YEAR - 1 DAY)
						GROUP BY A1.ALF_PE, ASTHMA_RX_12M_1

		 
		 ) B

		 ON					A.ALF_PE = B.ALF_PE

		 WHEN MATCHED THEN	UPDATE SET A.ASTHMA_RX_12M_1 = B.ASTHMA_RX_12M_1;



		 -- ASTHMA_RX_12M_2
		 -- Asthma prescriptions in the last 12 months - year 1
		 -- COUNT_OF_EVENTS: COUNT occuerences of events specified with Read codes in SAIL-GP during a specified date range
		 -- Final value: count(G.EVENT_CD)

		 MERGE INTO			SAILW0317V.ASTINEQ_V5_COHORT_SELECTION_DEC2019 A
		 USING				(
		 

		 SELECT 		A1.ALF_PE,
		 count(G.EVENT_CD) AS	ASTHMA_RX_12M_2
		 FROM		SAILW0317V.ASTINEQ_V5_COHORT_SELECTION_DEC2019  A1
		 	   	   JOIN	SAIL0317V.WLGP_GP_EVENT_ALF_CLEANSED_20180820  G
		 	   	   ON		A1.ALF_PE = G.ALF_PE
		 	   	   AND		(
										G.EVENT_CD IN ('c111.', 'c112.', 'c113.', 'c114.', 'c115.', 'c116.', 'c117.', 'c118.', 'c119.', 'c11a.', 'c11A.', 'c11B.', 'c11b.', 'c11C.', 'c11c.', 'c11d.', 'c11D.', 'c11e.', 'c11f.', 'c11g.', 'c11h.', 'c11i.', 'c11j.', 'c11k.', 'c11m.', 'c11n.', 'c11o.', 'c11p.', 'c11q.', 'c11v.', 'c11w.', 'c11x.', 'c11y.', 'c11z.', 'c121.', 'c122.', 'c123.', 'c124.', 'c125.', 'c126.', 'c12w.', 'c12x.', 'c12y.', 'c12z.', 'c131.', 'c132.', 'c133.', 'c134.', 'c135.', 'c136.', 'c137.', 'c138.', 'c139.', 'c13a.', 'c13A.', 'c13b.', 'c13B.', 'c13c.', 'c13C.', 'c13D.', 'c13d.', 'c13E.', 'c13e.', 'c13F.', 'c13f.', 'c13G.', 'c13g.', 'c13H.', 'c13h.', 'c13I.', 'c13i.', 'c13J.', 'c13j.', 'c13k.', 'c13K.', 'c13l.', 'c13L.', 'c13M.', 'c13m.', 'c13n.', 'c13N.', 'c13o.', 'c13O.', 'c13p.', 'c13P.', 'c13q.', 'c13Q.', 'c13r.', 'c13R.', 'c13s.', 'c13S.', 'c13T.', 'c13U.', 'c13V.', 'c13v.', 'c13W.', 'c13w.', 'c13X.', 'c13x.', 'c13Y.', 'c13y.', 'c13Z.', 'c13z.', 'c141.', 'c142.', 'c143.', 'c144.', 'c145.', 'c146.', 'c147.', 'c148.', 'c149.', 'c14a.', 'c14b.', 'c14c.', 'c14d.', 'c14e.', 'c14f.', 'c14g.', 'c14h.', 'c14i.', 'c14j.', 'c14k.', 'c14r.', 'c14s.', 'c14t.', 'c14u.', 'c14v.', 'c14w.', 'c14x.', 'c14y.', 'c14z.', 'c151.', 'c152.', 'c153.', 'c154.', 'c15y.', 'c15z.', 'c191.', 'c192.', 'c193.', 'c194.', 'c195.', 'c196.', 'c197.', 'c198.', 'c199.', 'c19A.', 'c19B.', 'c19z.', 'c1B1.', 'c1B2.', 'c1B3.', 'c1B4.', 'c1c1.', 'c1C1.', 'c1c2.', 'c1C2.', 'c1c3.', 'c1C3.', 'c1C4.', 'c1C5.', 'c1C6.', 'c1C7.', 'c1C8.', 'c1cx.', 'c1cy.', 'c1Cy.', 'c1cz.', 'c1Cz.', 'c1D1.', 'c1D2.', 'c1D3.', 'c1D4.', 'c1D5.', 'c1D6.', 'c1D7.', 'c1D8.', 'c1Du.', 'c1Dv.', 'c1Dw.', 'c1Dx.', 'c1Dy.', 'c1Dz.', 'c1E1.', 'c1E2.', 'c1E3.', 'c1E4.', 'c1E5.', 'c1E6.', 'c1E7.', 'c1E8.', 'c1E9.', 'c1EA.', 'c1EB.', 'c1EC.', 'c1ED.', 'c1EE.', 'c211.', 'c212.', 'c213.', 'c214.', 'c215.', 'c216.', 'c221.', 'c222.', 'c223.', 'c224.', 'c225.', 'c226.', 'c227.', 'c251.', 'c252.', 'c253.', 'c254.', 'c255.', 'c25v.', 'c25w.', 'c25x.', 'c25y.', 'c25z.', 'c311.', 'c312.', 'c313.', 'c314.', 'c315.', 'c316.', 'c317.', 'c318.', 'c319.', 'c31A.', 'c31B.', 'c31C.', 'c31D.', 'c31E.', 'c31F.', 'c31G.', 'c31t.', 'c31u.', 'c31v.', 'c31w.', 'c31x.', 'c31y.', 'c31z.', 'c331.', 'c332.', 'c333.', 'c33x.', 'c33y.', 'c33z.', 'c341.', 'c342.', 'c351.', 'c352.', 'c411.', 'c412.', 'c413.', 'c414.', 'c415.', 'c416.', 'c417.', 'c418.', 'c419.', 'c41A.', 'c41a.', 'c41B.', 'c41b.', 'c41C.', 'c41c.', 'c41d.', 'c41e.', 'c41f.', 'c41g.', 'c41h.', 'c41i.', 'c41j.', 'c41k.', 'c41m.', 'c431.', 'c432.', 'c433.', 'c434.', 'c435.', 'c436.', 'c437.', 'c438.', 'c439.', 'c43a.', 'c43A.', 'c43b.', 'c43B.', 'c43c.', 'c43d.', 'c43e.', 'c43f.', 'c43g.', 'c43h.', 'c43i.', 'c43j.', 'c43k.', 'c43m.', 'c43n.', 'c43o.', 'c43p.', 'c43q.', 'c43r.', 'c43s.', 'c43t.', 'c43u.', 'c43v.', 'c43w.', 'c43x.', 'c43y.', 'c43z.', 'c511.', 'c512.', 'c513.', 'c514.', 'c515.', 'c516.', 'c517.', 'c518.', 'c519.', 'c51a.', 'c51A.', 'c51b.', 'c51B.', 'c51c.', 'c51C.', 'c51D.', 'c51d.', 'c51e.', 'c51E.', 'c51f.', 'c51F.', 'c51g.', 'c51G.', 'c51h.', 'c51H.', 'c51i.', 'c51I.', 'c51j.', 'c51J.', 'c51K.', 'c51k.', 'c51l.', 'c51L.', 'c51m.', 'c51n.', 'c51o.', 'c51p.', 'c51q.', 'c51r.', 'c51s.', 'c51t.', 'c51u.', 'c51v.', 'c51w.', 'c51x.', 'c51y.', 'c531.', 'c611.', 'c612.', 'c613.', 'c614.', 'c615.', 'c616.', 'c617.', 'c618.', 'c619.', 'c61A.', 'c61a.', 'c61B.', 'c61b.', 'c61C.', 'c61c.', 'c61D.', 'c61d.', 'c61E.', 'c61e.', 'c61F.', 'c61f.', 'c61G.', 'c61g.', 'c61H.', 'c61h.', 'c61i.', 'c61j.', 'c61J.', 'c61k.', 'c61K.', 'c61l.', 'c61L.', 'c61M.', 'c61m.', 'c61N.', 'c61n.', 'c61O.', 'c61P.', 'c61p.', 'c61Q.', 'c61q.', 'c61R.', 'c61r.', 'c61s.', 'c61S.', 'c61t.', 'c61T.', 'c61u.', 'c61U.', 'c61v.', 'c61V.', 'c61W.', 'c61w.', 'c61x.', 'c61X.', 'c61Y.', 'c61y.', 'c61z.', 'c61Z.', 'c621.', 'c622.', 'c623.', 'c624.', 'c631.', 'c63z.', 'c641.', 'c642.', 'c643.', 'c644.', 'c645.', 'c646.', 'c647.', 'c648.', 'c649.', 'c64A.', 'c64a.', 'c64B.', 'c64b.', 'c64c.', 'c64C.', 'c64d.', 'c64D.', 'c64e.', 'c64E.', 'c64F.', 'c64g.', 'c64G.', 'c64h.', 'c64H.', 'c64i.', 'c64I.', 'c64j.', 'c64J.', 'c64k.', 'c64K.', 'c64l.', 'c64L.', 'c64m.', 'c64M.', 'c64N.', 'c64n.', 'c64o.', 'c64p.', 'c64u.', 'c64v.', 'c64w.', 'c64x.', 'c64y.', 'c64z.', 'c651.', 'c652.', 'c653.', 'c654.', 'c655.', 'c656.', 'c657.', 'c658.', 'c659.', 'c65a.', 'c65A.', 'c65B.', 'c65b.', 'c65c.', 'c65C.', 'c65d.', 'c65D.', 'c65e.', 'c65E.', 'c65F.', 'c65f.', 'c65g.', 'c65G.', 'c65H.', 'c65I.', 'c65J.', 'c65K.', 'c65L.', 'c65M.', 'c65N.', 'c65O.', 'c65P.', 'c65Q.', 'c65R.', 'c65S.', 'c65T.', 'c65U.', 'c65V.', 'c65W.', 'c65X.', 'c65Y.', 'c65Z.', 'c661.', 'c662.', 'c663.', 'c664.', 'c665.', 'c666.', 'c667.', 'c668.', 'c669.', 'c66A.', 'c66a.', 'c66B.', 'c66b.', 'c66C.', 'c66c.', 'c66D.', 'c66d.', 'c66E.', 'c66e.', 'c66F.', 'c66f.', 'c66g.', 'c66G.', 'c66H.', 'c66h.', 'c66I.', 'c66J.', 'c66K.', 'c66L.', 'c66M.', 'c66N.', 'c66P.', 'c66Q.', 'c66R.', 'c66S.', 'c66T.', 'c66U.', 'c66V.', 'c66W.', 'c66X.', 'c66Y.', 'c66Z.', 'c671.', 'c672.', 'c673.', 'c674.', 'c675.', 'c67x.', 'c67y.', 'c67z.', 'c681.', 'c682.', 'c683.', 'c684.', 'c691.', 'c692.', 'c69y.', 'c69z.', 'c6A1.', 'c6A2.', 'c6Ay.', 'c6Az.', 'c6B1.', 'c6B2.', 'c6B3.', 'c6B4.', 'c711.', 'c712.', 'c713.', 'c714.', 'c715.', 'c716.', 'c717.', 'c718.', 'c719.', 'c71a.', 'c71b.', 'c71c.', 'c71d.', 'c71e.', 'c71f.', 'c71g.', 'c71h.', 'c71i.', 'c71j.', 'c71k.', 'c721.', 'c722.', 'c723.', 'c72y.', 'c72z.', 'c731.', 'c732.', 'c733.', 'c734.', 'c735.', 'c736.', 'c73x.', 'c73y.', 'c73z.', 'c741.', 'c742.', 'c743.', 'c744.', 'c745.', 'c746.', 'c747.', 'cA11.', 'cA12.', 'cA13.', 'cA14.', 'cA15.', 'cA16.', 'cA1y.', 'cA1z.', 'cA21.', 'cA22.', 'ck11.', 'ck12.', 'ck13.', 'ck14.', 'ck15.', 'ck16.')
									)
						AND 		(G.EVENT_DT >= SAILW0317V.ASTINEQ_V5_COHORT_SELECTION_DEC2019_FOLLOWUP_START_DATE + 1 YEAR AND G.EVENT_DT < SAILW0317V.ASTINEQ_V5_COHORT_SELECTION_DEC2019_FOLLOWUP_START_DATE + 2 YEAR - 1 DAY)
						GROUP BY A1.ALF_PE, ASTHMA_RX_12M_2

		 
		 ) B

		 ON					A.ALF_PE = B.ALF_PE

		 WHEN MATCHED THEN	UPDATE SET A.ASTHMA_RX_12M_2 = B.ASTHMA_RX_12M_2;



		 -- ASTHMA_RX_12M_3
		 -- Asthma prescriptions in the last 12 months - year 1
		 -- COUNT_OF_EVENTS: COUNT occuerences of events specified with Read codes in SAIL-GP during a specified date range
		 -- Final value: count(G.EVENT_CD)

		 MERGE INTO			SAILW0317V.ASTINEQ_V5_COHORT_SELECTION_DEC2019 A
		 USING				(
		 

		 SELECT 		A1.ALF_PE,
		 count(G.EVENT_CD) AS	ASTHMA_RX_12M_3
		 FROM		SAILW0317V.ASTINEQ_V5_COHORT_SELECTION_DEC2019  A1
		 	   	   JOIN	SAIL0317V.WLGP_GP_EVENT_ALF_CLEANSED_20180820  G
		 	   	   ON		A1.ALF_PE = G.ALF_PE
		 	   	   AND		(
										G.EVENT_CD IN ('c111.', 'c112.', 'c113.', 'c114.', 'c115.', 'c116.', 'c117.', 'c118.', 'c119.', 'c11a.', 'c11A.', 'c11B.', 'c11b.', 'c11C.', 'c11c.', 'c11d.', 'c11D.', 'c11e.', 'c11f.', 'c11g.', 'c11h.', 'c11i.', 'c11j.', 'c11k.', 'c11m.', 'c11n.', 'c11o.', 'c11p.', 'c11q.', 'c11v.', 'c11w.', 'c11x.', 'c11y.', 'c11z.', 'c121.', 'c122.', 'c123.', 'c124.', 'c125.', 'c126.', 'c12w.', 'c12x.', 'c12y.', 'c12z.', 'c131.', 'c132.', 'c133.', 'c134.', 'c135.', 'c136.', 'c137.', 'c138.', 'c139.', 'c13a.', 'c13A.', 'c13b.', 'c13B.', 'c13c.', 'c13C.', 'c13D.', 'c13d.', 'c13E.', 'c13e.', 'c13F.', 'c13f.', 'c13G.', 'c13g.', 'c13H.', 'c13h.', 'c13I.', 'c13i.', 'c13J.', 'c13j.', 'c13k.', 'c13K.', 'c13l.', 'c13L.', 'c13M.', 'c13m.', 'c13n.', 'c13N.', 'c13o.', 'c13O.', 'c13p.', 'c13P.', 'c13q.', 'c13Q.', 'c13r.', 'c13R.', 'c13s.', 'c13S.', 'c13T.', 'c13U.', 'c13V.', 'c13v.', 'c13W.', 'c13w.', 'c13X.', 'c13x.', 'c13Y.', 'c13y.', 'c13Z.', 'c13z.', 'c141.', 'c142.', 'c143.', 'c144.', 'c145.', 'c146.', 'c147.', 'c148.', 'c149.', 'c14a.', 'c14b.', 'c14c.', 'c14d.', 'c14e.', 'c14f.', 'c14g.', 'c14h.', 'c14i.', 'c14j.', 'c14k.', 'c14r.', 'c14s.', 'c14t.', 'c14u.', 'c14v.', 'c14w.', 'c14x.', 'c14y.', 'c14z.', 'c151.', 'c152.', 'c153.', 'c154.', 'c15y.', 'c15z.', 'c191.', 'c192.', 'c193.', 'c194.', 'c195.', 'c196.', 'c197.', 'c198.', 'c199.', 'c19A.', 'c19B.', 'c19z.', 'c1B1.', 'c1B2.', 'c1B3.', 'c1B4.', 'c1c1.', 'c1C1.', 'c1c2.', 'c1C2.', 'c1c3.', 'c1C3.', 'c1C4.', 'c1C5.', 'c1C6.', 'c1C7.', 'c1C8.', 'c1cx.', 'c1cy.', 'c1Cy.', 'c1cz.', 'c1Cz.', 'c1D1.', 'c1D2.', 'c1D3.', 'c1D4.', 'c1D5.', 'c1D6.', 'c1D7.', 'c1D8.', 'c1Du.', 'c1Dv.', 'c1Dw.', 'c1Dx.', 'c1Dy.', 'c1Dz.', 'c1E1.', 'c1E2.', 'c1E3.', 'c1E4.', 'c1E5.', 'c1E6.', 'c1E7.', 'c1E8.', 'c1E9.', 'c1EA.', 'c1EB.', 'c1EC.', 'c1ED.', 'c1EE.', 'c211.', 'c212.', 'c213.', 'c214.', 'c215.', 'c216.', 'c221.', 'c222.', 'c223.', 'c224.', 'c225.', 'c226.', 'c227.', 'c251.', 'c252.', 'c253.', 'c254.', 'c255.', 'c25v.', 'c25w.', 'c25x.', 'c25y.', 'c25z.', 'c311.', 'c312.', 'c313.', 'c314.', 'c315.', 'c316.', 'c317.', 'c318.', 'c319.', 'c31A.', 'c31B.', 'c31C.', 'c31D.', 'c31E.', 'c31F.', 'c31G.', 'c31t.', 'c31u.', 'c31v.', 'c31w.', 'c31x.', 'c31y.', 'c31z.', 'c331.', 'c332.', 'c333.', 'c33x.', 'c33y.', 'c33z.', 'c341.', 'c342.', 'c351.', 'c352.', 'c411.', 'c412.', 'c413.', 'c414.', 'c415.', 'c416.', 'c417.', 'c418.', 'c419.', 'c41A.', 'c41a.', 'c41B.', 'c41b.', 'c41C.', 'c41c.', 'c41d.', 'c41e.', 'c41f.', 'c41g.', 'c41h.', 'c41i.', 'c41j.', 'c41k.', 'c41m.', 'c431.', 'c432.', 'c433.', 'c434.', 'c435.', 'c436.', 'c437.', 'c438.', 'c439.', 'c43a.', 'c43A.', 'c43b.', 'c43B.', 'c43c.', 'c43d.', 'c43e.', 'c43f.', 'c43g.', 'c43h.', 'c43i.', 'c43j.', 'c43k.', 'c43m.', 'c43n.', 'c43o.', 'c43p.', 'c43q.', 'c43r.', 'c43s.', 'c43t.', 'c43u.', 'c43v.', 'c43w.', 'c43x.', 'c43y.', 'c43z.', 'c511.', 'c512.', 'c513.', 'c514.', 'c515.', 'c516.', 'c517.', 'c518.', 'c519.', 'c51a.', 'c51A.', 'c51b.', 'c51B.', 'c51c.', 'c51C.', 'c51D.', 'c51d.', 'c51e.', 'c51E.', 'c51f.', 'c51F.', 'c51g.', 'c51G.', 'c51h.', 'c51H.', 'c51i.', 'c51I.', 'c51j.', 'c51J.', 'c51K.', 'c51k.', 'c51l.', 'c51L.', 'c51m.', 'c51n.', 'c51o.', 'c51p.', 'c51q.', 'c51r.', 'c51s.', 'c51t.', 'c51u.', 'c51v.', 'c51w.', 'c51x.', 'c51y.', 'c531.', 'c611.', 'c612.', 'c613.', 'c614.', 'c615.', 'c616.', 'c617.', 'c618.', 'c619.', 'c61A.', 'c61a.', 'c61B.', 'c61b.', 'c61C.', 'c61c.', 'c61D.', 'c61d.', 'c61E.', 'c61e.', 'c61F.', 'c61f.', 'c61G.', 'c61g.', 'c61H.', 'c61h.', 'c61i.', 'c61j.', 'c61J.', 'c61k.', 'c61K.', 'c61l.', 'c61L.', 'c61M.', 'c61m.', 'c61N.', 'c61n.', 'c61O.', 'c61P.', 'c61p.', 'c61Q.', 'c61q.', 'c61R.', 'c61r.', 'c61s.', 'c61S.', 'c61t.', 'c61T.', 'c61u.', 'c61U.', 'c61v.', 'c61V.', 'c61W.', 'c61w.', 'c61x.', 'c61X.', 'c61Y.', 'c61y.', 'c61z.', 'c61Z.', 'c621.', 'c622.', 'c623.', 'c624.', 'c631.', 'c63z.', 'c641.', 'c642.', 'c643.', 'c644.', 'c645.', 'c646.', 'c647.', 'c648.', 'c649.', 'c64A.', 'c64a.', 'c64B.', 'c64b.', 'c64c.', 'c64C.', 'c64d.', 'c64D.', 'c64e.', 'c64E.', 'c64F.', 'c64g.', 'c64G.', 'c64h.', 'c64H.', 'c64i.', 'c64I.', 'c64j.', 'c64J.', 'c64k.', 'c64K.', 'c64l.', 'c64L.', 'c64m.', 'c64M.', 'c64N.', 'c64n.', 'c64o.', 'c64p.', 'c64u.', 'c64v.', 'c64w.', 'c64x.', 'c64y.', 'c64z.', 'c651.', 'c652.', 'c653.', 'c654.', 'c655.', 'c656.', 'c657.', 'c658.', 'c659.', 'c65a.', 'c65A.', 'c65B.', 'c65b.', 'c65c.', 'c65C.', 'c65d.', 'c65D.', 'c65e.', 'c65E.', 'c65F.', 'c65f.', 'c65g.', 'c65G.', 'c65H.', 'c65I.', 'c65J.', 'c65K.', 'c65L.', 'c65M.', 'c65N.', 'c65O.', 'c65P.', 'c65Q.', 'c65R.', 'c65S.', 'c65T.', 'c65U.', 'c65V.', 'c65W.', 'c65X.', 'c65Y.', 'c65Z.', 'c661.', 'c662.', 'c663.', 'c664.', 'c665.', 'c666.', 'c667.', 'c668.', 'c669.', 'c66A.', 'c66a.', 'c66B.', 'c66b.', 'c66C.', 'c66c.', 'c66D.', 'c66d.', 'c66E.', 'c66e.', 'c66F.', 'c66f.', 'c66g.', 'c66G.', 'c66H.', 'c66h.', 'c66I.', 'c66J.', 'c66K.', 'c66L.', 'c66M.', 'c66N.', 'c66P.', 'c66Q.', 'c66R.', 'c66S.', 'c66T.', 'c66U.', 'c66V.', 'c66W.', 'c66X.', 'c66Y.', 'c66Z.', 'c671.', 'c672.', 'c673.', 'c674.', 'c675.', 'c67x.', 'c67y.', 'c67z.', 'c681.', 'c682.', 'c683.', 'c684.', 'c691.', 'c692.', 'c69y.', 'c69z.', 'c6A1.', 'c6A2.', 'c6Ay.', 'c6Az.', 'c6B1.', 'c6B2.', 'c6B3.', 'c6B4.', 'c711.', 'c712.', 'c713.', 'c714.', 'c715.', 'c716.', 'c717.', 'c718.', 'c719.', 'c71a.', 'c71b.', 'c71c.', 'c71d.', 'c71e.', 'c71f.', 'c71g.', 'c71h.', 'c71i.', 'c71j.', 'c71k.', 'c721.', 'c722.', 'c723.', 'c72y.', 'c72z.', 'c731.', 'c732.', 'c733.', 'c734.', 'c735.', 'c736.', 'c73x.', 'c73y.', 'c73z.', 'c741.', 'c742.', 'c743.', 'c744.', 'c745.', 'c746.', 'c747.', 'cA11.', 'cA12.', 'cA13.', 'cA14.', 'cA15.', 'cA16.', 'cA1y.', 'cA1z.', 'cA21.', 'cA22.', 'ck11.', 'ck12.', 'ck13.', 'ck14.', 'ck15.', 'ck16.')
									)
						AND 		(G.EVENT_DT >= SAILW0317V.ASTINEQ_V5_COHORT_SELECTION_DEC2019_FOLLOWUP_START_DATE + 2 YEAR AND G.EVENT_DT < SAILW0317V.ASTINEQ_V5_COHORT_SELECTION_DEC2019_FOLLOWUP_START_DATE + 3 YEAR - 1 DAY)
						GROUP BY A1.ALF_PE, ASTHMA_RX_12M_3

		 
		 ) B

		 ON					A.ALF_PE = B.ALF_PE

		 WHEN MATCHED THEN	UPDATE SET A.ASTHMA_RX_12M_3 = B.ASTHMA_RX_12M_3;



		 -- ASTHMA_RX_12M_4
		 -- Asthma prescriptions in the last 12 months - year 1
		 -- COUNT_OF_EVENTS: COUNT occuerences of events specified with Read codes in SAIL-GP during a specified date range
		 -- Final value: count(G.EVENT_CD)

		 MERGE INTO			SAILW0317V.ASTINEQ_V5_COHORT_SELECTION_DEC2019 A
		 USING				(
		 

		 SELECT 		A1.ALF_PE,
		 count(G.EVENT_CD) AS	ASTHMA_RX_12M_4
		 FROM		SAILW0317V.ASTINEQ_V5_COHORT_SELECTION_DEC2019  A1
		 	   	   JOIN	SAIL0317V.WLGP_GP_EVENT_ALF_CLEANSED_20180820  G
		 	   	   ON		A1.ALF_PE = G.ALF_PE
		 	   	   AND		(
										G.EVENT_CD IN ('c111.', 'c112.', 'c113.', 'c114.', 'c115.', 'c116.', 'c117.', 'c118.', 'c119.', 'c11a.', 'c11A.', 'c11B.', 'c11b.', 'c11C.', 'c11c.', 'c11d.', 'c11D.', 'c11e.', 'c11f.', 'c11g.', 'c11h.', 'c11i.', 'c11j.', 'c11k.', 'c11m.', 'c11n.', 'c11o.', 'c11p.', 'c11q.', 'c11v.', 'c11w.', 'c11x.', 'c11y.', 'c11z.', 'c121.', 'c122.', 'c123.', 'c124.', 'c125.', 'c126.', 'c12w.', 'c12x.', 'c12y.', 'c12z.', 'c131.', 'c132.', 'c133.', 'c134.', 'c135.', 'c136.', 'c137.', 'c138.', 'c139.', 'c13a.', 'c13A.', 'c13b.', 'c13B.', 'c13c.', 'c13C.', 'c13D.', 'c13d.', 'c13E.', 'c13e.', 'c13F.', 'c13f.', 'c13G.', 'c13g.', 'c13H.', 'c13h.', 'c13I.', 'c13i.', 'c13J.', 'c13j.', 'c13k.', 'c13K.', 'c13l.', 'c13L.', 'c13M.', 'c13m.', 'c13n.', 'c13N.', 'c13o.', 'c13O.', 'c13p.', 'c13P.', 'c13q.', 'c13Q.', 'c13r.', 'c13R.', 'c13s.', 'c13S.', 'c13T.', 'c13U.', 'c13V.', 'c13v.', 'c13W.', 'c13w.', 'c13X.', 'c13x.', 'c13Y.', 'c13y.', 'c13Z.', 'c13z.', 'c141.', 'c142.', 'c143.', 'c144.', 'c145.', 'c146.', 'c147.', 'c148.', 'c149.', 'c14a.', 'c14b.', 'c14c.', 'c14d.', 'c14e.', 'c14f.', 'c14g.', 'c14h.', 'c14i.', 'c14j.', 'c14k.', 'c14r.', 'c14s.', 'c14t.', 'c14u.', 'c14v.', 'c14w.', 'c14x.', 'c14y.', 'c14z.', 'c151.', 'c152.', 'c153.', 'c154.', 'c15y.', 'c15z.', 'c191.', 'c192.', 'c193.', 'c194.', 'c195.', 'c196.', 'c197.', 'c198.', 'c199.', 'c19A.', 'c19B.', 'c19z.', 'c1B1.', 'c1B2.', 'c1B3.', 'c1B4.', 'c1c1.', 'c1C1.', 'c1c2.', 'c1C2.', 'c1c3.', 'c1C3.', 'c1C4.', 'c1C5.', 'c1C6.', 'c1C7.', 'c1C8.', 'c1cx.', 'c1cy.', 'c1Cy.', 'c1cz.', 'c1Cz.', 'c1D1.', 'c1D2.', 'c1D3.', 'c1D4.', 'c1D5.', 'c1D6.', 'c1D7.', 'c1D8.', 'c1Du.', 'c1Dv.', 'c1Dw.', 'c1Dx.', 'c1Dy.', 'c1Dz.', 'c1E1.', 'c1E2.', 'c1E3.', 'c1E4.', 'c1E5.', 'c1E6.', 'c1E7.', 'c1E8.', 'c1E9.', 'c1EA.', 'c1EB.', 'c1EC.', 'c1ED.', 'c1EE.', 'c211.', 'c212.', 'c213.', 'c214.', 'c215.', 'c216.', 'c221.', 'c222.', 'c223.', 'c224.', 'c225.', 'c226.', 'c227.', 'c251.', 'c252.', 'c253.', 'c254.', 'c255.', 'c25v.', 'c25w.', 'c25x.', 'c25y.', 'c25z.', 'c311.', 'c312.', 'c313.', 'c314.', 'c315.', 'c316.', 'c317.', 'c318.', 'c319.', 'c31A.', 'c31B.', 'c31C.', 'c31D.', 'c31E.', 'c31F.', 'c31G.', 'c31t.', 'c31u.', 'c31v.', 'c31w.', 'c31x.', 'c31y.', 'c31z.', 'c331.', 'c332.', 'c333.', 'c33x.', 'c33y.', 'c33z.', 'c341.', 'c342.', 'c351.', 'c352.', 'c411.', 'c412.', 'c413.', 'c414.', 'c415.', 'c416.', 'c417.', 'c418.', 'c419.', 'c41A.', 'c41a.', 'c41B.', 'c41b.', 'c41C.', 'c41c.', 'c41d.', 'c41e.', 'c41f.', 'c41g.', 'c41h.', 'c41i.', 'c41j.', 'c41k.', 'c41m.', 'c431.', 'c432.', 'c433.', 'c434.', 'c435.', 'c436.', 'c437.', 'c438.', 'c439.', 'c43a.', 'c43A.', 'c43b.', 'c43B.', 'c43c.', 'c43d.', 'c43e.', 'c43f.', 'c43g.', 'c43h.', 'c43i.', 'c43j.', 'c43k.', 'c43m.', 'c43n.', 'c43o.', 'c43p.', 'c43q.', 'c43r.', 'c43s.', 'c43t.', 'c43u.', 'c43v.', 'c43w.', 'c43x.', 'c43y.', 'c43z.', 'c511.', 'c512.', 'c513.', 'c514.', 'c515.', 'c516.', 'c517.', 'c518.', 'c519.', 'c51a.', 'c51A.', 'c51b.', 'c51B.', 'c51c.', 'c51C.', 'c51D.', 'c51d.', 'c51e.', 'c51E.', 'c51f.', 'c51F.', 'c51g.', 'c51G.', 'c51h.', 'c51H.', 'c51i.', 'c51I.', 'c51j.', 'c51J.', 'c51K.', 'c51k.', 'c51l.', 'c51L.', 'c51m.', 'c51n.', 'c51o.', 'c51p.', 'c51q.', 'c51r.', 'c51s.', 'c51t.', 'c51u.', 'c51v.', 'c51w.', 'c51x.', 'c51y.', 'c531.', 'c611.', 'c612.', 'c613.', 'c614.', 'c615.', 'c616.', 'c617.', 'c618.', 'c619.', 'c61A.', 'c61a.', 'c61B.', 'c61b.', 'c61C.', 'c61c.', 'c61D.', 'c61d.', 'c61E.', 'c61e.', 'c61F.', 'c61f.', 'c61G.', 'c61g.', 'c61H.', 'c61h.', 'c61i.', 'c61j.', 'c61J.', 'c61k.', 'c61K.', 'c61l.', 'c61L.', 'c61M.', 'c61m.', 'c61N.', 'c61n.', 'c61O.', 'c61P.', 'c61p.', 'c61Q.', 'c61q.', 'c61R.', 'c61r.', 'c61s.', 'c61S.', 'c61t.', 'c61T.', 'c61u.', 'c61U.', 'c61v.', 'c61V.', 'c61W.', 'c61w.', 'c61x.', 'c61X.', 'c61Y.', 'c61y.', 'c61z.', 'c61Z.', 'c621.', 'c622.', 'c623.', 'c624.', 'c631.', 'c63z.', 'c641.', 'c642.', 'c643.', 'c644.', 'c645.', 'c646.', 'c647.', 'c648.', 'c649.', 'c64A.', 'c64a.', 'c64B.', 'c64b.', 'c64c.', 'c64C.', 'c64d.', 'c64D.', 'c64e.', 'c64E.', 'c64F.', 'c64g.', 'c64G.', 'c64h.', 'c64H.', 'c64i.', 'c64I.', 'c64j.', 'c64J.', 'c64k.', 'c64K.', 'c64l.', 'c64L.', 'c64m.', 'c64M.', 'c64N.', 'c64n.', 'c64o.', 'c64p.', 'c64u.', 'c64v.', 'c64w.', 'c64x.', 'c64y.', 'c64z.', 'c651.', 'c652.', 'c653.', 'c654.', 'c655.', 'c656.', 'c657.', 'c658.', 'c659.', 'c65a.', 'c65A.', 'c65B.', 'c65b.', 'c65c.', 'c65C.', 'c65d.', 'c65D.', 'c65e.', 'c65E.', 'c65F.', 'c65f.', 'c65g.', 'c65G.', 'c65H.', 'c65I.', 'c65J.', 'c65K.', 'c65L.', 'c65M.', 'c65N.', 'c65O.', 'c65P.', 'c65Q.', 'c65R.', 'c65S.', 'c65T.', 'c65U.', 'c65V.', 'c65W.', 'c65X.', 'c65Y.', 'c65Z.', 'c661.', 'c662.', 'c663.', 'c664.', 'c665.', 'c666.', 'c667.', 'c668.', 'c669.', 'c66A.', 'c66a.', 'c66B.', 'c66b.', 'c66C.', 'c66c.', 'c66D.', 'c66d.', 'c66E.', 'c66e.', 'c66F.', 'c66f.', 'c66g.', 'c66G.', 'c66H.', 'c66h.', 'c66I.', 'c66J.', 'c66K.', 'c66L.', 'c66M.', 'c66N.', 'c66P.', 'c66Q.', 'c66R.', 'c66S.', 'c66T.', 'c66U.', 'c66V.', 'c66W.', 'c66X.', 'c66Y.', 'c66Z.', 'c671.', 'c672.', 'c673.', 'c674.', 'c675.', 'c67x.', 'c67y.', 'c67z.', 'c681.', 'c682.', 'c683.', 'c684.', 'c691.', 'c692.', 'c69y.', 'c69z.', 'c6A1.', 'c6A2.', 'c6Ay.', 'c6Az.', 'c6B1.', 'c6B2.', 'c6B3.', 'c6B4.', 'c711.', 'c712.', 'c713.', 'c714.', 'c715.', 'c716.', 'c717.', 'c718.', 'c719.', 'c71a.', 'c71b.', 'c71c.', 'c71d.', 'c71e.', 'c71f.', 'c71g.', 'c71h.', 'c71i.', 'c71j.', 'c71k.', 'c721.', 'c722.', 'c723.', 'c72y.', 'c72z.', 'c731.', 'c732.', 'c733.', 'c734.', 'c735.', 'c736.', 'c73x.', 'c73y.', 'c73z.', 'c741.', 'c742.', 'c743.', 'c744.', 'c745.', 'c746.', 'c747.', 'cA11.', 'cA12.', 'cA13.', 'cA14.', 'cA15.', 'cA16.', 'cA1y.', 'cA1z.', 'cA21.', 'cA22.', 'ck11.', 'ck12.', 'ck13.', 'ck14.', 'ck15.', 'ck16.')
									)
						AND 		(G.EVENT_DT >= SAILW0317V.ASTINEQ_V5_COHORT_SELECTION_DEC2019_FOLLOWUP_START_DATE + 3 YEAR AND G.EVENT_DT < SAILW0317V.ASTINEQ_V5_COHORT_SELECTION_DEC2019_FOLLOWUP_START_DATE + 4 YEAR - 1 DAY)
						GROUP BY A1.ALF_PE, ASTHMA_RX_12M_4

		 
		 ) B

		 ON					A.ALF_PE = B.ALF_PE

		 WHEN MATCHED THEN	UPDATE SET A.ASTHMA_RX_12M_4 = B.ASTHMA_RX_12M_4;



		 -- ASTHMA_RX_12M_5
		 -- Asthma prescriptions in the last 12 months - year 1
		 -- COUNT_OF_EVENTS: COUNT occuerences of events specified with Read codes in SAIL-GP during a specified date range
		 -- Final value: count(G.EVENT_CD)

		 MERGE INTO			SAILW0317V.ASTINEQ_V5_COHORT_SELECTION_DEC2019 A
		 USING				(
		 

		 SELECT 		A1.ALF_PE,
		 count(G.EVENT_CD) AS	ASTHMA_RX_12M_5
		 FROM		SAILW0317V.ASTINEQ_V5_COHORT_SELECTION_DEC2019  A1
		 	   	   JOIN	SAIL0317V.WLGP_GP_EVENT_ALF_CLEANSED_20180820  G
		 	   	   ON		A1.ALF_PE = G.ALF_PE
		 	   	   AND		(
										G.EVENT_CD IN ('c111.', 'c112.', 'c113.', 'c114.', 'c115.', 'c116.', 'c117.', 'c118.', 'c119.', 'c11a.', 'c11A.', 'c11B.', 'c11b.', 'c11C.', 'c11c.', 'c11d.', 'c11D.', 'c11e.', 'c11f.', 'c11g.', 'c11h.', 'c11i.', 'c11j.', 'c11k.', 'c11m.', 'c11n.', 'c11o.', 'c11p.', 'c11q.', 'c11v.', 'c11w.', 'c11x.', 'c11y.', 'c11z.', 'c121.', 'c122.', 'c123.', 'c124.', 'c125.', 'c126.', 'c12w.', 'c12x.', 'c12y.', 'c12z.', 'c131.', 'c132.', 'c133.', 'c134.', 'c135.', 'c136.', 'c137.', 'c138.', 'c139.', 'c13a.', 'c13A.', 'c13b.', 'c13B.', 'c13c.', 'c13C.', 'c13D.', 'c13d.', 'c13E.', 'c13e.', 'c13F.', 'c13f.', 'c13G.', 'c13g.', 'c13H.', 'c13h.', 'c13I.', 'c13i.', 'c13J.', 'c13j.', 'c13k.', 'c13K.', 'c13l.', 'c13L.', 'c13M.', 'c13m.', 'c13n.', 'c13N.', 'c13o.', 'c13O.', 'c13p.', 'c13P.', 'c13q.', 'c13Q.', 'c13r.', 'c13R.', 'c13s.', 'c13S.', 'c13T.', 'c13U.', 'c13V.', 'c13v.', 'c13W.', 'c13w.', 'c13X.', 'c13x.', 'c13Y.', 'c13y.', 'c13Z.', 'c13z.', 'c141.', 'c142.', 'c143.', 'c144.', 'c145.', 'c146.', 'c147.', 'c148.', 'c149.', 'c14a.', 'c14b.', 'c14c.', 'c14d.', 'c14e.', 'c14f.', 'c14g.', 'c14h.', 'c14i.', 'c14j.', 'c14k.', 'c14r.', 'c14s.', 'c14t.', 'c14u.', 'c14v.', 'c14w.', 'c14x.', 'c14y.', 'c14z.', 'c151.', 'c152.', 'c153.', 'c154.', 'c15y.', 'c15z.', 'c191.', 'c192.', 'c193.', 'c194.', 'c195.', 'c196.', 'c197.', 'c198.', 'c199.', 'c19A.', 'c19B.', 'c19z.', 'c1B1.', 'c1B2.', 'c1B3.', 'c1B4.', 'c1c1.', 'c1C1.', 'c1c2.', 'c1C2.', 'c1c3.', 'c1C3.', 'c1C4.', 'c1C5.', 'c1C6.', 'c1C7.', 'c1C8.', 'c1cx.', 'c1cy.', 'c1Cy.', 'c1cz.', 'c1Cz.', 'c1D1.', 'c1D2.', 'c1D3.', 'c1D4.', 'c1D5.', 'c1D6.', 'c1D7.', 'c1D8.', 'c1Du.', 'c1Dv.', 'c1Dw.', 'c1Dx.', 'c1Dy.', 'c1Dz.', 'c1E1.', 'c1E2.', 'c1E3.', 'c1E4.', 'c1E5.', 'c1E6.', 'c1E7.', 'c1E8.', 'c1E9.', 'c1EA.', 'c1EB.', 'c1EC.', 'c1ED.', 'c1EE.', 'c211.', 'c212.', 'c213.', 'c214.', 'c215.', 'c216.', 'c221.', 'c222.', 'c223.', 'c224.', 'c225.', 'c226.', 'c227.', 'c251.', 'c252.', 'c253.', 'c254.', 'c255.', 'c25v.', 'c25w.', 'c25x.', 'c25y.', 'c25z.', 'c311.', 'c312.', 'c313.', 'c314.', 'c315.', 'c316.', 'c317.', 'c318.', 'c319.', 'c31A.', 'c31B.', 'c31C.', 'c31D.', 'c31E.', 'c31F.', 'c31G.', 'c31t.', 'c31u.', 'c31v.', 'c31w.', 'c31x.', 'c31y.', 'c31z.', 'c331.', 'c332.', 'c333.', 'c33x.', 'c33y.', 'c33z.', 'c341.', 'c342.', 'c351.', 'c352.', 'c411.', 'c412.', 'c413.', 'c414.', 'c415.', 'c416.', 'c417.', 'c418.', 'c419.', 'c41A.', 'c41a.', 'c41B.', 'c41b.', 'c41C.', 'c41c.', 'c41d.', 'c41e.', 'c41f.', 'c41g.', 'c41h.', 'c41i.', 'c41j.', 'c41k.', 'c41m.', 'c431.', 'c432.', 'c433.', 'c434.', 'c435.', 'c436.', 'c437.', 'c438.', 'c439.', 'c43a.', 'c43A.', 'c43b.', 'c43B.', 'c43c.', 'c43d.', 'c43e.', 'c43f.', 'c43g.', 'c43h.', 'c43i.', 'c43j.', 'c43k.', 'c43m.', 'c43n.', 'c43o.', 'c43p.', 'c43q.', 'c43r.', 'c43s.', 'c43t.', 'c43u.', 'c43v.', 'c43w.', 'c43x.', 'c43y.', 'c43z.', 'c511.', 'c512.', 'c513.', 'c514.', 'c515.', 'c516.', 'c517.', 'c518.', 'c519.', 'c51a.', 'c51A.', 'c51b.', 'c51B.', 'c51c.', 'c51C.', 'c51D.', 'c51d.', 'c51e.', 'c51E.', 'c51f.', 'c51F.', 'c51g.', 'c51G.', 'c51h.', 'c51H.', 'c51i.', 'c51I.', 'c51j.', 'c51J.', 'c51K.', 'c51k.', 'c51l.', 'c51L.', 'c51m.', 'c51n.', 'c51o.', 'c51p.', 'c51q.', 'c51r.', 'c51s.', 'c51t.', 'c51u.', 'c51v.', 'c51w.', 'c51x.', 'c51y.', 'c531.', 'c611.', 'c612.', 'c613.', 'c614.', 'c615.', 'c616.', 'c617.', 'c618.', 'c619.', 'c61A.', 'c61a.', 'c61B.', 'c61b.', 'c61C.', 'c61c.', 'c61D.', 'c61d.', 'c61E.', 'c61e.', 'c61F.', 'c61f.', 'c61G.', 'c61g.', 'c61H.', 'c61h.', 'c61i.', 'c61j.', 'c61J.', 'c61k.', 'c61K.', 'c61l.', 'c61L.', 'c61M.', 'c61m.', 'c61N.', 'c61n.', 'c61O.', 'c61P.', 'c61p.', 'c61Q.', 'c61q.', 'c61R.', 'c61r.', 'c61s.', 'c61S.', 'c61t.', 'c61T.', 'c61u.', 'c61U.', 'c61v.', 'c61V.', 'c61W.', 'c61w.', 'c61x.', 'c61X.', 'c61Y.', 'c61y.', 'c61z.', 'c61Z.', 'c621.', 'c622.', 'c623.', 'c624.', 'c631.', 'c63z.', 'c641.', 'c642.', 'c643.', 'c644.', 'c645.', 'c646.', 'c647.', 'c648.', 'c649.', 'c64A.', 'c64a.', 'c64B.', 'c64b.', 'c64c.', 'c64C.', 'c64d.', 'c64D.', 'c64e.', 'c64E.', 'c64F.', 'c64g.', 'c64G.', 'c64h.', 'c64H.', 'c64i.', 'c64I.', 'c64j.', 'c64J.', 'c64k.', 'c64K.', 'c64l.', 'c64L.', 'c64m.', 'c64M.', 'c64N.', 'c64n.', 'c64o.', 'c64p.', 'c64u.', 'c64v.', 'c64w.', 'c64x.', 'c64y.', 'c64z.', 'c651.', 'c652.', 'c653.', 'c654.', 'c655.', 'c656.', 'c657.', 'c658.', 'c659.', 'c65a.', 'c65A.', 'c65B.', 'c65b.', 'c65c.', 'c65C.', 'c65d.', 'c65D.', 'c65e.', 'c65E.', 'c65F.', 'c65f.', 'c65g.', 'c65G.', 'c65H.', 'c65I.', 'c65J.', 'c65K.', 'c65L.', 'c65M.', 'c65N.', 'c65O.', 'c65P.', 'c65Q.', 'c65R.', 'c65S.', 'c65T.', 'c65U.', 'c65V.', 'c65W.', 'c65X.', 'c65Y.', 'c65Z.', 'c661.', 'c662.', 'c663.', 'c664.', 'c665.', 'c666.', 'c667.', 'c668.', 'c669.', 'c66A.', 'c66a.', 'c66B.', 'c66b.', 'c66C.', 'c66c.', 'c66D.', 'c66d.', 'c66E.', 'c66e.', 'c66F.', 'c66f.', 'c66g.', 'c66G.', 'c66H.', 'c66h.', 'c66I.', 'c66J.', 'c66K.', 'c66L.', 'c66M.', 'c66N.', 'c66P.', 'c66Q.', 'c66R.', 'c66S.', 'c66T.', 'c66U.', 'c66V.', 'c66W.', 'c66X.', 'c66Y.', 'c66Z.', 'c671.', 'c672.', 'c673.', 'c674.', 'c675.', 'c67x.', 'c67y.', 'c67z.', 'c681.', 'c682.', 'c683.', 'c684.', 'c691.', 'c692.', 'c69y.', 'c69z.', 'c6A1.', 'c6A2.', 'c6Ay.', 'c6Az.', 'c6B1.', 'c6B2.', 'c6B3.', 'c6B4.', 'c711.', 'c712.', 'c713.', 'c714.', 'c715.', 'c716.', 'c717.', 'c718.', 'c719.', 'c71a.', 'c71b.', 'c71c.', 'c71d.', 'c71e.', 'c71f.', 'c71g.', 'c71h.', 'c71i.', 'c71j.', 'c71k.', 'c721.', 'c722.', 'c723.', 'c72y.', 'c72z.', 'c731.', 'c732.', 'c733.', 'c734.', 'c735.', 'c736.', 'c73x.', 'c73y.', 'c73z.', 'c741.', 'c742.', 'c743.', 'c744.', 'c745.', 'c746.', 'c747.', 'cA11.', 'cA12.', 'cA13.', 'cA14.', 'cA15.', 'cA16.', 'cA1y.', 'cA1z.', 'cA21.', 'cA22.', 'ck11.', 'ck12.', 'ck13.', 'ck14.', 'ck15.', 'ck16.')
									)
						AND 		(G.EVENT_DT >= SAILW0317V.ASTINEQ_V5_COHORT_SELECTION_DEC2019_FOLLOWUP_START_DATE + 4 YEAR AND G.EVENT_DT < SAILW0317V.ASTINEQ_V5_COHORT_SELECTION_DEC2019_FOLLOWUP_START_DATE + 5 YEAR - 1 DAY)
						GROUP BY A1.ALF_PE, ASTHMA_RX_12M_5

		 
		 ) B

		 ON					A.ALF_PE = B.ALF_PE

		 WHEN MATCHED THEN	UPDATE SET A.ASTHMA_RX_12M_5 = B.ASTHMA_RX_12M_5;
