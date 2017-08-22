select pathways
      ,count(student) as count 
      ,LTRIM(MAX(SYS_CONNECT_BY_PATH(student,' | ')) KEEP (DENSE_RANK LAST ORDER BY curr2),',') AS students      
from
      (select student
            ,pathways
            ,ROW_NUMBER() OVER (PARTITION BY pathways order by student) AS curr2
            ,ROW_NUMBER() OVER (PARTITION BY pathways order by student) -1 AS prev2
      from
            (SELECT student
                   ,grade_level
                   ,LTRIM(MAX(SYS_CONNECT_BY_PATH(hash,', ')) KEEP (DENSE_RANK LAST ORDER BY curr),',') AS pathways
            from       
                  (select student
                        ,course_number
                        ,grade_level
                        ,period
                        ,class || '|' || period as hash
                        ,ROW_NUMBER() OVER (PARTITION BY student ORDER BY period) AS curr
                        ,ROW_NUMBER() OVER (PARTITION BY student ORDER BY period) -1 AS prev
                  from
                       (select sched_cc.buildid
                              ,s.lastfirst as student
                              ,s.grade_level + 1 as grade_level
                              ,sched_cc.course_number
                              ,replace(replace(replace(replace(c.course_name,' '),'Free'),'High','Hi'),'Read','Rd') as class
                              ,substr(sched_cc.expression, 1, 1) as period
                        from schedulecc sched_cc
                        left outer join students s on sched_cc.studentid = s.id
                        left outer join courses c on sched_cc.course_number = c.course_number
                        where sched_cc.buildid = 55
                        order by student, period
                        )
                  )
            GROUP BY student, grade_level
            CONNECT BY prev = PRIOR curr AND student = PRIOR student
            START WITH curr = 1
            )
      order by pathways
              ,student
      )
GROUP BY pathways
CONNECT BY prev2 = PRIOR curr2 AND pathways = PRIOR pathways
START WITH curr2 = 1;



select pathway
      ,sum(dummy_count)
      ,wm_concat(student) as students
from
     (select student
            ,grade_level
            ,LISTAGG(class_hash, '|') WITHIN GROUP (ORDER BY grade_level) AS pathway
            ,case when grade_level > 0 then 1 else null end as dummy_count
            
      from
           (select student
                  ,course_number
                  ,grade_level
                  ,period
                  ,class || '|' || period AS class_hash
            from
                 (select sched_cc.buildid
                        ,s.lastfirst as student
                        ,s.grade_level + 1 as grade_level
                        ,sched_cc.course_number
                        ,replace(replace(replace(replace(c.course_name,' '),'Free'),'High','Hi'),'Read','Rd') as class
                        ,substr(sched_cc.expression, 1, 1) as period
                  from schedulecc sched_cc
                  left outer join students s on sched_cc.studentid = s.id
                  left outer join courses c on sched_cc.course_number = c.course_number
                  where sched_cc.buildid = 55
                  )
            )
      group by student
              ,grade_level
              ,period
      )
--where pathway like '%Math8Hi%'
group by pathway
order by pathway
;
SELECT gr_lev_pathway
      ,p1_course || ' | ' || p2_course || ' | ' || p3_course || ' | ' || p4_course || ' | ' || p5_course || ' | ' || p6_course AS pathway
      ,LEAST(p1_max, p2_max, p3_max, p4_max, p5_max, p6_max) AS max_seats
      ,LEAST(p1_avail, p2_avail, p3_avail, p4_avail, p5_avail, p6_avail) AS seats_remain
