DROP SCHEMA LIVE2 CASCADE;

CREATE SCHEMA LIVE2;

SET SCHEMA LIVE2;

-- create 4 tables
CREATE COLUMN TABLE "LIVE2"."Members" (
	 "memberId" INTEGER NOT NULL,
	 "firstName" NVARCHAR(5000),
	 "lastName" NVARCHAR(5000),
	 "email" NVARCHAR(5000),
	 "avatar" NVARCHAR(5000),
	 "lat" DOUBLE,
	 "lon" DOUBLE,
	 PRIMARY KEY ("memberId")
);

CREATE COLUMN TABLE "LIVE2"."Connections" (
	"memberIdFrom" INTEGER NOT NULL,
	"memberIdTo" INTEGER NOT NULL,
	PRIMARY KEY ("memberIdFrom","memberIdTo")
);

CREATE COLUMN TABLE "LIVE2"."Tweets" (
	 "tweetId" INTEGER NOT NULL,
	 "memberId" INTEGER,
	 "tweetDate" TIMESTAMP,
	 "tweetContent" NVARCHAR(500),
	 PRIMARY KEY ("tweetId")
);

CREATE COLUMN TABLE "LIVE2"."Timewindow" (
	 "gmt" LONGDATE CS_LONGDATE NOT NULL ,
	 "est" LONGDATE CS_LONGDATE,
	 "10_MinuteTimeWindow" NVARCHAR(5),
	 "30_MinuteTimeWindow" NVARCHAR(5),
	 PRIMARY KEY ("gmt")
);