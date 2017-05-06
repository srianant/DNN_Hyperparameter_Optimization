--Retained 2011 Counts
--MAINTENANCE: change re.entrydate/exitdate to correct year
select
   grade_level
  ,count(studentid) as Total_retained
  ,sum(case when gender = 'M' then 1 else 0 end) as Male_count
  ,sum(case when gender = 'F' then 1 else 0 end) as Female_count
  ,sum(case when SPED IN ('SPED','SPED SPEECH') then 1 else 0 end) as SPED_Count

from
      (select 
            re.studentid
           ,re.entrydate
           ,re.exitdate
           ,re.exitcomment
           ,re.schoolid
           ,re.grade_level
           ,s.gender
           ,ps_customfields.getcf('Students',s.id,'SPEDLEP') as SPED
      from reenrollments re
      join students s on re.studentid = s.id
      where re.entrydate >= '01-AUG-11'
        and re.exitdate <= '04-JUL-12'
        and re.exitcomment LIKE '%Retai%'
      )
      
group by cube (grade_level)

;


--Course Report for 2011 Final Grades
--MAINTENANCE:
--  Modify case and where statements to include correct course_numbers (these change year over year)
--  Edit term id to correct year

select
    credit_type
   ,Course_Category
   ,count(student_number) as total_students
--   ,count unique(course_number) as count_courses
   ,sum(case when gender = 'M' then 1 else 0 end) as Male_count
   ,sum(case when gender = 'F' then 1 else 0 end) as Female_count
   ,sum(case when SPED IN ('SPED','SPED SPEECH') then 1 else 0 end) as SPED_Count
   ,sum(case when percent >= 70 then 1 else 0 end) as Passed_count
  
from
(select 
     sg.storecode
    ,sg.credit_type
    ,sg.course_number
    ,sg.course_name
    ,case
          when sg.course_number = 'ENG45' then 'AP English'
          when sg.course_number = 'M400' then 'Algebra'
          when sg.course_number = 'M405' then 'Algebra'
          when sg.course_number = 'MATH71' then 'Algebra'
          when sg.course_number = 'MATH72' then 'Geometry'
          when sg.course_number = 'MATH10' then 'Algebra'
          when sg.course_number = 'MATH15' then 'Algebra'
          when sg.course_number = 'MATH20' then 'Geometry'
          when sg.course_number = 'MATH25' then 'Geometry'
          when sg.course_number = 'MATH30' then 'Math Advanced'
          when sg.course_number = 'MATH40' then 'Math Advanced'
          when sg.course_number = 'Sci400' then 'Science Gr8'
          when sg.course_number = 'SCI10' then 'Science Physical Science'
          when sg.course_number = 'SCI20' then 'Science Biology'
          when sg.course_number = 'SCI25' then 'Science Biology'
          when sg.course_number = 'SCI30' then 'Science Chemistry'
          when sg.course_number = 'SCI35' then 'Science Chemistry'
          when sg.course_number = 'SCI31' then 'Science Physics'
          when sg.course_number = 'SCI45' then 'Science Chemistry'
          when sg.course_number = 'SCI40' then 'Science Environmental'
          when sg.course_number = 'Sci302' then 'Science Gr7'
          when sg.course_number = 'Sci300' then 'Science Gr7'
          when sg.course_number = 'Sci401' then 'Science Gr8'
    else null end as Course_Category
    ,s.gender
    ,ps_customfields.getcf('Students',id,'SPEDLEP') as SPED
    ,sg.schoolid
    ,sg.grade_level as Grade_Course_Taken
    ,sg.percent
    ,sg.grade
    ,sg.termid
    ,s.student_number
  --,s.lastfirst
from storedgrades sg
join students s on sg.studentid = s.id
where sg.storecode IN ('Y1')        
      and sg.termid = 2100
      and sg.course_number IN (
                               'ENG45'
                              ,'M400'
                              ,'M405'
                              ,'MATH71'
                              ,'MATH72'
                              ,'MATH10'
                              ,'MATH15'
                              ,'MATH20'
                              ,'MATH25'
                              ,'MATH30'
                              ,'MATH40'
                              ,'Sci400'
                              ,'SCI10'
                              ,'SCI20'
                              ,'SCI25'
                              ,'SCI30'
                              ,'SCI35'
                              ,'SCI31'
                              ,'SCI45'
                              ,'SCI40'
                              ,'Sci302'
                              ,'Sci300'
                              ,'Sci401'
                              )
      --and sg.credit_type IN ('SCI')
      --and sg.course_name LIKE '%Alg%'
      --and sg.course_name NOT LIKE '%Pre-%'
      --and sg.course_number IN
order by sg.credit_type, sg.course_name, sg.grade_level)
group by cube (credit_type,Course_Category)
