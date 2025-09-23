create table performance_schema.replication_applier_status
(
    CHANNEL_NAME               char(64)           not null,
    SERVICE_STATE              enum ('ON', 'OFF') not null,
    REMAINING_DELAY            int unsigned       null,
    COUNT_TRANSACTIONS_RETRIES bigint unsigned    not null
);

create unique index `PRIMARY`
    on performance_schema.replication_applier_status (CHANNEL_NAME)
    using hash;

alter table performance_schema.replication_applier_status
    add primary key (CHANNEL_NAME) using hash;

