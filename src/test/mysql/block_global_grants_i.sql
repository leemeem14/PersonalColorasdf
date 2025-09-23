create definer = rdsadmin@localhost trigger block_global_grants_i
    before insert
    on global_grants
    for each row
BEGIN
   IF USER() != "rdsadmin@localhost" THEN
      SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'ERROR (RDS): ACCESS DENIED - CANNOT PERFORM INSERT ON THIS TABLE';
   END IF;
END;

