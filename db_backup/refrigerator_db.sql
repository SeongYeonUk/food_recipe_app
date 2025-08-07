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
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `users` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `email` varchar(255) NOT NULL,
  `nickname` varchar(255) NOT NULL,
  `password` varchar(255) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `UK6dotkott2kjsp8vw4d0m25fb7` (`email`),
  UNIQUE KEY `UK2ty1xmrrgtn89xt7kyxx6ta7h` (`nickname`)
) ENGINE=InnoDB AUTO_INCREMENT=18 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `users`
--

LOCK TABLES `users` WRITE;
/*!40000 ALTER TABLE `users` DISABLE KEYS */;
INSERT INTO `users` VALUES (1,'test@example.com','testuser','$2a$10$nqN75E/yrdEKTiOa7zTCluzKjNsHNMRcaj12xK5zzYLMdA4A.Ho/y'),(2,'kieesdeolain@gmail.com','mmmgyo','$2a$10$5DeNcJoh7pEMngI5jcGjnOTkSR0h68XbQ2TdAc4O2uxG2S99yEaqe'),(11,'alsry1811@gmail.com','mingyo','$2a$10$y.lNgLjZNeQSjfaR4LlxJO.X6aU33L5YAs9UwGV8aBAKsKKLUY.Dq'),(12,'hello@gmail.com','world','$2a$10$xh2Jh0kT6GqEx8lMEwLMMucqtHmGgafW5LDzMBZswgehREPNM73XC'),(13,'test@naver.com','wjdalsry','$2a$10$ejEUwCyCoyTy4wu.QX4mFOneD6whYoVLjgHT5JEaQ3gn85C6xYbOC'),(15,'postman@example.com','postman','$2a$10$ZGaffZpqftaG4mHb1CH0/.b8kes9ZzcM8mWXUuBSra0v7uMJcs/Ci'),(16,'testuser@example.com','tester','$2a$10$mS.dv1bvEvUcQwiAddS6x.X0JbX7ert5uAkE37aovfAUORNo6GyjC'),(17,'jeongmingyo@example.com','정민교','$2a$10$Kp8xd2bUGoczGIP57KJsROJx.LSQ0mhEgI4GHDSUmYn6OjKYGyCm.');
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

-- Dump completed on 2025-08-07 17:03:55
