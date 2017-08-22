--cube and drop audit detail
SELECT decode(GROUPING(school),0,to_char(school),'network') AS school
      ,decode(GROUPING(year),0,to_char(year),'all years') AS year
      ,ROUND(AVG(reenroll_dummy)*100,1) AS reenroll_pct
      ,ROUND(AVG(male_transf_dummy)*100,0) AS male_transf_pct
      ,ROUND(AVG(female_transf_dummy)*100,0) AS female_transf_pct
      ,100 - ROUND(AVG(reenroll_dummy)*100,1) AS attr_pct
      --,ROUND(AVG(math_scale_leavers),1) AS math_scale_leavers
      --,ROUND(AVG(math_scale_stayers),1) AS math_scale_stayers
      --,ROUND(AVG(ela_scale_leavers),1) AS ela_scale_leavers
      --,ROUND(AVG(ela_scale_stayers),1) AS ela_scale_stayers
      ,COUNT(*) AS N
      --,listagg(attr_detail, ', ') WITHIN GROUP 
      --   (ORDER BY lastfirst) AS audit_detail
FROM
      (SELECT reenroll.*
            ,CASE
               WHEN reenroll.reenroll_dummy = 0 THEN short_name
               ELSE null
             END AS attr_detail
            ,CASE
               WHEN reenroll.gender = 'M' AND reenroll_dummy = 0 THEN 1
               ELSE 0
             END AS male_transf_dummy
            ,CASE
               WHEN reenroll.gender = 'F' AND reenroll_dummy = 0 THEN 1
               ELSE 0
             END AS female_transf_dummy
            ,CASE
               WHEN reenroll.reenroll_dummy = 0 THEN math_scale
               ELSE null
             END AS math_scale_leavers
            ,CASE
               WHEN reenroll.reenroll_dummy != 0 THEN math_scale
               ELSE null
             END AS math_scale_stayers
            ,CASE
               WHEN reenroll.reenroll_dummy = 0 THEN ela_scale
               ELSE null
             END AS ela_scale_leavers
            ,CASE
               WHEN reenroll.reenroll_dummy != 0 THEN ela_scale
               ELSE null
             END AS ela_scale_stayers

      FROM 
           (SELECT base.studentid
                  ,base.lastfirst
                  ,SUBSTR(students.first_name,1,1) || ' ' || students.last_name AS short_name
                  ,base.grade_level
                  ,base.year
                  ,students.gender
                  ,schools.abbreviation AS school
                  ,to_char(base.exitdate,'MON') AS exit_month
                  ,CASE
                     WHEN base.exitcode = 'G1' 
                       OR (base.grade_level = 8 AND to_char(base.exitdate,'MON') = 'JUN') THEN 1
                     WHEN next.year IS NOT NULL THEN 1
                     ELSE 0
                   END AS reenroll_dummy
                  ,next.grade_level AS grade_plus_1
                  ,next.year AS year_plus_1
                  ,njask_math.njask_scale_score AS math_scale
                  ,njask_ela.njask_scale_score AS ela_scale
            FROM cohort$comprehensive_long base
            JOIN students ON base.studentid = students.id
            JOIN schools@PS_TEAM on base.schoolid = schools.school_number
            LEFT OUTER JOIN njask$detail njask_math
              ON base.studentid = njask_math.njask_studentid
             AND base.year = njask_math.test_year
             AND njask_math.subject = 'Math'
            LEFT OUTER JOIN njask$detail njask_ela
              ON base.studentid = njask_ela.njask_studentid
             AND base.year = njask_ela.test_year
             AND njask_ela.subject = 'ELA'
            --left outer keeps all base records even if no matching next year record is found
            LEFT OUTER JOIN cohort$comprehensive_long next
             --same studentd 
              ON base.studentid = next.studentid
             --next academic year
             AND next.year = base.year + 1
             --evaluate canonical record from next year result set
             AND next.rn = 1
            --canonical record from base and don't include graduated students
            WHERE base.rn = 1 AND base.schoolid != 999999 AND base.year < 2013
            ) reenroll
      ) audit_detail
--WHERE year = 2012
GROUP BY CUBE(school
             ,year
             )
ORDER BY decode(school, 'network', 10
                        ,'TEAM'   , 20
                        ,'Rise'   , 30
                        ,'NCA'    , 40
                        ,'SPARK'  , 50
                        ,'THRIVE' , 60
               )
        ,YEAR DESC
        
;
--no cube, keep audit detail
SELECT school
      ,year
      ,ROUND(AVG(reenroll_dummy)*100,0) AS reenroll_pct
      ,100 - ROUND(AVG(reenroll_dummy)*100,0) AS attr_pct
      ,COUNT(*) AS N
      ,listagg(attr_detail, ', ') WITHIN GROUP 
         (ORDER BY lastfirst) AS audit_detail
FROM
      (SELECT reenroll.*
            ,CASE
               WHEN reenroll.reenroll_dummy = 0 THEN short_name
               ELSE null
             END AS attr_detail
      FROM 
           (SELECT base.studentid
                  ,base.lastfirst
                  ,SUBSTR(students.first_name,1,1) || ' ' || students.last_name AS short_name
                  ,base.grade_level
                  ,base.year
                  ,schools.abbreviation AS school
                  ,to_char(base.exitdate,'MON') AS exit_month
                  ,CASE
                     WHEN base.exitcode = 'G1' 
                       OR (base.grade_level = 8 AND to_char(base.exitdate,'MON') = 'JUN') THEN 1
                     WHEN next.year IS NOT NULL THEN 1
                     ELSE 0
                   END AS reenroll_dummy
                  ,next.grade_level AS grade_plus_1
                  ,next.year AS year_plus_1
            FROM cohort$comprehensive_long base
            JOIN students ON base.studentid = students.id
            JOIN schools@PS_TEAM on base.schoolid = schools.school_number
            --left outer keeps all base records even if no matching next year record is found
            LEFT OUTER JOIN cohort$comprehensive_long next
             --same studentd 
              ON base.studentid = next.studentid
             --next academic year
             AND next.year = base.year + 1
             --evaluate canonical record from next year result set
             AND next.rn = 1
            --canonical record from base and don't include graduated students
            WHERE base.rn = 1 AND base.schoolid != 999999 AND base.year < 2012
            ) reenroll
      ) audit_detail
WHERE school = 'Rise'
GROUP BY school
        ,year
ORDER BY school
        ,year DESC