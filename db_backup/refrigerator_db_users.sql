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
) ENGINE=InnoDB AUTO_INCREMENT=19 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `users`
--

LOCK TABLES `users` WRITE;
/*!40000 ALTER TABLE `users` DISABLE KEYS */;
INSERT INTO `users` VALUES (1,'js1811','$2a$10$k5fviR3MTZmZ7ktnLo.F/OPDpDn0vCrXWZCBasZ96VFgezlD8r4vi','정민교'),(2,'test1234','$2a$10$MBCcCuFVZ4sdPG5HSf9tg.cu47n2oZQeKm.1zK2.OaruVB0C8D5rO','테스트'),(5,'1','$2a$10$C.RgTCVhmckHa1ehx4KJjuXlHOhYjG43ByuTcMGkmGXwnhk0T9dGC','1'),(6,'2','$2a$10$fm0RKDrFzTOmQ4wPx0OAmeFQt.XLichhMWy8XsqnULXehAsB2lpZ2','2'),(7,'jss1811','$2a$10$OyK9iv1iF5aG47WZPOpgzeTgbqwqFzCc24PorckdRA7eP6qHTDtpe','hi'),(8,'5','$2a$10$afenlqM5384/WihiXrje8u1125h7eGmmWNDtRCAAn9ZVwIt40Z.6a','5'),(9,'wjdalsry1811','$2a$10$oJDynePADtEYxThV10QKJeeUHrVZZauBV6H3WSByebB7IRlbzNjQq','hello'),(10,'hi123','$2a$10$YbPUE2fYDXvGuUplvuD2RuiuR4WpiZqP3ppRNwTjCl2PnPpqJFIYS','jjj'),(11,'jjang1811','$2a$10$IoVBUfYEWTnIg3rNXBLbVe7UWuXVmVyPTiTWa7W7lVcC7wJpnMYfu','hii'),(12,'asd123','$2a$10$f2u4VWcZuvD2Y/7q7ffvtuiBeqUchqcqWnrhHbK3YVv2pKREinCqi','jjjj'),(13,'test01','$2a$10$ZGV.4lNxE46ZkLNKcLpucOkxsGuQvy6dZYjkPNQTwR6QlSG/DLPRi','a'),(14,'mmmgyo','$2a$10$x4uVlofSOf3U.XHXKj/2zO.TbdHO9eb5vLNo17Mz21nm//Wx15ME.','j1j1'),(15,'wjdalsry','$2a$10$bigS0mztmxxYgBN843Nomuer8ZWoBsTOYRGH1x1LDaQDeudhvZLjS','jjy'),(16,'mmmg','$2a$10$tB1dPQrTXx6F7.Sr7kJhAOtZIYy1j0dfXiP1di5vxN9E18K1h0N5C','jjjiwji'),(17,'jjeong','$2a$10$ErvSNTzY9aKDh8PMIczqDeSe87aBoD1vFCgPDJKpg0AoGS2kEuB3u','jjjfjf'),(18,'user123','$2a$10$3D6jLpN6BBgqT1Om.h7Ecuael79gEr6ts7DJvMhmw3Tn4wIG1hRbe','yeonuk');
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

-- Dump completed on 2025-11-21 14:23:00
