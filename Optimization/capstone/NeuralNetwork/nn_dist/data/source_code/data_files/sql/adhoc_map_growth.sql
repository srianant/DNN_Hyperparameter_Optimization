SELECT m.grade_level
      ,m.year
      ,sch.abbreviation
      ,CAST(ROUND(AVG(m.start_rit + 0.0), 1) AS float) AS avg_start_rit
      ,CAST(ROUND(AVG(m.end_rit + 0.0), 1) AS float) AS avg_end_rit
      ,CAST(ROUND(AVG(m.met_typical_growth_target + 0.0) * 100, 1) AS float) AS pct_met
      ,CAST(ROUND(AVG(m.growth_percentile + 0.0), 1) AS float) AS avg_SGP
      ,COUNT(*) AS n
FROM KIPP_NJ..MAP$growth_measures_long#static m
JOIN KIPP_NJ..SCHOOLS sch
  ON m.schoolid = sch.school_number
WHERE year IN (2012, 2013)
  AND measurementscale = 'Reading'
  AND grade_level = 5
  AND period_string = 'Fall to Spring'
  AND valid_observation = 1
GROUP BY m.grade_level
        ,m.year
        ,sch.abbreviation
ORDER BY m.year
        ,sch.abbreviation
       