USE refrigerator_db;
SET NAMES utf8mb4;

-- 1) 기본 단위
CREATE TABLE IF NOT EXISTS unit_conversion (
  unit_label     VARCHAR(30) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci PRIMARY KEY,
  grams_per_unit DECIMAL(10,2) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

INSERT INTO unit_conversion (unit_label, grams_per_unit) VALUES
('g',1),('그램',1),('kg',1000),('Kg',1000),('mg',0.001),
('ml',1),('mL',1),('cc',1),('L',1000),
('컵',200),('큰술',15),('스푼',15),('작은술',5),('티스푼',5),
('공기',200),('개',50),('개씩',50),('마리',70),
('장',10),('장씩',10),('뿌리',20),('쪽',5),('톨',5),
('포기',300),('단',200),
('1/3개',58.5),('1/2컵',100),
('약간',5.0),('약간씩',5.0),('조금',5.0),('조금씩',5.0),('적당량',5.0),
('줄기',5),('잎',30),('한줌',20),('봉',175),('봉지',175)
ON DUPLICATE KEY UPDATE grams_per_unit = VALUES(grams_per_unit);

-- 2) 재료별 단위 보정
CREATE TABLE IF NOT EXISTS ingredient_unit_conversion (
  ingredient_id  BIGINT NOT NULL,
  unit_label     VARCHAR(30) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  grams_per_unit DECIMAL(10,2) NOT NULL,
  PRIMARY KEY (ingredient_id, unit_label)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

INSERT INTO ingredient_unit_conversion (ingredient_id, unit_label, grams_per_unit) VALUES
(217,'줄',65),(217,'컵',175),(193,'kg',1000),(208,'단',500),(207,'컵',200),
(12,'포기',2750),(104,'개',200),(104,'대',200),
(56,'개',175),(56,'1/3개',58.5),(56,'토막',75),
(70,'개',4.5),(70,'알',4.5),(17,'모',400),
(129,'작은술',5),(129,'큰술',15),(129,'약간',5),(129,'조금',5),(129,'약간씩',5),(129,'조금씩',5),(129,'적당량',5),
(160,'묶음',175),(89,'마리',3.5),(89,'한줌',17.5),
(119,'봉지',500),(119,'컵',175),
(191,'장',2),(180,'마리',1250),(9,'마리',1250),
(13,'kg',1000),(205,'포기',2750),(205,'통',2750),(212,'포기',2750),(219,'장',65),
(198,'큰술',14),(198,'약간',7),(198,'조금',7),(198,'약간씩',7),(198,'조금씩',7),(198,'적당량',7),
(299,'장',15),(57,'단',350),(112,'마리',20),
(42,'작은술',4),(42,'큰술',12),(42,'컵',200),(42,'과작은술',4),(42,'과큰술',12),(42,'과1/2큰술',18),
(42,'약간',4),(42,'조금',4),(42,'약간씩',4),(42,'조금씩',4),(42,'적당량',4),
(363,'작은술',4),(363,'큰술',12),(363,'컵',200),(363,'약간',4),(363,'조금',4),(363,'약간씩',4),(363,'조금씩',4),(363,'적당량',4),
(36,'작은술',5),(36,'큰술',15),(36,'1/4작은술',1.25),(36,'약간',5),(36,'조금',5),(36,'약간씩',5),(36,'조금씩',5),(36,'적당량',5),
(62,'kg',1000),(93,'단',250),(277,'장',75),(305,'잎',30),
(130,'개',20),(80,'개',215),(80,'개씩',215),(243,'개',40),(87,'개',175),(111,'마리',275),
(131,'큰술',14),(131,'과컵',200),(131,'약간',5),(131,'조금',5),(131,'약간씩',5),(131,'조금씩',5),(131,'적당량',5),
(82,'컵',200),(82,'큰술',15),(82,'1/2컵',100),
(174,'뿌리',250),(71,'컵',110),(71,'큰술',7.5),
(114,'개',75),(114,'쪽',75),(58,'개',7.5),(85,'개',125),
(52,'컵',180),(242,'봉',175),(242,'봉지',175),
(165,'개',125),(55,'개',400),(113,'컵',175),
(173,'약간',1),(173,'조금',1),(173,'약간씩',1),(173,'조금씩',1),(173,'적당량',1),
(210,'약간',1),(210,'조금',1),(210,'약간씩',1),(210,'조금씩',1),(210,'적당량',1)
ON DUPLICATE KEY UPDATE grams_per_unit = VALUES(grams_per_unit);

-- 3) g 환산 뷰
CREATE OR REPLACE VIEW recipe_ingredient_grams AS
WITH parsed AS (
    SELECT ri.id AS recipe_ingredient_id,
           ri.recipe_id,
           ri.ingredient_id,
           ri.amount AS amount_text,
           REGEXP_REPLACE(ri.amount,'[^0-9./]','') AS qty_text,
           TRIM(REPLACE(REPLACE(REPLACE(REGEXP_REPLACE(ri.amount,'[0-9./]',''),' ',''),'개씩','개'),'장씩','장')) AS unit_text
    FROM recipe_ingredient ri
),
converted AS (
    SELECT p.*,
           CASE
             WHEN qty_text = '' THEN NULL
             WHEN qty_text LIKE '%/%'
               THEN CAST(SUBSTRING_INDEX(qty_text,'/',1) AS DECIMAL(10,4)) /
                    NULLIF(CAST(SUBSTRING_INDEX(qty_text,'/',-1) AS DECIMAL(10,4)),0)
             ELSE CAST(qty_text AS DECIMAL(10,4))
           END AS qty_value
    FROM parsed p
)
SELECT
    ROW_NUMBER() OVER (ORDER BY c.recipe_id, c.ingredient_id) AS seq_no,
    c.recipe_ingredient_id,
    c.recipe_id,
    c.ingredient_id,
    i.name AS ingredient_name,
    c.amount_text,
    c.unit_text,
    c.qty_value,
    CASE
      WHEN c.unit_text IN ('','g','그램','ml','mL','cc') THEN c.qty_value
      WHEN iuc.grams_per_unit IS NOT NULL THEN c.qty_value * iuc.grams_per_unit
      WHEN uc.grams_per_unit  IS NOT NULL THEN c.qty_value * uc.grams_per_unit
      ELSE NULL
    END AS estimated_grams
