create
    definer = rdsadmin@localhost procedure rds_enable_gsh_collector()
begin
  call rds_set_gsh_collector(5);
end;

