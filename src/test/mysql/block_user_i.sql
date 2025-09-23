create definer = rdsadmin@localhost trigger block_user_i
    before insert
    on user
    for each row
block_user: BEGIN
  IF new.User = "rdsadmin" AND new.host = "localhost" THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'ERROR (RDS): CANNOT CREATE RDSADMIN@LOCALHOST USER';
  END IF;
  IF new.User = "rdsrepladmin" THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'ERROR (RDS): CANNOT CREATE RDSREPLADMIN USER';
  END IF;
  IF new.Host = "localhost" AND new.User IN ("mysql.session", "mysql.sys", "mysql.infoschema") THEN
    LEAVE block_user;
  END IF;
  IF new.super_priv = 'Y' THEN
    SIGNAL SQLSTATE '45000' SET SCHEMA_NAME = 'mysql', table_name = 'user', MESSAGE_TEXT = 'ERROR (RDS): SUPER PRIVILEGE CANNOT BE GRANTED';
  ELSEIF new.shutdown_priv = 'Y' THEN
    SIGNAL SQLSTATE '45000' SET SCHEMA_NAME = 'mysql', table_name = 'user', MESSAGE_TEXT = 'ERROR (RDS): SHUTDOWN PRIVILEGE CANNOT BE GRANTED. PLEASE USE RDS API';
  ELSEIF new.file_priv = 'Y' THEN
    SIGNAL SQLSTATE '45000' SET SCHEMA_NAME = 'mysql', table_name = 'user', MESSAGE_TEXT = 'ERROR (RDS): FILE PRIVILEGE CANNOT BE GRANTED';
  ELSEIF new.create_tablespace_priv = 'Y' THEN
    SIGNAL SQLSTATE '45000' SET SCHEMA_NAME = 'mysql', table_name = 'user', MESSAGE_TEXT = 'ERROR (RDS): CREATE TABLESPACE PRIVILEGE CANNOT BE GRANTED';
  END IF;
END;

