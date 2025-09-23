create
    definer = `mysql.sys`@localhost procedure sys.ps_truncate_all_tables(IN in_verbose tinyint(1)) comment '
Description
-----------

Truncates all summary tables within Performance Schema, 
resetting all aggregated instrumentation as a snapshot.

Parameters
-----------

in_verbose (BOOLEAN):
  Whether to print each TRUNCATE statement before running

Example
-----------

mysql> CALL sys.ps_truncate_all_tables(false);
+---------------------+
| summary             |
+---------------------+
| Truncated 44 tables |
+---------------------+
1 row in set (0.10 sec)

Query OK, 0 rows affected (0.10 sec)
' deterministic sql security invoker modifies sql data
-- missing source code
;

