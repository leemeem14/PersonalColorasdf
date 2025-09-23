create
    definer = `mysql.sys`@localhost procedure sys.ps_setup_reset_to_default(IN in_verbose tinyint(1)) comment '
Description
-----------

Resets the Performance Schema setup to the default settings.

Parameters
-----------

in_verbose (BOOLEAN):
  Whether to print each setup stage (including the SQL) whilst running.

Example
-----------

mysql> CALL sys.ps_setup_reset_to_default(true)\G
*************************** 1. row ***************************
status: Resetting: setup_actors
DELETE
FROM performance_schema.setup_actors
 WHERE NOT (HOST = ''%'' AND USER = ''%'' AND `ROLE` = ''%'')
1 row in set (0.00 sec)

*************************** 1. row ***************************
status: Resetting: setup_actors
INSERT IGNORE INTO performance_schema.setup_actors
VALUES (''%'', ''%'', ''%'')
1 row in set (0.00 sec)
...

mysql> CALL sys.ps_setup_reset_to_default(false)\G
Query OK, 0 rows affected (0.00 sec)
' sql security invoker modifies sql data
-- missing source code
;

