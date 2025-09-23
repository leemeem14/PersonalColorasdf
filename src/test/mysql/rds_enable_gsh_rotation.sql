create
    definer = rdsadmin@localhost procedure rds_enable_gsh_rotation()
begin
  call rds_set_gsh_rotation(7);
end;

