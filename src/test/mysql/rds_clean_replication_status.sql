create
    definer = rdsadmin@localhost procedure rds_clean_replication_status() sql security invoker
BEGIN
  DECLARE v_has_replication_log_file_column INT;
  DECLARE v_has_replication_stop_point_column INT;
  DECLARE v_has_replication_gtid_column INT;
  DECLARE v_current_security_context_user VARCHAR(352);
  
  
  
  
  SELECT CURRENT_USER() INTO v_current_security_context_user;
  IF v_current_security_context_user <> 'rdsadmin@localhost' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Must be rdsadmin@localhost to call this procedure';
  END IF;
  SELECT count(*) INTO v_has_replication_log_file_column FROM information_schema.columns WHERE table_schema = 'mysql' AND column_name = 'replication_log_file' AND table_name = 'rds_replication_status';
  SELECT count(*) INTO v_has_replication_stop_point_column FROM information_schema.columns WHERE table_schema = 'mysql' AND column_name = 'replication_stop_point' AND table_name = 'rds_replication_status';
  SELECT count(*) INTO v_has_replication_gtid_column FROM information_schema.columns WHERE table_schema = 'mysql' AND column_name = 'replication_gtid' AND table_name = 'rds_replication_status';
  IF v_has_replication_log_file_column > 0 THEN
    UPDATE mysql.rds_replication_status SET replication_log_file=NULL WHERE action IS NOT NULL;
  END IF;
  IF v_has_replication_stop_point_column > 0 THEN
    UPDATE mysql.rds_replication_status SET replication_stop_point=NULL WHERE action IS NOT NULL;
  END IF;
  IF v_has_replication_gtid_column > 0 THEN
    UPDATE mysql.rds_replication_status SET replication_gtid=NULL WHERE action IS NOT NULL;
  END IF;
  commit;
END;

