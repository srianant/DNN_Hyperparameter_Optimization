-- ------------
-- linganalysis
-- ------------

DROP SCHEMA "TA" CASCADE;
CREATE SCHEMA "TA";

-- simple example for linganalysis
CREATE COLUMN TABLE "TA"."A_TA_LING_EXAMPLE"
(
ID INTEGER PRIMARY KEY, 
STRING nvarchar(200)
)
;

-- insert some data
INSERT INTO "TA"."A_TA_LING_EXAMPLE" VALUES (1, 'Bob works at SAP.');

-- create index for text analysis
CREATE FULLTEXT INDEX myindex_ling ON "TA"."A_TA_LING_EXAMPLE" ("STRING")
CONFIGURATION 'LINGANALYSIS_FULL'
TEXT ANALYSIS ON;

-- create index with linganalysis on tweet data
DROP FULLTEXT INDEX "LIVE2"."MYINDEX_LING";
CREATE FULLTEXT INDEX myindex_ling ON "LIVE2"."Tweets" ("tweetContent")
-- CONFIGURATION 'EXTRACTION_CORE_VOICEOFCUSTOMER'
CONFIGURATION 'LINGANALYSIS_FULL'
TEXT ANALYSIS ON;

-- view text analysis table
SELECT * FROM "LIVE2"."$TA_MYINDEX_LING" ORDER BY "tweetId", TA_COUNTER ASC;

-- Select top 20 "tokens" from tweets
SELECT TOP 20 TA_TOKEN, COUNT(*) AS COUNT FROM "LIVE2"."$TA_MYINDEX_LING" GROUP BY TA_TOKEN ORDER BY COUNT DESC;

-- Select top 20 "types" from tweets
SELECT TOP 20 TA_TYPE, COUNT(*) AS COUNT FROM "LIVE2"."$TA_MYINDEX_LING" GROUP BY TA_TYPE ORDER BY COUNT DESC;

-- Select top 20 "nouns" from tweets
SELECT TOP 20 UPPER(TA_TOKEN) as TA_TOKEN, COUNT(*) AS COUNT FROM "LIVE2"."$TA_MYINDEX_LING" 
where TA_TYPE like 'noun' 
GROUP BY UPPER(TA_TOKEN) ORDER BY COUNT DESC;

-- -----------------
-- entity extraction
-- -----------------

-- simple example for entity extraction
CREATE COLUMN TABLE "TA"."A_TA_VOC_EXAMPLE"
(
ID INTEGER PRIMARY KEY, 
STRING nvarchar(200)
)
;

-- insert some data
INSERT INTO "TA"."A_TA_VOC_EXAMPLE" VALUES (1, 'Bob likes SAP.');
INSERT INTO "TA"."A_TA_VOC_EXAMPLE" VALUES (2, 'Bob dislikes exercise. Bob really likes New York');

-- create index for text analysis
CREATE FULLTEXT INDEX myindex_voc ON "TA"."A_TA_VOC_EXAMPLE" ("STRING")
CONFIGURATION 'EXTRACTION_CORE_VOICEOFCUSTOMER'
TEXT ANALYSIS ON;

-- create index with entity extraction on tweet data, which won't work :-(
CREATE FULLTEXT INDEX myindex_voc ON "LIVE2"."Tweets" ("tweetContent")
CONFIGURATION 'EXTRACTION_CORE_VOICEOFCUSTOMER'
-- CONFIGURATION 'LINGANALYSIS_FULL'
TEXT ANALYSIS ON;

-- ... so, create duplicate table
DROP TABLE "LIVE2"."Tweets_for_VOC" CASCADE;
CREATE COLUMN TABLE "LIVE2"."Tweets_for_VOC" ("tweetId" INTEGER CS_INT NOT NULL ,
	 "memberId" INTEGER CS_INT,
	 "tweetDate" LONGDATE CS_LONGDATE,
	 "tweetContent" NVARCHAR(500),
	 PRIMARY KEY ("tweetId")) UNLOAD PRIORITY 5 AUTO MERGE;

