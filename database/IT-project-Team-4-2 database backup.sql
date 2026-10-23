CREATE DATABASE  IF NOT EXISTS `ticketing_app` /*!40100 DEFAULT CHARACTER SET utf8mb3 */ /*!80016 DEFAULT ENCRYPTION='N' */;
USE `ticketing_app`;
-- MySQL dump 10.13  Distrib 8.0.46, for Win64 (x86_64)
--
-- Host: localhost    Database: ticketing_app
-- ------------------------------------------------------
-- Server version	8.0.46

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
-- Table structure for table `inbox`
--

DROP TABLE IF EXISTS `inbox`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `inbox` (
  `idEmail` varchar(320) NOT NULL,
  `date_sent` datetime NOT NULL,
  `sender` varchar(320) NOT NULL,
  `receiver` varchar(320) NOT NULL,
  `subject` varchar(998) DEFAULT NULL,
  `body` text,
  `status` varchar(20) NOT NULL,
  `date_received` datetime NOT NULL,
  PRIMARY KEY (`idEmail`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `inbox`
--

LOCK TABLES `inbox` WRITE;
/*!40000 ALTER TABLE `inbox` DISABLE KEYS */;
/*!40000 ALTER TABLE `inbox` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `manager`
--

DROP TABLE IF EXISTS `manager`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `manager` (
  `idManager` int NOT NULL AUTO_INCREMENT,
  `User_id` int NOT NULL,
  `Organization_id` int NOT NULL,
  PRIMARY KEY (`idManager`),
  KEY `fk_Manager_User1_idx` (`User_id`),
  KEY `fk_Manager_Organization1_idx` (`Organization_id`),
  CONSTRAINT `fk_Manager_Organization1` FOREIGN KEY (`Organization_id`) REFERENCES `organization` (`idOrganization`),
  CONSTRAINT `fk_Manager_User1` FOREIGN KEY (`User_id`) REFERENCES `user` (`idUser`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `manager`
--

LOCK TABLES `manager` WRITE;
/*!40000 ALTER TABLE `manager` DISABLE KEYS */;
INSERT INTO `manager` VALUES (1,1001,1),(2,1002,1),(3,2001,2),(4,2003,2);
/*!40000 ALTER TABLE `manager` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `member_report`
--

DROP TABLE IF EXISTS `member_report`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `member_report` (
  `idMemberReport` int NOT NULL AUTO_INCREMENT,
  `title` varchar(200) DEFAULT NULL,
  `body` text,
  `date_generated` datetime NOT NULL,
  `TeamMember_id` int NOT NULL,
  PRIMARY KEY (`idMemberReport`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `member_report`
--

LOCK TABLES `member_report` WRITE;
/*!40000 ALTER TABLE `member_report` DISABLE KEYS */;
INSERT INTO `member_report` VALUES (1,'Performance Report - David Chen (Logistics Team)','Team Member report --- David Chen\nTeam: Logistics Team\nGenerated: Thursday, 22 October 2026 at 08:10:31 PM\n\nStatistics\n----------\nTotal assigned jobs: 4\nCompleted jobs: 2\nJobs in progress: 2\nRevenue earned: $210\n\nCompleted Tickets\n-----------------\nTitle: Old server decommission\nLocation: Building F\nPay: $90\nAssigned: 2026-09-13T10:00\nCompleted: 2026-09-18T14:00\nTime to complete: 5 days 4 hours\n\nTitle: Warehouse inventory audit\nLocation: Warehouse A\nPay: $120\nAssigned: 2026-09-12T08:00\nCompleted: 2026-09-17T10:00\nTime to complete: 5 days 2 hours\n\n\nIn Progress Tickets\n-------------------\nTitle: Laptop setup assistance\nLocation: Remote\nPay: $50\nAssigned: 2026-09-15T15:00\n\nTitle: Projector repair\nLocation: Building D\nPay: $60\nAssigned: 2026-09-17T11:00\n\n','2026-10-22 20:10:31',4);
/*!40000 ALTER TABLE `member_report` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `organization`
--

DROP TABLE IF EXISTS `organization`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `organization` (
  `idOrganization` int NOT NULL AUTO_INCREMENT,
  `name` varchar(200) NOT NULL,
  PRIMARY KEY (`idOrganization`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `organization`
--

LOCK TABLES `organization` WRITE;
/*!40000 ALTER TABLE `organization` DISABLE KEYS */;
INSERT INTO `organization` VALUES (1,'Engineering'),(2,'Operations');
/*!40000 ALTER TABLE `organization` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `organization_report`
--

DROP TABLE IF EXISTS `organization_report`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `organization_report` (
  `idOrganizationReport` int NOT NULL AUTO_INCREMENT,
  `title` varchar(200) DEFAULT NULL,
  `body` text,
  `date_generated` datetime NOT NULL,
  `Organization_id` int NOT NULL,
  PRIMARY KEY (`idOrganizationReport`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `organization_report`
--

LOCK TABLES `organization_report` WRITE;
/*!40000 ALTER TABLE `organization_report` DISABLE KEYS */;
INSERT INTO `organization_report` VALUES (1,'Organization Performance Report - Engineering','Organization: Engineering\nManager(s): John Smith, Alice Lee\nGenerated: Thursday, 22 October 2026 at 08:10:31 PM\n\nOrganization Statistics\n-----------------------\nTotal teams: 2\nTotal members: 3\nTotal assigned jobs: 3\nTotal completed jobs: 3\nTotal jobs in progress: 0\nTotal revenue earned: $110\n\nTeam Breakdown\n Note: the team statistics is relative to a specific team, since one member can exist\n in multiple teams, the individual team statistics don\'t add up to the organization statistics\n --------------\nTeam: Backend Team\nMembers: 2\nAssigned jobs: 3\nCompleted jobs: 3\nJobs in progress: 0\nRevenue earned: $110\n\nTeam: Frontend Team\nMembers: 2\nAssigned jobs: 2\nCompleted jobs: 2\nJobs in progress: 0\nRevenue earned: $70\n\n','2026-10-22 20:10:31',1);
/*!40000 ALTER TABLE `organization_report` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `outbox`
--

DROP TABLE IF EXISTS `outbox`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `outbox` (
  `idEmail` varchar(320) NOT NULL,
  `date_sent` datetime NOT NULL,
  `sender` varchar(320) NOT NULL,
  `receiver` varchar(320) NOT NULL,
  `subject` varchar(998) DEFAULT NULL,
  `body` text,
  `status` varchar(20) NOT NULL,
  `date_received` datetime DEFAULT NULL,
  PRIMARY KEY (`idEmail`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `outbox`
--

LOCK TABLES `outbox` WRITE;
/*!40000 ALTER TABLE `outbox` DISABLE KEYS */;
/*!40000 ALTER TABLE `outbox` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `team`
--

DROP TABLE IF EXISTS `team`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `team` (
  `idTeam` int NOT NULL AUTO_INCREMENT,
  `Organization_id` int NOT NULL,
  `name` varchar(200) NOT NULL,
  PRIMARY KEY (`idTeam`),
  KEY `fk_Team_Organization1_idx` (`Organization_id`),
  CONSTRAINT `fk_Team_Organization1` FOREIGN KEY (`Organization_id`) REFERENCES `organization` (`idOrganization`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `team`
--

LOCK TABLES `team` WRITE;
/*!40000 ALTER TABLE `team` DISABLE KEYS */;
INSERT INTO `team` VALUES (1,1,'Backend Team'),(2,1,'Frontend Team'),(3,2,'Field Support Team'),(4,2,'Logistics Team');
/*!40000 ALTER TABLE `team` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `team_member`
--

DROP TABLE IF EXISTS `team_member`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `team_member` (
  `idTeamMember` int NOT NULL AUTO_INCREMENT,
  `Team_id` int NOT NULL,
  `User_id` int NOT NULL,
  `Organization_id` int NOT NULL,
  PRIMARY KEY (`idTeamMember`),
  KEY `fk_TeamMember_Team1_idx` (`Team_id`),
  KEY `fk_TeamMember_User1_idx` (`User_id`),
  KEY `fk_TeamMember_Organization1_idx` (`Organization_id`),
  CONSTRAINT `fk_TeamMember_Organization1` FOREIGN KEY (`Organization_id`) REFERENCES `organization` (`idOrganization`),
  CONSTRAINT `fk_TeamMember_Team1` FOREIGN KEY (`Team_id`) REFERENCES `team` (`idTeam`),
  CONSTRAINT `fk_TeamMember_User1` FOREIGN KEY (`User_id`) REFERENCES `user` (`idUser`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `team_member`
--

LOCK TABLES `team_member` WRITE;
/*!40000 ALTER TABLE `team_member` DISABLE KEYS */;
INSERT INTO `team_member` VALUES (1,1,1001,1),(2,2,1002,1),(3,1,1003,1),(4,4,2001,2),(5,3,2003,2),(6,2,1003,1);
/*!40000 ALTER TABLE `team_member` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `team_report`
--

DROP TABLE IF EXISTS `team_report`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `team_report` (
  `idTeamReport` int NOT NULL AUTO_INCREMENT,
  `title` varchar(200) DEFAULT NULL,
  `body` text,
  `date_generated` datetime NOT NULL,
  `Team_id` int NOT NULL,
  PRIMARY KEY (`idTeamReport`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `team_report`
--

LOCK TABLES `team_report` WRITE;
/*!40000 ALTER TABLE `team_report` DISABLE KEYS */;
INSERT INTO `team_report` VALUES (1,'Team Performance Report - Logistics Team','Team Report --- Logistics Team\nGenerated: Thursday, 22 October 2026 at 08:10:31 PM\n\nMembers\n-------\n- David Chen\n\nStatistics\n----------\nTotal assigned jobs: 4\nCompleted jobs: 2\nJobs in progress: 2\nRevenue earned: $210\n\nCompleted Tickets\n-----------------\nMember: David Chen\nTitle: Old server decommission\nLocation: Building F\nPay: $90\nAssigned: 2026-09-13T10:00\nCompleted: 2026-09-18T14:00\nTime to complete: 5 days 4 hours\n\nMember: David Chen\nTitle: Warehouse inventory audit\nLocation: Warehouse A\nPay: $120\nAssigned: 2026-09-12T08:00\nCompleted: 2026-09-17T10:00\nTime to complete: 5 days 2 hours\n\n\nIn Progress Tickets\n-------------------\nMember: David Chen\nTitle: Laptop setup assistance\nLocation: Remote\nPay: $50\nAssigned: 2026-09-15T15:00\n\nMember: David Chen\nTitle: Projector repair\nLocation: Building D\nPay: $60\nAssigned: 2026-09-17T11:00\n\n','2026-10-22 20:10:31',4);
/*!40000 ALTER TABLE `team_report` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ticket`
--

DROP TABLE IF EXISTS `ticket`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ticket` (
  `idTicket` int NOT NULL AUTO_INCREMENT,
  `poster_id` int NOT NULL,
  `title` varchar(998) NOT NULL,
  `description` text,
  `date_posted` datetime NOT NULL,
  `location` varchar(300) NOT NULL,
  `pay` int NOT NULL,
  `email` varchar(200) NOT NULL,
  `status` varchar(20) NOT NULL,
  `date_completed` datetime DEFAULT NULL,
  PRIMARY KEY (`idTicket`),
  KEY `fk_Ticket_User1_idx` (`poster_id`),
  CONSTRAINT `fk_Ticket_User1` FOREIGN KEY (`poster_id`) REFERENCES `user` (`idUser`)
) ENGINE=InnoDB AUTO_INCREMENT=13 DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ticket`
--

LOCK TABLES `ticket` WRITE;
/*!40000 ALTER TABLE `ticket` DISABLE KEYS */;
INSERT INTO `ticket` VALUES (1,1001,'Move office furniture','Need help moving desks and chairs to Level 3.','2026-09-15 09:00:00','Building A',80,'john@example.com','OPEN',NULL),(2,1002,'Laptop setup assistance','Configure a new company laptop.','2026-09-15 14:30:00','Remote',50,'alice@example.com','IN_PROGRESS',NULL),(3,1003,'Printer troubleshooting','Office printer is not connecting to the network.','2026-09-16 08:15:00','Building B',30,'bob@example.com','CLOSED','2026-09-20 14:00:00'),(4,1001,'Network cable installation','Install network cable in meeting room.','2026-09-14 11:00:00','Building C',40,'john@example.com','CLOSED','2026-09-18 16:30:00'),(5,1002,'Projector repair','Projector is flickering.','2026-09-17 10:30:00','Building D',60,'alice@example.com','IN_PROGRESS',NULL),(6,1003,'Software installation','Install licensed software.','2026-09-13 16:00:00','Building E',70,'bob@example.com','IN_PROGRESS',NULL),(7,1002,'Old server decommission','Retire legacy server.','2026-09-12 10:00:00','Building F',90,'alice@example.com','CLOSED','2026-09-18 14:00:00'),(8,1001,'Warehouse inventory audit','Perform quarterly inventory audit.','2026-09-11 09:00:00','Warehouse A',120,'john@example.com','CLOSED','2026-09-17 10:00:00'),(9,1001,'Conference room setup','Arrange tables and equipment for workshop.','2026-09-18 09:00:00','Building G',45,'john@example.com','OPEN',NULL),(10,1002,'Monitor installation','Install dual monitors at employee workstation.','2026-09-18 11:00:00','Building B',35,'alice@example.com','OPEN',NULL),(11,1003,'WiFi coverage check','Investigate weak WiFi signal in meeting rooms.','2026-09-19 08:30:00','Building C',55,'bob@example.com','OPEN',NULL),(12,1002,'Desktop cleanup','Remove unused files and organize workstation.','2026-09-19 13:15:00','Building D',25,'alice@example.com','OPEN',NULL);
/*!40000 ALTER TABLE `ticket` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ticket_assignment`
--

DROP TABLE IF EXISTS `ticket_assignment`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ticket_assignment` (
  `idTicketAssignment` int NOT NULL AUTO_INCREMENT,
  `assignee_id` int NOT NULL,
  `Ticket_id` int NOT NULL,
  `date_assigned` datetime NOT NULL,
  `related_team_id` int DEFAULT NULL,
  PRIMARY KEY (`idTicketAssignment`),
  KEY `fk_TicketAssignment_User1_idx` (`assignee_id`),
  KEY `fk_TicketAssignment_Ticket1_idx` (`Ticket_id`),
  KEY `fk_ticket_assignment_team1_idx` (`related_team_id`),
  CONSTRAINT `fk_ticket_assignment_team1` FOREIGN KEY (`related_team_id`) REFERENCES `team` (`idTeam`),
  CONSTRAINT `fk_TicketAssignment_Ticket1` FOREIGN KEY (`Ticket_id`) REFERENCES `ticket` (`idTicket`),
  CONSTRAINT `fk_TicketAssignment_User1` FOREIGN KEY (`assignee_id`) REFERENCES `user` (`idUser`)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ticket_assignment`
--

LOCK TABLES `ticket_assignment` WRITE;
/*!40000 ALTER TABLE `ticket_assignment` DISABLE KEYS */;
INSERT INTO `ticket_assignment` VALUES (1,2001,2,'2026-09-15 15:00:00',3),(2,2003,2,'2026-09-15 15:00:00',3),(3,2003,3,'2026-09-16 09:00:00',NULL),(4,1001,4,'2026-09-14 12:00:00',1),(5,1003,4,'2026-09-14 12:00:00',1),(6,2001,5,'2026-09-17 11:00:00',NULL),(7,2003,6,'2026-09-13 17:00:00',NULL),(8,2001,7,'2026-09-13 10:00:00',NULL),(9,2001,8,'2026-09-12 08:00:00',4),(10,1003,3,'2026-09-20 09:00:00',2);
/*!40000 ALTER TABLE `ticket_assignment` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ticket_attachment`
--

DROP TABLE IF EXISTS `ticket_attachment`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ticket_attachment` (
  `idTicketAttachment` int NOT NULL AUTO_INCREMENT,
  `Ticket_id` int NOT NULL,
  `attachment_name` varchar(45) DEFAULT NULL,
  `attachment_content` longblob,
  PRIMARY KEY (`idTicketAttachment`),
  KEY `fk_TicketAttachment_Ticket1_idx` (`Ticket_id`),
  CONSTRAINT `fk_TicketAttachment_Ticket1` FOREIGN KEY (`Ticket_id`) REFERENCES `ticket` (`idTicket`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ticket_attachment`
--

LOCK TABLES `ticket_attachment` WRITE;
/*!40000 ALTER TABLE `ticket_attachment` DISABLE KEYS */;
/*!40000 ALTER TABLE `ticket_attachment` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ticket_comment`
--

DROP TABLE IF EXISTS `ticket_comment`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ticket_comment` (
  `idticket_comment` int NOT NULL AUTO_INCREMENT,
  `ticket_idTicket` int NOT NULL,
  `user_idUser` int NOT NULL,
  `date` datetime NOT NULL,
  `content` text,
  PRIMARY KEY (`idticket_comment`),
  KEY `fk_ticket_comment_ticket1_idx` (`ticket_idTicket`),
  KEY `fk_ticket_comment_user1_idx` (`user_idUser`),
  CONSTRAINT `fk_ticket_comment_ticket1` FOREIGN KEY (`ticket_idTicket`) REFERENCES `ticket` (`idTicket`),
  CONSTRAINT `fk_ticket_comment_user1` FOREIGN KEY (`user_idUser`) REFERENCES `user` (`idUser`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ticket_comment`
--

LOCK TABLES `ticket_comment` WRITE;
/*!40000 ALTER TABLE `ticket_comment` DISABLE KEYS */;
/*!40000 ALTER TABLE `ticket_comment` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `user`
--

DROP TABLE IF EXISTS `user`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `user` (
  `idUser` int NOT NULL AUTO_INCREMENT,
  `name` varchar(100) NOT NULL,
  `email` varchar(200) NOT NULL,
  `description` text,
  `subscribe_email` tinyint NOT NULL DEFAULT '0',
  PRIMARY KEY (`idUser`)
) ENGINE=InnoDB AUTO_INCREMENT=2004 DEFAULT CHARSET=utf8mb3;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `user`
--

LOCK TABLES `user` WRITE;
/*!40000 ALTER TABLE `user` DISABLE KEYS */;
INSERT INTO `user` VALUES (1001,'John Smith','john@example.com',NULL,0),(1002,'Alice Lee','alice@example.com',NULL,0),(1003,'Bob Wilson','bob@example.com',NULL,0),(2001,'David Chen','david@example.com',NULL,0),(2003,'Emma Brown','emma@example.com',NULL,0);
/*!40000 ALTER TABLE `user` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-10-22 20:13:02
