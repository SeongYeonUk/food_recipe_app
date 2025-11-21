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
-- Table structure for table `refrigerators`
--

DROP TABLE IF EXISTS `refrigerators`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `refrigerators` (
  `refrigerator_id` bigint NOT NULL AUTO_INCREMENT,
  `type` enum('김치냉장고','냉동실','냉장고') NOT NULL,
  `user_id` bigint DEFAULT NULL,
  `is_primary` bit(1) NOT NULL,
  PRIMARY KEY (`refrigerator_id`),
  KEY `FKps913u29n3h8xha12dgb24iof` (`user_id`),
  CONSTRAINT `FKps913u29n3h8xha12dgb24iof` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=43 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `refrigerators`
--

LOCK TABLES `refrigerators` WRITE;
/*!40000 ALTER TABLE `refrigerators` DISABLE KEYS */;
INSERT INTO `refrigerators` VALUES (1,'냉장고',5,_binary '\0'),(2,'김치냉장고',5,_binary '\0'),(3,'냉동실',5,_binary '\0'),(4,'냉장고',6,_binary '\0'),(5,'김치냉장고',6,_binary '\0'),(6,'냉동실',6,_binary '\0'),(7,'냉장고',7,_binary '\0'),(8,'김치냉장고',7,_binary '\0'),(9,'냉동실',7,_binary '\0'),(10,'냉장고',8,_binary '\0'),(11,'김치냉장고',8,_binary '\0'),(12,'냉동실',8,_binary '\0'),(13,'냉장고',9,_binary '\0'),(14,'김치냉장고',9,_binary '\0'),(15,'냉동실',9,_binary '\0'),(16,'냉장고',10,_binary '\0'),(17,'김치냉장고',10,_binary '\0'),(18,'냉동실',10,_binary '\0'),(19,'냉장고',11,_binary '\0'),(20,'김치냉장고',11,_binary '\0'),(21,'냉동실',11,_binary '\0'),(22,'냉장고',12,_binary '\0'),(23,'김치냉장고',12,_binary '\0'),(24,'냉동실',12,_binary '\0'),(25,'냉장고',13,_binary '\0'),(26,'김치냉장고',13,_binary '\0'),(27,'냉동실',13,_binary '\0'),(28,'냉장고',14,_binary '\0'),(29,'김치냉장고',14,_binary '\0'),(30,'냉동실',14,_binary '\0'),(31,'냉장고',15,_binary '\0'),(32,'김치냉장고',15,_binary '\0'),(33,'냉동실',15,_binary '\0'),(34,'냉장고',16,_binary '\0'),(35,'김치냉장고',16,_binary '\0'),(36,'냉동실',16,_binary '\0'),(37,'냉장고',17,_binary '\0'),(38,'김치냉장고',17,_binary '\0'),(39,'냉동실',17,_binary '\0'),(40,'냉장고',18,_binary '\0'),(41,'김치냉장고',18,_binary '\0'),(42,'냉동실',18,_binary '\0');
/*!40000 ALTER TABLE `refrigerators` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2025-11-21 14:23:06
