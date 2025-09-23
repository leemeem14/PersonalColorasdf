create definer = rdsadmin@localhost trigger block_user_d
    before delete
    on user
    for each row
BEGIN
  IF old.User = 'rdsadmin' AND old.Host = 'localhost' THEN
    SIGNAL SQLSTATE '45000' SET SCHEMA_NAME = 'mysql', table_name = 'user', MESSAGE_TEXT = 'ERROR (RDS): CANNOT DROP RDSADMIN@LOCALHOST USER';
  END IF;
  IF old.User = 'rdsrepladmin' THEN
    SIGNAL SQLSTATE '45000' SET SCHEMA_NAME = 'mysql', table_name = 'user', MESSAGE_TEXT = 'ERROR (RDS): CANNOT DROP RDSREPLADMIN USER';
  END IF;
  IF old.User = 'mysql.infoschema' AND old.Host = 'localhost' THEN
    SIGNAL SQLSTATE '45000' SET SCHEMA_NAME = 'mysql', table_name = 'user', MESSAGE_TEXT = 'ERROR (RDS): CANNOT DROP MYSQL.INFOSCHEMA USER';
  END IF;
END;