FROM converted c
JOIN ingredient i ON i.id = c.ingredient_id
LEFT JOIN ingredient_unit_conversion iuc
       ON iuc.ingredient_id = c.ingredient_id AND iuc.unit_label = c.unit_text
LEFT JOIN unit_conversion uc
       ON uc.unit_label = c.unit_text
WHERE (CASE
         WHEN c.unit_text IN ('','g','그램','ml','mL','cc') THEN c.qty_value
         WHEN iuc.grams_per_unit IS NOT NULL THEN c.qty_value * iuc.grams_per_unit
         WHEN uc.grams_per_unit  IS NOT NULL THEN c.qty_value * uc.grams_per_unit
         ELSE NULL
       END) IS NOT NULL;

-- 4) 100g당 영양/가격 (중복 제거본) – 필요하면 여러 번에 나눠 실행
CREATE TABLE IF NOT EXISTS ingredient_nutrition_price (
  ingredient_id        BIGINT NOT NULL,
  calories_per_100g    INT    NOT NULL,
  carbs_per_100g       DECIMAL(6,2) NOT NULL,
  protein_per_100g     DECIMAL(6,2) NOT NULL,
  fat_per_100g         DECIMAL(6,2) NOT NULL,
  sodium_per_100g      INT    NOT NULL,
  min_price_per_100g   INT    NULL,
  max_price_per_100g   INT    NULL,
  PRIMARY KEY (ingredient_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- (VALUES는 긴 그대로 붙여도 되고, Workbench 부담 시 50개씩 쪼개 실행)
-- 아래 블록을 그대로 실행
INSERT INTO ingredient_nutrition_price
(ingredient_id, calories_per_100g, carbs_per_100g, protein_per_100g, fat_per_100g, sodium_per_100g, min_price_per_100g, max_price_per_100g)
VALUES
(286,20,3.5,2.0,0.3,25,100,400),(217,230,52.0,4.0,0.5,5,200,600),(193,250,0.0,19.0,20.0,70,3000,8000),
(137,90,2.0,16.0,1.0,150,800,2500),(208,20,3.5,2.0,0.3,25,100,400),(330,364,76.0,10.0,1.0,2,200,600),
(359,20,3.5,2.0,0.3,25,100,400),(45,20,3.5,2.0,0.3,25,100,400),(244,10,3.0,0.1,0.1,5,300,900),
(294,90,5.0,14.0,1.0,450,1000,3000),(326,300,0.0,17.0,26.0,70,2500,7000),(101,350,73.0,11.0,1.5,5,300,800),
(207,80,3.0,12.0,1.0,300,800,2500),(158,145,3.8,1.0,15.0,1500,800,2500),(12,40,6.5,2.0,0.6,500,200,600),
(69,200,45.0,4.0,2.0,3,300,900),(138,90,2.0,16.0,1.0,150,800,2500),(95,350,73.0,11.0,1.5,5,300,800),
(262,20,3.5,2.0,0.3,25,100,400),(160,25,4.5,2.5,0.3,5,500,2000),(123,250,0.0,19.0,20.0,70,3000,8000),
(222,40,6.5,2.0,0.6,500,200,600),(377,20,3.5,2.0,0.3,25,100,400),(180,165,0.0,31.0,3.6,80,800,2500),
(9,165,0.0,31.0,3.6,80,800,2500),(56,45,10.0,1.0,0.2,40,150,500),(53,373,90.0,0.3,0.1,10,300,900),
(190,110,0.0,24.0,1.0,70,1000,3500),(70,280,75.0,4.0,0.4,5,800,2500),(104,20,3.5,2.0,0.3,25,100,400),
(263,45,10.0,1.0,0.2,40,150,500),(44,45,10.0,1.0,0.2,40,150,500),(150,110,0.0,24.0,1.0,70,1000,3500),
(199,290,0.0,18.0,24.0,70,1500,4000),(271,290,0.0,18.0,24.0,70,1500,4000),(13,290,0.0,18.0,24.0,70,1500,4000),
(17,79,2.0,8.0,4.5,5,300,900),(331,250,50.0,8.0,1.0,10,300,1500),(129,45,11.0,0.5,0.2,1,300,1000),
(146,20,3.5,2.0,0.3,25,100,400),(266,20,3.5,2.0,0.3,25,100,400),(293,290,6.0,60.0,2.0,1500,3000,8000),
(387,290,6.0,60.0,2.0,1500,3000,8000),(301,110,12.0,8.0,4.0,800,800,2500),(89,210,0.0,30.0,10.0,500,1000,4000),
(119,80,3.0,12.0,1.0,300,800,2500),(191,25,4.5,2.5,0.3,5,500,2000),(121,45,10.0,1.0,0.2,40,150,500),
(273,82,2.0,15.0,1.0,120,800,2500),(35,20,3.5,2.0,0.3,25,100,400),(329,80,3.0,12.0,1.0,300,800,2500),
(122,25,5.0,2.0,0.5,250,300,1200),(91,364,76.0,10.0,1.0,2,200,600),(253,350,73.0,11.0,1.5,5,300,800),
(215,80,3.0,12.0,1.0,300,800,2500),(151,36,5.0,3.0,0.6,20,500,2000),(11,130,29.0,2.5,0.3,1,150,400),
(132,20,4.5,1.0,0.2,5,200,600),(382,20,3.5,2.0,0.3,25,100,400),(57,20,3.5,2.0,0.3,25,100,400),
(120,290,0.0,65.0,1.0,500,2000,6000),(152,145,3.8,1.0,15.0,1500,800,2500),(136,82,2.0,15.0,1.0,120,800,2500),
(112,99,1.0,24.0,0.3,200,1000,3500),(145,20,3.5,2.0,0.3,25,100,400),(395,99,1.0,24.0,0.3,200,1000,3500),
(246,120,3.0,19.0,3.0,200,500,1500),(250,80,0.0,17.0,1.0,80,500,1500),(295,350,73.0,11.0,1.5,5,300,800),
(62,250,0.0,19.0,20.0,70,3000,8000),(343,180,0.0,23.0,10.0,70,3500,9000),(43,32,5.0,3.0,0.4,5,300,1500),
(214,50,2.0,5.0,2.5,5,300,800),(154,36,5.0,3.0,0.6,20,500,2000),(297,350,73.0,11.0,1.5,5,300,800),
(320,20,3.5,2.0,0.3,25,100,400),(93,20,3.5,2.0,0.3,25,100,400),(337,20,3.5,2.0,0.3,25,100,400),
(328,110,0.0,24.0,1.0,70,1000,3500),(357,600,20.0,20.0,50.0,5,1000,4000),(33,180,0.0,23.0,10.0,70,3500,9000),
(318,20,3.5,2.0,0.3,25,100,400),(248,294,0.0,25.0,21.0,70,2500,6000),(380,25,4.5,2.5,0.3,5,500,2000),
(46,250,0.0,19.0,20.0,70,3000,8000),(260,45,10.0,1.0,0.2,40,150,500),(157,36,5.0,3.0,0.6,20,500,2000),
(332,260,66.0,0.3,0.1,20,400,1500),(383,88,19.0,3.2,1.2,15,300,700),(241,20,3.5,2.0,0.3,25,100,400),
(327,350,73.0,11.0,1.5,5,300,800),(270,140,10.0,12.0,6.0,700,500,1500),(247,220,3.0,18.0,15.0,900,2000,6000),
(368,80,3.0,12.0,1.0,300,800,2500),(141,80,3.0,12.0,1.0,300,800,2500),(272,150,0.0,26.0,5.0,350,1000,3000),
(371,20,3.5,2.0,0.3,25,100,400),(10,350,70.0,12.0,5.0,800,500,2000),(185,350,73.0,11.0,1.5,5,300,800),
(312,20,3.5,2.0,0.3,25,100,400),(396,380,85.0,7.0,3.0,400,800,2500),(19,32,5.0,3.0,0.4,5,300,1500),
(345,45,10.0,1.0,0.2,40,150,500),(362,60,15.0,0.8,0.3,0,300,1000),(276,45,10.0,1.0,0.2,40,150,500),
(319,20,3.5,2.0,0.3,25,100,400),(210,36,5.0,3.0,0.6,20,500,2000),(223,25,1.0,5.0,0.1,900,800,2500),
(280,270,3.0,16.0,22.0,1100,1500,4500),(302,70,18.0,0.3,0.1,5,400,1500),(317,180,0.0,22.0,10.0,900,2000,6000),
(120,290,0.0,65.0,1.0,500,2000,6000),(155,85,2.6,0.1,0.0,5,400,2000),(113,80,3.0,12.0,1.0,300,800,2500),
(55,20,4.5,1.0,0.2,5,200,600),(165,20,4.5,1.0,0.2,5,200,600),(242,25,4.5,2.5,0.3,5,500,2000),
(114,25,5.0,2.5,0.2,10,200,600),(85,20,4.5,1.0,0.2,5,200,600),(82,64,5.0,3.3,3.6,44,150,400),
(131,884,0.0,0.0,100.0,0,1500,5000),(58,40,9.0,2.0,0.4,7,300,900),(205,20,3.5,2.0,0.3,25,100,400),
(212,40,6.5,2.0,0.6,500,200,600),(219,20,3.5,2.0,0.3,25,100,400),(198,717,0.5,0.5,81.0,700,1500,5000),
(299,270,3.0,16.0,22.0,1100,1500,4500),(57,20,3.5,2.0,0.3,25,100,400),(112,99,1.0,24.0,0.3,200,1000,3500),
(42,400,100.0,0.0,0.0,0,150,500),(36,0,0.0,0.0,0.0,39000,50,200),(173,40,9.0,2.0,0.4,7,300,900),
(93,20,3.5,2.0,0.3,25,100,400),(277,20,3.5,2.0,0.3,25,100,400),(305,20,3.5,2.0,0.3,25,100,400),
(130,25,4.5,2.5,0.3,5,500,2000),(80,45,10.0,1.0,0.2,40,150,500),(243,140,10.0,12.0,6.0,700,500,1500),
(87,20,4.5,1.0,0.2,5,200,600),(111,90,2.0,16.0,1.0,150,800,2500),(174,45,10.0,1.0,0.2,40,150,500),
(210,36,5.0,3.0,0.6,20,500,2000),(52,340,60.0,21.0,1.5,5,300,900),(165,20,4.5,1.0,0.2,5,200,600),
(55,20,4.5,1.0,0.2,5,200,600),(113,80,3.0,12.0,1.0,300,800,2500),(155,85,2.6,0.1,0.0,5,400,2000),
(302,70,18.0,0.3,0.1,5,400,1500),(317,180,0.0,22.0,10.0,900,2000,6000)
ON DUPLICATE KEY UPDATE
  calories_per_100g  = VALUES(calories_per_100g),
  carbs_per_100g     = VALUES(carbs_per_100g),
  protein_per_100g   = VALUES(protein_per_100g),
  fat_per_100g       = VALUES(fat_per_100g),
  sodium_per_100g    = VALUES(sodium_per_100g),
  min_price_per_100g = VALUES(min_price_per_100g),
  max_price_per_100g = VALUES(max_price_per_100g);

-- 5) 컬럼 추가 (컬럼이 있으면 1060 에러 나니, 처음 한 번만 실행)
ALTER TABLE recipe_ingredient
  ADD COLUMN estimated_grams    DECIMAL(12,2) NULL,
  ADD COLUMN line_kcal          DECIMAL(12,2) NULL,
  ADD COLUMN line_carbs_g       DECIMAL(12,2) NULL,
  ADD COLUMN line_protein_g     DECIMAL(12,2) NULL,
  ADD COLUMN line_fat_g         DECIMAL(12,2) NULL,
  ADD COLUMN line_sodium_mg     DECIMAL(12,2) NULL,
  ADD COLUMN line_min_price_krw DECIMAL(12,2) NULL,
  ADD COLUMN line_max_price_krw DECIMAL(12,2) NULL;

ALTER TABLE recipe
  ADD COLUMN total_kcal               DECIMAL(12,2) NULL,
  ADD COLUMN total_carbs_g            DECIMAL(12,2) NULL,
  ADD COLUMN total_protein_g          DECIMAL(12,2) NULL,
  ADD COLUMN total_fat_g              DECIMAL(12,2) NULL,
  ADD COLUMN total_sodium_mg          DECIMAL(12,2) NULL,
  ADD COLUMN estimated_min_price_krw  DECIMAL(12,2) NULL,
  ADD COLUMN estimated_max_price_krw  DECIMAL(12,2) NULL;

-- 6) 줄별/총합 값 적재
SET SQL_SAFE_UPDATES = 0;

