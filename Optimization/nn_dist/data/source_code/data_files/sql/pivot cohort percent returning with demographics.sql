USE KIPP_NJ
GO

WITH attrition_test AS
   (SELECT c.studentid
		  ,c.year
		  ,c.grade_level
		  ,c_next.grade_level AS next_grade_level
		  ,c.exitcode
		  ,CASE
			 --grad flag
			 WHEN c.exitcode = 'G1' OR c_next.grade_level = 99 THEN 1
			 --if there's a value in next year grade level, code as good
			 WHEN c_next.grade_level IS NOT NULL THEN 1
			 --any missing data = student gone.
			 WHEN c_next.grade_level IS NULL THEN 0
		   END AS attr_flag
	FROM COHORT$comprehensive_long#static c
	JOIN students s
	  ON c.studentid = s.id
	 --AND s.gender = 'M'
	 AND s.ethnicity = 'B'
	LEFT OUTER JOIN COHORT$comprehensive_long#static c_next
	  ON c.studentid = c_next.studentid
	 AND c.year + 1 = c_next.year
	 AND c_next.rn = 1
	 AND c.year < 2013
	 --student needs to have made it to 10-15 in next school year
	 AND c_next.exitdate > CAST(CAST(c_next.year AS varchar) + '-' + CAST(10 AS varchar) + '-' + CAST(15 AS varchar) AS DATETIME)
	WHERE c.year > 2004
	  AND c.schoolid != 999999
	  AND c.rn = 1
	  AND DATEDIFF(day, c.entrydate, c.exitdate) > 30
	)
SELECT *
FROM
	   (SELECT year
			  ,CASE GROUPING(grade_level)
				 WHEN 1 THEN 'network'
				 ELSE 
				   CASE 
				     WHEN grade_level < 10 THEN '0' + CAST(grade_level AS NVARCHAR)
				     ELSE CAST(grade_level AS NVARCHAR)
				   END
			   END AS grade_level 
			  ,CAST(ROUND(AVG(attr_flag + 0.0) * 100,0) AS INT) AS pct_return_or_grad
		FROM attrition_test
		GROUP BY year
				,CUBE(grade_level)
		) sub
PIVOT (MAX(pct_return_or_grad) FOR year in ([2004],[2005],[2006],[2007],[2008],[2009],[2010],[2011],[2012])) as AvgIncomePerDay
--PIVOT (pct_return_or_grad FOR year in ([2004],[2005],[2006],[2007],[2008],[2009],[2010],[2011],[2012])) as AvgIncomePerDay