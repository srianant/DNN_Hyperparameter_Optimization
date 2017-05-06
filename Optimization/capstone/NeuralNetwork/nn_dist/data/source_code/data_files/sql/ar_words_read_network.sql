SELECT *
FROM
     (SELECT ar.student_number
            ,students.lastfirst AS student
            ,students.grade_level AS grade
            ,schools.abbreviation AS school
            ,to_char(SUM(ar.iwordcount),'999,999,999') AS total_words
            ,SUM(ar.iwordcount) as words_numeric
            ,COUNT(*) AS N
      FROM AR_DETAIL_PASSED_1112 ar
      JOIN students 
        ON to_char(students.student_number) = ar.student_number
      JOIN schools@PS_TEAM
        ON students.schoolid = schools.school_number
      GROUP BY ar.student_number
              ,students.lastfirst
              ,students.grade_level
              ,schools.abbreviation
      )
--WHERE school = 'SPARK'
--WHERE school = 'Rise' AND words_numeric >= 900000 AND words_numeric < 1000000
ORDER BY total_words asc
