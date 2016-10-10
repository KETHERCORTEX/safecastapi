SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

-- 2014-10-25 ND: add minor filtering, new device support.

-- =========================
-- ABSTRACT
-- =========================
-- dump_clean and its SQL query, dump_clean.sql, perform a filtered dump of the measurements table per user request.
--
-- The filtering is the same as that used by the iOS app.
--
-- This differs from dump_measurements, which does not filter data at all.
-- The schema returned is also different; redundant/unused columns have been eliminated, and id/user_id finally included.
-- The ORDER BY clause was removed for performance.
--

-- todo: test if this can be multiline, it's difficult to read and maintain in this form

\copy (select id, user_id, captured_at, ST_Y(location::geometry), ST_X(location::geometry), value, unit, device_id from measurements WHERE (measurement_import_id NOT IN (SELECT id FROM measurement_imports WHERE subtype NOT IN ('None', 'Drive')) OR measurement_import_id IS NULL) AND id NOT BETWEEN 23181608 AND 23182462 AND id NOT BETWEEN 20798302 AND 20803607 AND id NOT BETWEEN 21977826 AND 21979768 AND id NOT BETWEEN 24060795 AND 24067649 AND id NOT BETWEEN 54522618 AND 54523174 AND id NOT BETWEEN 55671785 AND 55676469 AND id NOT BETWEEN 59724187 AND 59724235 AND id NOT IN (72588855,13194822,15768545,15768817,15690104,15768346,15768782,15768792,16381794,18001818,17342620,14669786,25389168,25389158,25389157,25389153,24482487,16537265,16537266,19554057,19554058,19554059,19554060,19555677,19589301,19589302,19589303,19589304,19589305,19589303,19589304,19589305,19600634,19699406,17461603,17461607,17461611,17461615,16981355,16240105,16240101,16240097,16240093,16241392,16241388,18001769,25702033,25702031) AND id NOT IN (14764408,14764409,14764410,14764411,14764412,14764413,13872611,13872612,14764388,14764389,14764390,14764391,14764392,14764393,14764394,14764395,14764396,14764397,14764398,14764399,14764400,14764401,14764402,14764403,14764404,14764405,14764406,14764407) AND id NOT IN (33708769,33708779,33709181,33709199,33709164,39366523,39417687,63242347,63347043,55846508,55846405,55846384) AND id NOT IN (40660074, 40660076, 60030299, 60030298, 60030297, 60030296, 24836479, 24836480, 24836482, 24836481, 24836485, 24836483, 24836484, 40790198, 40790201, 40790203, 14864065, 14880942, 14885129, 14801612, 14864081, 14880681, 14880718, 14880838, 14880927, 14880975, 14885086, 14885150, 14885165, 14885185, 15084125, 15084258, 15100856, 15768545, 15768826, 15821550, 40660078, 40660079, 56193501, 56193500, 56193499, 56193498, 56193497, 56193496) AND id NOT BETWEEN 48821163 AND 48825707 AND id NOT BETWEEN 51725281 AND 51730948 AND id NOT BETWEEN 56496499 AND 56499124 AND id NOT IN (66684139,69542903) AND id NOT IN (66071904,70321927,70321926,70321925,70321924,70321923,70321922,70321921,70321920,70321919,70321918,70321975,70321974) AND id NOT BETWEEN 42741132 AND 42743148 AND id NOT BETWEEN 26158517 AND 26158723 AND id NOT BETWEEN 26157859 AND 26158516 AND id NOT BETWEEN 54806156 AND 54806236 AND id NOT BETWEEN 39712555 AND 39713449 AND id NOT BETWEEN 36736478 AND 36736489 AND id NOT BETWEEN 42129750 AND 42129806 AND (id NOT BETWEEN 28484658 AND 29430580 OR user_id != 9) AND id NOT IN (17573243,17573245,17573249,17573252,17573254,17573256,17573258,17573262,17573265,17573268,17573271,17573274,17573278,17573281,17573284,17573287,17573290,17573292,17573294,17573296,17573299,17573303,17573307,17573310,17573313,17573316,17573319,17573323,17573327,17573329,17573332,17573335,17573338,17573341,17573345,17573348,17573350,17573352,17573355,17573358,17573363,17573367,17573370,17573372,17573376,17573379,17573382,17573385,17573388,17573392,17573395,17573399,17573401,17573404,17573407,17573410,17573413,17573417,17573420,17573423,17573426,17573429,17573432,17573435,17573438,17573441,17573444,17573447,17573450,17573453,17573456,17573459,17573462,17573465,17573468,17573472,17573475,17573478,17573481,17573484,17573487,17573491,17573495,17573499,17573503,17573507,17573512,17573516,17573520,17573524,17573528,17573532,17573536,17573540,17573544,17573548,17573552,17573556,17573560,17573564,17573569,17573573)AND id NOT IN (70555855,70555854,70555853,70555852,70555851,70555850,70555849,70555848,70555847,70555846,70555845,70555844,70555813,70555812,70555811,70555810,70555809,70555808,70555807,70555806,70555805,70555804,70555803,70555802,70555353,70555352,70555351,70555350,70555349,70555348,70555347,70555346,70555345,70555344,70555343,70555342,70555341,70554461,70554460,70554459,70554458,70554457,70554456,70554455,70554454,70554453,70554452,70554451,70554450,70554449) AND id NOT IN (57830339,57830338,57830337,57830336,57830335,57830334,57830332,57830330,57830329,57830326,57830324,57830322)  AND user_id NOT IN (345,902,1032) AND captured_at > TIMESTAMP '2011-03-01 00:00:00' AND captured_at < localtimestamp + interval '48 hours' AND captured_at IS NOT NULL AND value IS NOT NULL AND location IS NOT NULL AND ((unit  = 'cpm' AND ((device_id IS NULL AND value BETWEEN 10.00 AND 350000.0) OR ((device_id <= 24 OR device_id IN (69,89)) AND value BETWEEN 10.00 AND 30000.0))) OR (unit IN ('microsievert','usv') AND value BETWEEN 0.02 AND 5.0)) AND (ST_X(location::geometry) != 0.0 OR ST_Y(location::geometry) != 0.0) AND ST_Y(location::geometry) BETWEEN -85.05 AND 85.05 AND ST_X(location::geometry) BETWEEN -180.00 AND 180.00 AND (user_id NOT IN (9,442) OR value < 35.0 OR ST_Y(location::geometry) NOT BETWEEN  35.4489 AND  35.7278 OR ST_X(location::geometry) NOT BETWEEN 139.5706 AND 139.9186) AND (user_id != 366 OR value <  35.0 OR ST_Y(location::geometry) NOT BETWEEN -45.5201 AND -7.6228 OR ST_X(location::geometry) NOT BETWEEN 111.3241 AND 153.8620 OR (value < 105.0 AND ST_X(location::geometry) < 111.3241))) to '/tmp/mclean.csv' csv
