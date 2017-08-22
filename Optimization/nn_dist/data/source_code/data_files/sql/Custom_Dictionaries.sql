-- Custom Dictionaries

-- reset all .. run in studio
DROP USER MYUSER;
DROP TABLE "TA"."A_TA_CD_TABLE" CASCADE;
DROP TABLE "LIVE2"."Tweets_for_CD" CASCADE;

-- give rights to myuser .. run in studio

CREATE USER MYUSER PASSWORD Password1;
GRANT CREATE ANY, ALTER, DROP, EXECUTE, SELECT, INSERT, UPDATE, DELETE, INDEX, DEBUG, TRIGGER, REFERENCES ON SCHEMA LIVE2 TO MYUSER;
GRANT CREATE ANY, ALTER, DROP, EXECUTE, SELECT, INSERT, UPDATE, DELETE, INDEX, DEBUG, TRIGGER, REFERENCES ON SCHEMA TA TO MYUSER;
GRANT REPO.READ, REPO.EDIT_IMPORTED_OBJECTS, REPO.ACTIVATE_IMPORTED_OBJECTS, 
REPO.MAINTAIN_IMPORTED_PACKAGES ON "sap.hana.ta.config" TO MYUSER;
CALL GRANT_ACTIVATED_ROLE('sap.hana.xs.ide.roles::Developer','MYUSER');

-- Using Web IDE
-- http://hana:8001/sap/hana/xs/ide/
-- login as MYSUSER

SELECT TOP 20 TA_TOKEN, COUNT(*) AS COUNT 
FROM "LIVE2"."$TA_MYINDEX_VOC" 
where TA_TYPE like 'PERSON' 
GROUP BY TA_TOKEN
ORDER BY COUNT DESC;

-- Create file "LIVE2_CD.hdbtextdict"
<?xml version="1.0" encoding="UTF-8"?>
<dictionary xmlns="http://www.sap.com/ta/4.0">
	<entity_category name="CANDIDATES">
		<entity_name standard_form="Obama">
			<variant name="Obama" />
			<variant name="Barack Obama" />
			<variant name="Barack" />
			<variant name="Mr. Obama" />
			<variant_generation type="standard" language="english" />
		</entity_name>
		<entity_name standard_form="McCain">
			<variant name="McCain" />
			<variant name="John McCain" />
			<variant name="John" />
			<variant name="McPain" />
			<variant name="McCains" />
			<variant name="Sen. McCain" />
			<variant_generation type="standard" language="english" />
		</entity_name>
	</entity_category>
</dictionary>

-- LIVE2_CC.hdbtextconfig
<string-list-value>sap.hana.ta.config::LIVE2_CD.hdbtextdict</string-list-value>

-- as we need an "old" and "new" index, let's replicate our tweets table
-- we need the table for later on ... so, create duplicate table
DROP TABLE "LIVE2"."Tweets_for_Live2CD" CASCADE;
CREATE COLUMN TABLE "LIVE2"."Tweets_for_Live2CD" ("tweetId" INTEGER CS_INT NOT NULL ,
	 "memberId" INTEGER CS_INT,
	 "tweetDate" LONGDATE CS_LONGDATE,
	 "tweetContent" NVARCHAR(500),
	 PRIMARY KEY ("tweetId")) UNLOAD PRIORITY 5 AUTO MERGE;

-- don't forget to insert some data into it
INSERT INTO "LIVE2"."Tweets_for_Live2CD" 
SELECT * FROM "LIVE2"."Tweets";

-- create the a new sentiment analysis index table on the additional new table
DROP FULLTEXT INDEX "LIVE2"."MYINDEX_VOC_WITH_LIVE2CD";
CREATE FULLTEXT INDEX myindex_voc_with_live2cd ON "LIVE2"."Tweets_for_Live2CD" ("tweetContent")
CONFIGURATION 'sap.hana.ta.config::LIVE2_CC'
TEXT ANALYSIS ON;

-- look at the normalized data
SELECT * FROM "LIVE2"."$TA_MYINDEX_VOC_WITH_LIVE2CD"
WHERE "TA_TYPE" = 'CANDIDATES';

SELECT TA_NORMALIZED, TA_TYPE, TA_TOKEN, COUNT(*) AS COUNT
FROM "LIVE2"."$TA_MYINDEX_VOC_WITH_LIVE2CD"
WHERE "TA_TYPE" = 'CANDIDATES'
GROUP BY TA_NORMALIZED, TA_TYPE, TA_TOKEN
ORDER BY COUNT DESC;

SELECT TA_NORMALIZED, COUNT(*) AS COUNT
FROM "LIVE2"."$TA_MYINDEX_VOC_WITH_LIVE2CD"
WHERE "TA_TYPE" = 'CANDIDATES'
GROUP BY TA_NORMALIZED
ORDER BY COUNT DESC;