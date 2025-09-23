create view information_schema.VIEW_ROUTINE_USAGE as
select `cat`.`name`            AS `TABLE_CATALOG`,
       `sch`.`name`            AS `TABLE_SCHEMA`,
       `vw`.`name`             AS `TABLE_NAME`,
       `vru`.`routine_catalog` AS `SPECIFIC_CATALOG`,
       `vru`.`routine_schema`  AS `SPECIFIC_SCHEMA`,
       `vru`.`routine_name`    AS `SPECIFIC_NAME`
from ((((`tables` `vw` join `schemata` `sch` on ((`vw`.`schema_id` = `sch`.`id`))) join `catalogs` `cat`
        on ((`cat`.`id` = `sch`.`catalog_id`))) join `view_routine_usage` `vru`
       on ((`vru`.`view_id` = `vw`.`id`))) join `routines` `rtn`
      on (((`vru`.`routine_catalog` = `cat`.`name`) and (`vru`.`routine_schema` = `sch`.`name`) and
           (`vru`.`routine_name` = `rtn`.`name`))))
where ((`vw`.`type` = 'VIEW') and
       (0 <> can_access_routine(`vru`.`routine_schema`, `vru`.`routine_name`, `rtn`.`type`, `rtn`.`definer`, false)) and
       (0 <> can_access_view(`sch`.`name`, `vw`.`name`, `vw`.`view_definer`, `vw`.`options`)));

