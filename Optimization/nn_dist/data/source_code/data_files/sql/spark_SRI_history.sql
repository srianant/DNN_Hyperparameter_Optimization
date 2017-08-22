select sq_1.*
      ,sri.*
from
      (select s.id
            ,s.student_number
            ,s.lastfirst
            ,s.grade_level
      from students@PS_TEAM s
      where s.schoolid = 73254 and s.enroll_status = 0) sq_1
join sri_testing_history sri on to_char(sq_1.student_number) = sri.base_student_number
order by sq_1.lastfirst, sri.rn_lifetime

      