select base_studentid, base_schoolid, base_grade_level
from
    (select re.studentid as base_studentid
           ,re.schoolid as base_schoolid
           ,re.grade_level as base_grade_level
           --the row number function assigns a number to ALL the re-entry events for each student in the query
           --so if a student transfers in and out multiple times during the year, these will be numbered 1,2,3 etc.
           --by sorting by exit date descending, we put them in order from most recent - oldest.
           --turning this into a subquery allows us to take only rn = 1, ie the 'last' re-entry event of the year.
           ,row_number() over(partition by re.studentid order by re.exitdate desc) as rn
     from reenrollments re
     where re.entrydate >= '01-AUG-10' and re.exitdate < '01-JUL-11' and (re.exitdate - re.entrydate) > 0)
where rn = 1
 union all
 --get the students who TRANSFERRED mid year last year.
 --logic here is to decode by entry date & enroll status
 --excluding schoolid 999999 makes sure that students who were transferred to 'graduated students' 
 --don't show up in this query.
  select students.id as base_studentid
       ,students.schoolid as base_schoolid
       ,students.grade_level as base_grade_level
from students
where students.entrydate > '01-AUG-10' and students.entrydate < '28-JUN-11'
  and students.enroll_status > 0 and students.exitdate > '01-AUG-10' and students.schoolid != 999999 
  and (students.exitdate - students.entrydate) > 0;
