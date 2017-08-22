select course
      ,expression
      ,tardies_yr
      ,t_aug
      ,t_sep
      ,t_oct
      ,t_nov
      ,t_dec
      ,t_jan
      ,t_feb
      ,t_mar
      ,t_apr
      ,t_may
      ,t_jun
from
     (select decode(grouping(course),1,'sum',course) course
            ,decode(grouping(expression),1,'sum',expression) expression
            ,sum(tardy) as tardies_yr
            ,sum(t_aug) as t_aug
            ,sum(t_sep) as t_sep
            ,sum(t_oct) as t_oct
            ,sum(t_nov) as t_nov
            ,sum(t_dec) as t_dec
            ,sum(t_jan) as t_jan
            ,sum(t_feb) as t_feb
            ,sum(t_mar) as t_mar
            ,sum(t_apr) as t_apr
            ,sum(t_may) as t_may
            ,sum(t_jun) as t_jun
      from
            (select course
                   ,expression
                   ,tardy
                   ,case when t_month = 'AUG' then 1 else 0 end as t_aug
                   ,case when t_month = 'SEP' then 1 else 0 end as t_sep
                   ,case when t_month = 'OCT' then 1 else 0 end as t_oct
                   ,case when t_month = 'NOV' then 1 else 0 end as t_nov
                   ,case when t_month = 'DEC' then 1 else 0 end as t_dec
                   ,case when t_month = 'JAN' then 1 else 0 end as t_jan
                   ,case when t_month = 'FEB' then 1 else 0 end as t_feb
                   ,case when t_month = 'MAR' then 1 else 0 end as t_mar
                   ,case when t_month = 'APR' then 1 else 0 end as t_apr
                   ,case when t_month = 'MAY' then 1 else 0 end as t_may
                   ,case when t_month = 'JUN' then 1 else 0 end as t_jun
             from      
                   (select s.student_number
                          ,s.lastfirst as lastfirst
                          ,s.grade_level
                          ,s.gender
                          ,sections.course_number as course
                          ,sections.course_number || ' ' || p.abbreviation as expression
                          ,case when att_code.att_code in ('T', 'T10') then 1 else null end as tardy
                          ,case when att_code.att_code in ('T', 'T10') then to_char(att.att_date,'MON') else null end t_month
                    from students s
                    left outer join attendance att on s.id = att.studentid and att.att_date >= '01-AUG-11' and att.schoolid = 73253
                                                  and att.att_mode_code = 'ATT_ModeMeeting'
                    left outer join attendance_code att_code on att.attendance_codeid = att_code.id
                    left outer join cc cc on att.ccid = cc.id
                    join sections sections on cc.sectionid = sections.id and sections.course_number != 'HR'
                    join period p on REGEXP_REPLACE(sections.expression, '^(\d+)(.*)', '\1') = p.period_number and p.schoolid = 73253 and p.year_id = 21 and (instr(sections.expression,'(')-1) > 0
                    where s.schoolid = 73253 and s.enroll_status = 0))
      group by rollup(course, expression
                     )
     having sum(tardy) > 0
   )
order by decode(course
               ,'sum', 10
                     , 20)
        ,decode(expression
               ,'sum', 10
                     , 20)
        ,rownum
;
 