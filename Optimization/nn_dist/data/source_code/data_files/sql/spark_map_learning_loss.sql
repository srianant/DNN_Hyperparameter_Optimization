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
            ,round(median(testritscore),1) as rit
            ,round(median(testpercentile),1) as percentile
            ,round(median(percentile_2008_norms),1) as percentile_2008_norms
            ,round(avg(testritscore),1) as rit_mean
            ,round(avg(testpercentile),1) as percentile_mean
            ,round(avg(percentile_2008_norms),1) as percentile_2008_norms_mean
            ,round(avg(goal1ritscore),1) as goal1_rit
            ,round(avg(goal2ritscore),1) as goal2_rit
            ,round(avg(goal3ritscore),1) as goal3_rit
            ,round(avg(goal4ritscore),1) as goal4_rit
            ,round(avg(goal5ritscore),1) as goal5_rit
            ,round(avg(goal6ritscore),1) as goal6_rit
            ,count(*) as n
      from map_comprehensive_identifiers
      where fallwinterspring != 'Winter' 
        and rn = 1
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
where school like 'SPARK%'
  and grade_level is not null 
  and cohort is not null
  and school is not null
  and year is not null
  and fallwinterspring is not null
  and measurementscale is not null
;

select sq_2.*
      ,case
         when sq_2.rit_chg > sq_2.compound_se then 'gain'
         when sq_2.rit_chg < (-1*sq_2.compound_se) then 'decline'
         else 'inside margin of error'
       end as interp
from
      (select sq_1.cohort
            --,sq_1.year
            ,sq_1.lastfirst
            ,sq_1.measurementscale
            ,sq_1.spr_rit
            ,sq_1.fall_rit
            ,sq_1.fall_rit - sq_1.spr_rit as rit_chg
            ,sq_1.spr_pctle
            ,sq_1.fall_pctle
            ,sq_1.fall_pctle - sq_1.spr_pctle as pctle_chg
            ,sq_1.compound_se
       from
            (select spr_11.COHORT
                  --,spr_11.GRADE_LEVEL 
                  --,spr_11.YEAR_ABBREVIATION as year      
                  --,spr_11.MAP_YEAR_ACADEMIC
                  --,spr_11.PS_STUDENTID
                  ,spr_11.LASTFIRST
                 -- ,spr_11.FALLWINTERSPRING
                 --,spr_11.MAP_YEAR
                  --,spr_11.TERMNAME
                  --,spr_11.STUDENTID
                  --,spr_11.SCHOOLNAME
                  ,spr_11.MEASUREMENTSCALE
                  --,spr_11.DISCIPLINE
                  --,spr_11.GROWTHMEASUREYN
                  --,spr_11.TESTTYPE
                  --,spr_11.TESTNAME
                  --,spr_11.TESTSTARTDATE
                  --,spr_11.TESTDURATIONINMINUTES as minutes_tested
                  ,spr_11.TESTRITSCORE as spr_rit
                  ,spr_11.TESTSTANDARDERROR as spr_se
                  ,spr_11.testritscore - spr_11.TESTSTANDARDERROR as spr_se_min
                  ,spr_11.testritscore + spr_11.TESTSTANDARDERROR as spr_se_max
                  ,spr_11.TESTPERCENTILE as spr_pctle
                  --,spr_11.PERCENTILE_2008_NORMS
                  --,spr_11.TYPICALFALLTOFALLGROWTH
                  --,spr_11.TYPICALSPRINGTOSPRINGGROWTH
                  --,spr_11.TYPICALFALLTOSPRINGGROWTH
                  ,fall_11.testritscore as fall_rit
                  ,fall_11.TESTSTANDARDERROR as spr_se
                  ,fall_11.testritscore - fall_11.TESTSTANDARDERROR as fall_se_min
                  ,fall_11.testritscore + fall_11.TESTSTANDARDERROR as fall_se_max
                  ,fall_11.testpercentile as fall_pctle
                  ,fall_11.TESTDURATIONINMINUTES as fall_min_tested
                  ,round(sqrt((spr_11.teststandarderror*spr_11.teststandarderror) + (fall_11.teststandarderror*fall_11.teststandarderror)),1) as compound_se
            from map_comprehensive_identifiers spr_11
            left outer join map_comprehensive_identifiers fall_11 on fall_11.termname = 'Fall 2011' and fall_11.rn = 1
                                                                 and spr_11.studentid = fall_11.studentid 
                                                                 and spr_11.measurementscale = fall_11.measurementscale     
            where spr_11.termname = 'Spring 2011' and spr_11.schoolname like 'SPARK%' and spr_11.rn = 1
            order by spr_11.measurementscale, spr_11.cohort, spr_11.lastfirst
            ) sq_1
      )sq_2

