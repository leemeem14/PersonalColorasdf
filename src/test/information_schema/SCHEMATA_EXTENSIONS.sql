create view information_schema.SCHEMATA_EXTENSIONS as
select `cat`.`name`                           AS `CATALOG_NAME`,
       `sch`.`name`                           AS `SCHEMA_NAME`,
       get_dd_schema_options(`sch`.`options`) AS `OPTIONS`
from (`schemata` `sch` join `catalogs` `cat` on ((`cat`.`id` = `sch`.`catalog_id`)))
where (0 <> can_access_database(`sch`.`name`));

