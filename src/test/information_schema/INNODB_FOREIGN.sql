create view information_schema.INNODB_FOREIGN as
select concat(`sch`.`name`, '/', `fk`.`name`)                                                            AS `ID`,
       concat(`sch`.`name`, '/', `tbl`.`name`)                                                           AS `FOR_NAME`,
       concat(`fk`.`referenced_table_schema`, '/', `fk`.`referenced_table_name`)                         AS `REF_NAME`,
       count(0)                                                                                          AS `N_COLS`,
       (((((if((`fk`.`delete_rule` = 'CASCADE'), 1, 0) | if((`fk`.`delete_rule` = 'SET NULL'), 2, 0)) |
           if((`fk`.`update_rule` = 'CASCADE'), 4, 0)) | if((`fk`.`update_rule` = 'SET NULL'), 8, 0)) |
         if((`fk`.`delete_rule` = 'NO ACTION'), 16, 0)) | if((`fk`.`update_rule` = 'NO ACTION'), 32, 0)) AS `TYPE`
from (((`foreign_keys` `fk` join `tables` `tbl` on ((`fk`.`table_id` = `tbl`.`id`))) join `schemata` `sch`
       on ((`fk`.`schema_id` = `sch`.`id`))) join `foreign_key_column_usage` `col`
      on ((`fk`.`id` = `col`.`foreign_key_id`)))
where ((`tbl`.`type` <> 'VIEW') and (`tbl`.`hidden` = 'Visible') and (`tbl`.`se_private_id` is not null) and
       (`tbl`.`engine` = 'INNODB'))
group by `fk`.`id`;

