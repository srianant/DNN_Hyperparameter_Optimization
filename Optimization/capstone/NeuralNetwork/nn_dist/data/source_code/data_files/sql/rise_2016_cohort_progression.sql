--cohorts for becca
SELECT base.studentid
      ,base.lastfirst
      ,base.grade_level AS x2008_grade
      ,base.cohort      AS x2008_cohort
      ,CASE
         WHEN in_6th.grade_level IS NOT NULL THEN 1
         ELSE 0
       END AS in_6th_dummy
      ,CASE
         WHEN in_7th.grade_level IS NOT NULL THEN 1
         ELSE 0
       END AS in_7th_dummy
      ,CASE
         WHEN in_8th.grade_level IS NOT NULL THEN 1
         ELSE 0
       END AS in_8th_dummy
FROM
      (SELECT *
      FROM cohort$comprehensive_long
      WHERE cohort = 2016
        AND schoolid = 73252
        AND grade_level = 5
      ) base
LEFT OUTER JOIN cohort$comprehensive_long in_6th
  ON base.studentid = in_6th.studentid
    AND in_6th.cohort = 2016
    AND in_6th.grade_level = 6
    AND in_6th.schoolid = 73252
LEFT OUTER JOIN cohort$comprehensive_long in_7th
  ON base.studentid = in_7th.studentid
    AND in_7th.cohort = 2016
    AND in_7th.grade_level = 7
    AND in_7th.schoolid = 73252
LEFT OUTER JOIN cohort$comprehensive_long in_8th
  ON base.studentid = in_8th.studentid
    AND in_8th.cohort = 2016
    AND in_8th.grade_level = 8
    AND in_8th.schoolid = 73252

;
--cohort totals
SELECT detail.x2008_grade
      ,COUNT(*) AS x2016_cohort_starting_N
      ,SUM(in_6th_dummy) AS n_in_6th
      ,SUM(in_7th_dummy) AS n_in_7th
      ,SUM(in_8th_dummy) AS n_in_8th
FROM
      (SELECT base.studentid
            ,base.lastfirst
            ,base.grade_level AS x2008_grade
            ,base.cohort      AS x2008_cohort
            
            ,CASE
               WHEN in_6th.grade_level IS NOT NULL THEN 1
               ELSE 0
             END AS in_6th_dummy
            ,CASE
               WHEN in_7th.grade_level IS NOT NULL THEN 1
               ELSE 0
             END AS in_7th_dummy
            ,CASE
               WHEN in_8th.grade_level IS NOT NULL THEN 1
               ELSE 0
             END AS in_8th_dummy
      FROM
            (SELECT *
            FROM cohort$comprehensive_long
            WHERE cohort = 2016
              AND schoolid = 73252
              AND grade_level = 5
            ) base
      LEFT OUTER JOIN cohort$comprehensive_long in_6th
        ON base.studentid = in_6th.studentid
          AND in_6th.cohort = 2016
          AND in_6th.grade_level = 6
          AND in_6th.schoolid = 73252
      LEFT OUTER JOIN cohort$comprehensive_long in_7th
        ON base.studentid = in_7th.studentid
          AND in_7th.cohort = 2016
          AND in_7th.grade_level = 7
          AND in_7th.schoolid = 73252
      LEFT OUTER JOIN cohort$comprehensive_long in_8th
        ON base.studentid = in_8th.studentid
          AND in_8th.cohort = 2016
          AND in_8th.grade_level = 8
          AND in_8th.schoolid = 73252
      ) detail
GROUP BY x2008_grade
;
--ANY progression, not specific
SELECT detail.x2008_grade
      ,COUNT(*) AS x2016_cohort_starting_N
      ,SUM(in_year_2_dummy) AS n_in_year_2
      ,SUM(in_year_3_dummy) AS n_in_year_3
      ,SUM(in_year_4_dummy) AS n_in_year_4
FROM
      (SELECT base.studentid
            ,base.lastfirst
            ,base.grade_level AS x2008_grade
            ,base.cohort      AS x2008_cohort
            
            ,CASE
               WHEN in_year_2.grade_level IS NOT NULL THEN 1
               ELSE 0
             END AS in_year_2_dummy
            ,CASE
               WHEN in_year_3.grade_level IS NOT NULL THEN 1
               ELSE 0
             END AS in_year_3_dummy
            ,CASE
               WHEN in_year_4.grade_level IS NOT NULL THEN 1
               ELSE 0
             END AS in_year_4_dummy
            ,in_year_2.grade_level as year_2_grade 
            ,in_year_3.grade_level as year_3_grade
            ,in_year_4.grade_level as year_4_grade
      FROM
            (SELECT *
            FROM cohort$comprehensive_long
            WHERE cohort = 2016
              AND schoolid = 73252
              AND grade_level = 5
            ) base
      LEFT OUTER JOIN cohort$comprehensive_long in_year_2
        ON base.studentid = in_year_2.studentid
          AND in_year_2.year = 2009
          AND in_year_2.schoolid = 73252
      LEFT OUTER JOIN cohort$comprehensive_long in_year_3
        ON base.studentid = in_year_3.studentid
          AND in_year_3.year = 2010
          AND in_year_3.schoolid = 73252
      LEFT OUTER JOIN cohort$comprehensive_long in_year_4
        ON base.studentid = in_year_4.studentid
          AND in_year_4.year = 2011
          AND in_year_4.schoolid = 73252
      ) detail
GROUP BY x2008_grade