FROM
       (SELECT p_1.dept AS gr_lev_pathway
              ,p_1.course_name    AS p1_course
              ,p_1.no_of_students AS p1_count
              ,p_1.maxenrollment  AS p1_max
              ,p_1.seats_avail    AS p1_avail
              ,p_2.course_name    AS p2_course
              ,p_2.no_of_students AS p2_count
              ,p_2.maxenrollment  AS p2_max
              ,p_2.seats_avail    AS p2_avail
              ,p_3.course_name    AS p3_course
              ,p_3.no_of_students AS p3_count
              ,p_3.maxenrollment  AS p3_max
              ,p_3.seats_avail    AS p3_avail
              ,p_4.course_name    AS p4_course
              ,p_4.no_of_students AS p4_count
              ,p_4.maxenrollment  AS p4_max
              ,p_4.seats_avail    AS p4_avail
              ,p_5.course_name    AS p5_course
              ,p_5.no_of_students AS p5_count
              ,p_5.maxenrollment  AS p5_max
              ,p_5.seats_avail    AS p5_avail      
              ,p_6.course_name    AS p6_course
              ,p_6.no_of_students AS p6_count
              ,p_6.maxenrollment  AS p6_max
              ,p_6.seats_avail    AS p6_avail      
        FROM
             (SELECT sect.course_number
                    ,c.course_name
                    ,c.sched_department AS dept
                    ,SUBSTR(sect.expression,1,1) AS period
                    ,sect.no_of_students
                    ,sect.maxenrollment
                    ,sect.maxenrollment - sect.no_of_students AS seats_avail
              FROM schedulesections sect
              JOIN courses c on sect.course_number = c.course_number
              WHERE sect.buildid = 55
                AND SUBSTR(sect.expression,1,1) = 1
              ) p_1
        JOIN (SELECT sect.course_number
                    ,c.course_name
                    ,c.sched_department AS dept
                    ,SUBSTR(sect.expression,1,1) AS period
                    ,sect.no_of_students
                    ,sect.maxenrollment
                    ,sect.maxenrollment - sect.no_of_students AS seats_avail
              FROM schedulesections sect
              JOIN courses c on sect.course_number = c.course_number
              WHERE sect.buildid = 55
                AND SUBSTR(sect.expression,1,1) = 2
              ) p_2
          ON p_1.dept = p_2.dept
         AND p_1.course_number != p_2.course_number
        JOIN (SELECT sect.course_number
                    ,c.course_name
                    ,c.sched_department AS dept
                    ,SUBSTR(sect.expression,1,1) AS period
                    ,sect.no_of_students
                    ,sect.maxenrollment
                    ,sect.maxenrollment - sect.no_of_students AS seats_avail
              FROM schedulesections sect
              JOIN courses c on sect.course_number = c.course_number
              WHERE sect.buildid = 55
                AND SUBSTR(sect.expression,1,1) = 3
              ) p_3
          ON p_1.dept = p_3.dept
         AND p_1.course_number != p_3.course_number
         AND p_2.course_number != p_3.course_number
        JOIN (SELECT sect.course_number
                    ,c.course_name
                    ,c.sched_department AS dept
                    ,SUBSTR(sect.expression,1,1) AS period
                    ,sect.no_of_students
                    ,sect.maxenrollment
                    ,sect.maxenrollment - sect.no_of_students AS seats_avail
              FROM schedulesections sect
              JOIN courses c on sect.course_number = c.course_number
              WHERE sect.buildid = 55
                AND SUBSTR(sect.expression,1,1) = 4
              ) p_4
          ON p_1.dept = p_4.dept
          AND p_1.course_number != p_4.course_number
          AND p_2.course_number != p_4.course_number
          AND p_3.course_number != p_4.course_number
        JOIN (SELECT sect.course_number
                    ,c.course_name
                    ,c.sched_department AS dept
                    ,SUBSTR(sect.expression,1,1) AS period
                    ,sect.no_of_students
                    ,sect.maxenrollment
                    ,sect.maxenrollment - sect.no_of_students AS seats_avail
              FROM schedulesections sect
              JOIN courses c on sect.course_number = c.course_number
              WHERE sect.buildid = 55
                AND SUBSTR(sect.expression,1,1) = 5
              ) p_5
          ON p_1.dept = p_5.dept
          AND p_1.course_number != p_5.course_number
          AND p_2.course_number != p_5.course_number
          AND p_3.course_number != p_5.course_number
          AND p_4.course_number != p_5.course_number
        JOIN (SELECT sect.course_number
                    ,c.course_name
                    ,c.sched_department AS dept
                    ,SUBSTR(sect.expression,1,1) AS period
                    ,sect.no_of_students
                    ,sect.maxenrollment
                    ,sect.maxenrollment - sect.no_of_students AS seats_avail
              FROM schedulesections sect
              JOIN courses c on sect.course_number = c.course_number
              WHERE sect.buildid = 55
                AND SUBSTR(sect.expression,1,1) = 6
              ) p_6
          ON p_1.dept = p_6.dept
          AND p_1.course_number != p_6.course_number
          AND p_2.course_number != p_6.course_number
          AND p_3.course_number != p_6.course_number
          AND p_4.course_number != p_6.course_number
          AND p_5.course_number != p_6.course_number
        ORDER BY p_1.course_number
                ,p_2.course_number
                ,p_3.course_number
                ,p_4.course_number
                ,p_5.course_number
                ,p_6.course_number
        ) pathways
        
;

SELECT level_1.*
      ,ROW_NUMBER() OVER (PARTITION BY grade_pathway ORDER BY credittype) AS rn
