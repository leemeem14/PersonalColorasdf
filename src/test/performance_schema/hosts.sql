create table performance_schema.hosts
(
    HOST                          char(255)       null,
    CURRENT_CONNECTIONS           bigint          not null,
    TOTAL_CONNECTIONS             bigint          not null,
    MAX_SESSION_CONTROLLED_MEMORY bigint unsigned not null,
    MAX_SESSION_TOTAL_MEMORY      bigint unsigned not null,
    constraint HOST
        unique (HOST) using hash
);

