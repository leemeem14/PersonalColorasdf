create table performance_schema.log_status
(
    SERVER_UUID     char(36) not null,
    LOCAL           json     not null,
    REPLICATION     json     not null,
    STORAGE_ENGINES json     not null
);

