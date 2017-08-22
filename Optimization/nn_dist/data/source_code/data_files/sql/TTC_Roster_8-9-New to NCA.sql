--KTC Roster
--KTC Roster
--Roster of students currently in 8th, 9th + any new to NCA students since last October

select *
from
      (select
         s.grade_level as current_grade
        ,case when s.schoolid = 133570965 then 'TEAM'
              when s.schoolid = 73252 then 'Rise'
              when s.schoolid = 73253 then 'NCA'
              else null end current_school
        ,s.last_name
        ,s.first_name
        ,s.middle_name as MI
        ,s.gender
        ,s.ethnicity as race
        ,s.student_number as student_id
        ,case when cohort.schoolid = 133570965 then 'TEAM'
              when cohort.schoolid = 73252 then 'Rise'
            else 'Out of Network'
            end MS_attending
        ,cohort.entrydate as MS_start_date
        ,cohort.grade_level as MS_start_grade
        ,s.dob as Date_of_birth
        ,s.lunchstatus
        ,s.street
        ,s.city
        ,s.state
        ,s.zip
        ,null as student_email
        ,null as student_mobile
        ,null as student_homephone
        ,s.mother as parent1
        ,custom_students.mother_cell as parent1_workphone
        ,s.home_phone as parent1_homephone
        ,local_emails.contactemail as parent1_email
        ,s.father as parent2
        ,custom_students.father_cell as parent2_workphone
        ,s.home_phone as parent2_homephone
        ,local_emails.contactemail as parent2_email
        ,case when cohort.schoolid = 999999 then null 
              else row_number() over (partition by cohort.studentid
                                          order by cohort.year asc) end as rn_cycle
        
from students s
join custom_students on s.id = custom_students.studentid
join local_emails on s.id = local_emails.studentid
left outer join cohort$comprehensive_long cohort on s.id = cohort.studentid

where   s.grade_level IN (8,9)
  and   s.enroll_status = 0
  
order by current_grade,s.lastfirst)

where rn_cycle = 1

union all

select *
from
      (select
         s.grade_level as current_grade
        ,case when s.schoolid = 133570965 then 'TEAM'
              when s.schoolid = 73252 then 'Rise'
              when s.schoolid = 73253 then 'NCA'
              else null end current_school
        ,s.last_name
        ,s.first_name
        ,s.middle_name as MI
        ,s.gender
        ,s.ethnicity as race
        ,s.student_number as student_id
        ,case when cohort.schoolid = 133570965 then 'TEAM'
              when cohort.schoolid = 73252 then 'Rise'
            else 'Out of Network'
            end MS_attending
        ,cohort.entrydate as MS_start_date
        ,cohort.grade_level as MS_start_grade
        ,s.dob as Date_of_birth
        ,s.lunchstatus
        ,s.street
        ,s.city
        ,s.state
        ,s.zip
        ,null as student_email
        ,null as student_mobile
        ,null as student_homephone
        ,s.mother as parent1
        ,custom_students.mother_cell as parent1_workphone
        ,s.home_phone as parent1_homephone
        ,local_emails.contactemail as parent1_email
        ,s.father as parent2
        ,custom_students.father_cell as parent2_workphone
        ,s.home_phone as parent2_homephone
        ,local_emails.contactemail as parent2_email
        ,case when cohort.schoolid = 999999 then null 
              else row_number() over (partition by cohort.studentid
                                          order by cohort.year asc) end as rn_cycle
        
from students s
join custom_students on s.id = custom_students.studentid
join local_emails on s.id = local_emails.studentid
left outer join cohort$comprehensive_long cohort on s.id = cohort.studentid

where   s.schoolid = 73253
  and   s.grade_level >= 10
  and   s.enroll_status = 0
  and   s.DistrictEntryDate >= '15-OCT-2011'
  
order by current_grade,s.lastfirst)

where rn_cycle = 1
