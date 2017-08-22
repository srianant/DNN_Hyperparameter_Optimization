--student roster
SELECT sub_1.student_number
      ,sub_1.ps_id
      ,sub_1.first_name
      ,sub_1.last_name
      ,sub_1.lastfirst
      ,sub_1.name
      ,sub_1.subject
      ,sub_1.grade_level
      ,enrollments.course_name AS match_course
      ,enrollments.enr_hash AS match_section
      ,sub_1.spedlep
      ,sub_1.best_prev_rit
      ,sub_1.typical_growth_goal
      ,sub_1.typical_growth_target
      ,sgp01_goal
      ,sgp25_goal
      ,sgp50_goal
      ,sgp70_goal
      ,sgp80_goal
      ,sgp90_goal
      ,sgp95_goal
      ,sgp99_goal      
FROM
     (SELECT baseline.student_number
            ,baseline.ps_id
            ,baseline.first_name
            ,baseline.last_name
            ,baseline.lastfirst
            ,baseline.name
            ,baseline.subject
            ,baseline.grade_level
            ,cust.spedlep
            ,CASE
               WHEN baseline.subject = 'Mathematics' THEN 'MATH'
               WHEN baseline.subject = 'Reading' THEN 'ENG'
               WHEN baseline.subject = 'Language Usage' THEN 'RHET'
               WHEN baseline.subject IN ('Concepts and Processes', 'General Science') THEN 'SCI'
             END AS credit_join
            ,baseline.best_prev_rit
            ,norms.r22 AS typical_growth_goal
            ,baseline.best_prev_rit + norms.r22 AS typical_growth_target
            --SGPs
            ,ROUND((norm_dist.p01_zscore * norms.s22) + (baseline.best_prev_rit + norms.t22),0) AS sgp01_goal
            ,ROUND((norm_dist.p25_zscore * norms.s22) + (baseline.best_prev_rit + norms.t22),0) AS sgp25_goal
            ,ROUND((norm_dist.p50_zscore * norms.s22) + (baseline.best_prev_rit + norms.t22),0) AS sgp50_goal
            ,ROUND((norm_dist.p70_zscore * norms.s22) + (baseline.best_prev_rit + norms.t22),0) AS sgp70_goal
            ,ROUND((norm_dist.p80_zscore * norms.s22) + (baseline.best_prev_rit + norms.t22),0) AS sgp80_goal
            ,ROUND((norm_dist.p90_zscore * norms.s22) + (baseline.best_prev_rit + norms.t22),0) AS sgp90_goal
            ,ROUND((norm_dist.p95_zscore * norms.s22) + (baseline.best_prev_rit + norms.t22),0) AS sgp95_goal
            ,ROUND((norm_dist.p99_zscore * norms.s22) + (baseline.best_prev_rit + norms.t22),0) AS sgp99_goal
      FROM map$best_baseline_detail baseline
      JOIN custom_students cust
        ON baseline.ps_id = cust.studentid
      LEFT OUTER JOIN map$growth_norms_data#2011 norms
        ON baseline.subject = norms.subject
       AND baseline.grade_level - 1 = norms.startgrade
       AND baseline.best_prev_rit = norms.startrit
      JOIN (
            SELECT *
            FROM 
                 (SELECT z.zscore
                        ,z.percentile
                  FROM
                       (SELECT zscore
                              ,percentile
                              ,row_number() OVER
                                 (PARTITION BY percentile
                                     ORDER BY zscore ASC
                                  ) AS rn
                        FROM ZSCORES
                        WHERE percentile IN (1,5,10,20,25,30,40,50,60,70,75,80,90,95,99)
                        ) z
                  WHERE rn = 1 
                  )
            S PIVOT (MAX(zscore) AS zscore
                       FOR percentile IN (
                         '1'  p01
                        ,'5'  p05
                        ,'10' p10
                        ,'20' p20
                        ,'25' p25
                        ,'30' p30
                        ,'40' p40
                        ,'50' p50
                        ,'60' p60
                        ,'70' p70
                        ,'75' p75
                        ,'80' p80
                        ,'90' p90
                        ,'95' p95
                        ,'99' p99
                       )
                    )
      ) norm_dist ON 1=1
      WHERE schoolid = 73252
      ) sub_1
LEFT OUTER JOIN
   (SELECT cc.studentid
          ,courses.course_name
          ,courses.credittype
          ,courses.course_number
          ,courses.course_name || ': ' || sections.section_number AS enr_hash
    FROM cc
    JOIN courses 
      ON cc.course_number = courses.course_number
     AND courses.credittype != 'COCUR'
     AND courses.credittype != 'WLANG'
    JOIN sections@PS_TEAM
      ON cc.sectionid = sections.id
    WHERE cc.schoolid = 73252 
      AND cc.termid >= 2200
      ) enrollments
  ON sub_1.ps_id = enrollments.studentid
 AND sub_1.credit_join = enrollments.credittype
;

