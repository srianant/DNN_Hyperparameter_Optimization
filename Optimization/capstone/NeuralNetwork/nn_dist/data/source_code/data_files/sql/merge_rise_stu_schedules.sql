select grade_level
      ,student
      ,rating
      
--    //PERIOD 1//      
      ,p1_teacher
      ,p1_room 
      ,p1_course


--    //PERIOD 2//      
      ,p2_teacher
      ,p2_room
      ,p2_course

--    //PERIOD 3//      
      ,p3_teacher
      ,p3_room
      ,p3_course

--    //PERIOD 4//      
      ,p4_teacher
      ,p4_room
      ,p4_course

--    //PERIOD 5//      
      ,p5_teacher
      ,p5_room
      ,p5_course

--    //PERIOD 6//      
      ,p6_teacher
      ,p6_room
      ,p6_course

from
(select s.lastfirst as student
      ,s.grade_level + 1 as grade_level
      ,s.ethnicity as rating
      
--    //PERIOD 1//      
      ,sched_cc_p1.course_number               as p1_abbrev
      ,substr(sched_cc_p1.expression, 1, 1)    as p1_expression
      ,sect_p1.room                            as p1_room
      ,t_p1.last_name                          as p1_teacher
      ,c_p1.course_name                        as p1_course

--    //PERIOD 2//      
      ,sched_cc_p2.course_number               as p2_abbrev
      ,substr(sched_cc_p2.expression, 1, 1)    as p2_expression
      ,sect_p2.room                            as p2_room
      ,t_p2.last_name                          as p2_teacher
      ,c_p2.course_name                        as p2_course
      
--    //PERIOD 3//      
      ,sched_cc_p3.course_number               as p3_abbrev
      ,substr(sched_cc_p3.expression, 1, 1)    as p3_expression
      ,sect_p3.room                            as p3_room
      ,t_p3.last_name                          as p3_teacher
      ,c_p3.course_name                        as p3_course

--    //PERIOD 4//      
      ,sched_cc_p4.course_number               as p4_abbrev
      ,substr(sched_cc_p4.expression, 1, 1)    as p4_expression
      ,sect_p4.room                            as p4_room
      ,t_p4.last_name                          as p4_teacher
      ,c_p4.course_name                        as p4_course

--    //PERIOD 5//      
      ,sched_cc_p5.course_number               as p5_abbrev
      ,substr(sched_cc_p5.expression, 1, 1)    as p5_expression
      ,sect_p5.room                            as p5_room
      ,t_p5.last_name                          as p5_teacher
      ,c_p5.course_name                        as p5_course

--    //PERIOD 6//      
      ,sched_cc_p6.course_number               as p6_abbrev
      ,substr(sched_cc_p6.expression, 1, 1)    as p6_expression
      ,sect_p6.room                            as p6_room
      ,t_p6.last_name                          as p6_teacher
      ,c_p6.course_name                        as p6_course

from students s 

--//PERIOD 1//
left outer join schedulecc sched_cc_p1 on sched_cc_p1.studentid = s.id and sched_cc_p1.buildid = 54 
            and sched_cc_p1.expression = '1(A)'
left outer join teachers t_p1 on sched_cc_p1.teacherid = t_p1.id
left outer join schedulesections sect_p1 on sched_cc_p1.sectionid = sect_p1.id
left outer join courses c_p1 on sect_p1.course_number = c_p1.course_number

--//PERIOD 2//
left outer join schedulecc sched_cc_p2 on sched_cc_p2.studentid = s.id and sched_cc_p2.buildid = 54 
            and sched_cc_p2.expression = '2(A)'
left outer join teachers t_p2 on sched_cc_p2.teacherid = t_p2.id
left outer join schedulesections sect_p2 on sched_cc_p2.sectionid = sect_p2.id
left outer join courses c_p2 on sect_p2.course_number = c_p2.course_number

--//PERIOD 3//
left outer join schedulecc sched_cc_p3 on sched_cc_p3.studentid = s.id and sched_cc_p3.buildid = 54 
            and sched_cc_p3.expression = '3(A)'
left outer join teachers t_p3 on sched_cc_p3.teacherid = t_p3.id
left outer join schedulesections sect_p3 on sched_cc_p3.sectionid = sect_p3.id
left outer join courses c_p3 on sect_p3.course_number = c_p3.course_number

--//PERIOD 4//
left outer join schedulecc sched_cc_p4 on sched_cc_p4.studentid = s.id and sched_cc_p4.buildid = 54 
            and sched_cc_p4.expression = '4(A)'
left outer join teachers t_p4 on sched_cc_p4.teacherid = t_p4.id
left outer join schedulesections sect_p4 on sched_cc_p4.sectionid = sect_p4.id
left outer join courses c_p4 on sect_p4.course_number = c_p4.course_number

--//PERIOD 5//
left outer join schedulecc sched_cc_p5 on sched_cc_p5.studentid = s.id and sched_cc_p5.buildid = 54 
            and sched_cc_p5.expression = '5(A)'
left outer join teachers t_p5 on sched_cc_p5.teacherid = t_p5.id
left outer join schedulesections sect_p5 on sched_cc_p5.sectionid = sect_p5.id
left outer join courses c_p5 on sect_p5.course_number = c_p5.course_number

--//PERIOD 6//
left outer join schedulecc sched_cc_p6 on sched_cc_p6.studentid = s.id and sched_cc_p6.buildid = 54 
            and sched_cc_p6.expression = '6(A)'
left outer join teachers t_p6 on sched_cc_p6.teacherid = t_p6.id
left outer join schedulesections sect_p6 on sched_cc_p6.sectionid = sect_p6.id
left outer join courses c_p6 on sect_p6.course_number = c_p6.course_number

where s.schoolid = 7325211 and s.grade_level in (6,7) and s.sched_scheduled = 1)
order by grade_level, student;
