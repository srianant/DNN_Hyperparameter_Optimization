delete from npc_monstersay;
REPLACE npc_monstersay (entry, event, chance, language, type, monstername, text0, text1, text2, text3, text4)
SELECT entry, event, chance, language, type, monstername, text0, text1, text2, text3, text4
FROM npc_monstersay_localized where (`language_code`='deDE');