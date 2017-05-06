--god, this is ugly.  but it gets everything that you need...
SELECT sts1.alphascore as TermName
,s.student_number as student_number
,r.schoolid
,sts6.alphascore as TestName
,sts2.alphascore as MeasurementScale
,sts19.alphascore as GrowthMeasureYN
,sts20.numscore as TestDuration
,sts3.numscore as TestRITScore
,sts21.numscore as TestStandardError
,sts5.numscore as TestPercentile
,sts22.numscore as LexileScore
,sts23.numscore as LexileMin
,sts24.numscore as LexileMax
,sts8.alphascore as GoalOneName
,sts7.numscore as GoalOneRITScore
,sts25.numscore as GoalOneStdErr
,sts26.alphascore as GoalOneRange
,sts27.alphascore as GoalOneAdjective
,sts10.alphascore as GoalTwoName
,sts9.numscore as GoalTwoRITScore
,sts28.numscore as GoalTwoStdErr
,sts29.alphascore as GoalTwoRange
,sts30.alphascore as GoalTwoAdjective
,sts12.alphascore as GoalThreeName
,sts11.numscore as GoalThreeRITScore
,sts31.numscore as GoalThreeStdErr
,sts32.alphascore as GoalThreeRange
,sts33.alphascore as GoalThreeAdjective
,sts14.alphascore as GoalFourName
,sts13.numscore as GoalFourRITScore
,sts34.numscore as GoalFourStdErr
,sts35.alphascore as GoalFourRange
,sts36.alphascore as GoalFourAdjective
,sts16.alphascore as GoalFiveName
,sts15.numscore as GoalFiveRITScore
,sts37.numscore as GoalFiveStdErr
,sts38.alphascore as GoalFiveRange
,sts39.alphascore as GoalFiveAdjective
,sts40.numscore as GLEq
,sts2.alphascore || '@' || s.student_number || '@' || sts1.alphascore as Measure_at_Number_at_Term
,sts41.numscore as FallRIT
,sts42.numscore as NormalGrowth
,sts43.numscore as ActualGrowth
,sts44.numscore as PercentOfNormalGrowth
FROM PS.STUDENTTESTSCORE STS1 
join students s on (sts1.studentid = s.id)
left outer join reenrollments r on r.studentid = s.id
join studenttest st1 on sts1.studenttestid = st1.id
join test t1 on st1.testid = t1.id and t1.name = 'MAP Comprehensive'
join studenttestscore sts2 on sts1.studenttestid = sts2.studenttestid and sts2.alphascore in ('Mathematics','Reading')
     join testscore ts2 on sts2.testscoreid = ts2.id and ts2.name = 'MeasurementScale'
join studenttestscore sts3 on sts1.studenttestid = sts3.studenttestid
     join testscore ts3 on sts3.testscoreid = ts3.id and ts3.name = 'TestRITScore'
join studenttestscore sts4 on sts1.studenttestid = sts4.studenttestid
     join testscore ts4 on sts4.testscoreid = ts4.id and ts4.name = 'TypicalSpringToSpringGrowth' 
join studenttestscore sts5 on sts1.studenttestid = sts5.studenttestid
     join testscore ts5 on sts5.testscoreid = ts5.id and ts5.name = 'TestPercentile'
join studenttestscore sts6 on sts1.studenttestid = sts6.studenttestid
     join testscore ts6 on sts6.testscoreid = ts6.id and ts6.name = 'TestName'
join studenttestscore sts7 on sts1.studenttestid = sts7.studenttestid
     join testscore ts7 on sts7.testscoreid = ts7.id and ts7.name = 'Goal1RITScore'      
join studenttestscore sts8 on sts1.studenttestid = sts8.studenttestid
     join testscore ts8 on sts8.testscoreid = ts8.id and ts8.name = 'Goal1Name'      
join studenttestscore sts9 on sts1.studenttestid = sts9.studenttestid
     join testscore ts9 on sts9.testscoreid = ts9.id and ts9.name = 'Goal2RITScore'  
join studenttestscore sts10 on sts1.studenttestid = sts10.studenttestid
     join testscore ts10 on sts10.testscoreid = ts10.id and ts10.name = 'Goal2Name'      
join studenttestscore sts11 on sts1.studenttestid = sts11.studenttestid
     join testscore ts11 on sts11.testscoreid = ts11.id and ts11.name = 'Goal3RITScore'  
join studenttestscore sts12 on sts1.studenttestid = sts12.studenttestid
     join testscore ts12 on sts12.testscoreid = ts12.id and ts12.name = 'Goal3Name'      
join studenttestscore sts13 on sts1.studenttestid = sts13.studenttestid
     join testscore ts13 on sts13.testscoreid = ts13.id and ts13.name = 'Goal4RITScore'  
join studenttestscore sts14 on sts1.studenttestid = sts14.studenttestid
     join testscore ts14 on sts14.testscoreid = ts14.id and ts14.name = 'Goal4Name' 
join studenttestscore sts15 on sts1.studenttestid = sts15.studenttestid
     join testscore ts15 on sts15.testscoreid = ts15.id and ts15.name = 'Goal5RITScore'  
join studenttestscore sts16 on sts1.studenttestid = sts16.studenttestid
     join testscore ts16 on sts16.testscoreid = ts16.id and ts16.name = 'Goal5Name'  
