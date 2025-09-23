create
    definer = rdsadmin@localhost procedure rds_skip_repl_error_for_channel(IN channel varchar(64))
BEGIN
  DECLARE v_channel_service_state ENUM('ON', 'OFF', 'BROKEN', 'NOT_EXIST');
  DECLARE v_called_by_user VARCHAR(352);
  DECLARE v_mysql_version VARCHAR(20);
  DECLARE sql_logging BOOLEAN;
  DECLARE v_max_applier_error_number INT;
  DECLARE skip_repl_error INT;
  SELECT @@sql_log_bin, user(), version(), mysql.rds_replication_service_state_for_channel(channel) into sql_logging, v_called_by_user, v_mysql_version, v_channel_service_state;
  SELECT MAX(rasbw.LAST_ERROR_NUMBER) INTO v_max_applier_error_number FROM performance_schema.replication_applier_status_by_worker rasbw WHERE CONVERT(QUOTE(channel_name) USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT(QUOTE(TRIM(BOTH FROM channel)) USING utf8mb4) COLLATE utf8mb4_0900_ai_ci;
  BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN SET @@sql_log_bin=sql_logging; RESIGNAL; END;
    SET @@sql_log_bin=OFF;
    IF CONVERT(QUOTE(TRIM(BOTH FROM channel)) USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT(QUOTE('') USING utf8mb4) COLLATE utf8mb4_0900_ai_ci
    THEN
      INSERT into mysql.rds_history(called_by_user, action, mysql_version) values (v_called_by_user,'Starting: skip_repl_error',v_mysql_version);
      COMMIT;
    ELSE
      INSERT into mysql.rds_history(called_by_user, action, mysql_version) values (v_called_by_user,'Starting: skip_repl_err_ch',v_mysql_version);
      COMMIT;
    END IF;
    SET @@sql_log_bin=sql_logging;
  END;
  IF CONVERT(v_channel_service_state USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT('NOT_EXIST' USING utf8mb4) COLLATE utf8mb4_0900_ai_ci 
  THEN
    IF CONVERT(QUOTE(TRIM(BOTH FROM channel)) USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT(QUOTE('') USING utf8mb4) COLLATE utf8mb4_0900_ai_ci
    THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'You can''t skip a replication error because the replica isn''t configured. First call mysql.rds_set_external_master.';
    ELSE
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'The given channel does not exist. Run SHOW REPLICA STATUS\\G to find all existing channel names.';
    END IF;
  ELSEIF CONVERT(v_channel_service_state USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT('ON' USING utf8mb4) COLLATE utf8mb4_0900_ai_ci 
  THEN
    IF CONVERT(QUOTE(TRIM(BOTH FROM channel)) USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT(QUOTE('') USING utf8mb4) COLLATE utf8mb4_0900_ai_ci
    THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Slave is running normally.  No errors detected to skip.';
    ELSE
      SET @message_text = CONCAT('Replication is running normally and no errors detected to skip for channel ', QUOTE(TRIM(BOTH FROM channel)));
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = @message_text;
    END IF;
  ELSEIF CONVERT(v_channel_service_state USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT('OFF' USING utf8mb4) COLLATE utf8mb4_0900_ai_ci 
  THEN
    IF CONVERT(QUOTE(TRIM(BOTH FROM channel)) USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT(QUOTE('') USING utf8mb4) COLLATE utf8mb4_0900_ai_ci
    THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Slave is down or disabled.';
    ELSE
      SET @message_text = CONCAT('Replication is down or disabled for channel ', QUOTE(TRIM(BOTH FROM channel)));
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = @message_text;
    END IF;
  ELSE 
    
    IF v_max_applier_error_number > 0
    THEN
      BEGIN
        DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN SET @@sql_log_bin=sql_logging; RESIGNAL; END;
        SET @@sql_log_bin=OFF;
        
        
        SELECT @@global.sql_replica_skip_counter into skip_repl_error;
        IF skip_repl_error = 0
        THEN
          SET GLOBAL sql_replica_skip_counter = 1;
          SET @cmd = CONCAT('STOP REPLICA FOR CHANNEL ', QUOTE(TRIM(BOTH FROM channel)));
          PREPARE rds_stop_replica_for_channel FROM @cmd;
          EXECUTE rds_stop_replica_for_channel;
          DEALLOCATE PREPARE rds_stop_replica_for_channel;
          DO SLEEP(2);
          SET @cmd = CONCAT('START REPLICA FOR CHANNEL ', QUOTE(TRIM(BOTH FROM channel)));
          PREPARE rds_start_replica_for_channel FROM @cmd;
          EXECUTE rds_start_replica_for_channel;
          DEALLOCATE PREPARE rds_start_replica_for_channel;
          DO SLEEP(2);
        ELSE
          IF CONVERT(QUOTE(TRIM(BOTH FROM channel)) USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT(QUOTE('') USING utf8mb4) COLLATE utf8mb4_0900_ai_ci
          THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'A mysql.rds_skip_repl_error procedure is in progress. Wait a few seconds before calling mysql.rds_skip_repl_error again.';
          ELSE
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Another skip_repl_error procedure is in progress. Wait a few seconds before calling mysql.rds_skip_repl_error_for_channel again.';
          END IF;
        END IF;
        IF CONVERT(QUOTE(TRIM(BOTH FROM channel)) USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT(QUOTE('') USING utf8mb4) COLLATE utf8mb4_0900_ai_ci
        THEN
          SELECT 'Statement in error has been skipped' as Message;
        ELSE
          SELECT CONCAT('Statement in error has been skipped for channel ', QUOTE(TRIM(BOTH from channel))) as Message;
        END IF;
        SELECT mysql.rds_replication_service_state_for_channel(channel) INTO v_channel_service_state;
        IF CONVERT(v_channel_service_state USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT('ON' USING utf8mb4) COLLATE utf8mb4_0900_ai_ci
        THEN
          IF CONVERT(QUOTE(TRIM(BOTH FROM channel)) USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT(QUOTE('') USING utf8mb4) COLLATE utf8mb4_0900_ai_ci
          THEN
            SELECT 'Slave is now running normally' as Message;
            INSERT into mysql.rds_history(called_by_user, action, mysql_version) values (v_called_by_user,'skip_repl_error:OK',v_mysql_version);
            COMMIT;
          ELSE
            SELECT CONCAT('Replication is running normally for channel ', QUOTE(TRIM(BOTH from channel))) as Message;
            INSERT into mysql.rds_history(called_by_user, action, mysql_version) values (v_called_by_user,'skip_repl_err_ch:OK',v_mysql_version);
            COMMIT;
          END IF;
        ELSE
          IF CONVERT(QUOTE(TRIM(BOTH FROM channel)) USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT(QUOTE('') USING utf8mb4) COLLATE utf8mb4_0900_ai_ci
          THEN
            INSERT into mysql.rds_history(called_by_user, action, mysql_version) values (v_called_by_user,'skip_repl_error:ERR',v_mysql_version);
            COMMIT;
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Slave has encountered a new error. Please use SHOW SLAVE STATUS to see the error.';
          ELSE
            INSERT into mysql.rds_history(called_by_user, action, mysql_version) values (v_called_by_user,'skip_repl_err_ch:ERR',v_mysql_version);
            COMMIT;
            SELECT CONCAT('Replication for specified channel encountered a new error. Run SHOW REPLICA STATUS FOR CHANNEL ', QUOTE(TRIM(BOTH from channel)), ';') as Message;
          END IF;
        END IF;
        SET @@sql_log_bin=sql_logging;
      END;
    ELSE
      
      IF CONVERT(QUOTE(TRIM(BOTH FROM channel)) USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT(QUOTE('') USING utf8mb4) COLLATE utf8mb4_0900_ai_ci
      THEN
        SELECT CONCAT('The replica SQL thread is running for the specified channel without encountering errors. Run SHOW REPLICA STATUS FOR CHANNEL ', QUOTE(''), ';') as Message;
      ELSE
        SELECT CONCAT('Replica SQL_Thread running normally for specified channel. Run SHOW REPLICA STATUS FOR CHANNEL ', QUOTE(TRIM(BOTH from channel)), ';') as Message;
      END IF;
    END IF;
  END IF;
END;

