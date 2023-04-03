-- *******************************=========================Data Analytics Portfolio project======================******************
-- -----------------------------------------------Check the table-----------------------------------------
SELECT * FROM datacleaning.laptop;

-- -------------------------------------------create backup of the Database --------------------------------------
CREATE TABLE laptop_backup LIKE laptop;
INSERT INTO laptop_backup 
SELECT * FROM laptop;

-- -------------------------------------------Check the size of the dataset------------------------------------------
SELECT DATA_LENGTH FROM information_schema.TABLES
WHERE TABLE_SCHEMA = "datacleaning"
AND TABLE_NAME="laptop";

-- ----------------------------------------------- Drop unnecessary Column --------------------------------------------
ALTER TABLE laptop DROP COLUMN `Unnamed: 0`;

-- -------------------------------------------------- Drop Null Values -------------------------------------------------

CREATE TEMPORARY TABLE temp_index 
SELECT `index` FROM laptop
WHERE Company IS NULL AND TypeName IS NULL AND Inches IS NULL
AND ScreenResolution IS NULL AND Cpu IS NULL AND Ram IS NULL
AND Memory IS NULL AND Gpu IS NULL AND OpSys IS NULL AND
WEIGHT IS NULL AND Price IS NULL;

DELETE FROM laptop 
WHERE `index` IN (SELECT `index` FROM temp_index);


-- ------------------------------------------------Drop duplicate values --------------------------------------------------
-- ****14 Duplicate are available *****
CREATE  TEMPORARY TABLE temp_indexx
SELECT MIN(`index`) FROM laptop 
GROUP BY Company,TypeName,Inches,ScreenResolution,Cpu,Ram,
Memory,Gpu,OpSys,Weight,Price
HAVING COUNt(*) > 1;

DELETE FROM laptop WHERE `index` IN (SELECT * FROM temp_indexx);

-- ------------------------------------ Convert the `inches` column datatype to decimal--------------------------------------

ALTER TABLE laptop MODIFY COLUMN Inches DECIMAL(10,2);

-- -----------------------------------Clean the RAM  like GB,column and change it to integer----------------------------------
UPDATE laptop 
SET Ram = REPLACE(Ram,'GB','');
ALTER TABLE laptop MODIFY COLUMN Ram INTEGER;

-- ------------------------------ Split the weight '1.37kg' to '1.37' and Convert it to float ---------------------------------
UPDATE laptop 
SET Weight =REPLACE(Weight,'kg','');

-- ------ we have some incorrect vlaues so we use the this commad to replace this  type of values
UPDATE laptop SET Weight = 0
WHERE Weight = '?';

--  ---------------------------------------now convert this column datatype ----------------------------------------------------
ALTER TABLE laptop MODIFY COLUMN Weight DECIMAL(10,2);

-- ------------------Inches column have values like 10.30 so here is need to remove last 0 values from Inches column---------------
ALTER TABLE laptop MODIFY COLUMN  Inches TEXT;
UPDATE laptop SET Inches =TRUNCATE(Inches,1);


-- --------------------------Price column in double formate datatype and float values so covert it to Integer -----------------------
CREATE TEMPORARY TABLE temp_laptop1 AS
SELECT `index`, ROUND(Price) AS rounded_price
FROM laptop;

UPDATE laptop l1
JOIN temp_laptop1 t ON l1.`index` = t.`index`
SET l1.Price = t.rounded_price;

-- Drop temporary table 
DROP TABLE temp_laptop1;
-- -----------------------------------------OpSys column have incorrect values so convert it to proper values------------------------
-- give the proper values for column
-- use if else statement in mysql using CASE stetement,
SELECT * FROM laptop;
SELECT OpSys, 
CASE
	WHEN OpSys LIKE '%mac%' THEN 'macos'
    WHEN OpSys LIKE 'windows%' THEN 'windows'
    WHEN OpSys LIKE '%linux%' THEN 'linux'
    WHEN OpSys LIKE 'No OS' THEN 'N/A'
END AS 'os_brand'
FROM laptop;
--  Then update this kind of values in our table
UPDATE laptop
SET OpSys = CASE
	WHEN OpSys LIKE '%mac%' THEN 'macos'
    WHEN OpSys LIKE 'windows%' THEN 'windows'
    WHEN OpSys LIKE '%linux%' THEN 'linux'
    WHEN OpSys LIKE 'No OS' THEN 'N/A'
END;


-- ---------------------Gpu Column have mixed values like 'Gpu brand' and 'Gpu name' here we are separated each other--------------------
-- first add two column Cpu and gpu_brand
ALTER TABLE laptop
ADD COLUMN gpu_brand VARCHAR (255) AFTER Gpu,
ADD COLUMN gpu_name VARCHAR(255) AFTER gpu_brand;

-- this is another way to update the table this is extra method to update the column
UPDATE laptop t1
JOIN (SELECT `index`,SUBSTRING_INDEX(Gpu,' ',1) AS gpu_brand FROM laptop ) t2
ON t1.`index`=t2.`index`
SET t1.gpu_brand = t2.gpu_brand;


