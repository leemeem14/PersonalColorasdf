create table performance_schema.users
(
    USER                          char(32)        null,
    CURRENT_CONNECTIONS           bigint          not null,
    TOTAL_CONNECTIONS             bigint          not null,
    MAX_SESSION_CONTROLLED_MEMORY bigint unsigned not null,
    MAX_SESSION_TOTAL_MEMORY      bigint unsigned not null,
    constraint USER
        unique (USER) using hash
);

