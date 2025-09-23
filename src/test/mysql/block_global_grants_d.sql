create definer = rdsadmin@localhost trigger block_global_grants_d
    before delete
    on global_grants
    for each row
BEGIN
   IF USER() != "rdsadmin@localhost" THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'ERROR (RDS): ACCESS DENIED - CANNOT PERFORM DELETE ON THIS TABLE';
   END IF;
END;

