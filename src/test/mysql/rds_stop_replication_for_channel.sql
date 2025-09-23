create
    definer = rdsadmin@localhost procedure rds_stop_replication_for_channel(IN channel varchar(64))
BEGIN
  DECLARE v_mysql_version VARCHAR(20);
  DECLARE v_called_by_user VARCHAR(50);
  DECLARE v_channel_service_state ENUM('ON', 'OFF', 'BROKEN', 'NOT_EXIST');
  DECLARE sql_logging BOOLEAN;
  SELECT @@sql_log_bin, user(), version(), mysql.rds_replication_service_state_for_channel(channel) INTO sql_logging, v_called_by_user, v_mysql_version, v_channel_service_state;
  BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN SET @@sql_log_bin=sql_logging; RESIGNAL; END;
    SET @@sql_log_bin=OFF;
    IF CONVERT(QUOTE(TRIM(BOTH FROM channel)) USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT(QUOTE('') USING utf8mb4) COLLATE utf8mb4_0900_ai_ci
    THEN
      INSERT INTO mysql.rds_history (called_by_user,action,mysql_version) VALUES (v_called_by_user, 'Starting: stop slave', v_mysql_version);
      COMMIT;
    ELSE
      INSERT INTO mysql.rds_history (called_by_user,action,mysql_version) VALUES (v_called_by_user, 'Starting: stop channel', v_mysql_version);
      COMMIT;
    END IF;
    SET @@sql_log_bin=sql_logging;
  END;
  IF CONVERT(v_called_by_user USING utf8mb4) COLLATE utf8mb4_0900_ai_ci != CONVERT('rdsadmin@localhost' USING utf8mb4) COLLATE utf8mb4_0900_ai_ci AND CONVERT(mysql.rds_is_semi_sync() USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT('REPLICA' USING utf8mb4) COLLATE utf8mb4_0900_ai_ci
  THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Permission Denied: Replication for Multi-AZ clusters is managed exclusively by RDS.';
  END IF;
  IF CONVERT(v_channel_service_state USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT('OFF' USING utf8mb4) COLLATE utf8mb4_0900_ai_ci
  THEN
    IF CONVERT(QUOTE(TRIM(BOTH FROM channel)) USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT(QUOTE('') USING utf8mb4) COLLATE utf8mb4_0900_ai_ci
    THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Slave is already stopped or may not be configured. Run SHOW SLAVE STATUS\\G;';
    ELSE
      SET @message_text = CONCAT('Replication is already stopped for the given channel. Run SHOW REPLICA STATUS\\G .');
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = @message_text;
    END IF;
  ELSEIF CONVERT(v_channel_service_state USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT('NOT_EXIST' USING utf8mb4) COLLATE utf8mb4_0900_ai_ci 
  THEN
    IF CONVERT(QUOTE(TRIM(BOTH FROM channel)) USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT(QUOTE('') USING utf8mb4) COLLATE utf8mb4_0900_ai_ci
    THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'You can''t stop replication because the replica isn''t configured. First call mysql.rds_set_external_master.';
    ELSE
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'The given channel does not exist. Run SHOW REPLICA STATUS\\G to find all existing channel names.';
    END IF;
  ELSE
    BEGIN
      DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN SET @@sql_log_bin=sql_logging; RESIGNAL; END;
      SET @@sql_log_bin=OFF;
      IF CONVERT(QUOTE(TRIM(BOTH FROM channel)) USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT(QUOTE('') USING utf8mb4) COLLATE utf8mb4_0900_ai_ci
      THEN
        SET @action = 'stop slave';
      ELSE
        SET @action = 'stop channel';
      END IF;
      SET @cmd = CONCAT('STOP REPLICA FOR CHANNEL ', QUOTE(TRIM(BOTH FROM channel)));
      PREPARE rds_stop_replica_for_channel FROM @cmd;
      UPDATE mysql.rds_replication_status rrs SET called_by_user=v_called_by_user, action=@action, mysql_version=v_mysql_version
                                              WHERE rrs.action IS NOT NULL AND CONVERT(QUOTE(rrs.channel_name) USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT(QUOTE(TRIM(BOTH FROM channel)) USING utf8mb4) COLLATE utf8mb4_0900_ai_ci;
      COMMIT;
      DO SLEEP(1);
      EXECUTE rds_stop_replica_for_channel;
      DO SLEEP(2);
      SELECT mysql.rds_replication_service_state_for_channel(channel) INTO v_channel_service_state;
      IF CONVERT(v_channel_service_state USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT('OFF' USING utf8mb4) COLLATE utf8mb4_0900_ai_ci
      THEN
        INSERT INTO mysql.rds_history (called_by_user,action,mysql_version) VALUES (v_called_by_user, @action, v_mysql_version);
        COMMIT;
        IF CONVERT(QUOTE(TRIM(BOTH FROM channel)) USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT(QUOTE('') USING utf8mb4) COLLATE utf8mb4_0900_ai_ci
        THEN
          SELECT 'Slave is now down or disabled' AS Message;
        ELSE
          SELECT CONCAT('Replication for channel ', QUOTE(TRIM(BOTH FROM channel)), ' is down or disabled.') AS Message;
        END IF;
      ELSE
        IF CONVERT(QUOTE(TRIM(BOTH FROM channel)) USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT(QUOTE('') USING utf8mb4) COLLATE utf8mb4_0900_ai_ci
        THEN
          SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Slave has encountered an error. Run SHOW SLAVE STATUS\\G; to see the error.';
        ELSE
          SET @message_text = CONCAT('Stop replication failed. To see the error, run SHOW REPLICA STATUS FOR CHANNEL ', QUOTE(TRIM(BOTH FROM channel)), '\\G .');
          SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = @message_text;
        END IF;
      END IF;
      DEALLOCATE PREPARE rds_stop_replica_for_channel;
      SET @@sql_log_bin=sql_logging;
    END;
  END IF;
END;

