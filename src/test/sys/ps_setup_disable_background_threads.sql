create
    definer = `mysql.sys`@localhost procedure sys.ps_setup_disable_background_threads() comment '
Description
-----------

Disable all background thread instrumentation within Performance Schema.

Parameters
-----------

None.

Example
-----------

mysql> CALL sys.ps_setup_disable_background_threads();
+--------------------------------+
| summary                        |
+--------------------------------+
| Disabled 18 background threads |
+--------------------------------+
1 row in set (0.00 sec)
' sql security invoker modifies sql data
-- missing source code
;