--NEW QUERY FOR TEACHER GOALS
SELECT grade_level
      ,subject
      ,iep_status
      ,course
      ,avg_baseline_rit
      ,avg_cohort_change
      ,cohort_sd
      ,ROUND((p01_zscore * cohort_sd) + (avg_baseline_rit + avg_cohort_change),1) AS p01_goal_spr_2013
      ,ROUND((p05_zscore * cohort_sd) + (avg_baseline_rit + avg_cohort_change),1) AS p05_goal_spr_2013
      ,ROUND((p10_zscore * cohort_sd) + (avg_baseline_rit + avg_cohort_change),1) AS p10_goal_spr_2013
      ,ROUND((p20_zscore * cohort_sd) + (avg_baseline_rit + avg_cohort_change),1) AS p20_goal_spr_2013
      ,ROUND((p25_zscore * cohort_sd) + (avg_baseline_rit + avg_cohort_change),1) AS p25_goal_spr_2013
      ,ROUND((p30_zscore * cohort_sd) + (avg_baseline_rit + avg_cohort_change),1) AS p30_goal_spr_2013
      ,ROUND((p40_zscore * cohort_sd) + (avg_baseline_rit + avg_cohort_change),1) AS p40_goal_spr_2013
      ,ROUND(avg_baseline_rit + avg_cohort_change,1) AS p50_goal_spr_2013
      ,ROUND((p60_zscore * cohort_sd) + (avg_baseline_rit + avg_cohort_change),1) AS p60_goal_spr_2013
      ,ROUND((p70_zscore * cohort_sd) + (avg_baseline_rit + avg_cohort_change),1) AS p70_goal_spr_2013
      ,ROUND((p75_zscore * cohort_sd) + (avg_baseline_rit + avg_cohort_change),1) AS p75_goal_spr_2013
      ,ROUND((p80_zscore * cohort_sd) + (avg_baseline_rit + avg_cohort_change),1) AS p80_goal_spr_2013
      ,ROUND((p90_zscore * cohort_sd) + (avg_baseline_rit + avg_cohort_change),1) AS p90_goal_spr_2013
      ,ROUND((p95_zscore * cohort_sd) + (avg_baseline_rit + avg_cohort_change),1) AS p95_goal_spr_2013
      ,ROUND((p99_zscore * cohort_sd) + (avg_baseline_rit + avg_cohort_change),1) AS p99_goal_spr_2013
