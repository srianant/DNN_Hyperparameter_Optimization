DELETE FROM `vendors` WHERE `entry` NOT IN (SELECT `entry` FROM `creature_proto`);
DELETE FROM `vendors` WHERE `item` NOT IN (SELECT `entry` FROM `items`);

DELETE FROM `creature_waypoints` WHERE `spawnid` NOT IN (SELECT `id` FROM `creature_spawns`);

DELETE FROM `trainer_spells` WHERE `entry` NOT IN (SELECT `entry` FROM `creature_proto`);
DELETE FROM `trainer_defs` WHERE `entry` NOT IN (SELECT `entry` FROM `creature_proto`);
DELETE FROM `trainer_spells` WHERE `entry` NOT IN (SELECT `entry` FROM `trainer_defs`);
DELETE FROM `trainer_defs` WHERE `entry` NOT IN (SELECT `entry` FROM `trainer_spells`);

DELETE FROM `creature_quest_starter` WHERE `quest` NOT IN (SELECT `entry` FROM `quests`);
DELETE FROM `creature_quest_finisher` WHERE `quest` NOT IN (SELECT `entry` FROM `quests`);
DELETE FROM `gameobject_quest_starter` WHERE `quest` NOT IN (SELECT `entry` FROM `quests`);
DELETE FROM `gameobject_quest_finisher` WHERE `quest` NOT IN (SELECT `entry` FROM `quests`);

DELETE FROM `creature_quest_starter` WHERE `id` NOT IN (SELECT `entry` FROM `creature_proto`);
DELETE FROM `creature_quest_finisher` WHERE `id` NOT IN (SELECT `entry` FROM `creature_proto`);
DELETE FROM `gameobject_quest_starter` WHERE `id` NOT IN (SELECT `entry` FROM `gameobject_names`);
DELETE FROM `gameobject_quest_finisher` WHERE `id` NOT IN (SELECT `entry` FROM `gameobject_names`);

DELETE FROM `itemloot` WHERE `itemid` NOT IN (SELECT `entry` FROM `items`);
DELETE FROM `gameobjectloot` WHERE `itemid` NOT IN (SELECT `entry` FROM `items`);
DELETE FROM `creatureloot` WHERE `itemid` NOT IN (SELECT `entry` FROM `items`);
DELETE FROM `pickpocketingloot` WHERE `itemid` NOT IN (SELECT `entry` FROM `items`);
DELETE FROM `fishingloot` WHERE `itemid` NOT IN (SELECT `entry` FROM `items`);
DELETE FROM `skinningloot` WHERE `itemid` NOT IN (SELECT `entry` FROM `items`);
DELETE FROM `prospectingloot` WHERE `itemid` NOT IN (SELECT `entry` FROM `items`);

DELETE FROM `itemloot` WHERE `entryid` NOT IN (SELECT `entry` FROM `items`);
DELETE FROM `prospectingloot` WHERE `entryid` NOT IN (SELECT `entry` FROM `items`);
DELETE FROM `fishingloot` WHERE `entryid` NOT IN (SELECT `Zone` FROM `fishing`);
DELETE FROM `gameobjectloot` WHERE `entryid` NOT IN (SELECT `entry` FROM `gameobject_names`);
DELETE FROM `creatureloot` WHERE `entryid` NOT IN (SELECT `entry` FROM `creature_proto`);
DELETE FROM `pickpocketingloot` WHERE `entryid` NOT IN (SELECT `entry` FROM `creature_proto`);
DELETE FROM `skinningloot` WHERE `entryid` NOT IN (SELECT `entry` FROM `creature_proto`);