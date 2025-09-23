create
    definer = `mysql.sys`@localhost procedure sys.statement_performance_analyzer(IN in_action enum ('snapshot', 'overall', 'delta', 'create_table', 'create_tmp', 'save', 'cleanup'),
                                                                                 IN in_table varchar(129),
                                                                                 IN in_views set ('with_runtimes_in_95th_percentile', 'analysis', 'with_errors_or_warnings', 'with_full_table_scans', 'with_sorting', 'with_temp_tables', 'custom'))
    comment '
Description
-----------

Create a report of the statements running on the server.

The views are calculated based on the overall and/or delta activity.

Requires the SUPER privilege for "SET sql_log_bin = 0;".

Parameters
-----------

in_action (ENUM(''snapshot'', ''overall'', ''delta'', ''create_tmp'', ''create_table'', ''save'', ''cleanup'')):
  The action to take. Supported actions are:
    * snapshot      Store a snapshot. The default is to make a snapshot of the current content of
                    performance_schema.events_statements_summary_by_digest, but by setting in_table
                    this can be overwritten to copy the content of the specified table.
                    The snapshot is stored in the sys.tmp_digests temporary table.
    * overall       Generate analyzis based on the content specified by in_table. For the overall analyzis,
                    in_table can be NOW() to use a fresh snapshot. This will overwrite an existing snapshot.
                    Use NULL for in_table to use the existing snapshot. If in_table IS NULL and no snapshot
                    exists, a new will be created.
                    See also in_views and @sys.statement_performance_analyzer.limit.
    * delta         Generate a delta analysis. The delta will be calculated between the reference table in
                    in_table and the snapshot. An existing snapshot must exist.
                    The action uses the sys.tmp_digests_delta temporary table.
                    See also in_views and @sys.statement_performance_analyzer.limit.
    * create_table  Create a regular table suitable for storing the snapshot for later use, e.g. for
                    calculating deltas.
    * create_tmp    Create a temporary table suitable for storing the snapshot for later use, e.g. for
                    calculating deltas.
    * save          Save the snapshot in the table specified by in_table. The table must exists and have
                    the correct structure.
                    If no snapshot exists, a new is created.
    * cleanup       Remove the temporary tables used for the snapshot and delta.

