SELECT --converting our school IDs to foundation IDs
       CASE
         WHEN decode.schoolid = 133570965 THEN 9
         WHEN decode.schoolid = 73252     THEN 52
         WHEN decode.schoolid = 73253     THEN 63
         WHEN decode.schoolid = 73254     THEN 86
       END AS school_id
      ,s.student_number AS student_id
      ,s.first_name
      ,s.middle_name
      ,s.last_name
      ,decode.grade_level
      ,CASE
         WHEN lower(s.ethnicity) = 'i' THEN 1
         WHEN lower(s.ethnicity) = 'a' THEN 2
         WHEN lower(s.ethnicity) = 'b' THEN 3
         WHEN lower(s.ethnicity) = 'h' THEN 4
         WHEN lower(s.ethnicity) = 'p' THEN 5
         WHEN lower(s.ethnicity) = 'w' THEN 6
         WHEN lower(s.ethnicity) = 't' THEN 9
       END AS race_id
      ,s.gender
      ,s.dob
      ,'U' AS free_reduced_lunch
      --specific to our setup/fields, YMMMV
      ,CASE
         WHEN ps_customfields.getcf('Students',ID,'SPEDLEP') LIKE 'SPED%' 
           THEN 'Y'
         ELSE 'N'
       END AS special_needs
      --date of student's first entry to *school of this enr*
      ,first_enr.first_entry AS entry_date
      ,CASE
         --null for all kids who were here on Oct 1 of this year
         WHEN s.exitdate > '01-OCT-12' THEN NULL
         ELSE s.exitdate
       END AS exit_date
      ,CASE
         WHEN decode.cur_year_status = 'Graduated' THEN 1
         ELSE 0
       END AS graduation
      --leave blank 
        --TEAM captures this info on a separate tracker
      ,NULL AS exit_reason
      --get exit information for students who left
      ,CASE
         --null for all kids who were here on Oct 1 of this year
         WHEN s.exitdate > '01-OCT-12' THEN NULL
         ELSE s.exitcomment
       END AS exit_comment_1
      ,CASE
         --null for all kids who were here on Oct 1 of this year
         WHEN s.exitdate > '01-OCT-12' THEN NULL
         ELSE s.exitcode
       END AS exit_comment_2
FROM
     (SELECT denom.*
            ,CASE
               --handle last year's graduated students properly
               WHEN denom.exitcode = 'G1'
                 THEN 'Graduated'
               WHEN this_year.studentid IS NOT NULL
                 THEN 'Returned'
               WHEN this_year.studentid IS NULL
                 THEN 'Left'
             END AS cur_year_status
      FROM
            --everyone in the school who was active on 
            --october 1st, PRIOR year
           (SELECT studentid
                  ,schoolid
                  ,entrydate
                  ,exitdate
                  ,exitcode
                  ,grade_level
              --a SIS view that has all enrollment records
            FROM pssis_enrollment_all
              --21 is year code for 2011
            WHERE yearid = 21
              --active on october 1, 2011
              AND entrydate <= '1-OCT-2011'
              AND exitdate  >  '1-OCT-2011'
              --exclude students in the 'graduated students' school
                --nb, if you use a pre-enrollment school or a summer school
                --may want to exclude those here as well...
              AND grade_level != 99
            ) denom
      LEFT OUTER JOIN
             --everyone in the school who was active on 
             --october 1st THIS year
           (SELECT studentid
                  ,schoolid
                  ,entrydate
                  ,exitdate
                  ,grade_level
            FROM pssis_enrollment_all
            WHERE yearid = 22
              AND entrydate <= '1-OCT-2012'
              AND exitdate  >  '1-OCT-2012'
              AND grade_level != 99
            ) this_year
        ON denom.studentid = this_year.studentid    
      ) decode
JOIN students s
  ON decode.studentid = s.ID
JOIN 
     (SELECT studentid
            ,schoolid
            ,MIN(entrydate) AS first_entry
      FROM pssis_enrollment_all
      WHERE schoolid != 999999
      GROUP BY studentid
              ,schoolid
     ) first_enr
  ON decode.studentid = first_enr.studentid
  AND decode.schoolid = first_enr.schoolid
--WHERE decode.studentid = 59
ORDER BY s.exitdate ASC