;
select sq_3.measurementscale
      ,sq_3.cohort
      ,sq_3.interp
      ,count(*)
from
     (select sq_2.*
            ,case
               when sq_2.rit_chg > sq_2.compound_se then 'gain'
               when sq_2.rit_chg < (-1*sq_2.compound_se) then 'decline'
               else 'inside margin of error'
             end as interp
      from
            (select sq_1.cohort
                  --,sq_1.year
                  ,sq_1.lastfirst
                  ,sq_1.measurementscale
                  ,sq_1.spr_rit
                  ,sq_1.fall_rit
                  ,sq_1.fall_rit - sq_1.spr_rit as rit_chg
                  ,sq_1.spr_pctle
                  ,sq_1.fall_pctle
                  ,sq_1.fall_pctle - sq_1.spr_pctle as pctle_chg
                  ,sq_1.compound_se
             from
                  (select spr_11.COHORT
                        --,spr_11.GRADE_LEVEL 
                        --,spr_11.YEAR_ABBREVIATION as year      
                        --,spr_11.MAP_YEAR_ACADEMIC
                        --,spr_11.PS_STUDENTID
                        ,spr_11.LASTFIRST
                       -- ,spr_11.FALLWINTERSPRING
                       --,spr_11.MAP_YEAR
                        --,spr_11.TERMNAME
                        --,spr_11.STUDENTID
                        --,spr_11.SCHOOLNAME
                        ,spr_11.MEASUREMENTSCALE
                        --,spr_11.DISCIPLINE
                        --,spr_11.GROWTHMEASUREYN
                        --,spr_11.TESTTYPE
                        --,spr_11.TESTNAME
                        --,spr_11.TESTSTARTDATE
                        --,spr_11.TESTDURATIONINMINUTES as minutes_tested
                        ,spr_11.TESTRITSCORE as spr_rit
                        ,spr_11.TESTSTANDARDERROR as spr_se
                        ,spr_11.testritscore - spr_11.TESTSTANDARDERROR as spr_se_min
                        ,spr_11.testritscore + spr_11.TESTSTANDARDERROR as spr_se_max
                        ,spr_11.TESTPERCENTILE as spr_pctle
                        --,spr_11.PERCENTILE_2008_NORMS
                        --,spr_11.TYPICALFALLTOFALLGROWTH
                        --,spr_11.TYPICALSPRINGTOSPRINGGROWTH
                        --,spr_11.TYPICALFALLTOSPRINGGROWTH
                        ,fall_11.testritscore as fall_rit
                        ,fall_11.TESTSTANDARDERROR as spr_se
                        ,fall_11.testritscore - fall_11.TESTSTANDARDERROR as fall_se_min
                        ,fall_11.testritscore + fall_11.TESTSTANDARDERROR as fall_se_max
                        ,fall_11.testpercentile as fall_pctle
                        ,fall_11.TESTDURATIONINMINUTES as fall_min_tested
                        ,round(sqrt((spr_11.teststandarderror*spr_11.teststandarderror) + (fall_11.teststandarderror*fall_11.teststandarderror)),1) as compound_se
                  from map_comprehensive_identifiers spr_11
                  left outer join map_comprehensive_identifiers fall_11 on fall_11.termname = 'Fall 2011' and fall_11.rn = 1
                                                                       and spr_11.studentid = fall_11.studentid 
                                                                       and spr_11.measurementscale = fall_11.measurementscale     
                  where spr_11.termname = 'Spring 2011' and spr_11.schoolname like 'SPARK%' and spr_11.rn = 1
                  order by spr_11.measurementscale, spr_11.cohort, spr_11.lastfirst
                  ) sq_1
            )sq_2
      ) sq_3
