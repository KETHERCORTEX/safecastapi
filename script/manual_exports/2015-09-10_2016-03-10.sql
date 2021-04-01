-- This script is invoked by `dump_measurements_ios_periods.sh`
-- It exports a "snapshot" or 6-month timeslice.

-- It should not be called directly
-- It will output a CSV in `/tmp/` and take ~30 mins to run

-- This is a clone of `ios_query.sql` (as of 2017-01-21), with the following changes:
-- 1. `iOSLastExport` table references removed
-- 2. 6-month date range added to query
-- 3. Output CSV name changed to include date range

-- ATTENTION!  This should not be run at the same time as any export jobs on the server.
--             There may be name collisions on the temp tables, but even if not, it will
--             cause DB server timeouts.  Thus, the normal export jobs should be disabled
--             then re-enabled after these scripts are run.

-- =================
-- Maintenance Notes
-- =================
--
-- This script is a clone of `ios_query.sql` and intended to be run very infrequently.
-- Before running it, it is recommended to bring the query SQL up to date with `ios_query.sql`
-- as there may be changed to `ios_query.sql` made after the last update of this file, such
-- as to the blacklists in the WHERE clause.
--
-- Ultimately, this process mirrors the normal iOS / OSX data export to create a SQLite3
-- XYZ DB.
-- 
-- The following steps are then performed:
-- 
-- -----------------
-- TILE DB CREATION:
-- -----------------
-- 1. The `.sqlite` file is manually downloaded to a development OS X machine.
-- 2. A development copy of the Safecast OS X app should be open in XCode
-- 3. The .sqlite file is moved to `~/Library/Containers/com.ndolezal.GeigerBotOSX/Data/Documents/ios13download.sqlite`
-- 4. In the OS X app, in the file `GeigerBotDataUpdater.m`, line 11 is uncommented (`#define TEST_MODE_KEEP_DOWNLOAD 1`)
-- 5. The app is run in Xcode
-- 6. `Layers` > `Update Safecast Data` is performed, with compression specified as `DEFLATE`.
-- 7. After the data update, `~/Library/Containers/com.ndolezal.GeigerBotOSX/Data/Documents/safecast-2014-03-11.sqlite`
--    is renamed appropriately for the time period (eg, `safecast-2011-03-10_2011-09-10.sqlite`).
-- -------------------
-- ADD TILE DB TO APP:
-- -------------------
-- 8. This renamed tile database is then copied to the development path of the app, and added to the project in XCode.
--    (Make sure target membership is checked)
-- 9. In `gbDLR.c`, the extent is manually added to `gbDLR_GetExtent_ForLayerId()`.
--    This can be found by opening a command prompt then:
--      `> sqlite3 safecast-2011-03-10_2011-09-10.sqlite`
--      `> SELECT MIN(TileX) AS MinX, MAX(TileX) AS MaxX, MIN(TileY) AS MinY, MAX(TileY) AS MaxY FROM Tiles WHERE TileLevel = 13;`
--      `> .quit`
-- 10. In `gbDLR.c`, `gbDLR_GetMaxLayerId()` is changed to return a hardcoded value including the new layer as appropriate.
--     (eg, increment by 1)
-- 11. In `gbDLR.c`, `gbDLR_GetUnimplemented_ForLayerId()` is changed to remove any references to the layer as appropriate.
-- 12. In `MainMenu.xib`, the slider control for the `Safecast Snapshots` window (`winTimeSlice`) has an additional tick 
--     added by incrementing the max value.
-- ---------------------
-- EXPORT TILES AS PNGS:
-- ---------------------
-- 13. Re-run the app
-- 14. Now, export the tiles as PNGs for the webmap.
--     1. LUT: `Cyan Halo`, Discretize: `64`, Min: `0.03`, Max: `65.54`, Scale: `LOG10`
--     2. Custom Layer:
--          - Layer 1: <timeslice>
--              - PreFx: `Smart Resize 3x3`
--              - PostFx: `Shadow Halo`
--              - Alpha: 100%
--     3. `Layer` -> `Export PNG Tileset From Layer`
--          - Max Zoom Level: `17`
--          - Only Export Primary Layer: `NO`
--          - Optimize For All Displays: `YES`
--          - Click `Export`, wait
--     4. Next, re-export low zoom levels for bitmap indexing.  It's
--        inefficient to do this for the higher zoom levels.
--     5. Custom Layer:
--          - Layer 1: <timeslice>
--              - PreFx: `None`
--              - PostFx: `None`
--              - Alpha: 100%
--          - Layer 2: <timeslice>
--              - PreFx: `Smart Resize 3x3`
--              - PostFx: `Shadow Halo`
--              - Alpha: 95%
--     6. `Layer` -> `Export PNG Tileset From Layer`
--          - Max Zoom Level: `9`
--          - Only Export Primary Layer: `NO`
--          - Optimize For All Displays: `YES`
--          - Click `Export`, wait
-- -----------------------
-- RETILE TO 512X512 PNGS:
-- -----------------------
-- 15. Make a script for Retile with one line per zoom level using the syntax: 
--     ============= <TODO> =============
-- -----------------------
-- TRANSFER TO MIT SERVER:
-- -----------------------
-- 16. Create a TAR archive of the 512x512 tiles only:
--     ============= <TODO> =============
-- -----------------
-- SYNC TILES TO S3:
-- -----------------
-- 17. Connect to `safecast.media.mit.edu` via SSH or VNC.
-- 18. Extract the archive to a temp directory, but also leave the original in the Tilemap path at 
--     `\Library\WebServer\Documents\Tilemap\<filename>.tar.gz` to ensure it is backed up.
-- 19. Create a script to sync all zoom levels to both US and JP S3 buckets, examples can be found at:
--     ============= <TODO> =============
-- 20. Run script and wait.  Delete the extracted files when done.
-- 22. NOTE: Make sure to disable the server's normal sync process and tile creation!
-- --------------
-- UPDATE WEBMAP:
-- --------------
-- 23. After S3 sync, update the Tilemap's `index.html` to add an additional tick to the `tsSlider` control.
--      - This is done by incrementing the `max` property of the element.
-- 24. Next, edit `SafecastDateHelper.GetTimeSliceLayerDateRangesUTC()` in `safemap.js`.
--      - Uncomment the line of the new timeslice and add it to the array.
-- 25. Update the slider image embedded as a base64 image in `index.html` near the `tsSlider` control to have an additional tick.
--     It will take some degree of trial and error to get the tick marks to align with the slider.  The algorithm used by
--     browsers for this is unknown.  Note the slider image should saved as a grayscale+alpha PNG, then optimized with `optipng`,
--     before base64 conversion.
-- 25. Minify `safemap.js` -> `safemap_min.js` and deploy along with `index.html`.
--
--
-- Note the above steps reflect adding a new timeslice in chronological order.  If updating, some of the steps should obviously be skipped.


SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

BEGIN TRANSACTION;
     CREATE TEMPORARY TABLE IF NOT EXISTS Temp1(X1 INT, Y1 INT, captured_at INT2, DRE FLOAT4);
     TRUNCATE TABLE Temp1;
COMMIT TRANSACTION;

BEGIN TRANSACTION;

INSERT INTO Temp1(X1, Y1, captured_at, DRE)
SELECT CAST( 
              (ST_X(location::geometry) + 180.0) * 5825.422222222222 + 0.5 
            AS INT
           )
       + (CASE WHEN (user_id = 347) THEN 2 ELSE 0 END)
       AS X1
    ,CAST(
            (0.5 - LN(  (1.0 + SIN(ST_Y(location::geometry) * 0.0174532925199433))
                      / (1.0 - SIN(ST_Y(location::geometry) * 0.0174532925199433)))
                   * 0.0795774715459477
            ) * 2097152.0 + 0.5 
          AS INT
         )
     + (CASE WHEN (user_id = 347) THEN -2 ELSE 0 END)
     AS Y1
    ,CAST( 
            EXTRACT(epoch FROM captured_at) / 86400 
          AS INT2
         )
     + (CASE WHEN (user_id = 347) THEN -730 ELSE 0 END)
     AS captured_at
    ,CASE
        WHEN unit='cpm' AND device_id IS NULL                     THEN value * 0.0029940119760479
        WHEN unit IN ('microsievert','usv')                       THEN value
        WHEN unit='cpm' AND device_id IN (5,15,16,17,18,22,69,89) THEN value * 0.0028571428571429
        WHEN unit='cpm' AND device_id IN (6,7,11,13,23)           THEN value * 0.01
        WHEN unit='cpm' AND device_id IN (4,9,10,12,19,24)        THEN value * 0.0075757575757576
        WHEN unit='cpm' AND device_id=21 AND user_id=530          THEN value * 0.0000909090909090909
        WHEN unit='cpm' AND device_id IN (21)                     THEN value * 0.0005714285714285714
        ELSE 0.0
    END 
    AS DRE
