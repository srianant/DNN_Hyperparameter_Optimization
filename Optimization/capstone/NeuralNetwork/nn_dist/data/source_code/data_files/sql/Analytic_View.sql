-- Analytic_View.sql

-- Access Right for Analytic View
-- Fixes issue when refreshing Text Analysis Analytic View
grant select on schema LIVE2 to _SYS_REPO with grant option;

-- if statement for Analytic View for TOKEN/TYPE
if(isnull("TA_NORMALIZED"),UPPER("TA_TOKEN"),UPPER("TA_NORMALIZED"))

-- if statement for Lumira Calculated Dimension for TOKEN/TYPE
if IsNull({TA_NORMALIZED}) then {TA_TOKEN} else {TA_NORMALIZED}