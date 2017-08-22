select iuserid
      ,student_number
      ,lastfirst
      ,grade_level
      ,pointsearned
from
(select ar.iuserid
      ,ar.student_number
      ,s.lastfirst
      ,s.grade_level
      ,sum(dpointsearned) pointsearned
from ar_detail_passed_1011 ar
left outer join students@PS_TEAM s on to_char(s.student_number) = ar.student_number
group by ar.iuserid, ar.student_number, s.lastfirst, s.grade_level)
order by pointsearned desc;


select grade_level
      ,round(avg(pointsearned),2) avg_points
from
(select s.grade_level
       ,s.id
      ,sum(dpointsearned) pointsearned
from ar_detail_passed_1011 ar
left outer join students@PS_TEAM s on to_char(s.student_number) = ar.student_number
group by s.grade_level,s.id)
group by grade_level
order by grade_level desc
