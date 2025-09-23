create view information_schema.VIEWS as
select `cat`.`name`                                                                      AS `TABLE_CATALOG`,
       `sch`.`name`                                                                      AS `TABLE_SCHEMA`,
       `vw`.`name`                                                                       AS `TABLE_NAME`,
       if((can_access_view(`sch`.`name`, `vw`.`name`, `vw`.`view_definer`, `vw`.`options`) = true),
          `vw`.`view_definition_utf8`, '')                                               AS `VIEW_DEFINITION`,
       `vw`.`view_check_option`                                                          AS `CHECK_OPTION`,
       `vw`.`view_is_updatable`                                                          AS `IS_UPDATABLE`,
       `vw`.`view_definer`                                                               AS `DEFINER`,
       if((`vw`.`view_security_type` = 'DEFAULT'), 'DEFINER', `vw`.`view_security_type`) AS `SECURITY_TYPE`,
       `cs`.`name`                                                                       AS `CHARACTER_SET_CLIENT`,
       `conn_coll`.`name`                                                                AS `COLLATION_CONNECTION`
from (((((`tables` `vw` join `schemata` `sch` on ((`vw`.`schema_id` = `sch`.`id`))) join `catalogs` `cat`
         on ((`cat`.`id` = `sch`.`catalog_id`))) join `collations` `conn_coll`
        on ((`conn_coll`.`id` = `vw`.`view_connection_collation_id`))) join `collations` `client_coll`
       on ((`client_coll`.`id` = `vw`.`view_client_collation_id`))) join `character_sets` `cs`
      on ((`cs`.`id` = `client_coll`.`character_set_id`)))
where ((0 <> can_access_table(`sch`.`name`, `vw`.`name`)) and (`vw`.`type` = 'VIEW'));