UPDATE recipe_ingredient ri
JOIN recipe_ingredient_grams rig   ON rig.recipe_ingredient_id = ri.id
JOIN ingredient_nutrition_price n  ON n.ingredient_id = rig.ingredient_id
SET ri.estimated_grams    = rig.estimated_grams,
    ri.line_kcal          = ROUND(rig.estimated_grams/100 * n.calories_per_100g, 2),
    ri.line_carbs_g       = ROUND(rig.estimated_grams/100 * n.carbs_per_100g, 2),
    ri.line_protein_g     = ROUND(rig.estimated_grams/100 * n.protein_per_100g, 2),
    ri.line_fat_g         = ROUND(rig.estimated_grams/100 * n.fat_per_100g, 2),
    ri.line_sodium_mg     = ROUND(rig.estimated_grams/100 * n.sodium_per_100g, 2),
    ri.line_min_price_krw = ROUND(rig.estimated_grams/100 * n.min_price_per_100g, 2),
    ri.line_max_price_krw = ROUND(rig.estimated_grams/100 * n.max_price_per_100g, 2);

UPDATE recipe r
JOIN (
  SELECT
    recipe_id,
    SUM(line_kcal)          AS total_kcal,
    SUM(line_carbs_g)       AS total_carbs_g,
    SUM(line_protein_g)     AS total_protein_g,
    SUM(line_fat_g)         AS total_fat_g,
    SUM(line_sodium_mg)     AS total_sodium_mg,
    SUM(line_min_price_krw) AS min_price,
    SUM(line_max_price_krw) AS max_price
  FROM recipe_ingredient
  GROUP BY recipe_id
) s ON s.recipe_id = r.id
SET r.total_kcal              = ROUND(s.total_kcal, 2),
    r.total_carbs_g           = ROUND(s.total_carbs_g, 2),
    r.total_protein_g         = ROUND(s.total_protein_g, 2),
    r.total_fat_g             = ROUND(s.total_fat_g, 2),
    r.total_sodium_mg         = ROUND(s.total_sodium_mg, 2),
    r.estimated_min_price_krw = ROUND(s.min_price, 2),
    r.estimated_max_price_krw = ROUND(s.max_price, 2);

SET SQL_SAFE_UPDATES = 1;
