--enrollment for past 3 years
SELECT school
      ,sch_year
      ,n
      ,sch_year || ': ' || N AS display
FROM
     (SELECT schools.abbreviation AS school
            ,cohort.abbreviation AS sch_year
            ,COUNT(*) AS N
      FROM cohort$comprehensive_long cohort
      JOIN schools@PS_TEAM
        ON cohort.schoolid = schools.school_number
      WHERE schoolid != 999999
        AND rn =1
        AND exitdate - entrydate > 5
        AND year > 2008
      GROUP BY cube(schools.abbreviation)
              ,cohort.abbreviation
      ORDER BY schools.abbreviation
              ,cohort.abbreviation
      )

;
     
--farm previous
SELECT sub_2.*
      ,sch_year || ': ' || farm AS display
FROM
     (SELECT school
            ,sch_year
            ,ROUND(AVG(farm) * 100,1) AS farm
      FROM
            --2012
           (SELECT schools.abbreviation AS school
                  ,'12-13' AS sch_year
                  ,CASE
                     WHEN s.lunchstatus IN ('F','R','f','r') THEN 1
                     ELSE 0
                   END AS farm
            FROM students s
            JOIN schools@PS_TEAM
              ON s.schoolid = schools.school_number
            WHERE s.schoolid != 999999
              AND s.enroll_status = 0            
            UNION ALL
            --2011
            SELECT schools.abbreviation AS school
                  ,cohort.abbreviation AS sch_year
                  ,CASE
                     WHEN ps_customfields.getcf@PS_TEAM('Students',s.id,'Lunch_Status_1112') IN ('F','R','f','r') THEN 1
                     ELSE 0
                   END AS farm
            FROM cohort$comprehensive_long cohort
            JOIN schools@PS_TEAM
              ON cohort.schoolid = schools.school_number
            JOIN students s
              ON cohort.studentid = s.id
            WHERE cohort.schoolid != 999999
              AND rn = 1
              AND cohort.exitdate - cohort.entrydate > 5
              AND cohort.year = 2011
            
            UNION ALL
            --2010
            SELECT schools.abbreviation AS school
                  ,cohort.abbreviation AS sch_year
                  ,CASE
                     WHEN ps_customfields.getcf@PS_TEAM('Students',s.id,'Lunch_Status_1011') IN ('F','R','f','r') THEN 1
                     ELSE 0
                   END AS farm
            FROM cohort$comprehensive_long cohort
            JOIN schools@PS_TEAM
              ON cohort.schoolid = schools.school_number
            JOIN students s
              ON cohort.studentid = s.id
            WHERE cohort.schoolid != 999999
              AND rn = 1
              AND cohort.exitdate - cohort.entrydate > 5
              AND cohort.year = 2010
            
            UNION ALL
            --2009
            SELECT schools.abbreviation AS school
                  ,cohort.abbreviation AS sch_year
                  ,CASE
                     WHEN ps_customfields.getcf@PS_TEAM('Students',s.id,'Lunch_Status_0910') IN ('F','R','f','r') THEN 1
                     ELSE 0
                   END AS farm
            FROM cohort$comprehensive_long cohort
            JOIN schools@PS_TEAM
              ON cohort.schoolid = schools.school_number
            JOIN students s
              ON cohort.studentid = s.id
            WHERE cohort.schoolid != 999999
              AND rn = 1
              AND cohort.exitdate - cohort.entrydate > 5
              AND cohort.year = 2009
            ) sub_1
      GROUP BY CUBE(school)
              ,sch_year
      ORDER BY school
              ,sch_year
      ) sub_2
;
--farm THIS year
SELECT school
      ,sch_year
      ,ROUND(AVG(farm)*100, 1) AS farm
FROM
      (SELECT schools.abbreviation AS school
            ,'12-13' AS sch_year
            ,CASE
               WHEN s.lunchstatus IN ('F','R','f','r') THEN 1
               ELSE 0
             END AS farm
      FROM students s
      JOIN schools@PS_TEAM
        ON s.schoolid = schools.school_number
      WHERE s.schoolid != 999999
        AND s.enroll_status = 0            
      ) sub_1
GROUP BY school
        ,sch_year

;

--ethnicity for past three years     
SELECT sub_2.*
      ,sch_year || ': ' || ethnic_pct || '%' AS display
FROM
     (SELECT school
            ,sch_year
            ,ROUND(AVG(two_or_more_dummy) * 100, 0) AS ethnic_pct
            ,COUNT(*) AS N
      FROM
           (SELECT schools.abbreviation AS school
                  ,cohort.abbreviation AS sch_year
                  ,CASE
                     WHEN s.ethnicity = 'B' THEN 1
                     ELSE 0
                   END AS black_dummy
                  ,CASE
                     WHEN s.ethnicity = 'H' THEN 1
                     ELSE 0
                   END AS hispanic_dummy
                  ,CASE
                     WHEN s.ethnicity = 'W' THEN 1
                     ELSE 0
                   END AS white_dummy
                  ,CASE
                     WHEN s.ethnicity = 'A' THEN 1
                     ELSE 0
                   END AS asian_dummy
                  ,CASE
                     WHEN s.ethnicity = 'T' THEN 1
                     ELSE 0
                   END AS two_or_more_dummy
            FROM cohort$comprehensive_long cohort
            JOIN schools@PS_TEAM
              ON cohort.schoolid = schools.school_number
            JOIN students s
              ON cohort.studentid = s.id
            WHERE cohort.schoolid != 999999
              AND rn = 1
              AND cohort.exitdate - cohort.entrydate > 5
              AND cohort.year > 2008
            ) sub_1
      GROUP BY CUBE(school)
              ,sch_year
      ORDER BY school
              ,sch_year
      ) sub_2
