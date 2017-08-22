SELECT decode(GROUPING(grade_level),0,to_char(grade_level),'total') AS grade
      ,round(avg(sri_lexile),0) AS avg_sri_lexile
      ,round(avg(map_lexile_score),0) AS avg_map_lexile
      ,round(avg(SRI_inside_MAP_range)*100,0) || '%' AS sri_inside_map_range
      ,round(avg(SRI_above_MAP)*100,0) || '%' AS sri_above_map
      ,round(avg(SRI_below_MAP)*100,0) || '%' AS sri_below_map
      ,ROUND(CORR(sri_lexile, map_lexile_score),2) as SRI_MAP_CORR
      ,ROUND(CORR(sri_percentile, map_percentile),2) as SRI_MAP_PCTILE_CORR
FROM
      (SELECT level_2.*
            ,CASE 
               WHEN sri_lexile >= map_lexile_min
                AND sri_lexile <= map_lexile_max THEN 1
               WHEN sri_lexile <  map_lexile_min
                 OR sri_lexile >  map_lexile_max THEN 0
               ELSE null
             END AS SRI_inside_MAP_range
            ,CASE
               WHEN sri_lexile >= map_lexile_score THEN 1
               WHEN sri_lexile <  map_lexile_score THEN 0
               ELSE null
             END AS SRI_above_MAP
            ,CASE
               WHEN sri_lexile >= map_lexile_score THEN 0
               WHEN sri_lexile <  map_lexile_score THEN 1
               ELSE null
             END AS SRI_below_MAP
      FROM
            (SELECT level_1.*
                  ,sri.lexile AS sri_lexile
                  ,sri.nce AS sri_percentile
                  ,TO_NUMBER(REPLACE(map.rittoreadingscore,'BR',0)) as MAP_lexile_score
                  ,TO_NUMBER(REPLACE(map.rittoreadingmin,'BR',0)) as MAP_lexile_min
                  ,TO_NUMBER(REPLACE(map.rittoreadingmax,'BR',0)) as MAP_lexile_max
                  ,map.testpercentile as MAP_percentile
            FROM
                 (SELECT last_name
                        ,first_name
                        ,lastfirst
                        ,grade_level
                        ,student_number
                        ,id as studentid
                  FROM KIPP_NWK.students
                  WHERE students.enroll_status = 0
                    AND students.schoolid = 73252
                  ) level_1
            LEFT OUTER JOIN SRI_TESTING_HISTORY sri 
              ON to_char(level_1.student_number) = sri.base_student_number
              AND sri.full_cycle_name = 'Summer School 11-12' AND sri.rn_cycle = 1
            LEFT OUTER JOIN MAP_COMPREHENSIVE_IDENTIFIERS map
             ON level_1.studentid = map.ps_studentid
             AND map.measurementscale = 'Reading'
             AND map.termname = 'Fall 2011'
             AND map.rn = 1
            ) level_2
      ) level_3
GROUP BY CUBE(grade_level)