join studenttestscore sts17 on sts1.studenttestid = sts17.studenttestid
     join testscore ts17 on sts17.testscoreid = ts17.id and ts17.name = 'Goal6RITScore'  
join studenttestscore sts18 on sts1.studenttestid = sts18.studenttestid
     join testscore ts18 on sts18.testscoreid = ts18.id and ts18.name = 'Goal6Name'
join studenttestscore sts19 on sts1.studenttestid = sts19.studenttestid
     join testscore ts19 on sts19.testscoreid = ts19.id and ts19.name = 'GrowthMeasureYN'
join studenttestscore sts20 on sts1.studenttestid = sts20.studenttestid
     join testscore ts20 on sts20.testscoreid = ts20.id and ts20.name = 'TestDurationInMinutes'     
join studenttestscore sts21 on sts1.studenttestid = sts21.studenttestid
     join testscore ts21 on sts21.testscoreid = ts21.id and ts21.name = 'TestStandardError'
join studenttestscore sts22 on sts1.studenttestid = sts22.studenttestid
     join testscore ts22 on sts22.testscoreid = ts22.id and ts22.name = 'LexileScore'
join studenttestscore sts23 on sts1.studenttestid = sts23.studenttestid
     join testscore ts23 on sts23.testscoreid = ts23.id and ts23.name = 'LexileMin'
join studenttestscore sts24 on sts1.studenttestid = sts24.studenttestid
     join testscore ts24 on sts24.testscoreid = ts24.id and ts24.name = 'LexileMax' 
join studenttestscore sts25 on sts1.studenttestid = sts25.studenttestid
     join testscore ts25 on sts25.testscoreid = ts25.id and ts25.name = 'Goal1StdErr'
join studenttestscore sts26 on sts1.studenttestid = sts26.studenttestid
     join testscore ts26 on sts26.testscoreid = ts26.id and ts26.name = 'Goal1Range'
join studenttestscore sts27 on sts1.studenttestid = sts27.studenttestid
     join testscore ts27 on sts27.testscoreid = ts27.id and ts27.name = 'Goal1Adjective'
join studenttestscore sts28 on sts1.studenttestid = sts28.studenttestid
     join testscore ts28 on sts28.testscoreid = ts28.id and ts28.name = 'Goal2StdErr'
join studenttestscore sts29 on sts1.studenttestid = sts29.studenttestid
     join testscore ts29 on sts29.testscoreid = ts29.id and ts29.name = 'Goal2Range'
join studenttestscore sts30 on sts1.studenttestid = sts30.studenttestid
     join testscore ts30 on sts30.testscoreid = ts30.id and ts30.name = 'Goal2Adjective'
join studenttestscore sts31 on sts1.studenttestid = sts31.studenttestid
     join testscore ts31 on sts31.testscoreid = ts31.id and ts31.name = 'Goal3StdErr'
join studenttestscore sts32 on sts1.studenttestid = sts32.studenttestid
     join testscore ts32 on sts32.testscoreid = ts32.id and ts32.name = 'Goal3Range'
join studenttestscore sts33 on sts1.studenttestid = sts33.studenttestid
     join testscore ts33 on sts33.testscoreid = ts33.id and ts33.name = 'Goal3Adjective'
join studenttestscore sts34 on sts1.studenttestid = sts34.studenttestid
     join testscore ts34 on sts34.testscoreid = ts34.id and ts34.name = 'Goal4StdErr'
join studenttestscore sts35 on sts1.studenttestid = sts35.studenttestid
     join testscore ts35 on sts35.testscoreid = ts35.id and ts35.name = 'Goal4Range'
join studenttestscore sts36 on sts1.studenttestid = sts36.studenttestid
     join testscore ts36 on sts36.testscoreid = ts36.id and ts36.name = 'Goal4Adjective'
join studenttestscore sts37 on sts1.studenttestid = sts37.studenttestid
     join testscore ts37 on sts37.testscoreid = ts37.id and ts37.name = 'Goal5StdErr'     
join studenttestscore sts38 on sts1.studenttestid = sts38.studenttestid
     join testscore ts38 on sts38.testscoreid = ts38.id and ts38.name = 'Goal5Range'
join studenttestscore sts39 on sts1.studenttestid = sts39.studenttestid
     join testscore ts39 on sts39.testscoreid = ts39.id and ts39.name = 'Goal5Adjective'
join studenttestscore sts40 on sts1.studenttestid = sts40.studenttestid
     join testscore ts40 on sts40.testscoreid = ts40.id and ts40.name = 'GLEq'
join studenttestscore sts41 on sts1.studenttestid = sts41.studenttestid
     join testscore ts41 on sts41.testscoreid = ts41.id and ts41.name = 'PairedFallRIT'
join studenttestscore sts42 on sts1.studenttestid = sts42.studenttestid
     join testscore ts42 on sts42.testscoreid = ts42.id and ts42.name = 'NormalGrowth'
join studenttestscore sts43 on sts1.studenttestid = sts43.studenttestid
     join testscore ts43 on sts43.testscoreid = ts43.id and ts43.name = 'ActualGrowth'
join studenttestscore sts44 on sts1.studenttestid = sts44.studenttestid
     join testscore ts44 on sts44.testscoreid = ts44.id and ts44.name = 'PercentOfNormalGrowth'     
     
WHERE STS1.ALPHASCORE in ('Spring 2011') and s.schoolid in ('73254') and r.exitdate > '01-Jul-10'
order by s.schoolid, r.grade_level, s.lastfirst