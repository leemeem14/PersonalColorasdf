create table time_zone_transition
(
    Time_zone_id       int unsigned not null,
    Transition_time    bigint       not null,
    Transition_type_id int unsigned not null,
    primary key (Time_zone_id, Transition_time)
)
    comment 'Time zone transitions' charset = utf8mb3
                                    row_format = DYNAMIC
                                    stats_persistent = 0;