-- duplicate the data
INSERT INTO "LIVE2"."Tweets_for_VOC" 
SELECT * FROM "LIVE2"."Tweets";

-- create index with entity extraction on tweet data on COPIED table
CREATE FULLTEXT INDEX myindex_voc ON "LIVE2"."Tweets_for_VOC" ("tweetContent")
CONFIGURATION 'EXTRACTION_CORE_VOICEOFCUSTOMER'
-- CONFIGURATION 'LINGANALYSIS_FULL'
TEXT ANALYSIS ON;

-- view text analysis table
SELECT * FROM "LIVE2"."$TA_MYINDEX_VOC" ORDER BY "tweetId", TA_COUNTER ASC;

-- Select "tokens" from tweets
SELECT TA_TOKEN, COUNT(*) AS COUNT FROM "LIVE2"."$TA_MYINDEX_VOC" GROUP BY TA_TOKEN ORDER BY COUNT DESC;

-- Select "types" from tweets
SELECT TA_TYPE, COUNT(*) AS COUNT FROM "LIVE2"."$TA_MYINDEX_VOC" GROUP BY TA_TYPE ORDER BY COUNT DESC;

-- Select Amount of Senitiment in Tweets
SELECT TA_TYPE as SENTIMENT, COUNT(*) AS COUNT FROM "LIVE2"."$TA_MYINDEX_VOC" 
where TA_TYPE like '%Sentiment%' 
and TA_TYPE != 'Sentiment' 
GROUP BY TA_TYPE ORDER BY COUNT DESC;

-- Select top 20 +ve Senitiments in Tweets
SELECT TOP 20 UPPER(TA_TOKEN) AS TOKEN, COUNT(*) AS COUNT FROM "LIVE2"."$TA_MYINDEX_VOC" 
where TA_TYPE like 'StrongPositiveSentiment' 
GROUP BY UPPER(TA_TOKEN) ORDER BY COUNT DESC;

-- Select top 3 +ve Senitiments in Tweets
SELECT TOP 3 UPPER(TA_TOKEN) AS TOKEN, COUNT(*) AS COUNT FROM "LIVE2"."$TA_MYINDEX_VOC" 
where TA_TYPE like 'StrongNegativeSentiment'
GROUP BY UPPER(TA_TOKEN) ORDER BY COUNT DESC;

-- Select Emoticons in Tweets
SELECT TOP 20 UPPER(TA_TOKEN) AS TOKEN, COUNT(*) AS COUNT FROM "LIVE2"."$TA_MYINDEX_VOC" 
where TA_TYPE like '%eEmoticon' 
GROUP BY UPPER(TA_TOKEN) ORDER BY COUNT DESC;

-- Select Country Mentions in Tweets
-- can deal with multiple USs in Lumira, with CASE, but best of all, with CUSTOM DICTIONARIES
SELECT TOP 20 TOKEN, SUM(COUNT) as COUNT FROM
(SELECT CASE WHEN UPPER(TA_TOKEN) IN ('US','U.S.','AMERICA','USA','UNITED STATES')
THEN ('US') ELSE (UPPER(TA_TOKEN)) END AS TOKEN , COUNT(*) AS COUNT
FROM "LIVE2"."$TA_MYINDEX_VOC"  where TA_TYPE like 'COUNTRY' 
GROUP BY TA_TOKEN ORDER BY COUNT DESC)
GROUP BY TOKEN ORDER BY COUNT DESC;

-- Select Media Company Mentions in Tweets
SELECT TOP 20 UPPER(TA_TOKEN) AS TOKEN, COUNT(*) AS COUNT FROM "LIVE2"."$TA_MYINDEX_VOC" 
where TA_TYPE like 'ORGANIZATION/MEDIA' 
GROUP BY UPPER(TA_TOKEN) ORDER BY COUNT DESC;