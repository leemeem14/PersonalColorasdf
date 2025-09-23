create
    definer = `mysql.sys`@localhost procedure sys.ps_setup_enable_background_threads() comment '
Description
-----------

Enable all background thread instrumentation within Performance Schema.

Parameters
-----------

None.

Example
-----------

mysql> CALL sys.ps_setup_enable_background_threads();
+-------------------------------+
| summary                       |
+-------------------------------+
| Enabled 18 background threads |
+-------------------------------+
1 row in set (0.00 sec)
' sql security invoker modifies sql data
-- missing source code
;

