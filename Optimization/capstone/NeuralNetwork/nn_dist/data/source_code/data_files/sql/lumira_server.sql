-- http://help.sap.com/businessobject/product_guides/vi01/en/lumS115_user_en.pdf
-- http://help.sap.com/boall_en/

DROP USER LUMIRAUSER;
CREATE USER LUMIRAUSER PASSWORD Password1;
CALL GRANT_ACTIVATED_ROLE('sap.bi.common::BI_DATA_ANALYST','LUMIRAUSER');
CALL GRANT_ACTIVATED_ROLE('sap.bi.common::BI_TECH_USER','LUMIRAUSER');
GRANT MODELING TO LUMIRAUSER;
GRANT REPO.READ ON "live2_views" TO LUMIRAUSER;

-- %%%% Lumira Server Demo %%%%
Remember to change Tweets Table to Tweets_for_Live2CD Table in Analytic View
Build Sentiment Analyis Over Time Stacked Bar Chart

-- reset
delete from "LIVE2"."Tweets_for_Live2CD"
where "tweetId" > 9990;
delete from "LIVE2"."$TA_MYINDEX_VOC_WITH_LIVE2CD"
where "tweetId" > 9990;
SELECT count(*) FROM "LIVE2"."$TA_MYINDEX_VOC_WITH_LIVE2CD"
where TA_TYPE = 'WeakPositiveSentiment';
-- insert new data
insert into "LIVE2"."Tweets_for_Live2CD"
values(9991,1,'2008.9.27 01:01:00 AM','Liked the speech by Obama !');
-- select new insert
SELECT * FROM "LIVE2"."Tweets_for_Live2CD"
order by 3 asc;
-- select new data in index table
SELECT * FROM "LIVE2"."$TA_MYINDEX_VOC_WITH_LIVE2CD"
order by 1 desc;
SELECT count(*) FROM "LIVE2"."$TA_MYINDEX_VOC_WITH_LIVE2CD"
where TA_TYPE = 'WeakPositiveSentiment';
