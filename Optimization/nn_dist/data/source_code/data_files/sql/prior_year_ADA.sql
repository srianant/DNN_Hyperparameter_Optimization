select base_schoolid
      --,lunchstatus
      ,sum(membership_days)
      ,sum(days_present)
      ,ROUND(sum(days_present) / sum(membership_days),2) * 100 AS ada
from
   (select base_studentid
          ,base_schoolid
          ,base_grade_level
          ,lastfirst
          ,lunchstatus
          ,(absences_undoc + absences_doc) as absences
          ,membership_days
          --days present
          ,membership_days - (absences_undoc + absences_doc) as days_present
    from
       (select  base_studentid
               ,base_schoolid
               ,base_grade_level
               ,lastfirst
               ,lunchstatus
               ,absences_undoc
               ,absences_doc
               ,sum(mem_reg.studentmembership) as membership_days
        from   
           (select base_studentid
                  ,base_schoolid
                  ,base_grade_level
                  ,lastfirst
                  ,lunchstatus
                  ,sum(case
                       when att_code = 'A'
                       then 1
                       else 0
                       end) as absences_undoc
                  ,sum(case
                       when att_code = 'AD'
                       then 1
                       when att_code = 'D'
                       then 1
                       else 0
                       end) as absences_doc
                  ,sum(case
                       when att_code = 'T'
                       then 1
                       else 0
                       end) as tardies_reg
                   ,sum(case
                       when att_code = 'T10'
                       then 1
                       else 0
                       end) as tardies_T10
                   ,sum(case
                       when att_code = 'S'
                       then 1
                       else 0
                       end) as ISS
                   ,sum(case
                       when att_code = 'OS'
                       then 1
                       else 0
                       end) as OSS
            from
               (select base_studentid
                      ,base_schoolid
                      ,base_grade_level
                      ,s.lastfirst
                      ,upper(s.lunchstatus) as lunchstatus
                      ,psad.att_date
                      ,psad.att_code
                from
                     (select base_studentid
                            ,base_schoolid
                            ,base_grade_level
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
                           where re.entrydate >= '01-AUG-11' and re.exitdate < '30-JUL-12' and (re.exitdate - re.entrydate) > 0)
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
                      where students.entrydate > '01-AUG-11' and students.entrydate < '28-JUN-12'
                        and students.enroll_status > 0 and students.exitdate > '01-AUG-11' and students.schoolid != 999999 
                        and (students.exitdate - students.entrydate) > 0)
                left outer join students s on base_studentid = s.id
                left outer join PS_ATTENDANCE_DAILY psad on base_studentid = psad.studentid 
                                                                and psad.att_date >= '01-AUG-11'
                                                                and psad.att_date <  '01-JUL-12'
                                                                and psad.att_code is not null)
            group by base_studentid, base_schoolid, base_grade_level, lastfirst, lunchstatus)
        left outer join pssis_membership_reg mem_reg on base_studentid = mem_reg.studentid 
                                                            and mem_reg.calendardate >  '01-AUG-11' 
                                                            and mem_reg.calendardate <= '01-JUL-12'
                                                            and mem_reg.calendarmembership = 1
        group by base_studentid, base_schoolid, base_grade_level, lastfirst, lunchstatus, absences_undoc, absences_doc)
    where membership_days > 0)
group by cube(base_schoolid);

