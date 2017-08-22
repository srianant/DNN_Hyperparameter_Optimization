select base_schoolid
      ,base_grade_level
      ,sum(aug_member) as aug_member
      ,sum(sep_member) as sep_member
      ,sum(oct_member) as oct_member
      ,sum(nov_member) as nov_member
      ,sum(dec_member) as dec_member
      ,sum(jan_member) as jan_member
      ,sum(feb_member) as feb_member
      ,sum(mar_member) as mar_member
      ,sum(apr_member) as apr_member
      ,sum(may_member) as may_member
      ,sum(jun_member) as jun_member
from

  
          (select re.studentid as base_studentid
                 ,re.schoolid as base_schoolid
                 ,re.grade_level as base_grade_level
                 ,case when re.entrydate >='01-AUG-11' and re.exitdate >= '01-SEP-11' then 1 else 0 end as aug_member
                 ,case when re.entrydate >='01-AUG-11' and re.exitdate >= '01-OCT-11' then 1 else 0 end as sep_member
                 ,case when re.entrydate >='01-AUG-11' and re.exitdate >= '01-NOV-11' then 1 else 0 end as oct_member
                 ,case when re.entrydate >='01-AUG-11' and re.exitdate >= '01-DEC-11' then 1 else 0 end as nov_member
                 ,case when re.entrydate >='01-AUG-11' and re.exitdate >= '01-JAN-12' then 1 else 0 end as dec_member
                 ,case when re.entrydate >='01-AUG-11' and re.exitdate >= '01-FEB-12' then 1 else 0 end as jan_member
                 ,case when re.entrydate >='01-AUG-11' and re.exitdate >= '01-MAR-12' then 1 else 0 end as feb_member
                 ,case when re.entrydate >='01-AUG-11' and re.exitdate >= '01-APR-12' then 1 else 0 end as mar_member
                 ,case when re.entrydate >='01-AUG-11' and re.exitdate >= '01-MAY-12' then 1 else 0 end as apr_member
                 ,case when re.entrydate >='01-AUG-11' and re.exitdate >= '01-JUN-12' then 1 else 0 end as may_member
                 ,case when re.entrydate >='01-AUG-11' and re.exitdate >= '01-JUN-12' and re.exitdate < '01-JUL-12' then 1 else 0 end as jun_member
           from reenrollments re
           where re.entrydate >= '01-AUG-11' and re.exitdate < '01-JUL-12' --and re.schoolid != 999999
           union all
           select students.id as base_studentid
                 ,students.schoolid as base_schoolid
                 ,students.grade_level as base_grade_level
                 ,case when students.entrydate >='01-AUG-11' and students.exitdate >= '01-SEP-11' then 1 else 0 end as aug_member
                 ,case when students.entrydate >='01-AUG-11' and students.exitdate >= '01-OCT-11' then 1 else 0 end as sep_member
                 ,case when students.entrydate >='01-AUG-11' and students.exitdate >= '01-NOV-11' then 1 else 0 end as oct_member
                 ,case when students.entrydate >='01-AUG-11' and students.exitdate >= '01-DEC-11' then 1 else 0 end as nov_member
                 ,case when students.entrydate >='01-AUG-11' and students.exitdate >= '01-JAN-12' then 1 else 0 end as dec_member
                 ,case when students.entrydate >='01-AUG-11' and students.exitdate >= '01-FEB-12' then 1 else 0 end as jan_member
                 ,case when students.entrydate >='01-AUG-11' and students.exitdate >= '01-MAR-12' then 1 else 0 end as feb_member
                 ,case when students.entrydate >='01-AUG-11' and students.exitdate >= '01-APR-12' then 1 else 0 end as mar_member
                 ,case when students.entrydate >='01-AUG-11' and students.exitdate >= '01-MAY-12' then 1 else 0 end as apr_member
                 ,case when students.entrydate >='01-AUG-11' and students.exitdate >= '01-JUN-12' then 1 else 0 end as may_member
                 ,case when students.entrydate >='01-AUG-11' and students.exitdate >= '01-JUN-12' and students.exitdate < '01-JUL-12' then 1 else 0 end as jun_member
          from students
          where students.entrydate > '01-AUG-11'
            and students.enroll_status > 0 and students.exitdate > '01-AUG-11') --and students.schoolid != 999999
group by cube (base_schoolid, base_grade_level)
--group by base_schoolid, base_grade_level
order by base_schoolid, base_grade_level
