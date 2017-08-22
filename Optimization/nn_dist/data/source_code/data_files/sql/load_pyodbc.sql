-- load_py.sql

-- create blob table
CREATE COLUMN TABLE "LIVE2"."MYBINARIES"
(
ID INTEGER PRIMARY KEY, 
STRING BLOB ST_MEMORY_LOB
)
;

-- create full text index
DROP FULLTEXT INDEX "LIVE2"."MYINDEX_BLOB";
CREATE FULLTEXT INDEX myindex_blob ON "LIVE2"."MYBINARIES" ("STRING")
CONFIGURATION 'EXTRACTION_CORE'
TEXT ANALYSIS ON
MIME TYPE 'application/pdf';

-- code to run python to import PDFs
import pyodbc
conn = pyodbc.connect('DRIVER={HDBODBC};SERVERNODE=hana:30115;SERVERDB=DB1;UID=SYSTEM;PWD=SHALive1') #Open connection to SAP HANA  
cur = conn.cursor() #Open a cursor  
file = open('C:/Users/Administrator/Downloads/Debate_Transcript.pdf', 'rb') #Open file in read-only and binary   
content = file.read() #Save the content of the file in a variable  
cur.execute("INSERT INTO LIVE2.MYBINARIES VALUES(?,?)", ('1',content)) #Save the content to the table  
cur.execute("COMMIT") #Save the content to the table  
file.close() #Close the file  
cur.close() #Close the cursor  
conn.close() #Close the connection  