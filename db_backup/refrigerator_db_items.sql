-- MySQL dump 10.13  Distrib 8.0.43, for Win64 (x86_64)
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
  `icon_index` int NOT NULL,
  PRIMARY KEY (`item_id`),
  KEY `FKhx4edomcpkolv7ka210e2yh0v` (`refrigerator_id`),
  CONSTRAINT `FKhx4edomcpkolv7ka210e2yh0v` FOREIGN KEY (`refrigerator_id`) REFERENCES `refrigerators` (`refrigerator_id`)
) ENGINE=InnoDB AUTO_INCREMENT=76 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `items`
--

LOCK TABLES `items` WRITE;
/*!40000 ALTER TABLE `items` DISABLE KEYS */;
INSERT INTO `items` VALUES (1,'기타','2025-08-28','egg',1,'2025-08-21',1,0),(3,'기타','2025-09-06','oil',3,'2025-08-30',22,0),(11,'유제품','2025-09-11','egg',2,'2025-09-02',17,0),(17,'유제품','2025-09-28','egg',3,'2025-09-21',28,0),(18,'과일','2025-09-28','egg',10,'2025-09-21',18,0),(19,'채소','2025-09-28','ice',2,'2025-09-21',18,0),(20,'채소','2025-09-28','kimchi',2,'2025-09-21',18,0),(22,'채소','2025-09-30','gg',1,'2025-09-23',16,0),(23,'기타','2025-09-30','rice',2,'2025-09-23',16,0),(24,'가공식품','2025-09-30','ham',3,'2025-09-23',16,0),(26,'기타','2025-10-25','김',2,'2025-09-23',16,0),(27,'기타','2025-10-25','닭고기',2,'2025-09-23',16,0),(28,'기타','2025-10-25','닭고기',2,'2025-09-23',16,0),(29,'가공식품','2025-09-28','카레',2,'2025-09-23',16,0),(35,'기타','2025-09-28','밥',2,'2025-09-23',16,0),(36,'기타','2025-09-28','밥',2,'2025-09-23',16,0),(37,'기타','2025-09-28','밥',2,'2025-09-23',16,0),(39,'기타','2025-09-28','김치',2,'2025-09-23',16,0),(40,'기타','2025-09-28','김치',2,'2025-09-23',16,0),(41,'기타','2025-09-28','돼지고기',3,'2025-09-23',16,0),(42,'기타','2025-09-30','돼지고기',3,'2025-09-23',16,0),(43,'기타','2025-09-28','돼지고기',3,'2025-09-23',16,0),(44,'기타','2025-09-28','돼지고기',3,'2025-09-23',16,0),(45,'기타','2025-09-28','돼지고기',3,'2025-09-23',16,0),(46,'기타','2025-09-28','돼지고기',3,'2025-09-23',16,0),(47,'기타','2025-09-28','돼지고기',3,'2025-09-23',16,0),(48,'채소','2025-09-30','김치',4,'2025-09-23',16,0),(49,'채소','2025-09-30','김치',4,'2025-09-23',29,0),(50,'음료','2025-09-30','water',2,'2025-09-23',28,0),(51,'채소','2025-10-08','ice',3,'2025-09-30',16,0),(55,'채소','2025-10-12','계란',2,'2025-10-05',19,0),(56,'채소','2025-10-17','milk',2,'2025-10-10',16,0),(57,'채소','2025-10-17','밥',1,'2025-10-10',34,0),(58,'채소','2025-10-17','밥',2,'2025-10-10',38,0),(59,'채소','2025-10-17','계란',1,'2025-10-10',37,0),(60,'채소','2025-10-17','계란',2,'2025-10-10',16,0),(61,'채소','2025-10-18','두부',2,'2025-10-11',19,0),(62,'채소','2025-10-18','김치',2,'2025-10-11',19,0),(63,'과일','2025-11-03','coconut',1,'2025-10-27',17,0),(64,'가공식품','2025-11-04','콩나물',1,'2025-10-28',16,0),(65,'채소','2025-11-13','김치',1,'2025-11-06',40,0),(66,'채소','2025-11-13','양파',1,'2025-11-06',40,2),(67,'채소','2025-12-18','간장',1,'2025-11-13',40,0),(68,'육류','2025-11-20','항정살',1,'2025-11-13',40,0),(69,'기타','2025-11-20','가자미',1,'2025-11-13',40,0),(70,'유제품','2025-11-25','우유',1,'2025-11-18',40,0),(71,'기타','2025-12-12','밀키트',1,'2025-11-18',40,0),(72,'육류','2025-12-10','소고기',300,'2025-11-18',40,1),(73,'육류','2026-01-16','닭다리살',1,'2025-11-18',40,1),(74,'육류','2026-01-08','가브리살',1,'2025-11-18',40,0),(75,'채소','2025-11-28','오이',1,'2025-11-21',40,4);
/*!40000 ALTER TABLE `items` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2025-11-21 14:23:02