in_table (VARCHAR(129)):
  The table argument used for some actions. Use the format ''db1.t1'' or ''t1'' without using any backticks (`)
  for quoting. Periods (.) are not supported in the database and table names.

  The meaning of the table for each action supporting the argument is:

    * snapshot      The snapshot is created based on the specified table. Set to NULL or NOW() to use
                    the current content of performance_schema.events_statements_summary_by_digest.
    * overall       The table with the content to create the overall analyzis for. The following values
                    can be used:
                      - A table name - use the content of that table.
                      - NOW()        - create a fresh snapshot and overwrite the existing snapshot.
                      - NULL         - use the last stored snapshot.
    * delta         The table name is mandatory and specified the reference view to compare the currently
                    stored snapshot against. If no snapshot exists, a new will be created.
    * create_table  The name of the regular table to create.
    * create_tmp    The name of the temporary table to create.
    * save          The name of the table to save the currently stored snapshot into.

in_views (SET (''with_runtimes_in_95th_percentile'', ''analysis'', ''with_errors_or_warnings'',
               ''with_full_table_scans'', ''with_sorting'', ''with_temp_tables'', ''custom''))
  Which views to include:

    * with_runtimes_in_95th_percentile  Based on the sys.statements_with_runtimes_in_95th_percentile view
    * analysis                          Based on the sys.statement_analysis view
    * with_errors_or_warnings           Based on the sys.statements_with_errors_or_warnings view
    * with_full_table_scans             Based on the sys.statements_with_full_table_scans view
    * with_sorting                      Based on the sys.statements_with_sorting view
    * with_temp_tables                  Based on the sys.statements_with_temp_tables view
    * custom                            Use a custom view. This view must be specified in @sys.statement_performance_analyzer.view to an existing view or a query

Default is to include all except ''custom''.


Configuration Options
----------------------

sys.statement_performance_analyzer.limit
  The maximum number of rows to include for the views that does not have a built-in limit (e.g. the 95th percentile view).
  If not set the limit is 100.

sys.statement_performance_analyzer.view
  Used together with the ''custom'' view. If the value contains a space, it is considered a query, otherwise it must be
  an existing view querying the performance_schema.events_statements_summary_by_digest table. There cannot be any limit
  clause including in the query or view definition if @sys.statement_performance_analyzer.limit > 0.
  If specifying a view, use the same format as for in_table.

sys.debug
  Whether to provide debugging output.
  Default is ''OFF''. Set to ''ON'' to include.


Example
--------

To create a report with the queries in the 95th percentile since last truncate of performance_schema.events_statements_summary_by_digest
and the delta for a 1 minute period:

   1. Create a temporary table to store the initial snapshot.
   2. Create the initial snapshot.
   3. Save the initial snapshot in the temporary table.
   4. Wait one minute.
   5. Create a new snapshot.
   6. Perform analyzis based on the new snapshot.
   7. Perform analyzis based on the delta between the initial and new snapshots.

mysql> CALL sys.statement_performance_analyzer(''create_tmp'', ''mydb.tmp_digests_ini'', NULL);
Query OK, 0 rows affected (0.08 sec)

mysql> CALL sys.statement_performance_analyzer(''snapshot'', NULL, NULL);
Query OK, 0 rows affected (0.02 sec)

mysql> CALL sys.statement_performance_analyzer(''save'', ''mydb.tmp_digests_ini'', NULL);
Query OK, 0 rows affected (0.00 sec)

mysql> DO SLEEP(60);
Query OK, 0 rows affected (1 min 0.00 sec)

mysql> CALL sys.statement_performance_analyzer(''snapshot'', NULL, NULL);
Query OK, 0 rows affected (0.02 sec)

mysql> CALL sys.statement_performance_analyzer(''overall'', NULL, ''with_runtimes_in_95th_percentile'');
+-----------------------------------------+
| Next Output                             |
+-----------------------------------------+
| Queries with Runtime in 95th Percentile |
+-----------------------------------------+
1 row in set (0.05 sec)

...

mysql> CALL sys.statement_performance_analyzer(''delta'', ''mydb.tmp_digests_ini'', ''with_runtimes_in_95th_percentile'');
+-----------------------------------------+
| Next Output                             |
+-----------------------------------------+
| Queries with Runtime in 95th Percentile |
+-----------------------------------------+
1 row in set (0.03 sec)

...


To create an overall report of the 95th percentile queries and the top 10 queries with full table scans:

mysql> CALL sys.statement_performance_analyzer(''snapshot'', NULL, NULL);
Query OK, 0 rows affected (0.01 sec)

mysql> SET @sys.statement_performance_analyzer.limit = 10;
Query OK, 0 rows affected (0.00 sec)

mysql> CALL sys.statement_performance_analyzer(''overall'', NULL, ''with_runtimes_in_95th_percentile,with_full_table_scans'');
+-----------------------------------------+
| Next Output                             |
+-----------------------------------------+
| Queries with Runtime in 95th Percentile |
+-----------------------------------------+
1 row in set (0.01 sec)

...

+-------------------------------------+
| Next Output                         |
+-------------------------------------+
| Top 10 Queries with Full Table Scan |
+-------------------------------------+
1 row in set (0.09 sec)

...


Use a custom view showing the top 10 query sorted by total execution time refreshing the view every minute using
the watch command in Linux.

mysql> CREATE OR REPLACE VIEW mydb.my_statements AS
    -> SELECT sys.format_statement(DIGEST_TEXT) AS query,
    ->        SCHEMA_NAME AS db,
    ->        COUNT_STAR AS exec_count,
    ->        format_pico_time(SUM_TIMER_WAIT) AS total_latency,
    ->        format_pico_time(AVG_TIMER_WAIT) AS avg_latency,
    ->        ROUND(IFNULL(SUM_ROWS_SENT / NULLIF(COUNT_STAR, 0), 0)) AS rows_sent_avg,
    ->        ROUND(IFNULL(SUM_ROWS_EXAMINED / NULLIF(COUNT_STAR, 0), 0)) AS rows_examined_avg,
    ->        ROUND(IFNULL(SUM_ROWS_AFFECTED / NULLIF(COUNT_STAR, 0), 0)) AS rows_affected_avg,
    ->        DIGEST AS digest
    ->   FROM performance_schema.events_statements_summary_by_digest
    -> ORDER BY SUM_TIMER_WAIT DESC;
Query OK, 0 rows affected (0.01 sec)

mysql> CALL sys.statement_performance_analyzer(''create_table'', ''mydb.digests_prev'', NULL);
Query OK, 0 rows affected (0.10 sec)

shell$ watch -n 60 "mysql sys --table -e "
> SET @sys.statement_performance_analyzer.view = ''mydb.my_statements'';
> SET @sys.statement_performance_analyzer.limit = 10;
> CALL statement_performance_analyzer(''snapshot'', NULL, NULL);
> CALL statement_performance_analyzer(''delta'', ''mydb.digests_prev'', ''custom'');
> CALL statement_performance_analyzer(''save'', ''mydb.digests_prev'', NULL);
> ""

Every 60.0s: mysql sys --table -e "                                                                                                   ...  Mon Dec 22 10:58:51 2014

+----------------------------------+
| Next Output                      |
+----------------------------------+
| Top 10 Queries Using Custom View |
+----------------------------------+
+-------------------+-------+------------+---------------+-------------+---------------+-------------------+-------------------+----------------------------------+
| query             | db    | exec_count | total_latency | avg_latency | rows_sent_avg | rows_examined_avg | rows_affected_avg | digest                           |
+-------------------+-------+------------+---------------+-------------+---------------+-------------------+-------------------+----------------------------------+
...
'
    sql security invoker
-- missing source code
;

