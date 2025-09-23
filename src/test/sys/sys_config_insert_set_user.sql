create definer = `mysql.sys`@localhost trigger sys.sys_config_insert_set_user
    before insert
    on sys.sys_config
    for each row
begin
    -- missing source code
end;

