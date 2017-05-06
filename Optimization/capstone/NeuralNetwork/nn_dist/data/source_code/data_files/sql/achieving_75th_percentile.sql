select sq_1.*
from
      (select rtrim(
                   replace(
                           replace(
                                   decode(grouping(schoolname), 1, 'Network', schoolname)
                                   ,'Academy, a KIPP school','')
                          ,'Academy','')
                  ) as school
            ,year_abbreviation as year
            ,fallwinterspring
            ,grade_level
            ,cohort
            ,measurementscale
      --      ,round(avg(testritscore),1) as rit
            ,round(avg(case 
                         when testpercentile >= 75 then 1
                         when testpercentile < 75 then 0
                       end
                       )*100,0) as achieved_75th_pct
            ,sum(case
                     when testpercentile >= 75 then 1
                     else null
                 end) as achieved_75th_count
            ,count(*) as n
      from map_comprehensive_identifiers
      where fallwinterspring != 'Winter' and grade_level is not null and rn = 1
      group by cube (schoolname
                    ,year_abbreviation
                    ,fallwinterspring
                    ,grade_level
                    ,cohort
                    ,measurementscale)
      order by schoolname
              ,measurementscale
              ,year_abbreviation
              ,grade_level
              ,fallwinterspring
) sq_1
where fallwinterspring = 'Spring' 
  and grade_level = 8 
  and measurementscale is not null
  and cohort is not null 
  and year is not null
--  and school = 'Network'
order by measurementscale, school, year
