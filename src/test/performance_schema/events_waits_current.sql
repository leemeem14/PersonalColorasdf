create table performance_schema.events_waits_current
(
    THREAD_ID             bigint unsigned                                    not null,
    EVENT_ID              bigint unsigned                                    not null,
    END_EVENT_ID          bigint unsigned                                    null,
    EVENT_NAME            varchar(128)                                       not null,
    SOURCE                varchar(64)                                        null,
    TIMER_START           bigint unsigned                                    null,
    TIMER_END             bigint unsigned                                    null,
    TIMER_WAIT            bigint unsigned                                    null,
    SPINS                 int unsigned                                       null,
    OBJECT_SCHEMA         varchar(64)                                        null,
    OBJECT_NAME           varchar(512)                                       null,
    INDEX_NAME            varchar(64)                                        null,
    OBJECT_TYPE           varchar(64)                                        null,
    OBJECT_INSTANCE_BEGIN bigint unsigned                                    not null,
    NESTING_EVENT_ID      bigint unsigned                                    null,
    NESTING_EVENT_TYPE    enum ('TRANSACTION', 'STATEMENT', 'STAGE', 'WAIT') null,
    OPERATION             varchar(32)                                        not null,
    NUMBER_OF_BYTES       bigint                                             null,
    FLAGS                 int unsigned                                       null
);

create unique index `PRIMARY`
    on performance_schema.events_waits_current (THREAD_ID, EVENT_ID)
    using hash;

alter table performance_schema.events_waits_current
    add primary key (THREAD_ID, EVENT_ID) using hash;

