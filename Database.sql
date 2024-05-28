/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET NAMES utf8 */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

CREATE DATABASE IF NOT EXISTS `dv1663` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci */ /*!80016 DEFAULT ENCRYPTION='N' */;
USE `dv1663`;

CREATE TABLE IF NOT EXISTS `bookings` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `train_id` int unsigned NOT NULL,
  `customer_id` int unsigned NOT NULL,
  PRIMARY KEY (`id`),
  KEY `customer_id` (`customer_id`),
  KEY `train_id` (`train_id`),
  CONSTRAINT `customer_id` FOREIGN KEY (`customer_id`) REFERENCES `customers` (`id`),
  CONSTRAINT `train_id` FOREIGN KEY (`train_id`) REFERENCES `trains` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


CREATE TABLE IF NOT EXISTS `customers` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `f_name` varchar(30) NOT NULL DEFAULT '',
  `l_name` varchar(30) NOT NULL DEFAULT '',
  `email` varchar(60) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `email` (`email`)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


DELIMITER //
CREATE FUNCTION `get_route_from_stations`(
	`s_station` INT,
	`e_station` INT
) RETURNS int
    DETERMINISTIC
    COMMENT 'Get routes for provided stations.'
BEGIN
	DECLARE result INTEGER;

	SELECT DISTINCT routes.id AS route_id FROM routes
	JOIN tracks ON tracks.id=routes.track_id
	WHERE start_station=s_station
	INTERSECT
	SELECT DISTINCT routes.id AS route_id FROM routes
	JOIN tracks ON tracks.id=routes.track_id
	WHERE end_station=e_station AND routes.track_index > (SELECT routes.track_index FROM routes JOIN tracks ON tracks.id=routes.track_id WHERE start_station=s_station LIMIT 1)
	LIMIT 1
	INTO result;
	
	RETURN result;
END//
DELIMITER ;

DELIMITER //
CREATE FUNCTION `get_route_time`(
	`route_id` INT,
	`s_station` INT,
	`e_station` INT
) RETURNS int
    DETERMINISTIC
    COMMENT 'Get travel time for specified route and stations.'
BEGIN
	DECLARE s_index INTEGER;
	DECLARE e_index INTEGER;
	DECLARE minutes INTEGER;
	
	SELECT track_index FROM routes
	JOIN tracks ON tracks.id=routes.track_id
	WHERE routes.id=route_id AND start_station=s_station INTO s_index;
	
	SELECT track_index FROM routes
	JOIN tracks ON tracks.id=routes.track_id
	WHERE routes.id=route_id AND end_station=e_station INTO e_index;
	
	SELECT SUM(tracks.minutes) FROM tracks
	JOIN routes ON routes.track_id=tracks.id
	WHERE routes.id=route_id AND track_index BETWEEN s_index AND e_index INTO minutes;
	
	RETURN minutes;
END//
DELIMITER ;

DELIMITER //
CREATE PROCEDURE `get_stations_from_route`(
	IN `route_id` INT,
	OUT `s_station` INT,
	OUT `e_station` INT
)
    DETERMINISTIC
    COMMENT 'Get start and end station ids for a specified route.'
BEGIN
	SELECT start_station FROM routes
	JOIN tracks ON tracks.id=routes.track_id
	WHERE routes.id=route_id AND routes.track_index=0 INTO s_station;
	
	SELECT end_station FROM routes
	JOIN tracks ON tracks.id=routes.track_id
	WHERE routes.id=route_id AND routes.track_index=(SELECT MAX(routes.track_index) FROM routes JOIN tracks ON routes.track_id=tracks.id WHERE routes.id=route_id) INTO e_station;
END//
DELIMITER ;

DELIMITER //
CREATE FUNCTION `get_train_arrival_time`(
	`train_id` INT,
	`station_id` INT
) RETURNS datetime
    DETERMINISTIC
    COMMENT 'Get arrival time for a specfied train and station.'
BEGIN
	DECLARE result DATETIME;
	DECLARE add_minutes INTEGER;
	
	SELECT start_time FROM trains WHERE trains.id=train_id INTO @start_time;
	
	SELECT track_index FROM trains
	JOIN routes ON routes.id=trains.route_id
	JOIN tracks ON tracks.id=routes.track_id
	WHERE trains.id=train_id AND end_station=station_id
	INTO @track_index;
	
	SELECT SUM(MINUTES) FROM trains
	JOIN routes ON routes.id=trains.route_id
	JOIN tracks ON tracks.id=routes.track_id
	WHERE routes.id=route_id AND trains.id=train_id AND track_index <= @track_index
	GROUP BY routes.id
	INTO add_minutes;
	
	SELECT DATE_ADD(@start_time, INTERVAL (SELECT IFNULL(add_minutes, 0)) MINUTE) INTO result;
	
	RETURN result;
END//
DELIMITER ;

DELIMITER //
CREATE FUNCTION `get_train_count_passing`(
	`track_id` integer,
	`start_date` DATE,
	`end_date` DATE
) RETURNS int
    DETERMINISTIC
    COMMENT 'Get total amount of trains passing a specified track during a specified duration of time.'
BEGIN
	DECLARE count_trains INTEGER;
	SELECT COUNT(trains.id) FROM routes
	JOIN tracks ON tracks.id=routes.track_id
	JOIN trains ON trains.route_id=routes.id
	WHERE trains.start_time BETWEEN start_date AND end_date
	GROUP BY tracks.id HAVING tracks.id=track_id
	INTO count_trains;
	RETURN count_trains;
