create
    definer = rdsadmin@localhost procedure rds_set_external_source_for_channel(IN host varchar(255), IN port int,
                                                                               IN user text, IN passwd text,
                                                                               IN log_file_name text,
                                                                               IN pos bigint unsigned,
                                                                               IN enable_ssl_encryption tinyint(1),
                                                                               IN channel varchar(64))
BEGIN
  DECLARE v_rdsrepl INT;
  DECLARE v_same_name_channel_service_state ENUM('ON', 'OFF', 'BROKEN', 'NOT_EXIST');
  DECLARE v_mysql_version VARCHAR(20);
  DECLARE v_called_by_user VARCHAR(50);
  DECLARE v_channel_count INT;
  DECLARE v_same_source_count INT;
  DECLARE sql_logging BOOLEAN;
  SELECT @@sql_log_bin, user(), version(), mysql.rds_replication_service_state_for_channel(channel) INTO sql_logging, v_called_by_user, v_mysql_version, v_same_name_channel_service_state;
  SELECT count(1) INTO v_rdsrepl from mysql.rds_history WHERE CONVERT(action USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT('disable set master' USING utf8mb4) COLLATE utf8mb4_0900_ai_ci and CONVERT(master_user USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT('rdsrepladmin' USING utf8mb4) COLLATE utf8mb4_0900_ai_ci;
  SELECT count(1) INTO v_channel_count FROM performance_schema.replication_connection_status WHERE CONVERT(QUOTE(channel_name) USING utf8mb4) COLLATE utf8mb4_0900_ai_ci != CONVERT(QUOTE(TRIM(BOTH FROM channel))USING utf8mb4) COLLATE utf8mb4_0900_ai_ci;
  SELECT count(1) INTO v_same_source_count FROM performance_schema.replication_connection_configuration rcc WHERE rcc.HOST = host AND rcc.PORT = port AND CONVERT(QUOTE(rcc.CHANNEL_NAME) USING utf8mb4) COLLATE utf8mb4_0900_ai_ci != CONVERT(QUOTE(TRIM(BOTH FROM channel)) USING utf8mb4) COLLATE utf8mb4_0900_ai_ci;
  BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN SET @@sql_log_bin=sql_logging; RESIGNAL; END;
    SET @@sql_log_bin=OFF;
    IF CONVERT(QUOTE(TRIM(BOTH FROM channel)) USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT(QUOTE('') USING utf8mb4) COLLATE utf8mb4_0900_ai_ci
    THEN
      INSERT INTO mysql.rds_history(called_by_user, action, mysql_version, master_host, master_port, master_user, master_log_file, master_log_pos, master_ssl, auto_position)
      VALUES (v_called_by_user,'Starting: set master', v_mysql_version, TRIM(BOTH FROM host), port, TRIM(BOTH FROM user), TRIM(BOTH FROM log_file_name), pos, enable_ssl_encryption, 0);
      COMMIT;
    ELSE
      INSERT INTO mysql.rds_history(called_by_user, action, mysql_version, master_host, master_port, master_user, master_log_file, master_log_pos, master_ssl, auto_position)
      VALUES (v_called_by_user,'Starting: set channel', v_mysql_version, TRIM(BOTH FROM host), port, TRIM(BOTH FROM user), TRIM(BOTH FROM log_file_name), pos, enable_ssl_encryption, 0);
      COMMIT;
    END IF;
    SET @@sql_log_bin=sql_logging;
  END;
  IF v_rdsrepl > 0 AND CONVERT(v_called_by_user USING utf8mb4) COLLATE utf8mb4_0900_ai_ci != CONVERT('rdsadmin@localhost' USING utf8mb4) COLLATE utf8mb4_0900_ai_ci
  THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Permission Denied: This instance is a RDS Read Replica.';
  END IF;
  IF CONVERT(v_same_name_channel_service_state USING utf8mb4) COLLATE utf8mb4_0900_ai_ci != CONVERT('OFF' USING utf8mb4) COLLATE utf8mb4_0900_ai_ci AND CONVERT(v_same_name_channel_service_state USING utf8mb4) COLLATE utf8mb4_0900_ai_ci != CONVERT('NOT_EXIST' USING utf8mb4) COLLATE utf8mb4_0900_ai_ci
  THEN
    IF CONVERT(QUOTE(TRIM(BOTH FROM channel)) USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT(QUOTE('') USING utf8mb4) COLLATE utf8mb4_0900_ai_ci
    THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'You can''t modify replication because replication is running. First call mysql.rds_stop_replication.';
    ELSE
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'You can''t modify the given channel because replication is running. First call mysql.rds_stop_replication_for_channel.';
    END IF;
  END IF;
  
  IF v_channel_count >= 15
  THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Maximum 15 channels are allowed in multi-source replication on RDS.';
  END IF;
  
  IF v_same_source_count > 0
  THEN
    SET @error_message = CONCAT('Configuring multiple channels to replicate from the host: ', host, ' and port: ', port, ' is not supported.');
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = @error_message;
  END IF;
  
  BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN SET @@sql_log_bin=sql_logging; RESIGNAL; END;
    SET @@sql_log_bin=OFF;
    SET @cmd = CONCAT('CHANGE REPLICATION SOURCE TO',
                      ' SOURCE_HOST = ', QUOTE(TRIM(BOTH FROM host)),
                      ', SOURCE_PORT = ', port, 
                      ', SOURCE_USER = ', QUOTE(TRIM(BOTH FROM user)),
                      ', SOURCE_PASSWORD = ', QUOTE(TRIM(BOTH FROM passwd)),
                      ', SOURCE_LOG_FILE = ', QUOTE(TRIM(BOTH FROM log_file_name)),
                      ', SOURCE_LOG_POS = ', pos, 
                      ', SOURCE_SSL = ', enable_ssl_encryption, 
                      ', SOURCE_AUTO_POSITION = 0',
                      '  FOR CHANNEL ', QUOTE(TRIM(BOTH FROM channel))
                     );
    PREPARE rds_set_source FROM @cmd;
    IF CONVERT(QUOTE(TRIM(BOTH FROM channel)) USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT(QUOTE('') USING utf8mb4) COLLATE utf8mb4_0900_ai_ci
    THEN
      UPDATE mysql.rds_replication_status SET called_by_user=v_called_by_user, action='set master', mysql_version=v_mysql_version, master_host=TRIM(BOTH FROM host), master_port=port WHERE CONVERT(channel_name USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT('' USING utf8mb4) COLLATE utf8mb4_0900_ai_ci AND action IS NOT NULL;
      COMMIT;
    ELSE
      DELETE FROM mysql.rds_replication_status rrs WHERE CONVERT(QUOTE(rrs.channel_name) USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT(QUOTE(TRIM(BOTH FROM channel)) USING utf8mb4) COLLATE utf8mb4_0900_ai_ci;
      INSERT INTO mysql.rds_replication_status(called_by_user, action, mysql_version, master_host, master_port, channel_name)
      VALUES (v_called_by_user, 'set channel source', v_mysql_version, TRIM(BOTH FROM host), port, TRIM(BOTH FROM channel));
      COMMIT;
    END IF;
    IF CONVERT(QUOTE(TRIM(BOTH FROM channel)) USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT(QUOTE('') USING utf8mb4) COLLATE utf8mb4_0900_ai_ci
    THEN
      CALL mysql.rds_clean_replication_status_for_channel(channel);
    END IF;
    EXECUTE rds_set_source;
    DEALLOCATE PREPARE rds_set_source;
    IF CONVERT(QUOTE(TRIM(BOTH FROM channel)) USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT(QUOTE('') USING utf8mb4) COLLATE utf8mb4_0900_ai_ci
    THEN
      INSERT INTO mysql.rds_history(called_by_user, action, mysql_version, master_host, master_port, master_user, master_log_file, master_log_pos, master_ssl, auto_position)
      VALUES (v_called_by_user,'set master', v_mysql_version, TRIM(BOTH FROM host), port, TRIM(BOTH FROM user), TRIM(BOTH FROM log_file_name), pos, enable_ssl_encryption, 0);
      COMMIT;
    ELSE
      INSERT INTO mysql.rds_history(called_by_user, action, mysql_version, master_host, master_port, master_user, master_log_file, master_log_pos, master_ssl, auto_position)
      VALUES (v_called_by_user,'set channel source', v_mysql_version, TRIM(BOTH FROM host), port, TRIM(BOTH FROM user), TRIM(BOTH FROM log_file_name), pos, enable_ssl_encryption, 0);
      COMMIT;
    END IF;
    SET @@sql_log_bin=sql_logging;
  END;
END;

