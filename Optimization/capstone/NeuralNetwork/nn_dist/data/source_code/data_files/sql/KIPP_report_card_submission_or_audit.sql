--REGION PROFILE QUERIES

--1. Student information
  --total student enrollment 2012-13
  SELECT COUNT(*)
  FROM students
  WHERE exitdate >= '01-NOV-12'
    AND entrydate <= '01-NOV-12';
  
  --eligible for free/reduced price lunch
    --
  SELECT ROUND(AVG(farm_dummy) * 100,1) AS farm_pct
  FROM
       (SELECT ID
              ,CASE
                 WHEN students.lunchstatus IN ('F','R','f','r') THEN 1
                 WHEN students.lunchstatus IN ('P','NoD') THEN 0
               END AS farm_dummy 
        FROM students
        WHERE exitdate >= '01-NOV-12'
          AND entrydate <= '01-NOV-12'
        );
  
  --% african american
  SELECT ROUND(AVG(eth_dummy) * 100,1) AS afam_pct
  FROM
       (SELECT ID
              ,CASE
                 WHEN lower(ethnicity) = 'b' THEN 1
                 ELSE 0
               END AS eth_dummy
        FROM students
        WHERE exitdate >= '01-NOV-12'
          AND entrydate <= '01-NOV-12'
        );
        
  --% hispanic
  SELECT ROUND(AVG(eth_dummy) * 100,1) AS hisp_pct
  FROM
       (SELECT ID
              ,CASE
                 WHEN lower(ethnicity) = 'h' THEN 1
                 ELSE 0
               END AS eth_dummy
        FROM students
        WHERE exitdate >= '01-NOV-12'
          AND entrydate <= '01-NOV-12'
        );

  --% asian
  SELECT ROUND(AVG(eth_dummy) * 100,1) AS asian_pct
  FROM
       (SELECT ID
              ,CASE
                 WHEN lower(ethnicity) = 'a' THEN 1
                 ELSE 0
               END AS eth_dummy
        FROM students
        WHERE exitdate >= '01-NOV-12'
          AND entrydate <= '01-NOV-12'
        );
  
  --% caucasian
  SELECT ROUND(AVG(eth_dummy) * 100,1) AS w_pct
  FROM
       (SELECT ID
              ,CASE
                 WHEN lower(ethnicity) = 'w' THEN 1
                 ELSE 0
               END AS eth_dummy
        FROM students
        WHERE exitdate >= '01-NOV-12'
          AND entrydate <= '01-NOV-12'
        );
        
  --% other
  SELECT ROUND(AVG(eth_dummy) * 100,1) AS other_pct
  FROM
       (SELECT ID
              ,CASE
                 WHEN lower(ethnicity) NOT IN ('b','h','a','w') THEN 1
                 ELSE 0
               END AS eth_dummy
        FROM students
        WHERE exitdate >= '01-NOV-12'
          AND entrydate <= '01-NOV-12'
        );
  ---% special needs
  --n.b. this uses a custom field in our PS students table
  SELECT ROUND(AVG(sped_dummy) * 100,1) AS sped_pct
  FROM
       (SELECT ID
              ,CASE
                 WHEN ps_customfields.getcf('Students',s.ID,'SPEDLEP') LIKE ('SPED%') THEN 1
                 ELSE 0
               END AS sped_dummy 
        FROM students s
        WHERE exitdate >= '01-NOV-12'
          AND entrydate <= '01-NOV-12'
        );
        
  --attrition
  --see: https://github.com/almartin82/sundry_requests/blob/master/attrition_returned_or_graduated.sql
 SELECT subject
       ,test_grade_level
       ,ROUND(AVG(advanced_dummy) * 100, 2) AS pct_adv
       ,ROUND(AVG(proficient_dummy) * 100, 2) AS pct_prof
       ,ROUND(AVG(partial_dummy) * 100, 2) AS pct_partial
  FROM
        (SELECT subject
              ,test_grade_level
              ,CASE
                 WHEN njask_scale_score >= 250 THEN 1
                 WHEN njask_scale_score <  250 THEN 0
               END AS advanced_dummy
              ,CASE
                 WHEN njask_scale_score >= 250 THEN 0
                 WHEN njask_scale_score >= 200 THEN 1
                 WHEN njask_scale_score <  200 THEN 0
               END AS proficient_dummy
              ,CASE
                 WHEN njask_scale_score >= 200 THEN 0
                 WHEN njask_scale_score <  200 THEN 1
               END AS partial_dummy
        FROM njask$detail
        WHERE test_year = 2011
        --any zeros are bad imports
        AND njask_scale_score != 0
        )
  GROUP BY subject
          ,test_grade_level
  ORDER BY subject
          ,test_grade_level;
          
  --2012 NRT MAP results (quartile)   
    --lesson learned - use the synthetic 2011 norm lookup,
    --not testpercentile - if you change a kids grade level *after* rosters are
    --submitted to MAP, their percentile will be off.
  SELECT subject
        ,grade_level
        ,grade_term
        ,ROUND(AVG(npr_1_24_dummy) * 100,0) AS npr_1_24
        ,ROUND(AVG(npr_25_49_dummy) * 100,0) AS npr_25_49
        ,ROUND(AVG(npr_50_74_dummy) * 100,2) AS npr_50_74
        ,ROUND(AVG(npr_75_99_dummy) * 100,0) AS npr_75_99
  FROM
       (SELECT measurementscale AS subject
              ,students.student_number
              ,map.lastfirst
              ,map.grade_level
              ,fallwinterspring || ' ' || map.grade_level AS grade_term
              ,testpercentile
              ,CASE
                 WHEN percentile_2011_norms >= 1 AND percentile_2011_norms < 25 THEN 1
                 ELSE 0
               END AS npr_1_24_dummy
              ,CASE
                 WHEN percentile_2011_norms >= 25 AND percentile_2011_norms < 50 THEN 1
                 ELSE 0
               END AS npr_25_49_dummy
              ,CASE
                 WHEN percentile_2011_norms >= 50 AND percentile_2011_norms < 75 THEN 1
                 ELSE 0
               END AS npr_50_74_dummy
              ,CASE
                 WHEN percentile_2011_norms >= 75 AND percentile_2011_norms < 101 THEN 1
                 ELSE 0
               END AS npr_75_99_dummy
        FROM map$comprehensive_with_growth map
        JOIN students
          ON map.ps_studentid = students.id
        WHERE map_year_academic = 2012
          AND measurementscale IN ('Mathematics','Reading')
          AND fallwinterspring != 'Winter'
          AND rn = 1
        )
    GROUP BY subject
            ,grade_level
            ,grade_term
    ORDER BY subject
            ,grade_level
            ,grade_term;        
  
  --2012 MAP results (making 1+ year...)
  SELECT measurementscale
        ,school_type
        ,ROUND(AVG(met_fall2spring_growth_goal) * 100,2) AS pct_meeting_f2s
  FROM
       (SELECT measurementscale
              ,grade_level
              ,CASE
                 WHEN grade_level >= 5 AND grade_level <= 8 THEN 'M'
                 WHEN grade_level < 5 THEN 'E'
               END AS school_type
              ,met_fall2spring_growth_goal
        FROM map$comprehensive_with_growth
        WHERE map_year_academic = 2011
          AND rn = 1
          AND measurementscale IN ('Mathematics','Reading')
          AND termname = 'Spring 2012')
  GROUP BY measurementscale
          ,school_type;
  
  --mike h's grade level submission format
  SELECT school
        ,school_display_name
        ,grade_level
        ,COUNT(*) AS total_students
        ,SUM(male_dummy) AS male
        ,SUM(female_dummy) AS female
        ,SUM(white_dummy) AS white
        ,SUM(black_dummy) AS black
        ,SUM(latino_dummy) AS latino
        ,SUM(asian_dummy) AS asian
        ,SUM(native_dummy) AS NATIVE
        ,SUM(two_races_dummy) AS two_races
        ,SUM(special_needs_dummy) AS special_needs
        ,SUM(free_meals_dummy) AS free_meals
        ,SUM(reduced_meals_dummy) AS reduced_meals
  FROM
       (SELECT schools.abbreviation AS school
              ,schools.name AS school_display_name
              ,grade_level
              ,CASE
                 WHEN students.gender = 'M' THEN 1
                 ELSE 0
               END AS male_dummy
              ,CASE
                 WHEN students.gender = 'F' THEN 1
                 ELSE 0
               END AS female_dummy
              ,CASE
                 WHEN LOWER(students.ethnicity) = 'w' THEN 1
                 ELSE 0
               END AS white_dummy
              ,CASE
                 WHEN LOWER(students.ethnicity) = 'b' THEN 1
                 ELSE 0
               END AS black_dummy
              ,CASE
                 WHEN LOWER(students.ethnicity) = 'h' THEN 1
                 ELSE 0
               END AS latino_dummy
              ,CASE
                 WHEN LOWER(students.ethnicity) = 'a' THEN 1
                 ELSE 0
               END AS asian_dummy
              ,CASE
                 WHEN LOWER(students.ethnicity) = 'i' THEN 1
                 ELSE 0
               END AS native_dummy
              ,CASE
                 WHEN LOWER(students.ethnicity) = 't' THEN 1
                 ELSE 0
               END AS two_races_dummy
              --,demographic.lim_eng_prof AS ell_dummy
              ,CASE
                 WHEN custom_students.spedlep LIKE 'SPED%' THEN 1
                 ELSE 0
               END AS special_needs_dummy
              ,CASE
                 WHEN LOWER(students.lunchstatus) = 'f' THEN 1
                 ELSE 0
               END AS free_meals_dummy
              ,CASE
                 WHEN LOWER(students.lunchstatus) = 'r' THEN 1
                 ELSE 0
               END AS reduced_meals_dummy
        FROM students
        JOIN schools@PS_TEAM
          ON students.schoolid = schools.school_number
        --If you use the demographic table for state reporting, bring it 
        --in here:
        --JOIN demographic@PS_TEAM
          --ON students.id = demographic.studentid
        JOIN custom_students
          ON students.id = custom_students.studentid
        WHERE exitdate >= '01-NOV-12'
        AND entrydate <= '01-NOV-12'
        ) detail
  GROUP BY school
          ,school_display_name
          ,grade_level
  ORDER BY school_display_name
          ,grade_level
  ;
