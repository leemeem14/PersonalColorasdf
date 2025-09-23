create
    definer = rdsadmin@localhost procedure rds_start_replication_for_channel(IN channel varchar(64))
BEGIN
  DECLARE v_mysql_version VARCHAR(20);
  DECLARE v_semi_sync ENUM('SOURCE', 'REPLICA', 'NO');
  DECLARE v_called_by_user VARCHAR(50);
  DECLARE v_channel_service_state ENUM('ON', 'OFF', 'BROKEN', 'NOT_EXIST');
  DECLARE sql_logging BOOLEAN;
  DECLARE skip_repl_error INT;
  SELECT @@sql_log_bin, user(), version(), mysql.rds_replication_service_state_for_channel(channel), mysql.rds_is_semi_sync()
  INTO sql_logging, v_called_by_user, v_mysql_version, v_channel_service_state, v_semi_sync;
  BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN SET @@sql_log_bin=sql_logging; RESIGNAL; END;
    SET @@sql_log_bin=OFF;
    IF CONVERT(QUOTE(TRIM(BOTH FROM channel)) USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT(QUOTE('') USING utf8mb4) COLLATE utf8mb4_0900_ai_ci
    THEN
      INSERT INTO mysql.rds_history (called_by_user,action,mysql_version) VALUES (v_called_by_user, 'Starting: start slave', v_mysql_version);
      COMMIT;
    ELSE
      INSERT INTO mysql.rds_history (called_by_user,action,mysql_version) VALUES (v_called_by_user, 'Starting: start channel', v_mysql_version);
      COMMIT;
    END IF;
    SET @@sql_log_bin=sql_logging;
  END;
  IF CONVERT(v_called_by_user USING utf8mb4) COLLATE utf8mb4_0900_ai_ci != CONVERT('rdsadmin@localhost' USING utf8mb4) COLLATE utf8mb4_0900_ai_ci AND CONVERT(v_semi_sync USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT('REPLICA' USING utf8mb4) COLLATE utf8mb4_0900_ai_ci
  THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Permission Denied: Replication for Multi-AZ clusters is managed exclusively by RDS.';
  ELSEIF CONVERT(v_channel_service_state USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT('ON' USING utf8mb4) COLLATE utf8mb4_0900_ai_ci 
  THEN
    IF CONVERT(QUOTE(TRIM(BOTH FROM channel)) USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT(QUOTE('') USING utf8mb4) COLLATE utf8mb4_0900_ai_ci
    THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Replication may already be running. Call rds_stop_replication to stop replication';
    ELSE
      SET @message_text = CONCAT('Replication may already be running for channel. Run SHOW REPLICA STATUS FOR CHANNEL ', QUOTE(TRIM(BOTH FROM channel)), '\\G .' );
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = @message_text;
    END IF;
  ELSEIF CONVERT(v_channel_service_state USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT('NOT_EXIST' USING utf8mb4) COLLATE utf8mb4_0900_ai_ci 
  THEN
    IF CONVERT(QUOTE(TRIM(BOTH FROM channel)) USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT(QUOTE('') USING utf8mb4) COLLATE utf8mb4_0900_ai_ci
    THEN
      SET @message_text = CONCAT('You can''t start replication because the replica isn''t configured. First call mysql.rds_set_external_master.');
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = @message_text;
    ELSE
      SET @message_text = CONCAT('The given channel does not exist. Run SHOW REPLICA STATUS\\G to find all existing channel names.');
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = @message_text;
    END IF;
  ELSEIF CONVERT(v_channel_service_state USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT('BROKEN' USING utf8mb4) COLLATE utf8mb4_0900_ai_ci 
  THEN
    IF CONVERT(QUOTE(TRIM(BOTH FROM channel)) USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT(QUOTE('') USING utf8mb4) COLLATE utf8mb4_0900_ai_ci
    THEN
      
      
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Replication might be running. First call mysql.rds_stop_replication.';
    ELSE
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'The replication on given channel might be running. First call mysql.rds_stop_replication_for_channel.';
    END IF;
  ELSEIF CONVERT(v_channel_service_state USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT('OFF' USING utf8mb4) COLLATE utf8mb4_0900_ai_ci 
  THEN
    
    BEGIN
      DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN SET @@sql_log_bin=sql_logging; RESIGNAL; END;
      SET @@sql_log_bin=OFF;
      IF CONVERT(QUOTE(TRIM(BOTH FROM channel)) USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT(QUOTE('') USING utf8mb4) COLLATE utf8mb4_0900_ai_ci
      THEN
        SET @action = 'start slave';
      ELSE
        SET @action = 'start channel';
      END IF;
      SET @cmd = CONCAT('START REPLICA FOR CHANNEL ', QUOTE(TRIM(BOTH FROM channel)));
      PREPARE rds_start_replica_for_channel FROM @cmd;
      UPDATE mysql.rds_replication_status rrs SET called_by_user=v_called_by_user, action=@action, mysql_version=v_mysql_version
                                              WHERE rrs.action IS NOT NULL AND CONVERT(QUOTE(rrs.channel_name) USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT(QUOTE(TRIM(BOTH FROM channel)) USING utf8mb4) COLLATE utf8mb4_0900_ai_ci;
      COMMIT;
      CALL mysql.rds_clean_replication_status_for_channel(channel);
      DO SLEEP(1);
      SELECT @@global.sql_replica_skip_counter INTO skip_repl_error;
      IF skip_repl_error = 0
      THEN
        EXECUTE rds_start_replica_for_channel;
      ELSE
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Another session currently running the procedure mysql.rds_skip_repl_error_for_channel. Consider retrying the procedure call.';
      END IF;
      DO SLEEP(2);
      SELECT mysql.rds_replication_service_state_for_channel(channel) INTO v_channel_service_state;
      IF CONVERT(v_channel_service_state USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT('ON' USING utf8mb4) COLLATE utf8mb4_0900_ai_ci
      THEN
        INSERT INTO mysql.rds_history (called_by_user,action,mysql_version) VALUES (v_called_by_user, @action, v_mysql_version);
        COMMIT;
        IF CONVERT(QUOTE(TRIM(BOTH FROM channel)) USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT(QUOTE('') USING utf8mb4) COLLATE utf8mb4_0900_ai_ci
        THEN
          SELECT 'Replication started. Slave is now running normally.' AS Message;
        ELSE
          SELECT CONCAT('Replication started for channel ', QUOTE(TRIM(BOTH FROM channel)), ' and replication is now running normally.') AS Message;
        END IF;
      ELSE
        IF CONVERT(QUOTE(TRIM(BOTH FROM channel)) USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT(QUOTE('') USING utf8mb4) COLLATE utf8mb4_0900_ai_ci
        THEN
          SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Slave has encountered an error. Run SHOW SLAVE STATUS\\G; to see the error.';
        ELSE
          SET @message_text = CONCAT('Start replication failed. To see the error, run SHOW REPLICA STATUS FOR CHANNEL ', QUOTE(TRIM(BOTH FROM channel)), '\\G .');
          SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = @message_text;
        END IF;
      END IF;
      DEALLOCATE PREPARE rds_start_replica_for_channel;
      SET @@sql_log_bin=sql_logging;
    END;
  END IF;
END;

