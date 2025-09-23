create
    definer = rdsadmin@localhost procedure rds_start_replication_until_for_channel(IN replication_log_file text,
                                                                                   IN replication_stop_point bigint,
                                                                                   IN channel varchar(64))
BEGIN
  DECLARE v_mysql_version VARCHAR(20);
  DECLARE v_called_by_user VARCHAR(352);
  DECLARE v_service_state_for_channel ENUM('ON', 'OFF', 'BROKEN', 'NOT_EXIST');
  DECLARE v_replica_parallel_workers INT;
  DECLARE sql_logging BOOLEAN;
  DECLARE skip_repl_error INT;
  SELECT @@sql_log_bin, user(), version(), mysql.rds_replication_service_state_for_channel(channel) INTO sql_logging, v_called_by_user, v_mysql_version, v_service_state_for_channel;
  SELECT @@replica_parallel_workers into v_replica_parallel_workers;
  BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN SET @@sql_log_bin=sql_logging; RESIGNAL; END;
    SET @@sql_log_bin=OFF;
    IF CONVERT(QUOTE(TRIM(BOTH FROM channel)) USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT(QUOTE('') USING utf8mb4) COLLATE utf8mb4_0900_ai_ci
    THEN
      INSERT INTO mysql.rds_history(called_by_user, action, mysql_version, master_log_file, master_log_pos) VALUES(v_called_by_user, 'Starting: start slave until', v_mysql_version, SUBSTRING(replication_log_file, 1, 50), replication_stop_point);
      COMMIT;
    ELSE
      INSERT INTO mysql.rds_history(called_by_user, action, mysql_version, master_log_file, master_log_pos) VALUES(v_called_by_user, 'Starting: start channel until', v_mysql_version, SUBSTRING(replication_log_file, 1, 50), replication_stop_point);
      COMMIT;
    END IF;
    SET @@sql_log_bin=sql_logging;
  END;
  IF CONVERT(v_service_state_for_channel USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT('NOT_EXIST' USING utf8mb4) COLLATE utf8mb4_0900_ai_ci 
  THEN
    IF CONVERT(QUOTE(TRIM(BOTH FROM channel)) USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT(QUOTE('') USING utf8mb4) COLLATE utf8mb4_0900_ai_ci
    THEN
      SET @message_text = CONCAT('You can''t start replication because the replica isn''t configured. First call mysql.rds_set_external_master.');
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = @message_text;
    ELSE
      SET @message_text = CONCAT('The given channel does not exist. Run SHOW REPLICA STATUS\\G to find all existing channel names.');
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = @message_text;
    END IF;
  ELSEIF CONVERT(v_service_state_for_channel USING utf8mb4) COLLATE utf8mb4_0900_ai_ci in (CONVERT('ON' USING utf8mb4) COLLATE utf8mb4_0900_ai_ci  , CONVERT('BROKEN' USING utf8mb4) COLLATE utf8mb4_0900_ai_ci  )
  THEN
    
    
    IF CONVERT(QUOTE(TRIM(BOTH FROM channel)) USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT(QUOTE('') USING utf8mb4) COLLATE utf8mb4_0900_ai_ci
    THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Replication may already be running. Call rds_stop_replication to stop replication';
    ELSE
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Replication may already be running. Call rds_stop_replication_for_channel procedure to stop replication.';
    END IF;
  ELSEIF v_replica_parallel_workers > 1
  THEN
    IF CONVERT(QUOTE(TRIM(BOTH FROM channel)) USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT(QUOTE('') USING utf8mb4) COLLATE utf8mb4_0900_ai_ci
    THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'rds_start_replication_until is not supported for multi-threaded slaves';
    ELSE
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'rds_start_replication_until_for_channel is not supported in multi-threaded replica environment.';
    END IF;
  ELSEIF replication_stop_point IS NULL OR replication_stop_point <= 0
  THEN
    
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid input: replication_stop_point cannot be NULL, less than or equal to 0';
  END IF;
  
  BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN SET @@sql_log_bin=sql_logging; RESIGNAL; END;
    SET @@sql_log_bin=OFF;
    
    
    SELECT @@global.sql_replica_skip_counter INTO skip_repl_error;
    IF skip_repl_error > 0
    THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Another session currently running the procedure mysql.rds_skip_repl_error_for_channel. Consider retrying the procedure call.';
    END IF;
    IF CONVERT(QUOTE(TRIM(BOTH FROM channel)) USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT(QUOTE('') USING utf8mb4) COLLATE utf8mb4_0900_ai_ci
    THEN
      UPDATE mysql.rds_replication_status SET called_by_user = v_called_by_user, action = 'start slave until', mysql_version = v_mysql_version, replication_log_file = TRIM(replication_log_file), replication_stop_point = replication_stop_point, replication_gtid = NULL WHERE action IS NOT NULL AND (CONVERT(channel_name USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT('' USING utf8mb4) COLLATE utf8mb4_0900_ai_ci OR channel_name IS NULL);
      COMMIT;
    ELSE
      UPDATE mysql.rds_replication_status SET called_by_user = v_called_by_user, action = 'start channel until', mysql_version = v_mysql_version, replication_log_file = TRIM(replication_log_file), replication_stop_point = replication_stop_point, replication_gtid = NULL WHERE action IS NOT NULL AND CONVERT(QUOTE(channel_name) USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT(QUOTE(TRIM(BOTH FROM channel)) USING utf8mb4) COLLATE utf8mb4_0900_ai_ci;
      COMMIT;
    END IF;
    
    SET @cmd = CONCAT('START REPLICA UNTIL SOURCE_LOG_FILE = ', QUOTE(TRIM(replication_log_file)), ', SOURCE_LOG_POS = ', replication_stop_point, ' FOR CHANNEL ', QUOTE(TRIM(BOTH FROM channel)));
    PREPARE rds_start_replication_for_channel_until FROM @cmd;
    EXECUTE rds_start_replication_for_channel_until;
    DEALLOCATE PREPARE rds_start_replication_for_channel_until;
    DO SLEEP(2);
    SELECT mysql.rds_replication_service_state_for_channel(channel) INTO v_service_state_for_channel;
    IF CONVERT(v_service_state_for_channel USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT('ON' USING utf8mb4) COLLATE utf8mb4_0900_ai_ci
    THEN
      IF CONVERT(QUOTE(TRIM(BOTH FROM channel)) USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT(QUOTE('') USING utf8mb4) COLLATE utf8mb4_0900_ai_ci
      THEN
        INSERT INTO mysql.rds_history(called_by_user, action, mysql_version, master_log_file, master_log_pos) VALUES(v_called_by_user, 'start slave until', v_mysql_version, SUBSTRING(replication_log_file, 1, 50), replication_stop_point);
        COMMIT;
        SELECT CONCAT('Replication started until MASTER_LOG_FILE = ', QUOTE(TRIM(replication_log_file)), ' and MASTER_LOG_POS = ', replication_stop_point) AS Message;
      ELSE
        INSERT INTO mysql.rds_history(called_by_user, action, mysql_version, master_log_file, master_log_pos) VALUES(v_called_by_user, 'start channel until', v_mysql_version, SUBSTRING(replication_log_file, 1, 50), replication_stop_point);
        COMMIT;
        SELECT CONCAT('Replication started until SOURCE_LOG_FILE = ', QUOTE(TRIM(replication_log_file)), ' and SOURCE_LOG_POS = ', replication_stop_point, ' for channel ', QUOTE(TRIM(BOTH FROM channel))) AS Message;
      END IF;
    ELSE
      IF CONVERT(QUOTE(TRIM(BOTH FROM channel)) USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT(QUOTE('') USING utf8mb4) COLLATE utf8mb4_0900_ai_ci
      THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Slave has encountered an error. Run SHOW SLAVE STATUS\\G; to see the error.';
      ELSE
        SET @error_message = CONCAT('Replication for specified channel encountered an error. Run SHOW REPLICA STATUS FOR CHANNEL ', QUOTE(TRIM(BOTH FROM channel)));
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = @error_message;
      END IF;
    END IF;
    SET @@sql_log_bin=sql_logging;
  END;
END;

