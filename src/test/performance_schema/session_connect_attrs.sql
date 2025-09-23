create table performance_schema.session_connect_attrs
(
    PROCESSLIST_ID   bigint unsigned not null,
    ATTR_NAME        varchar(32)     not null,
    ATTR_VALUE       varchar(1024)   null,
    ORDINAL_POSITION int             null
);

create unique index `PRIMARY`
    on performance_schema.session_connect_attrs (PROCESSLIST_ID, ATTR_NAME)
    using hash;

alter table performance_schema.session_connect_attrs
    add primary key (PROCESSLIST_ID, ATTR_NAME) using hash;

