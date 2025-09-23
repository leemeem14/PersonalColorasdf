create
    definer = rdsadmin@localhost procedure rds_set_external_master(IN host varchar(255), IN port int, IN user text,
                                                                   IN passwd text, IN name text, IN pos bigint unsigned,
                                                                   IN enable_ssl_encryption tinyint(1))
BEGIN
  CALL mysql.rds_set_external_source_for_channel(host, port, user, passwd, name, pos, enable_ssl_encryption, '');
END;

grant select on user to 'mysql.session'@localhost;

