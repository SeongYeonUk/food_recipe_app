-- MySQL dump 10.13  Distrib 8.0.43, for macos15 (arm64)
--
-- Host: localhost    Database: refrigerator_db
-- ------------------------------------------------------
-- Server version	8.0.43

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `dislikes`
--

DROP TABLE IF EXISTS `dislikes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `dislikes` (
  `dislike_id` bigint NOT NULL AUTO_INCREMENT,
  `recipe_id` bigint DEFAULT NULL,
  `user_id` bigint DEFAULT NULL,
  PRIMARY KEY (`dislike_id`),
  UNIQUE KEY `UKd42b00hdri5t1xuoce3lhho1` (`user_id`,`recipe_id`),
  KEY `FKnv9dusbhfjd4mecjnl4h4jee4` (`recipe_id`),
  CONSTRAINT `FKdej1eqv0prsavr1warenj7ceb` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`),
  CONSTRAINT `FKnv9dusbhfjd4mecjnl4h4jee4` FOREIGN KEY (`recipe_id`) REFERENCES `recipe` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `dislikes`
--

LOCK TABLES `dislikes` WRITE;
/*!40000 ALTER TABLE `dislikes` DISABLE KEYS */;
/*!40000 ALTER TABLE `dislikes` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `favorite`
--

DROP TABLE IF EXISTS `favorite`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `favorite` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `recipe_id` bigint NOT NULL,
  `user_id` bigint NOT NULL,
  PRIMARY KEY (`id`),
  KEY `FKf9bc7126riig40ixsxetxtnnv` (`recipe_id`),
  KEY `FKa2lwa7bjrnbti5v12mga2et1y` (`user_id`),
  CONSTRAINT `FKa2lwa7bjrnbti5v12mga2et1y` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`),
  CONSTRAINT `FKf9bc7126riig40ixsxetxtnnv` FOREIGN KEY (`recipe_id`) REFERENCES `recipe` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=17 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `favorite`
--

LOCK TABLES `favorite` WRITE;
/*!40000 ALTER TABLE `favorite` DISABLE KEYS */;
INSERT INTO `favorite` VALUES (14,2,14),(16,2,10);
/*!40000 ALTER TABLE `favorite` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `hidden_recipe`
--

DROP TABLE IF EXISTS `hidden_recipe`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `hidden_recipe` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `recipe_id` bigint NOT NULL,
  `user_id` bigint NOT NULL,
  PRIMARY KEY (`id`),
  KEY `FKc9uimn7kdldbwk9vp5ipyyhqp` (`recipe_id`),
  KEY `FKba30a42cdbeibiip0sxn1gao0` (`user_id`),
  CONSTRAINT `FKba30a42cdbeibiip0sxn1gao0` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`),
  CONSTRAINT `FKc9uimn7kdldbwk9vp5ipyyhqp` FOREIGN KEY (`recipe_id`) REFERENCES `recipe` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `hidden_recipe`
--

LOCK TABLES `hidden_recipe` WRITE;
/*!40000 ALTER TABLE `hidden_recipe` DISABLE KEYS */;
/*!40000 ALTER TABLE `hidden_recipe` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ingredient_log`
--

DROP TABLE IF EXISTS `ingredient_log`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ingredient_log` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `created_at` datetime(6) DEFAULT NULL,
  `user_id` bigint NOT NULL,
  `item_id` bigint NOT NULL,
  PRIMARY KEY (`id`),
  KEY `FKn4esatp6montcbakfj9mkh604` (`user_id`),
  KEY `FK7b7xw2kp9q7ik89pfx1eqrvqr` (`item_id`),
  CONSTRAINT `FK7b7xw2kp9q7ik89pfx1eqrvqr` FOREIGN KEY (`item_id`) REFERENCES `items` (`item_id`),
  CONSTRAINT `FKn4esatp6montcbakfj9mkh604` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=17 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ingredient_log`
--

LOCK TABLES `ingredient_log` WRITE;
/*!40000 ALTER TABLE `ingredient_log` DISABLE KEYS */;
INSERT INTO `ingredient_log` VALUES (1,'2025-09-23 03:57:13.326591',10,35),(2,'2025-09-23 03:57:34.157425',10,36),(3,'2025-09-23 03:57:34.858615',10,37),(4,'2025-09-23 03:57:35.555574',10,38),(5,'2025-09-23 03:57:39.468977',10,39),(6,'2025-09-23 03:57:40.190098',10,40),(7,'2025-09-23 04:06:23.039909',10,41),(8,'2025-09-23 04:06:24.059595',10,42),(9,'2025-09-23 04:06:24.782625',10,43),(10,'2025-09-23 04:06:25.772493',10,44),(11,'2025-09-23 04:06:26.610705',10,45),(12,'2025-09-23 04:06:28.501144',10,46),(13,'2025-09-23 04:06:29.242366',10,47),(14,'2025-09-23 04:31:04.458106',10,48),(15,'2025-09-23 04:31:34.232434',14,49),(16,'2025-09-23 05:56:18.052637',14,50);
/*!40000 ALTER TABLE `ingredient_log` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ingredient_statics`
--

DROP TABLE IF EXISTS `ingredient_statics`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ingredient_statics` (
  `item_id` bigint NOT NULL,
  `total_count` bigint NOT NULL,
  PRIMARY KEY (`item_id`),
  CONSTRAINT `FKc59exqits4oe82669lf4ly5th` FOREIGN KEY (`item_id`) REFERENCES `items` (`item_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ingredient_statics`
--

LOCK TABLES `ingredient_statics` WRITE;
/*!40000 ALTER TABLE `ingredient_statics` DISABLE KEYS */;
INSERT INTO `ingredient_statics` VALUES (35,1),(36,1),(37,1),(38,1),(39,1),(40,1),(41,1),(42,1),(43,1),(44,1),(45,1),(46,1),(47,1),(48,1),(49,1),(50,1);
/*!40000 ALTER TABLE `ingredient_statics` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `items`
--

DROP TABLE IF EXISTS `items`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `items` (
  `item_id` bigint NOT NULL AUTO_INCREMENT,
  `category` enum('채소','과일','육류','어패류','유제품','가공식품','기타','음료') NOT NULL,
  `expiry_date` date DEFAULT NULL,
  `name` varchar(255) NOT NULL,
  `quantity` int NOT NULL,
  `registration_date` date DEFAULT NULL,
  `refrigerator_id` bigint DEFAULT NULL,
  PRIMARY KEY (`item_id`),
  KEY `FKhx4edomcpkolv7ka210e2yh0v` (`refrigerator_id`),
  CONSTRAINT `FKhx4edomcpkolv7ka210e2yh0v` FOREIGN KEY (`refrigerator_id`) REFERENCES `refrigerators` (`refrigerator_id`)
) ENGINE=InnoDB AUTO_INCREMENT=51 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `items`
--

LOCK TABLES `items` WRITE;
/*!40000 ALTER TABLE `items` DISABLE KEYS */;
INSERT INTO `items` VALUES (1,'기타','2025-08-28','egg',1,'2025-08-21',1),(3,'기타','2025-09-06','oil',3,'2025-08-30',22),(4,'채소','2025-09-06','eee',2,'2025-08-30',19),(11,'유제품','2025-09-11','egg',2,'2025-09-02',17),(17,'유제품','2025-09-28','egg',3,'2025-09-21',28),(18,'과일','2025-09-28','egg',10,'2025-09-21',18),(19,'채소','2025-09-28','ice',2,'2025-09-21',18),(20,'채소','2025-09-28','kimchi',2,'2025-09-21',18),(21,'채소','2025-09-28','밥',2,'2025-09-21',16),(22,'채소','2025-09-30','gg',1,'2025-09-23',16),(23,'기타','2025-09-30','rice',2,'2025-09-23',16),(24,'가공식품','2025-09-30','ham',3,'2025-09-23',16),(25,'기타','2025-10-20','계란',1,'2025-09-23',16),(26,'기타','2025-10-25','김',2,'2025-09-23',16),(27,'기타','2025-10-25','닭고기',2,'2025-09-23',16),(28,'기타','2025-10-25','닭고기',2,'2025-09-23',16),(29,'가공식품','2025-09-28','카레',2,'2025-09-23',16),(35,'기타','2025-09-28','밥',2,'2025-09-23',16),(36,'기타','2025-09-28','밥',2,'2025-09-23',16),(37,'기타','2025-09-28','밥',2,'2025-09-23',16),(38,'기타','2025-09-28','밥',2,'2025-09-23',16),(39,'기타','2025-09-28','김치',2,'2025-09-23',16),(40,'기타','2025-09-28','김치',2,'2025-09-23',16),(41,'기타','2025-09-28','돼지고기',3,'2025-09-23',16),(42,'기타','2025-09-28','돼지고기',3,'2025-09-23',16),(43,'기타','2025-09-28','돼지고기',3,'2025-09-23',16),(44,'기타','2025-09-28','돼지고기',3,'2025-09-23',16),(45,'기타','2025-09-28','돼지고기',3,'2025-09-23',16),(46,'기타','2025-09-28','돼지고기',3,'2025-09-23',16),(47,'기타','2025-09-28','돼지고기',3,'2025-09-23',16),(48,'채소','2025-09-30','김치',4,'2025-09-23',16),(49,'채소','2025-09-30','김치',4,'2025-09-23',29),(50,'음료','2025-09-30','water',2,'2025-09-23',28);
/*!40000 ALTER TABLE `items` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `likes`
--

DROP TABLE IF EXISTS `likes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `likes` (
  `like_id` bigint NOT NULL AUTO_INCREMENT,
  `recipe_id` bigint DEFAULT NULL,
  `user_id` bigint DEFAULT NULL,
  `created_at` datetime(6) DEFAULT NULL,
  PRIMARY KEY (`like_id`),
  UNIQUE KEY `UK1n8hu727ntfhogn3ew7hkc0nt` (`user_id`,`recipe_id`),
  KEY `FKkqm6yfj7ja4drk4imi5xrw5d6` (`recipe_id`),
  CONSTRAINT `FKkqm6yfj7ja4drk4imi5xrw5d6` FOREIGN KEY (`recipe_id`) REFERENCES `recipe` (`id`),
  CONSTRAINT `FKnvx9seeqqyy71bij291pwiwrg` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `likes`
--

LOCK TABLES `likes` WRITE;
/*!40000 ALTER TABLE `likes` DISABLE KEYS */;
INSERT INTO `likes` VALUES (3,2,10,'2025-09-23 05:46:52.697554'),(4,10,10,'2025-09-23 05:46:58.978020'),(6,2,14,'2025-09-23 05:49:19.839412'),(7,11,10,'2025-09-23 06:03:07.903545');
/*!40000 ALTER TABLE `likes` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `popular_ingredient`
--

DROP TABLE IF EXISTS `popular_ingredient`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `popular_ingredient` (
  `name` varchar(100) NOT NULL,
  `total_usage_count` bigint NOT NULL,
  PRIMARY KEY (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `popular_ingredient`
--

LOCK TABLES `popular_ingredient` WRITE;
/*!40000 ALTER TABLE `popular_ingredient` DISABLE KEYS */;
INSERT INTO `popular_ingredient` VALUES ('egg',4),('gg',1),('ice',1),('kimchi',1),('tt',1),('밥',1);
/*!40000 ALTER TABLE `popular_ingredient` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `recipe`
--

DROP TABLE IF EXISTS `recipe`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `recipe` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `image_url` varchar(255) DEFAULT NULL,
  `ingredients` varchar(255) DEFAULT NULL,
  `instructions` text,
  `time` int DEFAULT NULL,
  `title` varchar(255) NOT NULL,
  `author_id` bigint DEFAULT NULL,
  `description` varchar(255) DEFAULT NULL,
  `is_custom` bit(1) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `FKlvmxb2tmwa9979nk3yexb805p` (`author_id`),
  CONSTRAINT `FKlvmxb2tmwa9979nk3yexb805p` FOREIGN KEY (`author_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=13 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `recipe`
--

LOCK TABLES `recipe` WRITE;
/*!40000 ALTER TABLE `recipe` DISABLE KEYS */;
INSERT INTO `recipe` VALUES (2,'http://example.com/eggroll.jpg','계란, 파, 소금','1. 계란을 푼다. 2. 파를 썰어 넣는다. 3. 부친다.',10,'계란말이',NULL,NULL,_binary '\0'),(4,'/data/user/0/com.example.food_recipe_app/cache/30f2230a-07a2-4c6b-b725-c9fa5173ae54/스크린샷 2025-09-16 오후 8.20.31.png','kk 3','ffff',90,'chiken',NULL,'',_binary ''),(10,'http://example.com/ai_recipe_01.jpg','밥, 김치','김치볶음밥 레시피입니다.',90,'김치볶음밥',NULL,'',_binary '\0'),(11,'http://example.com/ai_recipe_01.jpg','밥, 야채','야채볶음밥 레시피입니다.',60,'야채볶음밥',NULL,'',_binary '\0'),(12,'http://example.com/ai_recipe_01.jpg','밥, 야채','야채볶음밥 레시피입니다.',60,'야채볶음밥',NULL,'',_binary '\0');
/*!40000 ALTER TABLE `recipe` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `refresh_token`
--

DROP TABLE IF EXISTS `refresh_token`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `refresh_token` (
  `uid` varchar(255) NOT NULL,
  `token_value` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`uid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `refresh_token`
--

LOCK TABLES `refresh_token` WRITE;
/*!40000 ALTER TABLE `refresh_token` DISABLE KEYS */;
INSERT INTO `refresh_token` VALUES ('1','eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIiwiaWF0IjoxNzU1NzE2Nzc3LCJleHAiOjE3NTY5MjYzNzd9.0rvSGDtLbojTQz45BcdDiFNGcy1zIWSJWSvMC7OjLSQ'),('2','eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIyIiwiaWF0IjoxNzU1NzE1MDI5LCJleHAiOjE3NTY5MjQ2Mjl9.rDTZp6sxgvGlJAKz4ZaY4_-E8fD_Na8aGpyoc7J_rkQ'),('5','eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiI1IiwiaWF0IjoxNzU1NzE1ODQwLCJleHAiOjE3NTY5MjU0NDB9.Tzs817JXHn3Zjan0XAKmSbfEDmzZHK07h09ucsTebGM'),('asd123','eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJhc2QxMjMiLCJpYXQiOjE3NTY0OTU1NDYsImV4cCI6MTc1NzcwNTE0Nn0.5dFHQfsRKDPpGHTa5FHVY4hBflYIbY_BHHi7Sn_cGQA'),('hi123','eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJoaTEyMyIsImlhdCI6MTc1ODU3NDk3OCwiZXhwIjoxNzU5Nzg0NTc4fQ.oVJ68bomgqq_rey7ZPrS4Gskd9ehop-9SQuMLvzHo2Q'),('jjang1811','eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJqamFuZzE4MTEiLCJpYXQiOjE3NTY0OTU1MTksImV4cCI6MTc1NzcwNTExOX0.gLPKLNGAqOEZoYX-eE8OfdKf0GAK9wgfqHxdXyg32rA'),('jss1811','eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJqc3MxODExIiwiaWF0IjoxNzU1NzE1Nzg2LCJleHAiOjE3NTY5MjUzODZ9.sVTfJAm2EIFxJdQfO8-3tN_ijDG1cMWwnh653LeYQzc'),('mmmgyo','eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJtbW1neW8iLCJpYXQiOjE3NTg1NzQwMzQsImV4cCI6MTc1OTc4MzYzNH0.FqYPWS8PrpqqMS2pQyBEJ6YzV_RBxjx8kleq9mpCWIE'),('test01','eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJ0ZXN0MDEiLCJpYXQiOjE3NTgwNDI2MDcsImV4cCI6MTc1OTI1MjIwN30.SJ7x6qX6ga4ui_E1Lqt-aoNvkgsHZI-lSldwumYLfv0'),('wjdalsry','eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJ3amRhbHNyeSIsImlhdCI6MTc1ODQ2MDkyNSwiZXhwIjoxNzU5NjcwNTI1fQ.3lZ06B1sC45k67VnuHhgp1ANG-j2kyjaNopymfkKBh4'),('wjdalsry1811','eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJ3amRhbHNyeTE4MTEiLCJpYXQiOjE3NTY0OTIwNDMsImV4cCI6MTc1NzcwMTY0M30.QSWcsCqpbfUfp2Vm9VPr6qTss7fDdM787rnvV35t7ZY');
/*!40000 ALTER TABLE `refresh_token` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `refrigerators`
--

DROP TABLE IF EXISTS `refrigerators`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `refrigerators` (
  `refrigerator_id` bigint NOT NULL AUTO_INCREMENT,
  `type` enum('김치냉장고','냉동실','냉장고') NOT NULL,
  `user_id` bigint DEFAULT NULL,
  PRIMARY KEY (`refrigerator_id`),
  KEY `FKps913u29n3h8xha12dgb24iof` (`user_id`),
  CONSTRAINT `FKps913u29n3h8xha12dgb24iof` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=34 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `refrigerators`
--

LOCK TABLES `refrigerators` WRITE;
/*!40000 ALTER TABLE `refrigerators` DISABLE KEYS */;
INSERT INTO `refrigerators` VALUES (1,'냉장고',5),(2,'김치냉장고',5),(3,'냉동실',5),(4,'냉장고',6),(5,'김치냉장고',6),(6,'냉동실',6),(7,'냉장고',7),(8,'김치냉장고',7),(9,'냉동실',7),(10,'냉장고',8),(11,'김치냉장고',8),(12,'냉동실',8),(13,'냉장고',9),(14,'김치냉장고',9),(15,'냉동실',9),(16,'냉장고',10),(17,'김치냉장고',10),(18,'냉동실',10),(19,'냉장고',11),(20,'김치냉장고',11),(21,'냉동실',11),(22,'냉장고',12),(23,'김치냉장고',12),(24,'냉동실',12),(25,'냉장고',13),(26,'김치냉장고',13),(27,'냉동실',13),(28,'냉장고',14),(29,'김치냉장고',14),(30,'냉동실',14),(31,'냉장고',15),(32,'김치냉장고',15),(33,'냉동실',15);
/*!40000 ALTER TABLE `refrigerators` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `users` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `uid` varchar(255) NOT NULL,
  `password` varchar(255) NOT NULL,
  `nickname` varchar(255) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `UK_uid` (`uid`),
  UNIQUE KEY `UK_nickname` (`nickname`)
) ENGINE=InnoDB AUTO_INCREMENT=16 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `users`
--

LOCK TABLES `users` WRITE;
/*!40000 ALTER TABLE `users` DISABLE KEYS */;
INSERT INTO `users` VALUES (1,'js1811','$2a$10$k5fviR3MTZmZ7ktnLo.F/OPDpDn0vCrXWZCBasZ96VFgezlD8r4vi','정민교'),(2,'test1234','$2a$10$MBCcCuFVZ4sdPG5HSf9tg.cu47n2oZQeKm.1zK2.OaruVB0C8D5rO','테스트'),(5,'1','$2a$10$C.RgTCVhmckHa1ehx4KJjuXlHOhYjG43ByuTcMGkmGXwnhk0T9dGC','1'),(6,'2','$2a$10$fm0RKDrFzTOmQ4wPx0OAmeFQt.XLichhMWy8XsqnULXehAsB2lpZ2','2'),(7,'jss1811','$2a$10$OyK9iv1iF5aG47WZPOpgzeTgbqwqFzCc24PorckdRA7eP6qHTDtpe','hi'),(8,'5','$2a$10$afenlqM5384/WihiXrje8u1125h7eGmmWNDtRCAAn9ZVwIt40Z.6a','5'),(9,'wjdalsry1811','$2a$10$oJDynePADtEYxThV10QKJeeUHrVZZauBV6H3WSByebB7IRlbzNjQq','hello'),(10,'hi123','$2a$10$YbPUE2fYDXvGuUplvuD2RuiuR4WpiZqP3ppRNwTjCl2PnPpqJFIYS','jjj'),(11,'jjang1811','$2a$10$IoVBUfYEWTnIg3rNXBLbVe7UWuXVmVyPTiTWa7W7lVcC7wJpnMYfu','hii'),(12,'asd123','$2a$10$f2u4VWcZuvD2Y/7q7ffvtuiBeqUchqcqWnrhHbK3YVv2pKREinCqi','jjjj'),(13,'test01','$2a$10$ZGV.4lNxE46ZkLNKcLpucOkxsGuQvy6dZYjkPNQTwR6QlSG/DLPRi','a'),(14,'mmmgyo','$2a$10$x4uVlofSOf3U.XHXKj/2zO.TbdHO9eb5vLNo17Mz21nm//Wx15ME.','j1j1'),(15,'wjdalsry','$2a$10$bigS0mztmxxYgBN843Nomuer8ZWoBsTOYRGH1x1LDaQDeudhvZLjS','jjy');
/*!40000 ALTER TABLE `users` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2025-09-23  6:14:05
