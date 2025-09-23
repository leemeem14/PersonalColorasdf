create view information_schema.ST_SPATIAL_REFERENCE_SYSTEMS as
select `st_spatial_reference_systems`.`name`                     AS `SRS_NAME`,
       `st_spatial_reference_systems`.`id`                       AS `SRS_ID`,
       `st_spatial_reference_systems`.`organization`             AS `ORGANIZATION`,
       `st_spatial_reference_systems`.`organization_coordsys_id` AS `ORGANIZATION_COORDSYS_ID`,
       `st_spatial_reference_systems`.`definition`               AS `DEFINITION`,
       `st_spatial_reference_systems`.`description`              AS `DESCRIPTION`
from `st_spatial_reference_systems`;

