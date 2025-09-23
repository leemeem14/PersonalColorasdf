create
    definer = rdsadmin@localhost procedure rds_next_source_log_for_channel(IN curr_source_log int, IN channel varchar(64))
BEGIN
  DECLARE v_service_state_for_channel ENUM('ON', 'OFF', 'BROKEN', 'NOT_EXIST');
  DECLARE v_called_by_user VARCHAR(352);
  DECLARE v_mysql_version VARCHAR(20);
  DECLARE sql_logging BOOLEAN;
  DECLARE skip_repl_error INT;
  DECLARE source_log_name TEXT;
  SELECT @@sql_log_bin, user(), version(), mysql.rds_replication_service_state_for_channel(channel) INTO sql_logging, v_called_by_user, v_mysql_version, v_service_state_for_channel;
  SELECT SUBSTRING(Master_log_name, 1, CHAR_LENGTH(Master_log_name)-6) INTO source_log_name FROM mysql.slave_master_info WHERE CONVERT(QUOTE(channel_name) USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT(QUOTE(TRIM(BOTH FROM channel)) USING utf8mb4) COLLATE utf8mb4_0900_ai_ci;
  BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN SET @@sql_log_bin=sql_logging; RESIGNAL; END;
    SET @@sql_log_bin=OFF;
    IF CONVERT(QUOTE(TRIM(BOTH FROM channel)) USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT(QUOTE('') USING utf8mb4) COLLATE utf8mb4_0900_ai_ci
    THEN
      INSERT into mysql.rds_history(called_by_user, action, mysql_version, master_log_file, master_log_pos) values (v_called_by_user,'Starting: next_master_log', v_mysql_version, CONCAT('mysql-bin-changelog.', LPAD('1' + curr_source_log, 6, '0')),4);
      COMMIT;
    ELSE
      INSERT into mysql.rds_history(called_by_user, action, mysql_version, master_log_file, master_log_pos) values (v_called_by_user,'Starting: next_channel_log', v_mysql_version, CONCAT(source_log_name, LPAD('1' + curr_source_log, 6, '0')),4);
      COMMIT;
    END IF;
    SET @@sql_log_bin=sql_logging;
  END;
  IF CONVERT(v_service_state_for_channel USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT('NOT_EXIST' USING utf8mb4) COLLATE utf8mb4_0900_ai_ci 
  THEN
    IF CONVERT(QUOTE(TRIM(BOTH FROM channel)) USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT(QUOTE('') USING utf8mb4) COLLATE utf8mb4_0900_ai_ci
    THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'You can''t set the log file name because the replica isn''t configured. First call mysql.rds_set_external_master.';
    ELSE
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'The given channel does not exist. Run SHOW REPLICA STATUS\\G to find all existing channel names.';
    END IF;
  ELSEIF CONVERT(v_service_state_for_channel USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT('ON' USING utf8mb4) COLLATE utf8mb4_0900_ai_ci 
  THEN
    
    
    IF CONVERT(QUOTE(TRIM(BOTH FROM channel)) USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT(QUOTE('') USING utf8mb4) COLLATE utf8mb4_0900_ai_ci
    THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Slave is running normally.  No errors detected to skip.';
    ELSE
      SET @message_text = CONCAT('Replication is running normally and no errors detected to skip for channel - ', QUOTE(TRIM(BOTH FROM channel)), '');
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = @message_text;
    END IF;
  ELSEIF CONVERT(v_service_state_for_channel USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT('OFF' USING utf8mb4) COLLATE utf8mb4_0900_ai_ci 
  THEN
    IF CONVERT(QUOTE(TRIM(BOTH FROM channel)) USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT(QUOTE('') USING utf8mb4) COLLATE utf8mb4_0900_ai_ci
    THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Slave is down or disabled.';
    ELSE
      SET @message_text = CONCAT('Replication is down or disabled for channel ', QUOTE(TRIM(BOTH FROM channel)));
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = @message_text;
    END IF;
  ELSE 
    
    
    SELECT @@global.sql_replica_skip_counter into skip_repl_error;
    IF skip_repl_error = 0
    THEN
      SET @cmd = CONCAT('STOP REPLICA FOR CHANNEL ', QUOTE(TRIM(BOTH FROM channel)));
      PREPARE rds_stop_replica_for_channel FROM @cmd;
      EXECUTE rds_stop_replica_for_channel;
      DEALLOCATE PREPARE rds_stop_replica_for_channel;
      DO SLEEP(2);
      
      IF CONVERT(QUOTE(TRIM(BOTH FROM channel)) USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT(QUOTE('') USING utf8mb4) COLLATE utf8mb4_0900_ai_ci
      THEN
        
        SET @cmd = CONCAT('CHANGE REPLICATION SOURCE TO SOURCE_LOG_FILE = ', QUOTE(CONCAT('mysql-bin-changelog.', LPAD(1 + curr_source_log, 6, '0'))) ,', SOURCE_LOG_POS = 4 FOR CHANNEL ', QUOTE(TRIM(BOTH FROM channel)));
      ELSE
        
        SET @cmd = CONCAT('CHANGE REPLICATION SOURCE TO SOURCE_LOG_FILE = ', QUOTE(CONCAT(source_log_name, LPAD(1 + curr_source_log, 6, '0'))) ,', SOURCE_LOG_POS = 4 FOR CHANNEL ', QUOTE(TRIM(BOTH FROM channel)));
      END IF;
      PREPARE rds_set_source FROM @cmd;
      EXECUTE rds_set_source;
      DEALLOCATE PREPARE rds_set_source;
      SET @cmd = CONCAT('START REPLICA FOR CHANNEL ', QUOTE(TRIM(BOTH FROM channel)));
      PREPARE rds_start_replica_for_channel FROM @cmd;
      EXECUTE rds_start_replica_for_channel;
      DEALLOCATE PREPARE rds_start_replica_for_channel;
      DO SLEEP(2);
      IF CONVERT(QUOTE(TRIM(BOTH FROM channel)) USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT(QUOTE('') USING utf8mb4) COLLATE utf8mb4_0900_ai_ci
      THEN
        SELECT 'Master Log Position has been set to start of next log' AS Message;
      ELSE
        SELECT CONCAT('Replication Log Position has been set to start from the next binary log for channel - ', QUOTE(TRIM(BOTH FROM channel))) AS Message;
      END IF;
    ELSE
    
      SET @message_text = CONCAT('Another session currently running the procedure mysql.rds_skip_repl_error_for_channel. Consider to retry the procedure call.');
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = @message_text;
    END IF;
    SELECT mysql.rds_replication_service_state_for_channel(channel) INTO v_service_state_for_channel;
    
    BEGIN
      DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN SET @@sql_log_bin=sql_logging; RESIGNAL; END;
      SET @@sql_log_bin=OFF;
      IF CONVERT(v_service_state_for_channel USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT('ON' USING utf8mb4) COLLATE utf8mb4_0900_ai_ci
      THEN
        IF CONVERT(QUOTE(TRIM(BOTH FROM channel)) USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT(QUOTE('') USING utf8mb4) COLLATE utf8mb4_0900_ai_ci
        THEN
          SELECT 'Slave is now running normally' AS Message;
          INSERT into mysql.rds_history(called_by_user, action, mysql_version, master_log_file, master_log_pos) values (v_called_by_user,'next_master_log:OK', v_mysql_version, CONCAT('mysql-bin-changelog.', LPAD('1' + curr_source_log, 6, '0')),4);
          COMMIT;
        ELSE
          SELECT CONCAT('Replication is now running normally for channel ', QUOTE(TRIM(BOTH FROM channel))) AS Message;
          INSERT into mysql.rds_history(called_by_user, action, mysql_version, master_log_file, master_log_pos) values (v_called_by_user,'next_channel_log:OK', v_mysql_version, CONCAT(source_log_name, LPAD('1' + curr_source_log, 6, '0')),4);
          COMMIT;
        END IF;
      ELSE
        IF CONVERT(QUOTE(TRIM(BOTH FROM channel)) USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT(QUOTE('') USING utf8mb4) COLLATE utf8mb4_0900_ai_ci
        THEN
          INSERT into mysql.rds_history(called_by_user, action, mysql_version, master_log_file, master_log_pos) values (v_called_by_user,'next_master_log:ERR', v_mysql_version, CONCAT('mysql-bin-changelog.', LPAD('1' + curr_source_log, 6, '0')),4);
          COMMIT;
          SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Slave has encountered a new error. Please use SHOW SLAVE STATUS to see the error.';
        ELSE
          INSERT into mysql.rds_history(called_by_user, action, mysql_version, master_log_file, master_log_pos) values (v_called_by_user,'next_channel_log:ERR', v_mysql_version, CONCAT(source_log_name, LPAD('1' + curr_source_log, 6, '0')),4);
          COMMIT;
          SET @message_text = CONCAT('Replication on mentioned channel encountered a new error. Run SHOW REPLICA STATUS FOR CHANNEL ', QUOTE(TRIM(BOTH FROM channel)));
          SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = @message_text;
        END IF;
      END IF;
      SET @@sql_log_bin=sql_logging;
    END;
  END IF;
END;

