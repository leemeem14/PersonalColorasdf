create definer = rdsadmin@localhost trigger block_role_edges_d
    before delete
    on role_edges
    for each row
BEGIN
  DECLARE rsv_user TEXT;
  DECLARE rsv_host TEXT;
  
  
  
  
  SELECT MAX(ru.user), MAX(ru.host) INTO rsv_user, rsv_host FROM mysql.rds_reserved_users ru WHERE (
       (ru.user = old.from_user AND ru.host = old.from_host)
    OR (ru.user = old.to_user AND ru.host = old.to_host));
  IF (rsv_user IS NOT NULL) AND (rsv_host IS NOT NULL) THEN
    SET @err_msg = CONCAT('CANNOT DELETE MYSQL.ROLE_EDGES FOR ', QUOTE(rsv_user), '@', QUOTE(rsv_host));
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = @err_msg;
  END IF;
END;

