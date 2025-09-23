create
    definer = rdsadmin@localhost procedure rds_set_source_delay_for_channel(IN delay int, IN channel varchar(64))
BEGIN
  DECLARE v_mysql_version VARCHAR(20);
  DECLARE v_called_by_user VARCHAR(352);
  DECLARE sql_logging BOOLEAN;
  DECLARE v_service_state_for_channel ENUM('ON', 'OFF', 'BROKEN', 'NOT_EXIST');
  SELECT @@sql_log_bin, user(), version(), mysql.rds_replication_service_state_for_channel(channel) INTO sql_logging, v_called_by_user, v_mysql_version, v_service_state_for_channel;
  BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN SET @@sql_log_bin=sql_logging; RESIGNAL; END;
    SET @@sql_log_bin=OFF;
    IF CONVERT(QUOTE(TRIM(BOTH FROM channel)) USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT(QUOTE('') USING utf8mb4) COLLATE utf8mb4_0900_ai_ci
    THEN
      INSERT INTO mysql.rds_history(called_by_user, action, mysql_version, master_delay) VALUES(v_called_by_user, 'Starting: set source delay', v_mysql_version, delay);
      COMMIT;
    ELSE
      INSERT INTO mysql.rds_history(called_by_user, action, mysql_version, master_delay) VALUES(v_called_by_user, 'Starting: set source delay channel', v_mysql_version, delay);
      COMMIT;
    END IF;
    SET @@sql_log_bin=sql_logging;
  END;
  IF CONVERT(rds_is_semi_sync() USING utf8mb4) COLLATE utf8mb4_0900_ai_ci != CONVERT('NO' USING utf8mb4) COLLATE utf8mb4_0900_ai_ci THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Source delay is not supported on the MySQL Multi-AZ cluster';
  ELSEIF delay IS NULL OR delay NOT BETWEEN 0 AND 86400 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'For source delay the value must be between 0 and 86400 inclusive.';
  END IF;
  IF CONVERT(v_service_state_for_channel USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT('NOT_EXIST' USING utf8mb4) COLLATE utf8mb4_0900_ai_ci 
  THEN
    IF CONVERT(QUOTE(TRIM(BOTH FROM channel)) USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT(QUOTE('') USING utf8mb4) COLLATE utf8mb4_0900_ai_ci
    THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'You can''t set replication delay because the replica isn''t configured. First call mysql.rds_set_external_master.';
    ELSE
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'The given channel does not exist. Run SHOW REPLICA STATUS\\G to find all existing channel names.';
    END IF;
  ELSEIF CONVERT(v_service_state_for_channel USING utf8mb4) COLLATE utf8mb4_0900_ai_ci in (CONVERT('ON' USING utf8mb4) COLLATE utf8mb4_0900_ai_ci  , CONVERT('BROKEN' USING utf8mb4) COLLATE utf8mb4_0900_ai_ci  )
  THEN
    IF CONVERT(QUOTE(TRIM(BOTH FROM channel)) USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT(QUOTE('') USING utf8mb4) COLLATE utf8mb4_0900_ai_ci
    THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'You can''t set replication delay because replication is running. First call mysql.rds_stop_replication.';
    ELSE
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'You can''t set replication delay for the given channel when replication is running. First call rds_stop_replication_for_channel.';
    END IF;
  END IF;
  BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN SET @@sql_log_bin=sql_logging; RESIGNAL; END;
    SET @@sql_log_bin=OFF;
    SET @cmd = CONCAT('CHANGE REPLICATION SOURCE TO SOURCE_DELAY = ', delay, ' FOR CHANNEL ', QUOTE(TRIM(BOTH FROM channel)));
    PREPARE rds_set_delay_for_channel FROM @cmd;
    EXECUTE rds_set_delay_for_channel;
    DEALLOCATE PREPARE rds_set_delay_for_channel;
    IF CONVERT(QUOTE(TRIM(BOTH FROM channel)) USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT(QUOTE('') USING utf8mb4) COLLATE utf8mb4_0900_ai_ci
    THEN
      UPDATE mysql.rds_configuration SET value = delay WHERE CONVERT(name USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT('source delay' USING utf8mb4) COLLATE utf8mb4_0900_ai_ci;
      COMMIT;
      INSERT INTO mysql.rds_history(called_by_user, action, mysql_version, master_delay) VALUES(v_called_by_user, 'set source delay', v_mysql_version, delay);
      COMMIT;
      SELECT 'source delay is set successfully.' AS Message;
    ELSE
      INSERT INTO mysql.rds_history(called_by_user, action, mysql_version, master_delay) VALUES(v_called_by_user, 'source delay channel', v_mysql_version, delay);
      COMMIT;
      SELECT CONCAT('source delay is set successfully for channel ', QUOTE(TRIM(BOTH FROM channel))) AS Message;
    END IF;
    SET @@sql_log_bin=sql_logging;
  END;
END;

