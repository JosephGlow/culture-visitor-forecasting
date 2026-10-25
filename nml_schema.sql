/*M!999999\- enable the sandbox mode */ 
-- MariaDB dump 10.19-11.8.6-MariaDB, for debian-linux-gnu (x86_64)
--
-- Host: localhost    Database: nml
-- ------------------------------------------------------
-- Server version	11.8.6-MariaDB-0+deb13u1 from Debian

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*M!100616 SET @OLD_NOTE_VERBOSITY=@@NOTE_VERBOSITY, NOTE_VERBOSITY=0 */;

--
-- Table structure for table `area`
--

DROP TABLE IF EXISTS `area`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `area` (
  `area` varchar(32) NOT NULL,
  `name` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`area`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `financial_year`
--

DROP TABLE IF EXISTS `financial_year`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `financial_year` (
  `fy` char(7) NOT NULL,
  `fy_start` date NOT NULL,
  `fy_end` date NOT NULL,
  PRIMARY KEY (`fy`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Temporary table structure for view `nml_visits_daily`
--

DROP TABLE IF EXISTS `nml_visits_daily`;
/*!50001 DROP VIEW IF EXISTS `nml_visits_daily`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8mb4;
/*!50001 CREATE VIEW `nml_visits_daily` AS SELECT
 1 AS `date`,
  1 AS `WM`,
  1 AS `WAG`,
  1 AS `MM`,
  1 AS `LLAG`,
  1 AS `SH`,
  1 AS `PMH`,
  1 AS `NCC`,
  1 AS `MoL`,
  1 AS `ISM`,
  1 AS `HH` */;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `term_dates`
--

DROP TABLE IF EXISTS `term_dates`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `term_dates` (
  `date` date NOT NULL,
  `wirral` varchar(16) DEFAULT NULL,
  `liverpool` varchar(16) DEFAULT NULL,
  `sefton` varchar(16) DEFAULT NULL,
  `knowsley` varchar(16) DEFAULT NULL,
  `st_helens` varchar(16) DEFAULT NULL,
  `halton` varchar(16) DEFAULT NULL,
  PRIMARY KEY (`date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `venue`
--

DROP TABLE IF EXISTS `venue`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `venue` (
  `id` varchar(255) NOT NULL,
  `area` varchar(32) NOT NULL,
  `name` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `fk_venue_area` (`area`),
  CONSTRAINT `fk_venue_area` FOREIGN KEY (`area`) REFERENCES `area` (`area`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Temporary table structure for view `venue_daily`
--

DROP TABLE IF EXISTS `venue_daily`;
/*!50001 DROP VIEW IF EXISTS `venue_daily`*/;
SET @saved_cs_client     = @@character_set_client;
SET character_set_client = utf8mb4;
/*!50001 CREATE VIEW `venue_daily` AS SELECT
 1 AS `date`,
  1 AS `weekday`,
  1 AS `venue_id`,
  1 AS `area`,
  1 AS `visits`,
  1 AS `temp_c`,
  1 AS `feels_like_c`,
  1 AS `dew_point_c`,
  1 AS `visibility_m`,
  1 AS `clouds_pct`,
  1 AS `wind_speed_ms`,
  1 AS `wind_gust_ms`,
  1 AS `rain_1h_mm`,
  1 AS `snow_1h_mm`,
  1 AS `weather_id`,
  1 AS `weather_desc`,
  1 AS `oh_temp_c`,
  1 AS `oh_feels_like_c`,
  1 AS `oh_dew_point_c`,
  1 AS `oh_visibility_m`,
  1 AS `oh_clouds_pct`,
  1 AS `oh_wind_speed_ms`,
  1 AS `oh_wind_gust_ms`,
  1 AS `oh_rain_1h_mm`,
  1 AS `oh_snow_1h_mm`,
  1 AS `oh_weather_id`,
  1 AS `oh_weather_desc`,
  1 AS `sources` */;
SET character_set_client = @saved_cs_client;

--
-- Table structure for table `visits_daily`
--

DROP TABLE IF EXISTS `visits_daily`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `visits_daily` (
  `date` date NOT NULL,
  `venue_id` varchar(255) NOT NULL,
  `visits` int(11) DEFAULT NULL,
  `sources` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`sources`)),
  PRIMARY KEY (`date`,`venue_id`),
  KEY `venue_id` (`venue_id`),
  CONSTRAINT `visits_daily_ibfk_1` FOREIGN KEY (`venue_id`) REFERENCES `venue` (`id`),
  CONSTRAINT `chk_vd_visits` CHECK (`visits` >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `visits_fy`
--

DROP TABLE IF EXISTS `visits_fy`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `visits_fy` (
  `fy` char(7) NOT NULL,
  `venue_id` varchar(255) NOT NULL,
  `visits` int(11) NOT NULL,
  `sources` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`sources`)),
  PRIMARY KEY (`fy`,`venue_id`),
  KEY `venue_id` (`venue_id`),
  CONSTRAINT `fk_visits_fy_year` FOREIGN KEY (`fy`) REFERENCES `financial_year` (`fy`),
  CONSTRAINT `visits_fy_ibfk_1` FOREIGN KEY (`venue_id`) REFERENCES `venue` (`id`),
  CONSTRAINT `chk_vfy_visits` CHECK (`visits` >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `visits_hourly`
--

DROP TABLE IF EXISTS `visits_hourly`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `visits_hourly` (
  `datetime` datetime NOT NULL COMMENT 'Europe/London local',
  `venue_id` varchar(255) NOT NULL,
  `visits` int(11) DEFAULT NULL,
  `sources` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`sources`)),
  PRIMARY KEY (`datetime`,`venue_id`),
  KEY `idx_venue_dt` (`venue_id`,`datetime`),
  CONSTRAINT `visits_hourly_ibfk_1` FOREIGN KEY (`venue_id`) REFERENCES `venue` (`id`),
  CONSTRAINT `chk_vh_visits` CHECK (`visits` >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `weather_3hourly`
--

DROP TABLE IF EXISTS `weather_3hourly`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `weather_3hourly` (
  `start_dt` datetime NOT NULL COMMENT 'Europe/London local, period start',
  `area` varchar(32) NOT NULL,
  `temp_c` decimal(4,1) DEFAULT NULL,
  `feels_like_c` decimal(4,1) DEFAULT NULL,
  `dew_point_c` decimal(4,1) DEFAULT NULL,
  `visibility_m` int(11) DEFAULT NULL,
  `clouds_pct` tinyint(4) DEFAULT NULL,
  `wind_speed_ms` decimal(4,1) DEFAULT NULL,
  `wind_gust_ms` decimal(4,1) DEFAULT NULL,
  `rain_1h_mm` decimal(5,2) DEFAULT NULL,
  `snow_1h_mm` decimal(5,2) DEFAULT NULL,
  `weather_id` smallint(6) DEFAULT NULL,
  `weather_desc` varchar(100) DEFAULT NULL,
  `sources` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`sources`)),
  PRIMARY KEY (`start_dt`,`area`),
  KEY `fk_w3h_area` (`area`),
  CONSTRAINT `fk_w3h_area` FOREIGN KEY (`area`) REFERENCES `area` (`area`),
  CONSTRAINT `chk_w3h_cloud` CHECK (`clouds_pct` between 0 and 100)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `weather_daily`
--

DROP TABLE IF EXISTS `weather_daily`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `weather_daily` (
  `date` date NOT NULL,
  `area` varchar(32) NOT NULL,
  `temp_c` decimal(4,1) DEFAULT NULL,
  `feels_like_c` decimal(4,1) DEFAULT NULL,
  `dew_point_c` decimal(4,1) DEFAULT NULL,
  `visibility_m` int(11) DEFAULT NULL,
  `clouds_pct` tinyint(4) DEFAULT NULL,
  `wind_speed_ms` decimal(4,1) DEFAULT NULL,
  `wind_gust_ms` decimal(4,1) DEFAULT NULL,
  `rain_1h_mm` decimal(5,2) DEFAULT NULL,
  `snow_1h_mm` decimal(5,2) DEFAULT NULL,
  `weather_id` smallint(6) DEFAULT NULL,
  `weather_desc` varchar(100) DEFAULT NULL,
  `oh_temp_c` decimal(4,1) DEFAULT NULL,
  `oh_feels_like_c` decimal(4,1) DEFAULT NULL,
  `oh_dew_point_c` decimal(4,1) DEFAULT NULL,
  `oh_visibility_m` int(11) DEFAULT NULL,
  `oh_clouds_pct` tinyint(4) DEFAULT NULL,
  `oh_wind_speed_ms` decimal(4,1) DEFAULT NULL,
  `oh_wind_gust_ms` decimal(4,1) DEFAULT NULL,
  `oh_rain_1h_mm` decimal(5,2) DEFAULT NULL,
  `oh_snow_1h_mm` decimal(5,2) DEFAULT NULL,
  `oh_weather_id` smallint(6) DEFAULT NULL,
  `oh_weather_desc` varchar(100) DEFAULT NULL,
  `sources` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`sources`)),
  PRIMARY KEY (`date`,`area`),
  KEY `fk_wd_area` (`area`),
  CONSTRAINT `fk_wd_area` FOREIGN KEY (`area`) REFERENCES `area` (`area`),
  CONSTRAINT `chk_wd_cloud` CHECK (`clouds_pct` between 0 and 100),
  CONSTRAINT `chk_wd_ohcloud` CHECK (`oh_clouds_pct` between 0 and 100)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Table structure for table `weather_hourly`
--

DROP TABLE IF EXISTS `weather_hourly`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `weather_hourly` (
  `dt` datetime NOT NULL COMMENT 'UTC (OpenWeather dt)',
  `area` varchar(32) NOT NULL,
  `temp_c` decimal(4,1) DEFAULT NULL,
  `feels_like_c` decimal(4,1) DEFAULT NULL,
  `dew_point_c` decimal(4,1) DEFAULT NULL,
  `visibility_m` int(11) DEFAULT NULL,
  `clouds_pct` tinyint(4) DEFAULT NULL,
  `wind_speed_ms` decimal(4,1) DEFAULT NULL,
  `wind_gust_ms` decimal(4,1) DEFAULT NULL,
  `rain_1h_mm` decimal(5,2) DEFAULT NULL,
  `snow_1h_mm` decimal(5,2) DEFAULT NULL,
  `weather_id` smallint(6) DEFAULT NULL,
  `weather_desc` varchar(100) DEFAULT NULL,
  `sources` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`sources`)),
  PRIMARY KEY (`dt`,`area`),
  KEY `idx_area_dt` (`area`,`dt`),
  CONSTRAINT `fk_wh_area` FOREIGN KEY (`area`) REFERENCES `area` (`area`),
  CONSTRAINT `chk_wh_cloud` CHECK (`clouds_pct` between 0 and 100)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping routines for database 'nml'
--

--
-- Final view structure for view `nml_visits_daily`
--

/*!50001 DROP VIEW IF EXISTS `nml_visits_daily`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_unicode_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=CURRENT_USER SQL SECURITY DEFINER */
/*!50001 VIEW `nml_visits_daily` AS select `visits_daily`.`date` AS `date`,max(case when `visits_daily`.`venue_id` = 'WM' then `visits_daily`.`visits` end) AS `WM`,max(case when `visits_daily`.`venue_id` = 'WAG' then `visits_daily`.`visits` end) AS `WAG`,max(case when `visits_daily`.`venue_id` = 'MM' then `visits_daily`.`visits` end) AS `MM`,max(case when `visits_daily`.`venue_id` = 'LLAG' then `visits_daily`.`visits` end) AS `LLAG`,max(case when `visits_daily`.`venue_id` = 'SH' then `visits_daily`.`visits` end) AS `SH`,max(case when `visits_daily`.`venue_id` = 'PMH' then `visits_daily`.`visits` end) AS `PMH`,max(case when `visits_daily`.`venue_id` = 'NCC' then `visits_daily`.`visits` end) AS `NCC`,max(case when `visits_daily`.`venue_id` = 'MoL' then `visits_daily`.`visits` end) AS `MoL`,max(case when `visits_daily`.`venue_id` = 'ISM' then `visits_daily`.`visits` end) AS `ISM`,max(case when `visits_daily`.`venue_id` = 'HH' then `visits_daily`.`visits` end) AS `HH` from `visits_daily` group by `visits_daily`.`date` order by `visits_daily`.`date` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;

--
-- Final view structure for view `venue_daily`
--

/*!50001 DROP VIEW IF EXISTS `venue_daily`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_uca1400_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 DEFINER=CURRENT_USER SQL SECURITY INVOKER */
/*!50001 VIEW `venue_daily` AS select `v`.`date` AS `date`,dayname(`v`.`date`) AS `weekday`,`v`.`venue_id` AS `venue_id`,`vn`.`area` AS `area`,`v`.`visits` AS `visits`,`w`.`temp_c` AS `temp_c`,`w`.`feels_like_c` AS `feels_like_c`,`w`.`dew_point_c` AS `dew_point_c`,`w`.`visibility_m` AS `visibility_m`,`w`.`clouds_pct` AS `clouds_pct`,`w`.`wind_speed_ms` AS `wind_speed_ms`,`w`.`wind_gust_ms` AS `wind_gust_ms`,`w`.`rain_1h_mm` AS `rain_1h_mm`,`w`.`snow_1h_mm` AS `snow_1h_mm`,`w`.`weather_id` AS `weather_id`,`w`.`weather_desc` AS `weather_desc`,`w`.`oh_temp_c` AS `oh_temp_c`,`w`.`oh_feels_like_c` AS `oh_feels_like_c`,`w`.`oh_dew_point_c` AS `oh_dew_point_c`,`w`.`oh_visibility_m` AS `oh_visibility_m`,`w`.`oh_clouds_pct` AS `oh_clouds_pct`,`w`.`oh_wind_speed_ms` AS `oh_wind_speed_ms`,`w`.`oh_wind_gust_ms` AS `oh_wind_gust_ms`,`w`.`oh_rain_1h_mm` AS `oh_rain_1h_mm`,`w`.`oh_snow_1h_mm` AS `oh_snow_1h_mm`,`w`.`oh_weather_id` AS `oh_weather_id`,`w`.`oh_weather_desc` AS `oh_weather_desc`,json_merge_preserve(`v`.`sources`,`w`.`sources`) AS `sources` from ((`visits_daily` `v` join `venue` `vn` on(`vn`.`id` = `v`.`venue_id`)) join `weather_daily` `w` on(`w`.`date` = `v`.`date` and `w`.`area` = `vn`.`area`)) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*M!100616 SET NOTE_VERBOSITY=@OLD_NOTE_VERBOSITY */;

-- Dump completed on 2026-09-25 14:39:46
