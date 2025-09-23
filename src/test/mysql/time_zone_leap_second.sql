create table time_zone_leap_second
(
    Transition_time bigint not null
        primary key,
    Correction      int    not null
)
    comment 'Leap seconds information for time zones' charset = utf8mb3
                                                      row_format = DYNAMIC
                                                      stats_persistent = 0;

