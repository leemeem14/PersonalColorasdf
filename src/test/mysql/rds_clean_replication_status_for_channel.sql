create
    definer = rdsadmin@localhost procedure rds_clean_replication_status_for_channel(IN channel varchar(64))
    sql security invoker
BEGIN
  DECLARE v_has_replication_log_file_column INT;
  DECLARE v_has_replication_stop_point_column INT;
  DECLARE v_has_replication_gtid_column INT;
  DECLARE v_has_replication_channel_name_column INT;
  DECLARE v_current_security_context_user VARCHAR(352);
  DECLARE sql_logging BOOLEAN;
  SELECT @@sql_log_bin INTO sql_logging;
  SELECT CURRENT_USER() INTO v_current_security_context_user;
  IF CONVERT(v_current_security_context_user USING utf8mb4) COLLATE utf8mb4_0900_ai_ci <> CONVERT('rdsadmin@localhost' USING utf8mb4) COLLATE utf8mb4_0900_ai_ci THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Must be rdsadmin@localhost to call this procedure';
  END IF;
  SELECT count(*) INTO v_has_replication_log_file_column FROM information_schema.columns WHERE table_schema = 'mysql' AND column_name = 'replication_log_file' AND table_name = 'rds_replication_status';
  SELECT count(*) INTO v_has_replication_stop_point_column FROM information_schema.columns WHERE table_schema = 'mysql' AND column_name = 'replication_stop_point' AND table_name = 'rds_replication_status';
  SELECT count(*) INTO v_has_replication_gtid_column FROM information_schema.columns WHERE table_schema = 'mysql' AND column_name = 'replication_gtid' AND table_name = 'rds_replication_status';
  SELECT count(*) INTO v_has_replication_channel_name_column FROM information_schema.columns WHERE table_schema = 'mysql' AND column_name = 'channel_name' AND table_name = 'rds_replication_status';
  BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN SET @@sql_log_bin=sql_logging; RESIGNAL; END;
    SET @@sql_log_bin=OFF;
    IF v_has_replication_channel_name_column > 0 THEN
      IF v_has_replication_log_file_column > 0 THEN
        UPDATE mysql.rds_replication_status SET replication_log_file=NULL WHERE action IS NOT NULL AND CONVERT(QUOTE(channel_name) USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT(QUOTE(TRIM(BOTH FROM channel)) USING utf8mb4) COLLATE utf8mb4_0900_ai_ci;
      END IF;
      IF v_has_replication_stop_point_column > 0 THEN
        UPDATE mysql.rds_replication_status SET replication_stop_point=NULL WHERE action IS NOT NULL AND CONVERT(QUOTE(channel_name) USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT(QUOTE(TRIM(BOTH FROM channel)) USING utf8mb4) COLLATE utf8mb4_0900_ai_ci;
      END IF;
      IF v_has_replication_gtid_column > 0 THEN
        UPDATE mysql.rds_replication_status SET replication_gtid=NULL WHERE action IS NOT NULL AND CONVERT(QUOTE(channel_name) USING utf8mb4) COLLATE utf8mb4_0900_ai_ci = CONVERT(QUOTE(TRIM(BOTH FROM channel)) USING utf8mb4) COLLATE utf8mb4_0900_ai_ci;
      END IF;
    ELSE
      IF v_has_replication_log_file_column > 0 THEN
        UPDATE mysql.rds_replication_status SET replication_log_file=NULL WHERE action IS NOT NULL;
      END IF;
      IF v_has_replication_stop_point_column > 0 THEN
        UPDATE mysql.rds_replication_status SET replication_stop_point=NULL WHERE action IS NOT NULL;
      END IF;
      IF v_has_replication_gtid_column > 0 THEN
        UPDATE mysql.rds_replication_status SET replication_gtid=NULL WHERE action IS NOT NULL;
      END IF;
    END IF;
    COMMIT;
    SET @@sql_log_bin=sql_logging;
  END;
END;