group by sq_3.measurementscale
        ,sq_3.cohort
        ,sq_3.interp
order by measurementscale, cohort, interp


;




















--old way


select sq_2.measurementscale
      ,sq_2.cohort
      ,sq_2.interp
      ,count(*)
from
       (select sq_1.cohort
              --,sq_1.year
              ,sq_1.lastfirst
              ,sq_1.measurementscale
              ,sq_1.spr_rit
              ,sq_1.fall_rit
              ,sq_1.spr_rit - sq_1.fall_rit as rit_chg
              ,sq_1.spr_pctle
              ,sq_1.fall_pctle
              ,-1*(sq_1.spr_pctle - sq_1.fall_pctle) as pctle_chg
         --     ,case
         --        when sq_1.fall_se_max < sq_1.spr_se_min then 'decline'
         --        when sq_1.fall_se_min > sq_1.spr_se_max then 'gain'
         --        else 'inside margin of error'
         --      end as interp
        from
              (select spr_11.COHORT
                    --,spr_11.GRADE_LEVEL 
                    --,spr_11.YEAR_ABBREVIATION as year      
                    --,spr_11.MAP_YEAR_ACADEMIC
                    --,spr_11.PS_STUDENTID
                    ,spr_11.LASTFIRST
                   -- ,spr_11.FALLWINTERSPRING
                   --,spr_11.MAP_YEAR
                    --,spr_11.TERMNAME
                    --,spr_11.STUDENTID
                    --,spr_11.SCHOOLNAME
                    ,spr_11.MEASUREMENTSCALE
                    --,spr_11.DISCIPLINE
                    --,spr_11.GROWTHMEASUREYN
                    --,spr_11.TESTTYPE
                    --,spr_11.TESTNAME
                    --,spr_11.TESTSTARTDATE
                    --,spr_11.TESTDURATIONINMINUTES as minutes_tested
                    ,spr_11.TESTRITSCORE as spr_rit
                    ,spr_11.TESTSTANDARDERROR as spr_se
                    ,spr_11.testritscore - spr_11.TESTSTANDARDERROR as spr_se_min
                    ,spr_11.testritscore + spr_11.TESTSTANDARDERROR as spr_se_max
                    ,spr_11.TESTPERCENTILE as spr_pctle
                    --,spr_11.PERCENTILE_2008_NORMS
                    --,spr_11.TYPICALFALLTOFALLGROWTH
                    --,spr_11.TYPICALSPRINGTOSPRINGGROWTH
                    --,spr_11.TYPICALFALLTOSPRINGGROWTH
                    ,fall_11.testritscore as fall_rit
                    ,fall_11.TESTSTANDARDERROR as spr_se
                    ,fall_11.testritscore - fall_11.TESTSTANDARDERROR as fall_se_min
                    ,fall_11.testritscore + fall_11.TESTSTANDARDERROR as fall_se_max
                    ,fall_11.testpercentile as fall_pctle
                    ,fall_11.TESTDURATIONINMINUTES as fall_min_tested
                    ,sqrt((spr_11.teststandarderror*spr_11.teststandarderror) + (fall_11.teststandarderror*fall_11.teststandarderror)) as compound_se
              from map_comprehensive_identifiers spr_11
              left outer join map_comprehensive_identifiers fall_11 on fall_11.termname = 'Fall 2011' and fall_11.rn = 1
                                                                   and spr_11.studentid = fall_11.studentid 
                                                                   and spr_11.measurementscale = fall_11.measurementscale     
              where spr_11.termname = 'Spring 2011' and spr_11.schoolname like 'SPARK%' and spr_11.rn = 1
              order by spr_11.measurementscale, spr_11.cohort, spr_11.lastfirst
              ) sq_1
        ) sq_2
group by sq_2.measurementscale
        ,sq_2.cohort
        ,sq_2.interp
order by measurementscale, cohort, interp