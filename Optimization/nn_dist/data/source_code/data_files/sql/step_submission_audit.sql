WITH roster AS

   (SELECT id AS studentid
          ,grade_level
          ,team
          ,lastfirst
          ,first_name + ' ' + last_name AS name
    FROM KIPP_NJ..students
    WHERE schoolid = 73254
      AND enroll_status = 0
      --AND team = 'Michigan'
    )

SELECT *
FROM
      (SELECT roster.*
             ,DATEDIFF(d, step.date_taken, GETDATE()) AS tested_days_ago
             ,step.date_taken
             ,step.step_level
             ,step.status
             ,ROW_NUMBER() OVER
                (PARTITION BY roster.studentid
                 ORDER BY step.date_taken DESC) AS rn
       FROM roster
       LEFT OUTER JOIN KIPP_NJ..LIT$step_headline_long#identifiers step
         ON roster.studentid = step.STUDENTID
        --AND step.DATE_TAKEN >= '01-06-13'
        AND DATEDIFF(d, step.DATE_TAKEN, GETDATE()) <= 45
       ) sub
WHERE sub.step_level IS NULL
ORDER BY sub.grade_level
        ,sub.team
        ,sub.lastfirst