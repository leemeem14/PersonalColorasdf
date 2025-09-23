-- 1. color_analysis
CREATE TABLE database_roe.color_analysis (
                                             id                 BIGINT AUTO_INCREMENT     NOT NULL,
                                             analyzed_at        DATETIME                  NULL,
                                             color_type         ENUM('RED','GREEN','BLUE','OTHER') NOT NULL,
                                             confidence         FLOAT                     NULL,
                                             description        VARCHAR(1000)             NULL,
                                             dominant_colors    VARCHAR(255)              NULL,
                                             original_file_name VARCHAR(255)              NOT NULL,
                                             stored_file_name   VARCHAR(255)              NOT NULL,
                                             user_id            BIGINT                    NOT NULL,
                                             PRIMARY KEY (id),
                                             CONSTRAINT fk_color_analysis_user
                                                 FOREIGN KEY (user_id)
                                                     REFERENCES database_roe.users(id)
                                                     ON DELETE NO ACTION
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 2. columns_priv
CREATE TABLE database_roe.columns_priv (
                                           Host        CHAR(255) NOT NULL DEFAULT '',
                                           Db          CHAR(64)  NOT NULL DEFAULT '',
                                           User        CHAR(32)  NOT NULL DEFAULT '',
                                           Table_name  CHAR(64)  NOT NULL DEFAULT '',
                                           Column_name CHAR(64)  NOT NULL DEFAULT '',
                                           Timestamp   TIMESTAMP NOT NULL DEFAULT NOW(),
                                           Column_priv SET(
                                               'SELECT','INSERT','UPDATE','DELETE',
                                               'CREATE','DROP','REFERENCES','INDEX'
                                               ) NOT NULL DEFAULT '',
                                           PRIMARY KEY (Host,User,Db,Table_name,Column_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    COMMENT='Column privileges';

-- 3. component
CREATE TABLE database_roe.component (
                                        component_id       INT UNSIGNED AUTO_INCREMENT NOT NULL,
                                        component_group_id INT UNSIGNED                NOT NULL,
                                        component_urn      LONGTEXT                    NOT NULL,
                                        PRIMARY KEY (component_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    COMMENT='Components';

-- 4. db (database privileges)
CREATE TABLE database_roe.db (
                                 Host                  CHAR(255) NOT NULL DEFAULT '',
                                 Db                    CHAR(64)  NOT NULL DEFAULT '',
                                 User                  CHAR(32)  NOT NULL DEFAULT '',
                                 Select_priv           ENUM('N','Y') NOT NULL DEFAULT 'N',
                                 Insert_priv           ENUM('N','Y') NOT NULL DEFAULT 'N',
                                 Update_priv           ENUM('N','Y') NOT NULL DEFAULT 'N',
                                 Delete_priv           ENUM('N','Y') NOT NULL DEFAULT 'N',
                                 Create_priv           ENUM('N','Y') NOT NULL DEFAULT 'N',
                                 Drop_priv             ENUM('N','Y') NOT NULL DEFAULT 'N',
                                 Grant_priv            ENUM('N','Y') NOT NULL DEFAULT 'N',
                                 References_priv       ENUM('N','Y') NOT NULL DEFAULT 'N',
                                 Index_priv            ENUM('N','Y') NOT NULL DEFAULT 'N',
                                 Alter_priv            ENUM('N','Y') NOT NULL DEFAULT 'N',
                                 Create_tmp_table_priv ENUM('N','Y') NOT NULL DEFAULT 'N',
                                 Lock_tables_priv      ENUM('N','Y') NOT NULL DEFAULT 'N',
                                 Create_view_priv      ENUM('N','Y') NOT NULL DEFAULT 'N',
                                 Show_view_priv        ENUM('N','Y') NOT NULL DEFAULT 'N',
                                 Create_routine_priv   ENUM('N','Y') NOT NULL DEFAULT 'N',
                                 Alter_routine_priv    ENUM('N','Y') NOT NULL DEFAULT 'N',
                                 Execute_priv          ENUM('N','Y') NOT NULL DEFAULT 'N',
                                 Event_priv            ENUM('N','Y') NOT NULL DEFAULT 'N',
                                 Trigger_priv          ENUM('N','Y') NOT NULL DEFAULT 'N',
                                 PRIMARY KEY (Host,User,Db)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    COMMENT='Database privileges';

-- 5. default_roles
CREATE TABLE database_roe.default_roles (
                                            HOST              CHAR(255) NOT NULL DEFAULT '',
                                            USER              CHAR(32)  NOT NULL DEFAULT '',
                                            DEFAULT_ROLE_HOST CHAR(255) NOT NULL DEFAULT '%',
                                            DEFAULT_ROLE_USER CHAR(32)  NOT NULL DEFAULT '',
                                            PRIMARY KEY (HOST,USER,DEFAULT_ROLE_HOST,DEFAULT_ROLE_USER)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    COMMENT='Default roles';

-- 6. engine_cost
CREATE TABLE database_roe.engine_cost (
                                          engine_name   VARCHAR(64) NOT NULL,
                                          device_type   INT         NOT NULL,
                                          cost_name     VARCHAR(64) NOT NULL,
                                          cost_value    FLOAT       NULL,
                                          last_update   TIMESTAMP   NOT NULL DEFAULT NOW(),
                                          comment       VARCHAR(1024) NULL,
                                          default_value FLOAT       NULL
                                                                             DEFAULT (
                                                                                 CASE cost_name
                                                                                     WHEN 'io_block_read_cost'     THEN 1.0
                                                                                     WHEN 'memory_block_read_cost' THEN 0.25
                                                                                     ELSE NULL
                                                                                     END
                                                                                 ),
                                          PRIMARY KEY (engine_name,device_type,cost_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 7. func
CREATE TABLE database_roe.func (
                                   name CHAR(64)              NOT NULL DEFAULT '',
                                   ret  TINYINT               NOT NULL DEFAULT 0,
                                   dl   CHAR(128)             NOT NULL DEFAULT '',
                                   type ENUM('FUNCTION','PROCEDURE') NOT NULL,
                                   PRIMARY KEY (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    COMMENT='User defined functions';

-- 8. general_log
CREATE TABLE database_roe.general_log (
                                          event_time   TIMESTAMP   NOT NULL DEFAULT NOW(6),
                                          user_host    LONGTEXT    NOT NULL,
                                          thread_id    BIGINT UNSIGNED NOT NULL,
                                          server_id    INT UNSIGNED NOT NULL,
                                          command_type VARCHAR(64) NOT NULL,
                                          argument     BLOB        NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    COMMENT='General log';

-- 9. global_grants
CREATE TABLE database_roe.global_grants (
                                            USER              CHAR(32)    NOT NULL DEFAULT '',
                                            HOST              CHAR(255)   NOT NULL DEFAULT '',
                                            PRIV              CHAR(32)    NOT NULL DEFAULT '',
                                            WITH_GRANT_OPTION ENUM('N','Y') NOT NULL DEFAULT 'N',
                                            PRIMARY KEY (USER,HOST,PRIV)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    COMMENT='Extended global grants';

-- 10. gtid_executed
CREATE TABLE database_roe.gtid_executed (
                                            source_uuid    CHAR(36) NOT NULL COMMENT 'uuid of the source where executed.',
                                            interval_start BIGINT   NOT NULL COMMENT 'First number of interval.',
                                            interval_end   BIGINT   NOT NULL COMMENT 'Last number of interval.',
                                            PRIMARY KEY (source_uuid,interval_start)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 11. help_category
CREATE TABLE database_roe.help_category (
                                            help_category_id   SMALLINT UNSIGNED NOT NULL,
                                            name               CHAR(64)          NOT NULL,
                                            parent_category_id SMALLINT UNSIGNED NULL,
                                            url                LONGTEXT          NOT NULL,
                                            PRIMARY KEY (help_category_id),
                                            CONSTRAINT uq_help_category_name UNIQUE (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    COMMENT='help categories';

-- 12. help_keyword
CREATE TABLE database_roe.help_keyword (
                                           help_keyword_id INT UNSIGNED NOT NULL,
                                           name            CHAR(64)     NOT NULL,
                                           PRIMARY KEY (help_keyword_id),
                                           CONSTRAINT uq_help_keyword_name UNIQUE (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    COMMENT='help keywords';

-- 13. help_topic
CREATE TABLE database_roe.help_topic (
                                         help_topic_id    INT UNSIGNED      NOT NULL,
                                         name             CHAR(64)          NOT NULL,
                                         help_category_id SMALLINT UNSIGNED NOT NULL,
                                         description      LONGTEXT          NOT NULL,
                                         example          LONGTEXT          NOT NULL,
                                         url              LONGTEXT          NOT NULL,
                                         PRIMARY KEY (help_topic_id),
                                         CONSTRAINT uq_help_topic_name UNIQUE (name),
                                         CONSTRAINT fk_help_topic_category
                                             FOREIGN KEY (help_category_id)
                                                 REFERENCES database_roe.help_category(help_category_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    COMMENT='help topics';

-- 14. help_relation
CREATE TABLE database_roe.help_relation (
                                            help_topic_id   INT UNSIGNED NOT NULL,
                                            help_keyword_id INT UNSIGNED NOT NULL,
                                            PRIMARY KEY (help_topic_id,help_keyword_id),
                                            CONSTRAINT fk_help_rel_topic
                                                FOREIGN KEY (help_topic_id)
                                                    REFERENCES database_roe.help_topic(help_topic_id),
                                            CONSTRAINT fk_help_rel_keyword
                                                FOREIGN KEY (help_keyword_id)
                                                    REFERENCES database_roe.help_keyword(help_keyword_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    COMMENT='keyword-topic relation';

-- 15. innodb_index_stats
CREATE TABLE database_roe.innodb_index_stats (
                                                 database_name    VARCHAR(64)      NOT NULL,
                                                 table_name       VARCHAR(199)     NOT NULL,
                                                 index_name       VARCHAR(64)      NOT NULL,
                                                 last_update      TIMESTAMP        NOT NULL DEFAULT NOW(),
                                                 stat_name        VARCHAR(64)      NOT NULL,
                                                 stat_value       BIGINT UNSIGNED  NOT NULL,
                                                 sample_size      BIGINT UNSIGNED  NULL,
                                                 stat_description VARCHAR(1024)    NOT NULL,
                                                 PRIMARY KEY (database_name,table_name,index_name,stat_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 16. innodb_table_stats
CREATE TABLE database_roe.innodb_table_stats (
                                                 database_name            VARCHAR(64)      NOT NULL,
                                                 table_name               VARCHAR(199)     NOT NULL,
                                                 last_update              TIMESTAMP        NOT NULL DEFAULT NOW(),
                                                 n_rows                   BIGINT UNSIGNED  NOT NULL,
                                                 clustered_index_size     BIGINT UNSIGNED  NOT NULL,
                                                 sum_of_other_index_sizes BIGINT UNSIGNED  NOT NULL,
                                                 PRIMARY KEY (database_name,table_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 17. password_history
CREATE TABLE database_roe.password_history (
                                               Host               CHAR(255)    NOT NULL DEFAULT '',
                                               User               CHAR(32)     NOT NULL DEFAULT '',
                                               Password_timestamp TIMESTAMP    NOT NULL DEFAULT NOW(6),
                                               Password           LONGTEXT     NULL,
                                               PRIMARY KEY (Host,User,Password_timestamp)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    COMMENT='Password history for user accounts';

-- 18. plugin
CREATE TABLE database_roe.plugin (
                                     name VARCHAR(64)  NOT NULL DEFAULT '',
                                     dl   VARCHAR(128) NOT NULL DEFAULT '',
                                     PRIMARY KEY (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    COMMENT='MySQL plugins';

-- 19. procs_priv
CREATE TABLE database_roe.procs_priv (
                                         Host         CHAR(255) NOT NULL DEFAULT '',
                                         Db           CHAR(64)  NOT NULL DEFAULT '',
                                         User         CHAR(32)  NOT NULL DEFAULT '',
                                         Routine_name CHAR(64)  NOT NULL DEFAULT '',
                                         Routine_type ENUM('FUNCTION','PROCEDURE') NOT NULL,
                                         Grantor      VARCHAR(288) NOT NULL DEFAULT '',
                                         Proc_priv    SET(
                                             'SELECT','INSERT','UPDATE','DELETE',
                                             'CREATE','DROP','REFERENCES','EXECUTE'
                                             ) NOT NULL DEFAULT '',
                                         Timestamp    TIMESTAMP NOT NULL DEFAULT NOW(),
                                         PRIMARY KEY (Host,User,Db,Routine_name,Routine_type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    COMMENT='Procedure privileges';

-- 20. proxies_priv
CREATE TABLE database_roe.proxies_priv (
                                           Host         CHAR(255) NOT NULL DEFAULT '',
                                           User         CHAR(32)  NOT NULL DEFAULT '',
                                           Proxied_host CHAR(255) NOT NULL DEFAULT '',
                                           Proxied_user CHAR(32)  NOT NULL DEFAULT '',
                                           With_grant   TINYINT(1) NOT NULL DEFAULT 0,
                                           Grantor      VARCHAR(288) NOT NULL DEFAULT '',
                                           Timestamp    TIMESTAMP NOT NULL DEFAULT NOW(),
                                           PRIMARY KEY (Host,User,Proxied_host,Proxied_user)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    COMMENT='User proxy privileges';

-- 21. replication_asynchronous_connection_failover
CREATE TABLE database_roe.replication_asynchronous_connection_failover (
                                                                           Channel_name      CHAR(64) NOT NULL COMMENT 'Channel name',
                                                                           Host              CHAR(255) NOT NULL COMMENT 'Source host',
                                                                           Port              INT UNSIGNED NOT NULL COMMENT 'Source port',
                                                                           Network_namespace CHAR(64) NOT NULL COMMENT 'Network namespace',
                                                                           Weight            TINYINT UNSIGNED NOT NULL COMMENT 'Failover weight',
                                                                           Managed_name      CHAR(64) NOT NULL DEFAULT '' COMMENT 'Group name',
                                                                           PRIMARY KEY (Channel_name,Host,Port,Network_namespace,Managed_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    COMMENT='Failover configuration';

-- 22. replication_asynchronous_connection_failover_managed
CREATE TABLE database_roe.replication_asynchronous_connection_failover_managed (
                                                                                   Channel_name CHAR(64) NOT NULL COMMENT 'Channel name',
                                                                                   Managed_name CHAR(64) NOT NULL DEFAULT '' COMMENT 'Managed group',
                                                                                   Managed_type CHAR(64) NOT NULL DEFAULT '' COMMENT 'Managed type',
                                                                                   Configuration JSON         NULL COMMENT 'Management configuration JSON',
                                                                                   PRIMARY KEY (Channel_name,Managed_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    COMMENT='Managed failover configuration';

-- 23. replication_group_configuration_version
CREATE TABLE database_roe.replication_group_configuration_version (
                                                                      name    CHAR(255)       NOT NULL COMMENT 'Configuration name',
                                                                      version BIGINT UNSIGNED NOT NULL COMMENT 'Version',
                                                                      PRIMARY KEY (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    COMMENT='Group config version';

-- 24. replication_group_member_actions
CREATE TABLE database_roe.replication_group_member_actions (
                                                               name           CHAR(255)        NOT NULL COMMENT 'Action name',
                                                               event          CHAR(64)         NOT NULL COMMENT 'Trigger event',
                                                               enabled        TINYINT(1)       NOT NULL COMMENT 'Enabled flag',
                                                               type           CHAR(64)         NOT NULL COMMENT 'Action type',
                                                               priority       TINYINT UNSIGNED NOT NULL COMMENT 'Execution priority',
                                                               error_handling CHAR(64)         NOT NULL COMMENT 'Error handling mode',
                                                               PRIMARY KEY (name,event)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    COMMENT='Member actions config';

-- 25. role_edges
CREATE TABLE database_roe.role_edges (
                                         FROM_HOST         CHAR(255) NOT NULL DEFAULT '',
                                         FROM_USER         CHAR(32)  NOT NULL DEFAULT '',
                                         TO_HOST           CHAR(255) NOT NULL DEFAULT '',
                                         TO_USER           CHAR(32)  NOT NULL DEFAULT '',
                                         WITH_ADMIN_OPTION ENUM('N','Y') NOT NULL DEFAULT 'N',
                                         PRIMARY KEY (FROM_HOST,FROM_USER,TO_HOST,TO_USER)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    COMMENT='Role hierarchy and grants';

-- 26. server_cost
CREATE TABLE database_roe.server_cost (
                                          cost_name     VARCHAR(64) NOT NULL,
                                          cost_value    FLOAT       NULL,
                                          last_update   TIMESTAMP   NOT NULL DEFAULT NOW(),
                                          comment       VARCHAR(1024) NULL,
                                          default_value FLOAT       NULL
                                                                             DEFAULT (
                                                                                 CASE cost_name
                                                                                     WHEN 'disk_temptable_create_cost'  THEN 20.0
                                                                                     WHEN 'disk_temptable_row_cost'     THEN 0.5
                                                                                     WHEN 'key_compare_cost'            THEN 0.05
                                                                                     WHEN 'memory_temptable_create_cost' THEN 1.0
                                                                                     WHEN 'memory_temptable_row_cost'    THEN 0.1
                                                                                     WHEN 'row_evaluate_cost'            THEN 0.1
                                                                                     ELSE NULL
                                                                                     END
                                                                                 ),
                                          PRIMARY KEY (cost_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 27. servers
CREATE TABLE database_roe.servers (
                                      Server_name CHAR(64) NOT NULL DEFAULT '',
                                      Host        CHAR(255) NOT NULL DEFAULT '',
                                      Db          CHAR(64)  NOT NULL DEFAULT '',
                                      Username    CHAR(64)  NOT NULL DEFAULT '',
                                      Password    CHAR(64)  NOT NULL DEFAULT '',
                                      Port        INT       NOT NULL DEFAULT 0,
                                      Socket      CHAR(64)  NOT NULL DEFAULT '',
                                      Wrapper     CHAR(64)  NOT NULL DEFAULT '',
                                      Owner       CHAR(64)  NOT NULL DEFAULT '',
                                      PRIMARY KEY (Server_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    COMMENT='MySQL Foreign Servers table';

-- 28. slave_master_info
CREATE TABLE database_roe.slave_master_info (
                                                Number_of_lines INT UNSIGNED NOT NULL COMMENT 'Line count',
                                                Master_log_name LONGTEXT     NOT NULL COMMENT 'Master binlog name',
                                                Master_log_pos  BIGINT UNSIGNED NOT NULL COMMENT 'Last read position',
                                                Host            VARCHAR(255) NULL COMMENT 'Master host',
                                                User_name       LONGTEXT     NULL COMMENT 'Master user',
                                                User_password   LONGTEXT     NULL COMMENT 'Master password',
                                                Port            INT UNSIGNED NOT NULL COMMENT 'Master port',
                                                Connect_retry   INT UNSIGNED NOT NULL COMMENT 'Retry interval(s)',
                                                Enabled_ssl     TINYINT(1)   NOT NULL COMMENT 'SSL supported',
                                                Ssl_ca          LONGTEXT     NULL COMMENT 'CA cert path',
                                                Ssl_capath      LONGTEXT     NULL COMMENT 'CA cert dir',
                                                Ssl_cert        LONGTEXT     NULL COMMENT 'Client cert file',
                                                Ssl_cipher      LONGTEXT     NULL COMMENT 'Cipher in use',
                                                Ssl_key         LONGTEXT     NULL COMMENT 'Client key file',
                                                Ssl_verify_server_cert TINYINT(1) NOT NULL COMMENT 'Verify server cert',
                                                Heartbeat       FLOAT        NOT NULL,
                                                Bind            LONGTEXT     NULL COMMENT 'Bind interface',
                                                Ignored_server_ids LONGTEXT  NULL COMMENT 'Ignored server IDs',
                                                Uuid            LONGTEXT     NULL COMMENT 'Master UUID',
                                                Retry_count     BIGINT UNSIGNED NOT NULL COMMENT 'Reconnect attempts',
                                                Ssl_crl         LONGTEXT     NULL COMMENT 'CRL file',
                                                Ssl_crlpath     LONGTEXT     NULL COMMENT 'CRL dir',
                                                Enabled_auto_position TINYINT(1) NOT NULL COMMENT 'Auto GTID',
                                                Channel_name    VARCHAR(64)  NOT NULL COMMENT 'Replication channel',
                                                Tls_version     LONGTEXT     NULL COMMENT 'TLS version',
                                                Public_key_path LONGTEXT     NULL COMMENT 'Master public key file',
                                                Get_public_key  TINYINT(1)   NOT NULL COMMENT 'Fetch public key',
                                                Network_namespace LONGTEXT   NULL COMMENT 'Network namespace',
                                                Master_compression_algorithm VARCHAR(64) NOT NULL COMMENT 'Compression algorithm',
                                                Master_zstd_compression_level INT UNSIGNED NOT NULL COMMENT 'zstd level',
                                                Tls_ciphersuites LONGTEXT    NULL COMMENT 'TLS 1.3 ciphersuites',
                                                Source_connection_auto_failover TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Enable failover',
                                                Gtid_only       TINYINT(1)   NOT NULL DEFAULT 0 COMMENT 'GTID only',
                                                PRIMARY KEY (Channel_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    COMMENT='Master Information';

-- 29. slave_relay_log_info
CREATE TABLE database_roe.slave_relay_log_info (
                                                   Number_of_lines                              INT UNSIGNED NOT NULL COMMENT 'Line count',
                                                   Relay_log_name                               LONGTEXT     NULL COMMENT 'Relay log name',
                                                   Relay_log_pos                                BIGINT UNSIGNED NULL COMMENT 'Last executed pos',
                                                   Master_log_name                              LONGTEXT     NULL COMMENT 'Master binlog name',
                                                   Master_log_pos                               BIGINT UNSIGNED NULL COMMENT 'Master log pos',
                                                   Sql_delay                                    INT          NULL COMMENT 'Seconds delay',
                                                   Number_of_workers                            INT UNSIGNED NULL,
                                                   Id                                           INT UNSIGNED NULL COMMENT 'Internal ID',
                                                   Channel_name                                 VARCHAR(64)  NOT NULL COMMENT 'Replication channel',
                                                   Privilege_checks_username                    VARCHAR(32)  NULL COMMENT 'PRIVILEGE_CHECKS_USER name',
                                                   Privilege_checks_hostname                    VARCHAR(255) NULL COMMENT 'PRIVILEGE_CHECKS_USER host',
                                                   Require_row_format                           TINYINT(1)   NOT NULL COMMENT 'Require row format',
                                                   Require_table_primary_key_check              ENUM('STREAM','FAIL') NOT NULL DEFAULT 'STREAM' COMMENT 'Policy for tables without PK',
                                                   Assign_gtids_to_anonymous_transactions_type  ENUM('OFF','LOCAL','UUID') NOT NULL DEFAULT 'OFF' COMMENT 'GTID assignment for anon txns',
                                                   Assign_gtids_to_anonymous_transactions_value LONGTEXT     NULL COMMENT 'UUID for anon txns',
                                                   PRIMARY KEY (Channel_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    COMMENT='Relay Log Information';

-- 30. slave_worker_info
CREATE TABLE database_roe.slave_worker_info (
                                                Id                         INT UNSIGNED    NOT NULL,
                                                Relay_log_name             LONGTEXT        NOT NULL,
                                                Relay_log_pos              BIGINT UNSIGNED NOT NULL,
                                                Master_log_name            LONGTEXT        NOT NULL,
                                                Master_log_pos             BIGINT UNSIGNED NOT NULL,
                                                Checkpoint_relay_log_name  LONGTEXT        NOT NULL,
                                                Checkpoint_relay_log_pos   BIGINT UNSIGNED NOT NULL,
                                                Checkpoint_master_log_name LONGTEXT        NOT NULL,
                                                Checkpoint_master_log_pos  BIGINT UNSIGNED NOT NULL,
                                                Checkpoint_seqno           INT UNSIGNED    NOT NULL,
                                                Checkpoint_group_size      INT UNSIGNED    NOT NULL,
                                                Checkpoint_group_bitmap    BLOB            NOT NULL,
                                                Channel_name               VARCHAR(64)     NOT NULL COMMENT 'Replication channel',
                                                PRIMARY KEY (Channel_name,Id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    COMMENT='Worker Information';

-- 31. slow_log
CREATE TABLE database_roe.slow_log (
                                       start_time     TIMESTAMP       NOT NULL DEFAULT NOW(6),
                                       user_host      LONGTEXT        NOT NULL,
                                       query_time     TIME            NOT NULL,
                                       lock_time      TIME            NOT NULL,
                                       rows_sent      INT             NOT NULL,
                                       rows_examined  INT             NOT NULL,
                                       db             VARCHAR(512)    NOT NULL,
                                       last_insert_id INT             NOT NULL,
                                       insert_id      INT             NOT NULL,
                                       server_id      INT UNSIGNED    NOT NULL,
                                       sql_text       BLOB            NOT NULL,
                                       thread_id      BIGINT UNSIGNED NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    COMMENT='Slow log';

-- 32. tables_priv
CREATE TABLE database_roe.tables_priv (
                                          Host        CHAR(255) NOT NULL DEFAULT '',
                                          Db          CHAR(64)  NOT NULL DEFAULT '',
                                          User        CHAR(32)  NOT NULL DEFAULT '',
                                          Table_name  CHAR(64)  NOT NULL DEFAULT '',
                                          Grantor     VARCHAR(288) NOT NULL DEFAULT '',
                                          Timestamp   TIMESTAMP NOT NULL DEFAULT NOW(),
                                          Table_priv  SET(
                                              'SELECT','INSERT','UPDATE','DELETE',
                                              'CREATE','DROP','REFERENCES','INDEX'
                                              ) NOT NULL DEFAULT '',
                                          Column_priv SET(
                                              'SELECT','INSERT','UPDATE','DELETE',
                                              'CREATE','DROP','REFERENCES','INDEX'
                                              ) NOT NULL DEFAULT '',
                                          PRIMARY KEY (Host,User,Db,Table_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    COMMENT='Table privileges';

-- 33. time_zone
CREATE TABLE database_roe.time_zone (
                                        Time_zone_id     INT UNSIGNED AUTO_INCREMENT NOT NULL,
                                        Use_leap_seconds ENUM('N','Y')                NOT NULL DEFAULT 'N',
                                        PRIMARY KEY (Time_zone_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    COMMENT='Time zones';

-- 34. time_zone_leap_second
CREATE TABLE database_roe.time_zone_leap_second (
                                                    Transition_time BIGINT NOT NULL,
                                                    Correction      INT    NOT NULL,
                                                    PRIMARY KEY (Transition_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    COMMENT='Leap seconds information for time zones';

-- 35. time_zone_name
CREATE TABLE database_roe.time_zone_name (
                                             Name         CHAR(64)     NOT NULL,
                                             Time_zone_id INT UNSIGNED NOT NULL,
                                             PRIMARY KEY (Name),
                                             CONSTRAINT fk_tzn_timezone
                                                 FOREIGN KEY (Time_zone_id)
                                                     REFERENCES database_roe.time_zone(Time_zone_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    COMMENT='Time zone names';

-- 36. time_zone_transition
CREATE TABLE database_roe.time_zone_transition (
                                                   Time_zone_id       INT UNSIGNED NOT NULL,
                                                   Transition_time    BIGINT       NOT NULL,
                                                   Transition_type_id INT UNSIGNED NOT NULL,
                                                   PRIMARY KEY (Time_zone_id,Transition_time),
                                                   CONSTRAINT fk_tzt_transition
                                                       FOREIGN KEY (Time_zone_id)
                                                           REFERENCES database_roe.time_zone(Time_zone_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    COMMENT='Time zone transitions';

-- 37. time_zone_transition_type
CREATE TABLE database_roe.time_zone_transition_type (
                                                        Time_zone_id       INT UNSIGNED                NOT NULL,
                                                        Transition_type_id INT UNSIGNED                NOT NULL,
                                                        `Offset`           INT              NOT NULL DEFAULT 0,
                                                        Is_DST             TINYINT UNSIGNED NOT NULL DEFAULT 0,
                                                        Abbreviation       CHAR(8)          NOT NULL DEFAULT '',
                                                        PRIMARY KEY (Time_zone_id,Transition_type_id),
                                                        CONSTRAINT fk_tztt_timezone
                                                            FOREIGN KEY (Time_zone_id)
                                                                REFERENCES database_roe.time_zone(Time_zone_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    COMMENT='Time zone transition types';

-- 38. user (global users and privileges)
CREATE TABLE database_roe.`user` (
                                     Host                     CHAR(255) NOT NULL DEFAULT '',
                                     User                     CHAR(32)  NOT NULL DEFAULT '',
                                     Select_priv              ENUM('N','Y') NOT NULL DEFAULT 'N',
                                     Insert_priv              ENUM('N','Y') NOT NULL DEFAULT 'N',
                                     Update_priv              ENUM('N','Y') NOT NULL DEFAULT 'N',
                                     Delete_priv              ENUM('N','Y') NOT NULL DEFAULT 'N',
                                     Create_priv              ENUM('N','Y') NOT NULL DEFAULT 'N',
                                     Drop_priv                ENUM('N','Y') NOT NULL DEFAULT 'N',
                                     Reload_priv              ENUM('N','Y') NOT NULL DEFAULT 'N',
                                     Shutdown_priv            ENUM('N','Y') NOT NULL DEFAULT 'N',
                                     Process_priv             ENUM('N','Y') NOT NULL DEFAULT 'N',
                                     File_priv                ENUM('N','Y') NOT NULL DEFAULT 'N',
                                     Grant_priv               ENUM('N','Y') NOT NULL DEFAULT 'N',
                                     References_priv          ENUM('N','Y') NOT NULL DEFAULT 'N',
                                     Index_priv               ENUM('N','Y') NOT NULL DEFAULT 'N',
                                     Alter_priv               ENUM('N','Y') NOT NULL DEFAULT 'N',
                                     Show_db_priv             ENUM('N','Y') NOT NULL DEFAULT 'N',
                                     Super_priv               ENUM('N','Y') NOT NULL DEFAULT 'N',
                                     Create_tmp_table_priv    ENUM('N','Y') NOT NULL DEFAULT 'N',
                                     Lock_tables_priv         ENUM('N','Y') NOT NULL DEFAULT 'N',
                                     Execute_priv             ENUM('N','Y') NOT NULL DEFAULT 'N',
                                     Repl_slave_priv          ENUM('N','Y') NOT NULL DEFAULT 'N',
                                     Repl_client_priv         ENUM('N','Y') NOT NULL DEFAULT 'N',
                                     Create_view_priv         ENUM('N','Y') NOT NULL DEFAULT 'N',
                                     Show_view_priv           ENUM('N','Y') NOT NULL DEFAULT 'N',
                                     Create_routine_priv      ENUM('N','Y') NOT NULL DEFAULT 'N',
                                     Alter_routine_priv       ENUM('N','Y') NOT NULL DEFAULT 'N',
                                     Create_user_priv         ENUM('N','Y') NOT NULL DEFAULT 'N',
                                     Event_priv               ENUM('N','Y') NOT NULL DEFAULT 'N',
                                     Trigger_priv             ENUM('N','Y') NOT NULL DEFAULT 'N',
                                     Create_tablespace_priv   ENUM('N','Y') NOT NULL DEFAULT 'N',
                                     ssl_type                 ENUM('','ANY','X509') NOT NULL DEFAULT '',
                                     ssl_cipher               BLOB        NOT NULL,
                                     x509_issuer              BLOB        NOT NULL,
                                     x509_subject             BLOB        NOT NULL,
                                     max_questions            INT UNSIGNED NOT NULL DEFAULT 0,
                                     max_updates              INT UNSIGNED NOT NULL DEFAULT 0,
                                     max_connections          INT UNSIGNED NOT NULL DEFAULT 0,
                                     max_user_connections     INT UNSIGNED NOT NULL DEFAULT 0,
                                     plugin                   CHAR(64)    NOT NULL DEFAULT 'caching_sha2_password',
                                     authentication_string    LONGTEXT    NULL,
                                     password_expired         ENUM('N','Y') NOT NULL DEFAULT 'N',
                                     password_last_changed    TIMESTAMP   NULL,
                                     password_lifetime        SMALLINT UNSIGNED NULL,
                                     account_locked           ENUM('N','Y') NOT NULL DEFAULT 'N',
                                     Create_role_priv         ENUM('N','Y') NOT NULL DEFAULT 'N',
                                     Drop_role_priv           ENUM('N','Y') NOT NULL DEFAULT 'N',
                                     Password_reuse_history   SMALLINT UNSIGNED NULL,
                                     Password_reuse_time      SMALLINT UNSIGNED NULL,
                                     Password_require_current ENUM('N','Y') NULL,
                                     User_attributes          JSON        NULL,
                                     PRIMARY KEY (Host,User)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    COMMENT='Users and global privileges';

-- 39. users (application users)
CREATE TABLE database_roe.users (
                                    id         BIGINT AUTO_INCREMENT NOT NULL,
                                    created_at DATETIME              NULL,
                                    email      VARCHAR(255)          NOT NULL,
                                    gender     ENUM('M','F','O','U') NOT NULL,
                                    name       VARCHAR(255)          NOT NULL,
                                    password   VARCHAR(255)          NOT NULL,
                                    updated_at DATETIME              NULL,
                                    PRIMARY KEY (id),
                                    CONSTRAINT uk_users_email UNIQUE (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- 40. 인덱스 정리
CREATE INDEX idx_replication_failover_channel
    ON database_roe.replication_asynchronous_connection_failover (Channel_name,Managed_name);
CREATE INDEX idx_tables_priv_grantor
    ON database_roe.tables_priv (Grantor);
CREATE INDEX idx_db_user
    ON database_roe.db (User);
CREATE INDEX idx_replication_actions_event
    ON database_roe.replication_group_member_actions (event);
