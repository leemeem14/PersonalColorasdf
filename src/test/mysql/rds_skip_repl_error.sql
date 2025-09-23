create
    definer = rdsadmin@localhost procedure rds_skip_repl_error()
BEGIN
  CALL mysql.rds_skip_repl_error_for_channel('');
END;

