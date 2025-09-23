create definer = rdsadmin@localhost trigger block_user_u
    before update
    on user
    for each row
BEGIN
  IF old.User = "rdsadmin" AND old.Host = "localhost" THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'ERROR (RDS): CANNOT UPDATE RDSADMIN@LOCALHOST USER';
  END IF;
  IF old.User = "rdsrepladmin" THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'ERROR (RDS): CANNOT UPDATE RDSREPLADMIN USER';
  END IF;
  if old.User = "mysql.infoschema" and new.select_priv = 'N' then
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'ERROR (RDS): CANNOT REMOVE SELECT PRIVILEGE FROM MYSQL.INFOSCHEMA';
  end if;
  IF old.super_priv <> 'Y' and new.super_priv = 'Y' THEN
    SIGNAL SQLSTATE '45000' SET SCHEMA_NAME = 'mysql', TABLE_NAME = 'user', MESSAGE_TEXT = 'ERROR (RDS): SUPER PRIVILEGE CANNOT BE GRANTED OR MAINTAINED';
  ELSEIF old.shutdown_priv <> 'Y' and new.shutdown_priv = 'Y' THEN
    SIGNAL SQLSTATE '45000' SET SCHEMA_NAME = 'mysql', TABLE_NAME = 'user', MESSAGE_TEXT = 'ERROR (RDS): SHUTDOWN PRIVILEGE CANNOT BE GRANTED OR MAINTAINED. PLEASE USE RDS API';
  ELSEIF old.file_priv <> 'Y' and new.file_priv = 'Y' THEN
    SIGNAL SQLSTATE '45000' SET SCHEMA_NAME = 'mysql', TABLE_NAME = 'user', MESSAGE_TEXT = 'ERROR (RDS): FILE PRIVILEGE CANNOT BE GRANTED OR MAINTAINED';
  ELSEIF old.create_tablespace_priv <> 'Y' and new.create_tablespace_priv = 'Y' THEN
    SIGNAL SQLSTATE '45000' SET SCHEMA_NAME = 'mysql', TABLE_NAME = 'user', MESSAGE_TEXT = 'ERROR (RDS): CREATE TABLESPACE PRIVILEGE CANNOT BE GRANTED OR MAINTAINED';
  END IF;
END;

