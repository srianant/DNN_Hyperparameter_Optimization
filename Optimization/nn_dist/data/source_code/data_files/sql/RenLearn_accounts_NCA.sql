select student_number as sid
      ,first_name as sfirst
      ,last_name as slast
      ,gender as sgender
      ,dob as sbirthday
      ,ethnicity as srace
      ,grade_level as sgrade
      ,student_web_id as susername
      ,student_web_password as spassword
      ,'AR' as course
      ,2024 + (-1 * grade_level) as class
from students
where schoolid = 73253 and enroll_status <= 0
order by grade_level, lastfirst