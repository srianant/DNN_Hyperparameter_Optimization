DROP SCHEMA LIVE2 CASCADE;

CREATE SCHEMA LIVE2;

SET SCHEMA LIVE2;

CREATE COLUMN TABLE "Members" (
	 "memberId" INTEGER NOT NULL,
	 "firstName" NVARCHAR(5000),
	 "lastName" NVARCHAR(5000),
	 "email" NVARCHAR(5000),
	 "avatar" NVARCHAR(5000),
	 "lat" DOUBLE,
	 "lon" DOUBLE,
	 PRIMARY KEY ("memberId")
);

CREATE COLUMN TABLE "Connections" (
	"memberIdFrom" INTEGER NOT NULL,
	"memberIdTo" INTEGER NOT NULL,
	PRIMARY KEY ("memberIdFrom","memberIdTo")
);
