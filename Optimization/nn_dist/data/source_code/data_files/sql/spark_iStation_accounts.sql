select s.schoolid as CAMPUS_ID
      ,sid as id
      ,sfirst as FNAME
      ,slast as LNAME
      ,sgrade as GRADE
      ,sgender as GENDER
      ,susername as DESIRED_STUDENT_USERNAME
      ,spassword as DESIRED_STUDENT_PASSWORD	
      ,tfirst as TFNAME
      ,tlast as TLNAME
      ,email_addr as EMAIL
      ,class as DESIRED_CLASS_IDENTIFIER
from SPARK_STUDENT_ACCTS
join students@PS_TEAM s on sid = s.student_number



