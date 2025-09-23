create table performance_schema.accounts
(
    USER                          char(32)        null,
    HOST                          char(255)       null,
    CURRENT_CONNECTIONS           bigint          not null,
    TOTAL_CONNECTIONS             bigint          not null,
    MAX_SESSION_CONTROLLED_MEMORY bigint unsigned not null,
    MAX_SESSION_TOTAL_MEMORY      bigint unsigned not null,
    constraint ACCOUNT
        unique (USER, HOST) using hash
);

