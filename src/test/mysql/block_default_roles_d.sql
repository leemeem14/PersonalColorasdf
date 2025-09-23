create definer = rdsadmin@localhost trigger block_default_roles_d
    before delete
    on default_roles
    for each row
BEGIN
  DECLARE rsv_user TEXT;
  DECLARE rsv_host TEXT;
  
  
  
  
  SELECT MAX(ru.user), MAX(ru.host) INTO rsv_user, rsv_host FROM mysql.rds_reserved_users ru WHERE (
       (ru.user = old.default_role_user AND ru.host = old.default_role_host)
    OR (ru.user = old.user AND ru.host = old.host));
  IF (rsv_user IS NOT NULL) AND (rsv_host IS NOT NULL) THEN
    SET @err_msg = CONCAT('CANNOT DELETE MYSQL.DEFAULT_ROLES FOR ', QUOTE(rsv_user), '@', QUOTE(rsv_host));
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = @err_msg;
  END IF;
END;