END//
DELIMITER ;

DELIMITER //
CREATE FUNCTION `get_train_depart_time`(
	`train_id` INT,
	`station_id` INT
) RETURNS datetime
    DETERMINISTIC
    COMMENT 'Get depart time for a specfied train and station.'
BEGIN
	DECLARE result DATETIME;
	DECLARE add_minutes INTEGER;
	
	SELECT start_time FROM trains WHERE trains.id=train_id INTO @start_time;
	
	SELECT track_index FROM trains
	JOIN routes ON routes.id=trains.route_id
	JOIN tracks ON tracks.id=routes.track_id
	WHERE trains.id=train_id AND start_station=station_id
	INTO @track_index;
	
	SELECT SUM(MINUTES) FROM trains
	JOIN routes ON routes.id=trains.route_id
	JOIN tracks ON tracks.id=routes.track_id
	WHERE routes.id=route_id AND trains.id=train_id AND track_index < @track_index
	GROUP BY routes.id
	INTO add_minutes;
	
	SELECT DATE_ADD(@start_time, INTERVAL (SELECT IFNULL(add_minutes, 0)) MINUTE) INTO result;
	
	RETURN result;
END//
DELIMITER ;

CREATE TABLE IF NOT EXISTS `routes` (
  `id` int unsigned NOT NULL,
  `track_id` int unsigned NOT NULL,
  `track_index` int unsigned NOT NULL,
  KEY `track_id` (`track_id`),
  CONSTRAINT `track_id` FOREIGN KEY (`track_id`) REFERENCES `tracks` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

INSERT INTO `routes` (`id`, `track_id`, `track_index`) VALUES
	(1, 1, 0),
	(1, 2, 1),
	(1, 3, 2),
	(1, 4, 3),
	(2, 5, 0),
	(2, 6, 1),
	(2, 7, 2),
	(2, 8, 3);

CREATE TABLE IF NOT EXISTS `stations` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `title` varchar(30) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

INSERT INTO `stations` (`id`, `title`) VALUES
	(1, 'Karlskrona C'),
	(2, 'Bergåsa'),
	(3, 'Holmsjö'),
	(4, 'Vissefjärda'),
	(5, 'Emmaboda');

CREATE TABLE IF NOT EXISTS `tracks` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `start_station` int unsigned NOT NULL,
  `end_station` int unsigned NOT NULL,
  `minutes` int unsigned NOT NULL,
  PRIMARY KEY (`id`),
  KEY `start_station` (`start_station`),
  KEY `end_station` (`end_station`),
  CONSTRAINT `end_station` FOREIGN KEY (`end_station`) REFERENCES `stations` (`id`),
  CONSTRAINT `start_station` FOREIGN KEY (`start_station`) REFERENCES `stations` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

INSERT INTO `tracks` (`id`, `start_station`, `end_station`, `minutes`) VALUES
	(1, 1, 2, 3),
	(2, 2, 3, 24),
	(3, 3, 4, 9),
	(4, 4, 5, 7),
	(5, 5, 4, 7),
	(6, 4, 3, 9),
	(7, 3, 2, 24),
	(8, 2, 1, 3);

CREATE TABLE IF NOT EXISTS `trains` (
  `id` int unsigned NOT NULL AUTO_INCREMENT,
  `route_id` int unsigned NOT NULL,
  `start_time` datetime NOT NULL,
  `operator` varchar(30) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `max_passengers` int unsigned NOT NULL,
  `booked_passengers` int unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

INSERT INTO `trains` (`id`, `route_id`, `start_time`, `operator`, `max_passengers`, `booked_passengers`) VALUES
	(1, 1, '2024-05-24 05:42:00', 'Krösatågen', 80, 0),
	(2, 2, '2024-05-24 06:34:00', 'Krösatågen', 80, 0);

SET @OLDTMP_SQL_MODE=@@SQL_MODE, SQL_MODE='ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';
DELIMITER //
CREATE TRIGGER `booking_add` BEFORE INSERT ON `bookings` FOR EACH ROW BEGIN
	SELECT booked_passengers FROM trains WHERE trains.id = NEW.train_id INTO @passengers;
	SELECT max_passengers FROM trains WHERE trains.id = NEW.train_id INTO @max_passengers;
	
	IF @passengers+1 > @max_passengers THEN
		SIGNAL SQLSTATE '45000' set message_text = 'Maximum train capacity reached';
	END IF;

	UPDATE trains SET trains.booked_passengers = trains.booked_passengers + 1
	WHERE trains.id = NEW.train_id;
END//
DELIMITER ;
SET SQL_MODE=@OLDTMP_SQL_MODE;

SET @OLDTMP_SQL_MODE=@@SQL_MODE, SQL_MODE='ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';
DELIMITER //
CREATE TRIGGER `booking_remove` AFTER DELETE ON `bookings` FOR EACH ROW BEGIN
	UPDATE trains SET trains.booked_passengers = trains.booked_passengers - 1
	WHERE trains.id = OLD.train_id;
END//
DELIMITER ;
SET SQL_MODE=@OLDTMP_SQL_MODE;

/*!40103 SET TIME_ZONE=IFNULL(@OLD_TIME_ZONE, 'system') */;
/*!40101 SET SQL_MODE=IFNULL(@OLD_SQL_MODE, '') */;
/*!40014 SET FOREIGN_KEY_CHECKS=IFNULL(@OLD_FOREIGN_KEY_CHECKS, 1) */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40111 SET SQL_NOTES=IFNULL(@OLD_SQL_NOTES, 1) */;
