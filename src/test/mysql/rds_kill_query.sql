create
    definer = rdsadmin@localhost procedure rds_kill_query(IN thread bigint)
BEGIN
  DECLARE l_user TEXT;
  DECLARE l_host TEXT;
  DECLARE rsv_user TEXT;
  DECLARE rsv_host TEXT;
  
  SELECT user, host INTO l_user, l_host
  FROM information_schema.processlist
  WHERE id = thread;
  
  SELECT MAX(user), MAX(host) INTO rsv_user, rsv_host
  FROM mysql.rds_reserved_users
  WHERE user = l_user;
  IF CONNECTION_ID() = thread THEN
    
    
    DO NULL;
  ELSEIF (rsv_user IS NOT NULL AND (l_host = rsv_host OR rsv_host = '%')) THEN
    
    SET @err_msg = CONCAT('CANNOT KILL ', UPPER(l_user), ' SESSION');
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = @err_msg;
  END IF;
  KILL QUERY thread;
END;

