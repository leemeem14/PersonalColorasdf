create
    definer = rdsadmin@localhost procedure rds_set_external_master_with_auto_position(IN host varchar(255), IN port int,
                                                                                      IN user text, IN passwd text,
                                                                                      IN enable_ssl_encryption tinyint(1),
                                                                                      IN delay int)
BEGIN
  CALL mysql.rds_set_external_source_with_auto_position_for_channel(host, port, user, passwd, enable_ssl_encryption, delay, '');
END;

