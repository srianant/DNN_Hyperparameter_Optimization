SELECT subject
      ,grade_level
      ,summer_2010_avg_change
      ,summer_2011_avg_change
      ,ROUND(((summer_2011_avg_change - summer_2010_avg_change) / ABS(summer_2010_avg_change))*100,0) AS pct_improvement
FROM
     (SELECT subject
            ,grade_level
            ,'Summer ' || summer_yr AS summer_yr 
            ,ROUND(AVG(summer_change_RIT),2) AS avg_change
      FROM
           (SELECT fall_base.studentid
                  ,fall_base.grade_level
                  ,fall_base.subject
                  ,fall_base.map_year_academic AS summer_yr
                  ,fall_base.fall_rit
                  ,fall_base.fall_percentile
                  ,spring_match.spr_rit
                  ,spring_match.spr_percentile
                  ,fall_base.fall_rit - spring_match.spr_rit AS summer_change_RIT
                  ,fall_base.fall_percentile - spring_match.spr_percentile AS summer_change_pctle
            FROM
                 (SELECT cohort.studentid
                        ,cohort.grade_level
                        ,map.measurementscale AS subject
                        ,map.fallwinterspring
                        ,map.map_year_academic
                        ,map.testritscore AS fall_rit
                        ,map.percentile_2011_norms AS fall_percentile 
                  FROM map$comprehensive_identifiers map
                  JOIN cohort$comprehensive_long cohort
                    ON map.ps_studentid = cohort.studentid
                    AND map.map_year_academic = cohort.year
                    AND cohort.rn = 1
                    AND cohort.schoolid = 73254
                  WHERE map.fallwinterspring = 'Fall'
                    AND map.rn = 1
                  ) fall_base
            JOIN (SELECT cohort.studentid
                        ,map.measurementscale AS subject
                        ,map.fallwinterspring
                        ,map.map_year_academic
                        ,map.testritscore AS spr_rit
                        ,map.percentile_2011_norms AS spr_percentile
                  FROM map$comprehensive_identifiers map
                  JOIN cohort$comprehensive_long cohort
                    ON map.ps_studentid = cohort.studentid
                    AND map.map_year_academic = cohort.year
                    AND cohort.rn = 1
                    AND cohort.schoolid = 73254
                  WHERE map.fallwinterspring = 'Spring'
                    AND map.rn = 1
                  ) spring_match
            ON fall_base.studentid = spring_match.studentid
            AND fall_base.subject = spring_match.subject
            AND (fall_base.map_year_academic - spring_match.map_year_academic) = 1
            ) matched
      GROUP BY subject
              ,grade_level
              ,summer_yr
      )
S PIVOT (MAX(avg_change) AS avg_change
         FOR summer_yr IN ('Summer 2010' Summer_2010
                          ,'Summer 2011' Summer_2011
                          )
        )
ORDER BY subject
        ,grade_level