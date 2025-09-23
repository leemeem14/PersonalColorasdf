create
    definer = `mysql.sys`@localhost procedure sys.diagnostics(IN in_max_runtime int unsigned,
                                                              IN in_interval int unsigned,
                                                              IN in_auto_config enum ('current', 'medium', 'full'))
    comment '
Description
-----------

Create a report of the current status of the server for diagnostics purposes. Data collected includes (some items depends on versions and settings):

   * The GLOBAL VARIABLES
   * Several sys schema views including metrics or equivalent (depending on version and settings)
   * Queries in the 95th percentile
   * Several ndbinfo views for MySQL Cluster
   * Replication (both master and slave) information.

Some of the sys schema views are calculated as initial (optional), overall, delta:

   * The initial view is the content of the view at the start of this procedure.
     This output will be the same as the the start values used for the delta view.
     The initial view is included if @sys.diagnostics.include_raw = ''ON''.
   * The overall view is the content of the view at the end of this procedure.
     This output is the same as the end values used for the delta view.
     The overall view is always included.
   * The delta view is the difference from the beginning to the end. Note that for min and max values
     they are simply the min or max value from the end view respectively, so does not necessarily reflect
     the minimum/maximum value in the monitored period.
     Note: except for the metrics views the delta is only calculation between the first and last outputs.

Requires the SUPER privilege for "SET sql_log_bin = 0;".

Parameters
-----------

in_max_runtime (INT UNSIGNED):
  The maximum time to keep collecting data.
  Use NULL to get the default which is 60 seconds, otherwise enter a value greater than 0.
in_interval (INT UNSIGNED):
  How long to sleep between data collections.
  Use NULL to get the default which is 30 seconds, otherwise enter a value greater than 0.
in_auto_config (ENUM(''current'', ''medium'', ''full''))
  Automatically enable Performance Schema instruments and consumers.
  NOTE: The more that are enabled, the more impact on the performance.
  Supported values are:
     * current - use the current settings.
     * medium - enable some settings. This requires the SUPER privilege.
     * full - enables all settings. This will have a big impact on the
              performance - be careful using this option. This requires
              the SUPER privilege.
  If another setting the ''current'' is chosen, the current settings
  are restored at the end of the procedure.


Configuration Options
----------------------

sys.diagnostics.allow_i_s_tables
  Specifies whether it is allowed to do table scan queries on information_schema.TABLES. This can be expensive if there
  are many tables. Set to ''ON'' to allow, ''OFF'' to not allow.
  Default is ''OFF''.

sys.diagnostics.include_raw
  Set to ''ON'' to include the raw data (e.g. the original output of "SELECT * FROM sys.metrics").
  Use this to get the initial values of the various views.
  Default is ''OFF''.

sys.statement_truncate_len
  How much of queries in the process list output to include.
  Default is 64.

sys.debug
  Whether to provide debugging output.
  Default is ''OFF''. Set to ''ON'' to include.


Example
--------

To create a report and append it to the file diag.out:

mysql> TEE diag.out;
mysql> CALL sys.diagnostics(120, 30, ''current'');
...
mysql> NOTEE;
'
    sql security invoker
    reads sql data
-- missing source code
;

