create
    definer = `mysql.sys`@localhost procedure sys.ps_setup_show_enabled_instruments() comment '
Description
-----------

Shows all currently enabled instruments.

Parameters
-----------

None

Example
-----------

mysql> CALL sys.ps_setup_show_enabled_instruments();
' deterministic sql security invoker reads sql data
-- missing source code
;