;

--
SELECT sub_2.*
      ,sch_year || ': ' || sped_pct || '%' AS display
FROM
     (SELECT school
            ,sch_year
            ,ROUND(AVG(sped_dummy) * 100, 0) AS sped_pct
            ,COUNT(*) AS N
      FROM
           (SELECT schools.abbreviation AS school
                  ,cohort.abbreviation AS sch_year
                  ,CASE
                     WHEN cust.spedlep LIKE 'SPED%' THEN 1
                     ELSE 0
                   END AS sped_dummy
            FROM cohort$comprehensive_long cohort
            JOIN schools@PS_TEAM
              ON cohort.schoolid = schools.school_number
            JOIN students s
              ON cohort.studentid = s.id
            JOIN custom_students cust
              ON s.id = cust.studentid
            WHERE cohort.schoolid != 999999
              AND rn = 1
              AND cohort.exitdate - cohort.entrydate > 5
              AND cohort.year > 2008
            ) sub_1
      GROUP BY CUBE (school)
              ,sch_year
      ORDER BY school
              ,sch_year
      ) sub_2

;

--NJASK by year and school

SELECT *
FROM
     (SELECT test_year
            ,decode(grouping(subject),0,subject,'total') AS subject
            ,decode(grouping(school),0,school || '','total') AS school
            ,decode(grouping(grade),0,grade || '','total') AS grade
            ,ROUND(AVG(not_proficient_dummy)*100,1) AS pct_not_proficient
            ,ROUND(AVG(proficient_dummy)*100,1) AS pct_proficient
            ,ROUND(AVG(adv_proficient_dummy)*100,1) AS pct_adv_proficient
            ,COUNT(*) AS N
      FROM
            (SELECT njask.subject
                  ,CASE 
                     WHEN njask.test_schoolid = 73252 THEN 'Rise'
                     WHEN njask.test_schoolid = 133570965 THEN 'TEAM'
                   END AS school
                  ,njask.test_grade_level AS grade
                  ,njask_scale_score
                  ,CASE
                     WHEN njask_scale_score < 200 THEN 1
                     ELSE 0
                   END AS not_proficient_dummy                  
                  ,CASE
                     WHEN njask_scale_score >= 200 AND njask_scale_score < 250 THEN 1
                     ELSE 0
                   END AS proficient_dummy
                  ,CASE
                     WHEN njask_scale_score >= 250 THEN 1
                     ELSE 0
                   END AS adv_proficient_dummy
                  ,to_char(test_date, 'YYYY') - 1 AS test_year
            FROM njask$detail njask
            --JOIN schools@PS_TEAM
            --  ON njask.test_schoolid = schools.school_number
            WHERE njask_scale_score > 0
              AND njask.subject != 'Science'
              AND test_date > '01-JAN-12'
            )
      WHERE test_year >= 2009
      GROUP BY test_year
              ,subject
              ,CUBE(school
                   ,grade)
      ORDER BY test_year
              ,subject
              ,school
              ,grade
      )
ORDER BY test_year
        ,decode(subject, 'total', 1, 'Math', 2, 'ELA', 3)
        ,decode(school, 'total', 1, 'TEAM', 2, 'Rise', 3)
        ,decode(grade, 'total', 1, '5',10, '6',11, '7', 12, '8', 13)

;
--pct of growth goal
SELECT decode(grouping(schoolid),0,schoolid,'network') AS school
      ,map_year_academic
      ,measurementscale
      ,grade_level
      ,ROUND(AVG(pct_of_goal),2) AS avg_pct_of_goal
FROM
      (SELECT measurementscale
            ,to_char(schoolid) AS schoolid
            ,map_year_academic
            ,grade_level
            ,matched_fall2spring_growth/matched_fall2spring_gr_goal AS pct_of_goal
      FROM map$comprehensive_with_growth map
      WHERE fallwinterspring = 'Spring'
        AND rn = 1
        AND stu_year_in_network = 1
      UNION ALL
      SELECT measurementscale
            ,to_char(schoolid) AS schoolid
            ,map_year_academic
            ,grade_level
            ,matched_spring2spring_growth/matched_spring2spring_gr_goal AS pct_of_goal
      FROM map$comprehensive_with_growth map
      WHERE fallwinterspring = 'Spring'
        AND rn = 1
        AND stu_year_in_network > 1
      ) sub_1
WHERE pct_of_goal IS NOT NULL
GROUP BY CUBE(schoolid)
      ,map_year_academic
      ,measurementscale
      ,grade_level
ORDER BY measurementscale
        ,school
        ,grade_level
        ,map_year_academic
        
;