-- 2nd way to update the column 
-- create the temporary table

CREATE TEMPORARY TABLE gpu_tem1
SELECT `index`, REPLACE(Gpu,gpu_brand,'') AS "gpu_name" FROM laptop;

-- update the table table with temporary table
UPDATE laptop t1
JOIN gpu_tem1 t2 
ON t1.`index` = t2.`index`
SET t1.gpu_name = t2.gpu_name;

-- Delete the Gpu column because we extract the 'Gpu_name' and 'Gpu_brand'
ALTER TABLE laptop DROP COLUMN Gpu;

-- In the cpu column have three pieces of infomartion such as 'cpu_brand','cpu_name','cpu_speed' so here is need to separated this info----
ALTER TABLE laptop ADD COLUMN cpu_brand VARCHAR(255) AFTER Cpu,
ADD COLUMN cpu_name VARCHAR(255) AFTER cpu_brand,
ADD COLUMN cpu_speed VARCHAR(255) AFTER cpu_name;


-- Create temporary table
CREATE TEMPORARY TABLE cpu_brand
SELECT `index`,SUBSTRING_INDEX(Cpu," ",1) AS "cpu_brand" FROM laptop;


-- update table using temporary table 
UPDATE laptop t1
JOIN cpu_brand t2
ON t1.`index` = t2.`index`
SET t1.cpu_brand = t2.cpu_brand;


-- --------------------now separated the cpu_name------------------------------
CREATE TEMPORARY TABLE tem_cpu1
SELECT `index`,SUBSTRING_INDEX(Cpu,' ',-3) FROM laptop;



SELECT `index`,CAST(REPLACE(SUBSTRING_INDEX(Cpu,' ',-1),'GHz','')
				AS DECIMAL(10,2)) FROM laptop;


-- ----------------------separated the 'Cpu speed'------------------------------------
CREATE TEMPORARY TABLE tem_speed
SELECT `index`,REPLACE(SUBSTRING_INDEX(Cpu,' ',-1),'GHz','') AS 'speed' FROM laptop;

UPDATE laptop t1
JOIN tem_speed t2
ON t1.`index` = t2.`index`
SET t1.cpu_speed = t2.speed;
--  ---------------Convert it to the decimal format ----------------------------

ALTER TABLE laptop MODIFY cpu_speed DECIMAL(10,2);


-- Drop temporary table 
DROP TABLE tem_speed;

-- ------------------separated the 'cpu_name'----------------------------------------

CREATE TEMPORARY TABLE tem_name
SELECT `index`, REPLACE(REPLACE(Cpu,cpu_brand,''),
SUBSTRING_INDEX(REPLACE(Cpu,cpu_brand,''),' ',-1),'') AS 'name' 
FROM laptop;

UPDATE laptop t1
JOIN tem_name t2 
ON t1.`index`= t2.`index`
SET t1.cpu_name = t2.name;


-- ===============This is another way to separated the cpu_name =============
-- CREATE TEMPORARY TABLE tem_name
-- SELECT `index`,
-- SUBSTRING_INDEX(TRIM(cpu_name),' ',2)  AS 'name_1'
-- FROM laptop;


-- UPDATE laptop t1
-- JOIN tem_name t2
-- ON t1.`index` = t2.`index`
-- SET t1.cpu_name = t2.name_1;

-- =================we can also do like  "Second Type Solution"=================
-- UPDATE TABLE laptop SET capu_name = SUBSTRING_INDEX(TRIM(cpu_name),' ',2)


-- -------------------Drop temporary table ----------------------
DROP TABLE tem_name;
 
 -- --Here we are drop the temporaray table And old cpu column--------------
DROP TABLE tem_name;
ALTER TABLE laptop DROP COLUMN Cpu;


-- -------------------Resolution Column-------------------------
-- Resolution column have 3 pieces of information 
-- 1. is screen height
-- 2. is  screen weight 
-- 3. is Touchscreen 
-- 1 fist extract resolution 'width' abd 'height'
CREATE TEMPORARY TABLE tem_width_height
SELECT `index`,SUBSTRING_INDEX(SUBSTRING_INDEX(ScreenResolution,' ',-1),'x',1)  AS 'width',
SUBSTRING_INDEX(SUBSTRING_INDEX(ScreenResolution,' ',-1),'x',-1) AS 'height'
FROM laptop;


-- ---------------create width and heigth column-------------------
ALTER TABLE laptop ADD COLUMN width INTEGER AFTER ScreenResolution,
ADD COLUMN height INTEGER AFTER width;


-- ---------- Update table with values width and height------------
UPDATE laptop t1
JOIN tem_width_height t2
ON t1.`index` = t2.`index`
SET t1.width = t2.width,t1.height = t2.height;

