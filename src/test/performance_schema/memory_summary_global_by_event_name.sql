create table performance_schema.memory_summary_global_by_event_name
(
    EVENT_NAME                   varchar(128)    not null,
    COUNT_ALLOC                  bigint unsigned not null,
    COUNT_FREE                   bigint unsigned not null,
    SUM_NUMBER_OF_BYTES_ALLOC    bigint unsigned not null,
    SUM_NUMBER_OF_BYTES_FREE     bigint unsigned not null,
    LOW_COUNT_USED               bigint          not null,
    CURRENT_COUNT_USED           bigint          not null,
    HIGH_COUNT_USED              bigint          not null,
    LOW_NUMBER_OF_BYTES_USED     bigint          not null,
    CURRENT_NUMBER_OF_BYTES_USED bigint          not null,
    HIGH_NUMBER_OF_BYTES_USED    bigint          not null
);

create unique index `PRIMARY`
    on performance_schema.memory_summary_global_by_event_name (EVENT_NAME)
    using hash;

alter table performance_schema.memory_summary_global_by_event_name
    add primary key (EVENT_NAME) using hash;

