create view information_schema.INNODB_FIELDS as
select get_dd_index_private_data(`idx`.`se_private_data`, 'id') AS `INDEX_ID`,
       `col`.`name`                                             AS `NAME`,
       (`fld`.`ordinal_position` - 1)                           AS `POS`
from (((`index_column_usage` `fld` join `columns` `col` on ((`fld`.`column_id` = `col`.`id`))) join `indexes` `idx`
       on ((`fld`.`index_id` = `idx`.`id`))) join `tables` `tbl` on ((`tbl`.`id` = `idx`.`table_id`)))
where ((`tbl`.`type` <> 'VIEW') and (`tbl`.`hidden` = 'Visible') and (0 = `fld`.`hidden`) and
       (`tbl`.`se_private_id` is not null) and (`tbl`.`engine` = 'INNODB'));

