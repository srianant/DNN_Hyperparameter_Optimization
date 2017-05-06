-- Smart_Data_Access.sql
-- Remote Data Sources

-- Remote HANA Data Source Connection
DROP REMOTE SOURCE REMOTE_HANA CASCADE;
CREATE REMOTE SOURCE REMOTE_HANA 
ADAPTER "odbc" 
CONFIGURATION 'DSN=REMOTEHDB' 
WITH CREDENTIAL TYPE 'PASSWORD' 
USING 'user=sourceuser;password=SHALive1';

-- Remote HANA Data Source Insert  
delete from "LIVE2"."Members";
insert into "LIVE2"."Members"
select * from "LIVE2"."REMOTE_HANA_SOURCEMEMBERS";

delete from "LIVE2"."Connections";
insert into "LIVE2"."Connections"
select * from "LIVE2"."REMOTE_HANA_SOURCECONNECTIONS";

delete from "LIVE2"."Tweets";
insert into "LIVE2"."Tweets"
select * from "LIVE2"."REMOTE_HANA_SOURCETWEETS";

delete from "LIVE2"."Timewindow";
insert into "LIVE2"."Timewindow"
select * from "LIVE2"."REMOTE_HANA_SOURCETIMEWINDOW";

-- -- Remote HANA Data Source Verification 
select count(*) from "LIVE2"."Members";
select count(*) from "LIVE2"."Connections";
select count(*) from "LIVE2"."Tweets";
select count(*) from "LIVE2"."Timewindow";

-- Remote Hadoop Data Source Connection
DROP REMOTE SOURCE HADOOP CASCADE;
CREATE REMOTE SOURCE HADOOP 
ADAPTER "hiveodbc" 
CONFIGURATION 'DSN=HIVE' 
WITH CREDENTIAL TYPE 'PASSWORD' 
USING 'user=hive;password=SHa12345';

-- Remote Hadoop Data Source Insert  
delete from "LIVE2"."Members";
insert into "LIVE2"."Members"
select * from "LIVE2"."HADOOP_members";

delete from "LIVE2"."Connections";
insert into "LIVE2"."Connections"
select * from "LIVE2"."HADOOP_connections";

delete from "LIVE2"."Tweets";
insert into "LIVE2"."Tweets"
select * from "LIVE2"."HADOOP_tweets"
where "tweetid" < 3239;

delete from "LIVE2"."Timewindow";
insert into "LIVE2"."Timewindow"
select * from "LIVE2"."HADOOP_timewindow";

-- -- Remote Hadoop Data Source Verification 
select count(*) from "LIVE2"."Members";
select count(*) from "LIVE2"."Connections";
select count(*) from "LIVE2"."Tweets";
select count(*) from "LIVE2"."Timewindow";