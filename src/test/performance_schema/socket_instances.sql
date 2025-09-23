create table performance_schema.socket_instances
(
    EVENT_NAME            varchar(128)            not null,
    OBJECT_INSTANCE_BEGIN bigint unsigned         not null,
    THREAD_ID             bigint unsigned         null,
    SOCKET_ID             int                     not null,
    IP                    varchar(64)             not null,
    PORT                  int                     not null,
    STATE                 enum ('IDLE', 'ACTIVE') not null
);

create index IP
    on performance_schema.socket_instances (IP, PORT)
    using hash;

create unique index `PRIMARY`
    on performance_schema.socket_instances (OBJECT_INSTANCE_BEGIN)
    using hash;

create index SOCKET_ID
    on performance_schema.socket_instances (SOCKET_ID)
    using hash;

create index THREAD_ID
    on performance_schema.socket_instances (THREAD_ID)
    using hash;

alter table performance_schema.socket_instances
    add primary key (OBJECT_INSTANCE_BEGIN) using hash;

