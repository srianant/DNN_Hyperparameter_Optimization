USE KIPP_NJ
GO

DECLARE @credittype AS VARCHAR(20) = 'MATH%'
       ,@measurementscale AS VARCHAR(20) = 'Mathematics'
       ,@termname AS VARCHAR(20) = 'Fall 2013-2014';


WITH roster AS
  (SELECT s.id AS studentid
         ,s.student_number
         ,s.grade_level
         ,s.lastfirst
         ,s.team
         ,s.schoolid
   FROM students s
   WHERE s.enroll_status = 0
   )
  
  ,enrollments AS
  (SELECT cc.termid AS termid
         ,cc.studentid
         ,sections.id AS sectionid
         ,sections.section_number
         ,courses.course_number
         ,courses.course_name
   FROM cc
   JOIN sections
     ON cc.sectionid = sections.id
    AND cc.termid >= 2300
   JOIN courses
     ON sections.course_number = courses.course_number
    AND courses.credittype LIKE @credittype
   WHERE cc.dateenrolled <= GETDATE()
	    AND cc.dateleft >= GETDATE()
  )

SELECT roster.*
      ,enrollments.*
      ,map.*
FROM roster

LEFT OUTER JOIN enrollments
  ON roster.studentid = enrollments.studentid

LEFT OUTER JOIN MAP$comprehensive#identifiers map
  ON CAST(roster.student_number AS NVARCHAR) = map.StudentID
 AND map.measurementscale LIKE @measurementscale
 AND map.TermName = @termname
 AND map.rn = 1

WHERE roster.schoolid = 73252
  AND roster.grade_level = 5
ORDER BY roster.grade_level
        ,enrollments.section_number
        ,roster.lastfirst

