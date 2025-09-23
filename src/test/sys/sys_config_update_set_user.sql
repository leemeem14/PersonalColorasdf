create definer = `mysql.sys`@localhost trigger sys.sys_config_update_set_user
    before update
    on sys.sys_config
    for each row
begin
    -- missing source code
end;