FROM measurements
WHERE captured_at IS NOT NULL
    AND captured_at >= TIMESTAMP '2015-09-10 15:00:00'
    AND captured_at <  TIMESTAMP '2016-03-10 15:00:00'
    AND (   measurement_import_id NOT IN (SELECT id FROM measurement_imports WHERE subtype NOT IN ('None', 'Drive'))
         OR measurement_import_id IS NULL)
    AND id NOT BETWEEN 23181608 AND 23182462 
    AND id NOT BETWEEN 20798302 AND 20803607 
    AND id NOT BETWEEN 21977826 AND 21979768 
    AND id NOT BETWEEN 24060795 AND 24067649 
    AND id NOT IN (13194822,15768545,15768817,15690104,15768346,15768782,15768792,16381794,18001818,17342620,14669786,25389168,25389158,25389157,25389153,24482487,16537265,16537266,19554057,19554058,19554059,19554060,19555677,19589301,19589302,19589303,19589304,19589305,19589303,19589304,19589305,19600634,19699406,17461603,17461607,17461611,17461615,16981355,16240105,16240101,16240097,16240093,16241392,16241388,18001769,25702033,25702031,72588855)
    AND id NOT IN (14764408,14764409,14764410,14764411,14764412,14764413,13872611,13872612,14764388,14764389,14764390,14764391,14764392,14764393,14764394,14764395,14764396,14764397,14764398,14764399,14764400,14764401,14764402,14764403,14764404,14764405,14764406,14764407) 
    AND id NOT IN (33708769,33708779,33709181,33709199,33709164,39366523,39417687,63242347,63347043,55846508,55846405,55846384)
    AND id NOT IN (40660074, 40660076, 60030299, 60030298, 60030297, 60030296, 24836479, 24836480, 24836482, 24836481, 24836485, 24836483, 24836484, 40790198, 40790201, 40790203, 14864065, 14880942, 14885129, 14801612, 14864081, 14880681, 14880718, 14880838, 14880927, 14880975, 14885086, 14885150, 14885165, 14885185, 15084125, 15084258, 15100856, 15768545, 15768826, 15821550, 40660078, 40660079, 56193501, 56193500, 56193499, 56193498, 56193497, 56193496) 
    AND id NOT BETWEEN 48821163 AND 48825707 
    AND id NOT BETWEEN 51725281 AND 51730948 
    AND id NOT BETWEEN 54522618 AND 54523174 
    AND id NOT BETWEEN 55671785 AND 55676469 
    AND id NOT BETWEEN 56496499 AND 56499124 
    AND id NOT BETWEEN 59724187 AND 59724235 
    AND id NOT IN (66684139,69542903) 
    AND id NOT IN (70555855,70555854,70555853,70555852,70555851,70555850,70555849,70555848,70555847,70555846,70555845,70555844,70555813,70555812,70555811,70555810,70555809,70555808,70555807,70555806,70555805,70555804,70555803,70555802,70555353,70555352,70555351,70555350,70555349,70555348,70555347,70555346,70555345,70555344,70555343,70555342,70555341,70554461,70554460,70554459,70554458,70554457,70554456,70554455,70554454,70554453,70554452,70554451,70554450,70554449) 
    AND id NOT IN (66071904,70321927,70321926,70321925,70321924,70321923,70321922,70321921,70321920,70321919,70321918,70321975,70321974) 
    AND id NOT BETWEEN 42741132 AND 42743148 
    AND id NOT BETWEEN 26158517 AND 26158723 
    AND id NOT BETWEEN 26157859 AND 26158516 
    AND id NOT BETWEEN 54806156 AND 54806236 
    AND id NOT BETWEEN 39712555 AND 39713449 
    AND id NOT BETWEEN 36736478 AND 36736489 
    AND id NOT BETWEEN 42129750 AND 42129806 
    AND (id NOT BETWEEN 28484658 AND 29430580 OR user_id != 9)
    AND id NOT IN (17573243,17573245,17573249,17573252,17573254,17573256,17573258,17573262,17573265,17573268,17573271,17573274,17573278,17573281,17573284,17573287,17573290,17573292,17573294,17573296,17573299,17573303,17573307,17573310,17573313,17573316,17573319,17573323,17573327,17573329,17573332,17573335,17573338,17573341,17573345,17573348,17573350,17573352,17573355,17573358,17573363,17573367,17573370,17573372,17573376,17573379,17573382,17573385,17573388,17573392,17573395,17573399,17573401,17573404,17573407,17573410,17573413,17573417,17573420,17573423,17573426,17573429,17573432,17573435,17573438,17573441,17573444,17573447,17573450,17573453,17573456,17573459,17573462,17573465,17573468,17573472,17573475,17573478,17573481,17573484,17573487,17573491,17573495,17573499,17573503,17573507,17573512,17573516,17573520,17573524,17573528,17573532,17573536,17573540,17573544,17573548,17573552,17573556,17573560,17573564,17573569,17573573)
    AND id NOT IN (57830339,57830338,57830337,57830336,57830335,57830334,57830332,57830330,57830329,57830326,57830324,57830322) 
    AND id NOT IN (43199883,43199875,75302533,43200647,66567253,66569229,66567254,66569231,66080351,72588855,77757657,77757750,68466104,68466223,68466103,68466103)
    AND id NOT BETWEEN 47531878 AND 47532148
    AND id NOT BETWEEN 17682519 AND 17682905
    AND user_id NOT IN (345,902,1032,1225,106)
    AND value       IS NOT NULL
    AND location    IS NOT NULL
    AND (   (unit  = 'cpm' AND (   (    device_id IS NULL     AND value BETWEEN 10.00 AND 350000.0) 
                                OR ((   device_id <= 24 
                                     OR device_id IN (69,89)) AND value BETWEEN 10.00 AND  30000.0)))
         OR (unit IN ('microsievert','usv')                   AND value BETWEEN  0.02 AND      5.0))
    AND (   ST_X(location::geometry) >  1.0
         OR ST_X(location::geometry) < -1.0
         OR ST_Y(location::geometry) >  1.0
         OR ST_Y(location::geometry) < -1.0)
    AND ST_Y(location::geometry) BETWEEN  -85.05 AND  85.05
    AND ST_X(location::geometry) BETWEEN -180.00 AND 180.00
    AND (   user_id NOT IN (9,442)
         OR value        < 35.0
         OR ST_Y(location::geometry) NOT BETWEEN  35.4489 AND  35.7278
         OR ST_X(location::geometry) NOT BETWEEN 139.5706 AND 139.9186)
    AND (   user_id != 366
         OR value    <  35.0
         OR ST_Y(location::geometry) NOT BETWEEN -45.5201 AND  -7.6228
         OR ST_X(location::geometry) NOT BETWEEN 111.3241 AND 153.8620
         OR (value < 105.0 AND ST_X(location::geometry) < 111.3241)   );
