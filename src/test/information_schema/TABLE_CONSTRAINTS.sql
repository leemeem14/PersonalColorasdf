create view information_schema.TABLE_CONSTRAINTS as
select `cat`.`name`                    AS `CONSTRAINT_CATALOG`,
       `sch`.`name`                    AS `CONSTRAINT_SCHEMA`,
       `constraints`.`CONSTRAINT_NAME` AS `CONSTRAINT_NAME`,
       `sch`.`name`                    AS `TABLE_SCHEMA`,
       `tbl`.`name`                    AS `TABLE_NAME`,
       `constraints`.`CONSTRAINT_TYPE` AS `CONSTRAINT_TYPE`,
       `constraints`.`ENFORCED`        AS `ENFORCED`
from (((`tables` `tbl` join `schemata` `sch` on ((`tbl`.`schema_id` = `sch`.`id`))) join `catalogs` `cat`
       on ((`cat`.`id` = `sch`.`catalog_id`))) join lateral (select `idx`.`name`                                                AS `CONSTRAINT_NAME`,
                                                                    if((`idx`.`type` = 'PRIMARY'), 'PRIMARY KEY', `idx`.`type`) AS `CONSTRAINT_TYPE`,
                                                                    'YES'                                                       AS `ENFORCED`
                                                             from `indexes` `idx`
                                                             where ((`idx`.`table_id` = `tbl`.`id`) and
                                                                    (`idx`.`type` in ('PRIMARY', 'UNIQUE')) and (0 <>
                                                                                                                 is_visible_dd_object(
                                                                                                                         `tbl`.`hidden`,
                                                                                                                         `idx`.`hidden`,
                                                                                                                         `idx`.`options`)))
                                                             union all
                                                             select (`fk`.`name` collate utf8mb3_tolower_ci) AS `CONSTRAINT_NAME`,
                                                                    'FOREIGN KEY'                            AS `CONSTRAINT_TYPE`,
                                                                    'YES'                                    AS `ENFORCED`
                                                             from `foreign_keys` `fk`
                                                             where (`fk`.`table_id` = `tbl`.`id`)
                                                             union all
                                                             select `cc`.`name`     AS `CONSTRAINT_NAME`,
                                                                    'CHECK'         AS `CONSTRAINT_TYPE`,
                                                                    `cc`.`enforced` AS `ENFORCED`
                                                             from `check_constraints` `cc`
                                                             where (`cc`.`table_id` = `tbl`.`id`)) `constraints`)
where ((0 <> can_access_table(`sch`.`name`, `tbl`.`name`)) and (0 <> is_visible_dd_object(`tbl`.`hidden`)));

