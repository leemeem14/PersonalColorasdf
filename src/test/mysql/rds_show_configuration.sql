create
    definer = rdsadmin@localhost procedure rds_show_configuration()
BEGIN
  SELECT name, value, description FROM mysql.rds_configuration;
END;

