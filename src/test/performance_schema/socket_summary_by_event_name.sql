create table performance_schema.socket_summary_by_event_name
(
    EVENT_NAME                varchar(128)    not null,
    COUNT_STAR                bigint unsigned not null,
    SUM_TIMER_WAIT            bigint unsigned not null,
    MIN_TIMER_WAIT            bigint unsigned not null,
    AVG_TIMER_WAIT            bigint unsigned not null,
    MAX_TIMER_WAIT            bigint unsigned not null,
    COUNT_READ                bigint unsigned not null,
    SUM_TIMER_READ            bigint unsigned not null,
    MIN_TIMER_READ            bigint unsigned not null,
    AVG_TIMER_READ            bigint unsigned not null,
    MAX_TIMER_READ            bigint unsigned not null,
    SUM_NUMBER_OF_BYTES_READ  bigint unsigned not null,
    COUNT_WRITE               bigint unsigned not null,
    SUM_TIMER_WRITE           bigint unsigned not null,
    MIN_TIMER_WRITE           bigint unsigned not null,
    AVG_TIMER_WRITE           bigint unsigned not null,
    MAX_TIMER_WRITE           bigint unsigned not null,
    SUM_NUMBER_OF_BYTES_WRITE bigint unsigned not null,
    COUNT_MISC                bigint unsigned not null,
    SUM_TIMER_MISC            bigint unsigned not null,
    MIN_TIMER_MISC            bigint unsigned not null,
    AVG_TIMER_MISC            bigint unsigned not null,
    MAX_TIMER_MISC            bigint unsigned not null
);

create unique index `PRIMARY`
    on performance_schema.socket_summary_by_event_name (EVENT_NAME)
    using hash;

alter table performance_schema.socket_summary_by_event_name
    add primary key (EVENT_NAME) using hash;

