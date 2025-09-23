create
    definer = rdsadmin@localhost function rds_version() returns varchar(60) deterministic sql security invoker no sql
BEGIN
RETURN '8.0.41.R2';
END;