FROM
     (SELECT sub_3.*
            ,norms.mean AS avg_cohort_change
            ,norms.sd AS cohort_sd
            ,row_number() OVER
               (PARTITION BY sub_3.grade_level
                            ,sub_3.subject
                            ,sub_3.iep_status
                            ,sub_3.course
                ORDER BY ABS(avg_baseline_rit - norms.rit) ASC
               ) AS closest_match
      FROM
            (SELECT grade_level
                  ,subject
                  ,DECODE(GROUPING(iep_status), 0, iep_status, 'All Students') AS iep_status
                  ,DECODE(GROUPING(match_course), 0, match_course, 'Whole Grade') AS course
                  ,ROUND(AVG(best_prev_rit),1) AS avg_baseline_RIT
            FROM
                  (SELECT sub_1.student_number
                        ,sub_1.ps_id
                        ,sub_1.first_name
                        ,sub_1.last_name
                        ,sub_1.lastfirst
                        ,sub_1.name
                        ,sub_1.subject
                        ,sub_1.grade_level
                        ,enrollments.course_name AS match_course
                        ,enrollments.enr_hash AS match_section
                        ,CASE
                           WHEN sub_1.spedlep LIKE '%SPED%' THEN 'IEP'
                           ELSE 'No IEP'
                         END AS iep_status
                        ,sub_1.best_prev_rit
                        ,sub_1.typical_growth_goal
                        ,sub_1.typical_growth_target
                        ,sgp01_goal
                        ,sgp25_goal
                        ,sgp50_goal
                        ,sgp70_goal
                        ,sgp80_goal
                        ,sgp90_goal
                        ,sgp95_goal
                        ,sgp99_goal      
                  FROM
                       (SELECT baseline.student_number
                              ,baseline.ps_id
                              ,baseline.first_name
                              ,baseline.last_name
                              ,baseline.lastfirst
                              ,baseline.name
                              ,baseline.subject
                              ,baseline.grade_level
                              ,cust.spedlep
                              ,CASE
                                 WHEN baseline.subject = 'Mathematics' THEN 'MATH'
                                 WHEN baseline.subject = 'Reading' THEN 'ENG'
                                 WHEN baseline.subject = 'Language Usage' THEN 'RHET'
                                 WHEN baseline.subject IN ('Concepts and Processes', 'General Science') THEN 'SCI'
                               END AS credit_join
                              ,baseline.best_prev_rit
                              ,norms.r22 AS typical_growth_goal
                              ,baseline.best_prev_rit + norms.r22 AS typical_growth_target
                              
                              ,ROUND((norm_dist.p01_zscore * norms.s22) + (baseline.best_prev_rit + norms.t22),0) AS sgp01_goal
                              ,ROUND((norm_dist.p25_zscore * norms.s22) + (baseline.best_prev_rit + norms.t22),0) AS sgp25_goal
                              ,ROUND((norm_dist.p50_zscore * norms.s22) + (baseline.best_prev_rit + norms.t22),0) AS sgp50_goal
                              ,ROUND((norm_dist.p70_zscore * norms.s22) + (baseline.best_prev_rit + norms.t22),0) AS sgp70_goal
                              ,ROUND((norm_dist.p80_zscore * norms.s22) + (baseline.best_prev_rit + norms.t22),0) AS sgp80_goal
                              ,ROUND((norm_dist.p90_zscore * norms.s22) + (baseline.best_prev_rit + norms.t22),0) AS sgp90_goal
                              ,ROUND((norm_dist.p95_zscore * norms.s22) + (baseline.best_prev_rit + norms.t22),0) AS sgp95_goal
                              ,ROUND((norm_dist.p99_zscore * norms.s22) + (baseline.best_prev_rit + norms.t22),0) AS sgp99_goal
                        FROM map$best_baseline_detail baseline
                        JOIN custom_students cust
                          ON baseline.ps_id = cust.studentid
                        LEFT OUTER JOIN map$growth_norms_data#2011 norms
                          ON baseline.subject = norms.subject
                         AND baseline.grade_level - 1 = norms.startgrade
                         AND baseline.best_prev_rit = norms.startrit
                        JOIN (
                              SELECT *
                              FROM 
                                   (SELECT z.zscore
                                          ,z.percentile
                                    FROM
                                         (SELECT zscore
                                                ,percentile
                                                ,row_number() OVER
                                                   (PARTITION BY percentile
                                                       ORDER BY zscore ASC
                                                    ) AS rn
                                          FROM ZSCORES
                                          WHERE percentile IN (1,5,10,20,25,30,40,50,60,70,75,80,90,95,99)
                                          ) z
                                    WHERE rn = 1 
                                    )
                              S PIVOT (MAX(zscore) AS zscore
                                         FOR percentile IN (
                                           '1'  p01
                                          ,'5'  p05
                                          ,'10' p10
                                          ,'20' p20
                                          ,'25' p25
                                          ,'30' p30
                                          ,'40' p40
                                          ,'50' p50
                                          ,'60' p60
                                          ,'70' p70
                                          ,'75' p75
                                          ,'80' p80
                                          ,'90' p90
                                          ,'95' p95
                                          ,'99' p99
                                         )
                                      )
                        ) norm_dist ON 1=1
                        WHERE schoolid = 73252
                        ) sub_1
                  LEFT OUTER JOIN
                     (SELECT cc.studentid
                            ,courses.course_name
                            ,courses.credittype
                            ,courses.course_number
                            ,courses.course_name || ': ' || sections.section_number AS enr_hash
                      FROM cc
                      JOIN courses 
                        ON cc.course_number = courses.course_number
                       AND courses.credittype != 'COCUR'
                       AND courses.credittype != 'WLANG'
                      JOIN sections@PS_TEAM
                        ON cc.sectionid = sections.id
                      WHERE cc.schoolid = 73252 
                        AND cc.termid >= 2200
                        ) enrollments
                    ON sub_1.ps_id = enrollments.studentid
                   AND sub_1.credit_join = enrollments.credittype
                  ) sub_2
            WHERE best_prev_rit IS NOT NULL
              AND sub_2.subject NOT IN ('General Science', 'Concepts and Processes')
            GROUP BY sub_2.grade_level
                    ,sub_2.subject
                    ,CUBE(sub_2.iep_status
                         ,sub_2.match_course)
            ) sub_3
      LEFT OUTER JOIN kipp_nwk.map_rit_mean_sd norms
              ON norms.subject = sub_3.subject
             AND norms.grade = sub_3.grade_level
             AND norms.term = 'Spring-to-Spring'
      WHERE (sub_3.iep_status = 'IEP' AND sub_3.course = 'Whole Grade') 
         OR sub_3.iep_status = 'All Students'
      ORDER BY sub_3.subject
              ,sub_3.grade_level
              ,DECODE(sub_3.course, 'Whole Grade', 1, 99) ASC
              ,sub_3.iep_status
      ) sub_4
LEFT OUTER JOIN (
      SELECT *
      FROM 
           (SELECT z.zscore
                  ,z.percentile
            FROM
                 (SELECT zscore
                        ,percentile
                        ,row_number() OVER
                           (PARTITION BY percentile
                               ORDER BY zscore ASC
                            ) AS rn
                  FROM ZSCORES
                  WHERE percentile IN (1,5,10,20,25,30,40,50,60,70,75,80,90,95,99)
                  ) z
            WHERE rn = 1 
            )
      S PIVOT (MAX(zscore) AS zscore
                 FOR percentile IN (
                   '1'  p01
                  ,'5'  p05
                  ,'10' p10
                  ,'20' p20
                  ,'25' p25
                  ,'30' p30
                  ,'40' p40
                  ,'50' p50
                  ,'60' p60
                  ,'70' p70
                  ,'75' p75
                  ,'80' p80
                  ,'90' p90
                  ,'95' p95
                  ,'99' p99
                 )
              )
) norm_dist ON 1=1
WHERE closest_match = 1