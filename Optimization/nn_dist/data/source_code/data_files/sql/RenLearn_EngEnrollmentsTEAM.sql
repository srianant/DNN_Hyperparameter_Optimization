select s.student_number as sid
      ,s.first_name as sfirst
      ,s.last_name as slast
--      ,s.gender as sgender
--      ,s.dob as sbirthday
--      ,s.ethnicity as srace
--      ,s.grade_level as sgrade
--      ,s.student_web_id as susername
--      ,s.student_web_password as spassword
      ,'ENG' as course
      ,c.course_name || ': ' || t.last_name || ' ' || sect.section_number as class
      ,t.first_name as TFIRST
      ,t.last_name as TLAST
      ,row_number() over(partition by s.student_number order by s.grade_level, s.lastfirst desc) as rn
from students s
join cc on s.id = cc.studentid and cc.termid = 2103 and cc.schoolid = 133570965
join sections sect on sect.id = cc.sectionid
join courses c on sect.course_number = c.course_number and c.credittype = 'ENG'
join teachers t on sect.teacher = t.id
where s.schoolid = 133570965 and s.enroll_status <= 0
order by s.grade_level, s.lastfirst desc