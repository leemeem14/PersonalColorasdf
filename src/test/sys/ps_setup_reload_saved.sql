create
    definer = `mysql.sys`@localhost procedure sys.ps_setup_reload_saved() comment '
Description
-----------

Reloads a saved Performance Schema configuration,
so that you can alter the setup for debugging purposes, 
but restore it to a previous state.

Use the companion procedure - ps_setup_save(), to 
save a configuration.

Requires the SUPER privilege for "SET sql_log_bin = 0;".

Parameters
-----------

None.

Example
-----------

mysql> CALL sys.ps_setup_save();
Query OK, 0 rows affected (0.08 sec)

mysql> UPDATE performance_schema.setup_instruments SET enabled = ''YES'', timed = ''YES'';
Query OK, 547 rows affected (0.40 sec)
Rows matched: 784  Changed: 547  Warnings: 0

/* Run some tests that need more detailed instrumentation here */

mysql> CALL sys.ps_setup_reload_saved();
Query OK, 0 rows affected (0.32 sec)
' sql security invoker modifies sql data
-- missing source code
;