-- here we are create by mistake wrong column name  'width' but we are we want to create the resolution_width name
ALTER TABLE laptop
CHANGE COLUMN width resolution_width INTEGER;


-- ------------here we are change the column name------------------- 
ALTER TABLE laptop
CHANGE COLUMN height resolution_height INTEGER;

-- ------------------Drop temporary table---------------------------
DROP TABLE tem_width_height;

-- -------------------------------------------------Add column Touchscreen----------------------------------------------------------
ALTER TABLE laptop ADD  COLUMN touchscreen INTEGER AFTER ScreenResolution;

-- ---------------------------update the touchscreeen column--------------
UPDATE laptop SET touchscreen = ScreenResolution LIKE '%Touch%';

-- --------------------------------------------Add screen type column Screen type -------------------------------------------------
ALTER TABLE laptop ADD COLUMN screen_type VARCHAR(255) AFTER ScreenResolution;


-- Create  a temporary table and store the value using if else 
CREATE TEMPORARY TABLE tem_screen
SELECT `index`,
CASE
	WHEN ScreenResolution LIKE 'Touch%' THEN 'touchscreen display'
    WHEN ScreenResolution LIKE '4%' THEN '4k display'
    WHEN ScreenResolution LIKE 'Q%' THEN 'quad display'
	WHEN ScreenResolution LIKE 'IPS%' THEN 'ips display'
    WHEN ScreenResolution LIKE 'Full%' THEN 'full hd display'
    WHEN ScreenResolution LIKE '1%' THEN 'N/A'
    WHEN ScreenResolution LIKE '2%' THEN 'N/A'
END AS screen_type
FROM laptop;


-- ------------------Update the table of screen_type column------------------
UPDATE laptop t1
JOIN tem_screen t2 
ON t1.`index` = t2.`index`
SET t1.screen_type = t2.screen_type;

-- ----------------------Drop the temporary table-----------------------------
DROP TABLE tem_screen;

-- Drop the ScreenResolution column 
ALTER TABLE laptop DROP COLUMN ScreenResolution;

-- --------------------------------------Memory column also contain many information----------------------------------------
-- like ssd
-- HDD
-- Hybride so seprate all this information 
-- Create 'memory_type', primary_storage,secondary_storage  Column 
ALTER TABLE laptop
ADD COLUMN memory_type VARCHAR(255) AFTER Memory,
ADD COLUMN primary_storage INTEGER AFTER memory_type,
ADD COLUMN secondary_storage INTEGER AFTER primary_storage;

-- --------------use if else statement------------------------
SELECT Memory,
CASE
	WHEN Memory LIKE '%SSD%' AND Memory LIKE '%HDD%' THEN 'Hybrid'
    WHEN Memory LIKE '%SSD%' THEN 'SSD'
    WHEN Memory LIKE '%HDD%' THEN 'HDD'
    WHEN Memory LIKE '%Flash Storage%' THEN 'Flash Storage'
    WHEN Memory LIKE '%Hybrid%' THEN 'Hybrid'
    WHEN Memory LIKE '%Flash Storage%' AND Memory LIKE '%HDD%' THEN 'Hybrid'
    ELSE NULL
END AS 'memory_type'
FROM laptop;

UPDATE laptop
SET memory_type = CASE
	WHEN Memory LIKE '%SSD%' AND Memory LIKE '%HDD%' THEN 'Hybrid'
    WHEN Memory LIKE '%SSD%' THEN 'SSD'
    WHEN Memory LIKE '%HDD%' THEN 'HDD'
    WHEN Memory LIKE '%Flash Storage%' THEN 'Flash Storage'
    WHEN Memory LIKE '%Hybrid%' THEN 'Hybrid'
    WHEN Memory LIKE '%Flash Storage%' AND Memory LIKE '%HDD%' THEN 'Hybrid'
    ELSE NULL
END;

-- Memory column have 2 pices of information such as primary storage and secondry storage
-- here is need to separated this 

SELECT Memory,
REGEXP_SUBSTR(SUBSTRING_INDEX(Memory,'+',1),'[0-9]+'),
CASE WHEN Memory LIKE '%+%' THEN REGEXP_SUBSTR(SUBSTRING_INDEX(Memory,'+',-1),'[0-9]+') ELSE 0 END
FROM laptop;


-- UPDATE the primary_storage 
UPDATE laptop
SET primary_storage = REGEXP_SUBSTR(SUBSTRING_INDEX(Memory,'+',1),'[0-9]+'),
secondary_storage = CASE WHEN Memory LIKE '%+%' THEN REGEXP_SUBSTR(SUBSTRING_INDEX(Memory,'+',-1),'[0-9]+') ELSE 0 END;


-- ----Now the drop column of Memory

ALTER TABLE laptop DROP COLUMN Memory;
SELECT * FROM laptop;

SELECT DATA_LENGTH FROM information_schema.TABLES
WHERE TABLE_SCHEMA = "datacleaning"
AND TABLE_NAME = "laptop";