FROM
      (SELECT DISTINCT
             c.credittype
            ,CASE
               WHEN req.coursenumber = 'Sci302' THEN 'GR7'
               WHEN req.coursenumber = 'Sci401' THEN 'GR8'
               ELSE c.sched_department
             END AS grade_pathway
      FROM schedulerequests req
      JOIN courses c
        ON req.coursenumber = c.course_number
      WHERE req.yearid = 2200
      AND req.schoolid = 73252
      ) level_1
;

--ALL possible pathways
SELECT clean.pathway
      ,stu_reqs.count
FROM
     (SELECT trim(c1 || ', ' || c2 || ', ' || c3 || ', ' || c4 || ', ' || c5 || ', ' || c6) AS pathway
      FROM
            (SELECT t1.coursenumber AS c1
                  ,t2.coursenumber AS c2
                  ,t3.coursenumber AS c3
                  ,t4.coursenumber AS c4
                  ,t5.coursenumber AS c5
                  ,t6.coursenumber AS c6
            FROM
                  (SELECT DISTINCT
                         req.coursenumber
                  FROM schedulerequests req
                  WHERE req.yearid = 2200
                  AND req.schoolid = 73252
                  ORDER BY req.coursenumber
                  ) t1      
            JOIN 
              (SELECT DISTINCT
                     req.coursenumber
              FROM schedulerequests req
              WHERE req.yearid = 2200
              AND req.schoolid = 73252
              ORDER BY req.coursenumber
              ) t2 
             ON t1.coursenumber < t2.coursenumber
            JOIN 
              (SELECT DISTINCT
                     req.coursenumber
              FROM schedulerequests req
              WHERE req.yearid = 2200
              AND req.schoolid = 73252
              ORDER BY req.coursenumber
              ) t3
             ON t1.coursenumber < t3.coursenumber
            AND t2.coursenumber < t3.coursenumber
            JOIN 
              (SELECT DISTINCT
                     req.coursenumber
              FROM schedulerequests req
              WHERE req.yearid = 2200
              AND req.schoolid = 73252
              ORDER BY req.coursenumber
              ) t4
             ON t1.coursenumber < t4.coursenumber
            AND t2.coursenumber < t4.coursenumber
            AND t3.coursenumber < t4.coursenumber
            JOIN 
              (SELECT DISTINCT
                     req.coursenumber
              FROM schedulerequests req
              WHERE req.yearid = 2200
              AND req.schoolid = 73252
              ORDER BY req.coursenumber
              ) t5
             ON t1.coursenumber < t5.coursenumber
            AND t2.coursenumber < t5.coursenumber
            AND t3.coursenumber < t5.coursenumber
            AND t4.coursenumber < t5.coursenumber
            JOIN 
              (SELECT DISTINCT
                     req.coursenumber
              FROM schedulerequests req
              WHERE req.yearid = 2200
              AND req.schoolid = 73252
              ORDER BY req.coursenumber
              ) t6
             ON t1.coursenumber < t6.coursenumber
            AND t2.coursenumber < t6.coursenumber
            AND t3.coursenumber < t6.coursenumber
            AND t4.coursenumber < t6.coursenumber
            AND t5.coursenumber < t6.coursenumber
            )
      ) clean
JOIN  
(select trim(pathways) AS pathway
      ,count(student) as count 
from
      (select student
            ,pathways
            ,ROW_NUMBER() OVER (PARTITION BY pathways order by student) AS curr2
            ,ROW_NUMBER() OVER (PARTITION BY pathways order by student) -1 AS prev2
      from
            (SELECT student
                   ,LTRIM(MAX(SYS_CONNECT_BY_PATH(course_number,', ')) KEEP (DENSE_RANK LAST ORDER BY curr),',') AS pathways
            from       
                  (select student
                        ,course_number
                        ,ROW_NUMBER() OVER (PARTITION BY student ORDER BY course_number) AS curr
                        ,ROW_NUMBER() OVER (PARTITION BY student ORDER BY course_number) -1 AS prev
                  from
                       (select sched_cc.buildid
                              ,s.lastfirst as student
                              ,s.grade_level + 1 as grade_level
                              ,sched_cc.course_number
                              ,c.course_name AS class
                              ,substr(sched_cc.expression, 1, 1) as period
                        from schedulecc sched_cc
                        left outer join students s on sched_cc.studentid = s.id
                        left outer join courses c on sched_cc.course_number = c.course_number
                        where sched_cc.buildid = 55
                        order by student, period
                        )
                  )
            GROUP BY student
            CONNECT BY prev = PRIOR curr AND student = PRIOR student
            START WITH curr = 1
            )
      order by pathways
              ,student
      )
GROUP BY pathways
CONNECT BY prev2 = PRIOR curr2 AND pathways = PRIOR pathways
START WITH curr2 = 1
) stu_reqs
ON clean.pathway = stu_reqs.pathway