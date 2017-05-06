--all students who attended SPARK in 2010-2011
select base_studentid
      ,base_grade_level
      ,s.lastfirst
      ,s.last_name
      ,s.first_name
from      
(select distinct re.studentid as base_studentid
        --select distinct is kinda sloppy here...but a kid can tranfer in and out over the course of the year
        --and you don't want dupes.  so there you have it...
       ,re.schoolid as base_schoolid
       ,re.grade_level as base_grade_level
 from reenrollments@PS_TEAM re
 where re.entrydate >= '01-AUG-10' and re.exitdate < '01-JUL-11' and re.schoolid = 73254
 union all
 select students.id as base_studentid
       ,students.schoolid as base_schoolid
       ,students.grade_level as base_grade_level
from students@PS_TEAM
where students.entrydate > '01-AUG-10' and students.schoolid = 73254 
  and students.enroll_status > 0 and students.exitdate > '01-AUG-10')
join students@PS_TEAM s on base_studentid = s.id
order by base_grade_level, s.lastfirst