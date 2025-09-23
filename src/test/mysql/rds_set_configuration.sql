create
    definer = rdsadmin@localhost procedure rds_set_configuration(IN name varchar(30), IN value int)
sp: BEGIN
  DECLARE v_exists INT;
  DECLARE sql_logging BOOLEAN;
  
  
  
  
  
  SELECT COUNT(1) INTO v_exists FROM mysql.rds_configuration WHERE CONVERT(mysql.rds_configuration.name USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT(name USING utf8mb4) COLLATE utf8mb4_0900_ai_ci;
  IF v_exists = 0 THEN
    SET @err = CONCAT('Cannot set unknown configuration parameter ', QUOTE(name), ' using mysql.rds_set_configuration.');
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = @err; 
  END IF;
  IF CONVERT(name USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT('binlog retention hours' USING utf8mb4) COLLATE utf8mb4_0900_ai_ci AND CONVERT(rds_is_semi_sync() USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT('REPLICA' USING utf8mb4) COLLATE utf8mb4_0900_ai_ci THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cannot enable the binlog retention hours on the reader instance in RDS Multi-AZ DB cluster. Please run this query on the writer.';
  ELSEIF CONVERT(name USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT('binlog retention hours' USING utf8mb4) COLLATE utf8mb4_0900_ai_ci AND value NOT BETWEEN 1 AND 168 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'For binlog retention hours the value must be between 1 and 168 inclusive or be NULL';
  ELSEIF CONVERT(name USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT('target delay' USING utf8mb4) COLLATE utf8mb4_0900_ai_ci AND CONVERT(rds_is_semi_sync() USING utf8mb4) COLLATE utf8mb4_0900_ai_ci != CONVERT('NO' USING utf8mb4) COLLATE utf8mb4_0900_ai_ci THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Target delay is not supported on the MySQL Multi-AZ cluster';
  ELSEIF CONVERT(name USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT('target delay' USING utf8mb4) COLLATE utf8mb4_0900_ai_ci AND (value IS NULL OR value NOT BETWEEN 0 AND 86400) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'For target delay the value must be between 0 and 86400 inclusive';
  ELSEIF CONVERT(name USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT('source delay' USING utf8mb4) COLLATE utf8mb4_0900_ai_ci THEN
    CALL mysql.rds_set_source_delay(value);
    LEAVE sp;
  END IF;
  SELECT @@sql_log_bin INTO sql_logging;
  
  BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN SET @@sql_log_bin=sql_logging; RESIGNAL; END;
    SET @@sql_log_bin=OFF;
    UPDATE mysql.rds_configuration
    SET mysql.rds_configuration.value = value
    WHERE CONVERT(mysql.rds_configuration.name USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT(name USING utf8mb4) COLLATE utf8mb4_0900_ai_ci;
    COMMIT;
    SET @@sql_log_bin=sql_logging;
  END;
END;

