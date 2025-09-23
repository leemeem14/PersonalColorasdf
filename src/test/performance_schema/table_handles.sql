create table performance_schema.table_handles
(
    OBJECT_TYPE           varchar(64)     not null,
    OBJECT_SCHEMA         varchar(64)     not null,
    OBJECT_NAME           varchar(64)     not null,
    OBJECT_INSTANCE_BEGIN bigint unsigned not null,
    OWNER_THREAD_ID       bigint unsigned null,
    OWNER_EVENT_ID        bigint unsigned null,
    INTERNAL_LOCK         varchar(64)     null,
    EXTERNAL_LOCK         varchar(64)     null
);

create index OBJECT_TYPE
    on performance_schema.table_handles (OBJECT_TYPE, OBJECT_SCHEMA, OBJECT_NAME)
    using hash;

create index OWNER_THREAD_ID
    on performance_schema.table_handles (OWNER_THREAD_ID, OWNER_EVENT_ID)
    using hash;

create unique index `PRIMARY`
    on performance_schema.table_handles (OBJECT_INSTANCE_BEGIN)
    using hash;

alter table performance_schema.table_handles
    add primary key (OBJECT_INSTANCE_BEGIN) using hash;

