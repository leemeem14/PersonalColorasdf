create
    definer = rdsadmin@localhost procedure rds_set_external_master_with_delay(IN host varchar(255), IN port int,
                                                                              IN user text, IN passwd text,
                                                                              IN name text, IN pos bigint unsigned,
                                                                              IN enable_ssl_encryption tinyint(1),
                                                                              IN delay int)
BEGIN
  CALL mysql.rds_set_external_source_with_delay_for_channel(host, port, user, passwd, name, pos, enable_ssl_encryption, delay, '');
END;

