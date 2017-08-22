SELECT s.lastfirst
      ,s.grade_level
      ,sri_base_11.lexile as lexile_base
      ,sri_T1_11.lexile   as lexile_T1
      ,sri_T2_11.lexile   as lexile_T2
      ,sri_T3_11.lexile   as lexile_T3
      ,sri_base_11.nce    as nce_base
      ,sri_T1_11.nce      as nce_T1
      ,sri_T2_11.nce      as nce_T2
      ,sri_T3_11.nce      as nce_T3
      ,sri_T1_11.lexile - sri_base_11.lexile as T1_cumulative_lexile_change
      ,sri_T2_11.lexile - sri_base_11.lexile as T2_cumulative_lexile_change
      ,sri_T3_11.lexile - sri_base_11.lexile as T3_cumulative_lexile_change
      ,sri_T1_11.nce - sri_base_11.nce       as T1_cumulative_nce_change
      ,sri_T2_11.nce - sri_base_11.nce       as T2_cumulative_nce_change
      ,sri_T3_11.nce - sri_base_11.nce       as T3_cumulative_nce_change
FROM students@PS_TEAM s
LEFT OUTER JOIN sri_testing_history sri_base_11 
             ON to_char(s.student_number) = sri_base_11.base_student_number 
            AND sri_base_11.full_cycle_name = 'Summer School 11-12' 
            AND sri_base_11.rn_cycle = 1
LEFT OUTER JOIN sri_testing_history sri_T1_11
             ON to_char(s.student_number) = sri_T1_11.base_student_number 
            AND sri_T1_11.full_cycle_name = 'End of T1 11-12' 
            AND sri_T1_11.rn_cycle = 1
LEFT OUTER JOIN sri_testing_history sri_T2_11
             ON to_char(s.student_number) = sri_T2_11.base_student_number 
            AND sri_T2_11.full_cycle_name = 'End of T2 11-12' 
            AND sri_T2_11.rn_cycle = 1
LEFT OUTER JOIN sri_testing_history sri_T3_11
             ON to_char(s.student_number) = sri_T3_11.base_student_number 
            AND sri_T3_11.full_cycle_name = 'End of T3 11-12' 
            AND sri_T3_11.rn_cycle = 1              
WHERE s.schoolid = 73252 AND s.enroll_status = 0
ORDER BY s.grade_level, s.lastfirst