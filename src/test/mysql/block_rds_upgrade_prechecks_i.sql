create definer = rdsadmin@localhost trigger block_rds_upgrade_prechecks_i
    before insert
    on rds_upgrade_prechecks
    for each row
BEGIN
    IF user()!='rdsadmin@localhost' AND (substring_index(version(),'.',2) = '8.0' AND substring(version(),5,6) <= 35)
    THEN
      
      
      
      
      
      
      
      IF @@GLOBAL.admin_tls_version != 'TLSv1.3'
      THEN
         SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'ERROR (RDS): ACCESS DENIED - CANNOT PERFORM INSERT ON THIS TABLE';
      END IF;
   ELSE
      
      
      
      
      
      
      
      IF USER()!='rdsadmin@localhost' AND @@SQL_LOG_BIN != 0
      THEN
         SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'ERROR (RDS): ACCESS DENIED - CANNOT PERFORM INSERT ON THIS TABLE';
      END IF;
   END IF;
END;