COMMIT TRANSACTION;




BEGIN TRANSACTION;
     CREATE INDEX idx_Temp1_X1Y1CD ON Temp1(X1,Y1,captured_at);
COMMIT TRANSACTION;


BEGIN TRANSACTION;
     UPDATE Temp1 SET X1 =       0 WHERE X1 <       0;
     UPDATE Temp1 SET X1 = 2097151 WHERE X1 > 2097151;
     UPDATE Temp1 SET Y1 =       0 WHERE Y1 <       0;
     UPDATE Temp1 SET Y1 = 2097151 WHERE Y1 > 2097151;
COMMIT TRANSACTION;


BEGIN TRANSACTION;
     CREATE TEMPORARY TABLE IF NOT EXISTS Temp2(X INT,Y INT,T INT2,Z FLOAT4);
     TRUNCATE TABLE Temp2;
     INSERT INTO Temp2(X,Y,T) 
     SELECT X1
           ,Y1
           ,MAX(captured_at) - 270 
     FROM Temp1 
     GROUP BY X1,Y1;
COMMIT TRANSACTION;



BEGIN TRANSACTION;
     UPDATE Temp2 SET Z = (SELECT AVG(DRE) FROM Temp1 WHERE X1=X AND Y1=Y AND captured_at > T);
     DROP TABLE Temp1;
COMMIT TRANSACTION;

\copy (SELECT X,Y,CAST(Z*1000.0 AS INT) FROM Temp2 ORDER BY ((Y>>20)<<1)+(X>>20),((Y>>19)<<2)+(X>>19),((Y>>18)<<3)+(X>>18),((Y>>17)<<4)+(X>>17),((Y>>16)<<5)+(X>>16),((Y>>15)<<6)+(X>>15),((Y>>14)<<7)+(X>>14),((Y>>13)<<8)+(X>>13),((Y>>12)<<9)+(X>>12),((Y>>11)<<10)+(X>>11),((Y>>10)<<11)+(X>>10),((Y>>9)<<12)+(X>>9),((Y>>8)<<13)+(X>>8)) to '/tmp/ios13_32_2015-09-10_2016-03-10.csv' csv

BEGIN TRANSACTION;
     DROP TABLE Temp2;
COMMIT TRANSACTION;



