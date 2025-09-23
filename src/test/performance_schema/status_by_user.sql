create table performance_schema.status_by_user
(
    USER           char(32)      null,
    VARIABLE_NAME  varchar(64)   not null,
    VARIABLE_VALUE varchar(1024) null,
    constraint USER
        unique (USER, VARIABLE_NAME) using hash
);

