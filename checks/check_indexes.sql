--drop function check_indexes;


CREATE OR REPLACE FUNCTION check_indexes (
    v_schema_name VARCHAR,
    v_table_name VARCHAR,
    v_warning_format VARCHAR default 'rows'
)
RETURNS TABLE (
    schema_name TEXT,
    table_name TEXT,
    index_name TEXT,
    index_type VARCHAR,
    index_definition VARCHAR,
    size_kb INTEGER,
    estimated_tuples INTEGER,
    estimated_tuples_as_of TIMESTAMPTZ,
    dead_tuples INTEGER,
    last_autovacuum TIMESTAMPTZ,
    last_manual_nonfull_vacuum TIMESTAMPTZ,
    is_unique BOOLEAN,
    is_primary BOOLEAN,
    table_oid INTEGER,
    index_oid INTEGER,
    priority INTEGER, 
    warning_summary VARCHAR,
    warning_details VARCHAR,
    url VARCHAR,
    drop_object_command VARCHAR
)
LANGUAGE plpgsql
AS $$
DECLARE
    sql_to_execute TEXT;
BEGIN
    CREATE TEMPORARY TABLE ci_indexes
    (
        schema_name VARCHAR,
        table_name VARCHAR,
        index_name VARCHAR,
        index_type VARCHAR,
        index_definition VARCHAR,
        size_kb INTEGER,
        estimated_tuples INTEGER,
        estimated_tuples_as_of TIMESTAMPTZ,
		dead_tuples INTEGER,
        is_unique BOOLEAN,
        is_primary BOOLEAN,
        table_oid INTEGER,
        index_oid INTEGER,
        relkind CHAR,
		reltoastrelid INTEGER,
		n_mod_since_analyze BIGINT,
		n_ins_since_vacuum BIGINT,
		last_autovacuum TIMESTAMPTZ,
		last_manual_nonfull_vacuum TIMESTAMPTZ,
		last_analyze TIMESTAMPTZ,
		last_autoanalyze TIMESTAMPTZ,
		drop_object_command VARCHAR
    );

	CREATE TEMPORARY TABLE ci_indexes_warnings
	(
		table_oid INTEGER,
		index_oid INTEGER,
		priority INTEGER,
		warning_summary VARCHAR,
		warning_details VARCHAR,
		url VARCHAR
	);




    -- Build SQL for Tables & Materialized Views
    sql_to_execute := '
    INSERT INTO ci_indexes (schema_name, table_name, index_name, index_type, index_definition, size_kb, estimated_tuples, estimated_tuples_as_of, 
		dead_tuples, is_unique, is_primary, table_oid, index_oid, relkind, reltoastrelid, 
		n_mod_since_analyze, n_ins_since_vacuum, last_manual_nonfull_vacuum, last_autovacuum, last_analyze, last_autoanalyze)
    SELECT
        nm.nspname AS schema_name,
        c_tbl.relname AS table_name,
        NULL AS index_name,
        CASE c_tbl.relkind
            WHEN ''r'' THEN ''ordinary table''
            WHEN ''S'' THEN ''sequence''
            WHEN ''t'' THEN ''TOAST table''
            WHEN ''v'' THEN ''view'' 
            WHEN ''m'' THEN ''materialized view'' 
            WHEN ''c'' THEN ''composite type'' 
            WHEN ''f'' THEN ''foreign table'' 
            WHEN ''p'' THEN ''partitioned table''
            ELSE ''unknown''
        END AS index_type,
        NULL AS index_definition,
        pg_relation_size(c_tbl.oid) / 1024.0 AS size_kb,
        GREATEST(c_tbl.reltuples, 0) AS estimated_tuples,
        GREATEST(stat.last_vacuum, stat.last_autovacuum, stat.last_analyze, stat.last_autoanalyze) AS estimated_tuples_as_of,
        stat.n_dead_tup AS dead_tuples,
		CAST(NULL AS BOOLEAN) AS is_unique,
        CAST(NULL AS BOOLEAN) AS is_primary,
        c_tbl.oid AS table_oid,
        CAST(NULL AS INTEGER) AS index_oid,
		c_tbl.relkind,
        c_tbl.reltoastrelid,
		stat.n_mod_since_analyze, stat.n_ins_since_vacuum, stat.last_vacuum, stat.last_autovacuum, stat.last_analyze, stat.last_autoanalyze
    FROM
        pg_catalog.pg_class c_tbl
    JOIN pg_catalog.pg_namespace nm ON
        c_tbl.relnamespace = nm.oid
    LEFT JOIN
        pg_catalog.pg_stat_user_tables stat ON
        stat.relid = c_tbl.oid
    WHERE
        (nm.nspname = ' || COALESCE(quote_literal(v_schema_name), 'nm.nspname') || ')
        AND (c_tbl.relname = ' || COALESCE(quote_literal(v_table_name), 'c_tbl.relname') || ')
        AND c_tbl.relkind NOT IN (''i'', ''I'', ''t'');';

    EXECUTE sql_to_execute;


    -- Build SQL for TOAST Tables
    sql_to_execute := '
    INSERT INTO ci_indexes (schema_name, table_name, index_name, index_type, index_definition, size_kb, estimated_tuples, estimated_tuples_as_of, dead_tuples, is_unique, is_primary, table_oid, index_oid, relkind)
    SELECT
        c_tbl.schema_name AS schema_name,
        c_tbl.table_name AS table_name,
        c_toast_tbl.relname AS index_name,
        ''toast'' AS index_type,
        NULL AS index_definition,
        pg_relation_size(c_toast_tbl.oid) / 1024.0 AS size_kb,
        NULL AS estimated_tuples,
        NULL AS estimated_tuples_as_of,
		NULL AS dead_tuples,
        NULL AS is_unique,
        NULL AS is_primary,
        c_tbl.table_oid AS table_oid,
        c_toast_tbl.oid AS index_oid,
        c_toast_tbl.relkind AS relkind
    FROM
        ci_indexes c_tbl
    JOIN 
        pg_catalog.pg_class c_toast_tbl
        ON c_tbl.reltoastrelid = c_toast_tbl.oid
	WHERE c_tbl.relkind NOT IN (''i'', ''I'', ''t'');';

    EXECUTE sql_to_execute;

    -- Build SQL for the underlying ordinary tables of the partitioned tables
    sql_to_execute := '
    INSERT INTO ci_indexes (schema_name, table_name, index_name, index_type, index_definition, size_kb, estimated_tuples, estimated_tuples_as_of, 
		is_unique, is_primary, table_oid, index_oid, relkind, reltoastrelid, 
		n_mod_since_analyze, n_ins_since_vacuum, last_manual_nonfull_vacuum, last_autovacuum, last_analyze, last_autoanalyze)
    SELECT
        nm.nspname AS schema_name,
        c_tbl.relname AS table_name,
        NULL AS index_name,
        CASE c_tbl.relkind
            WHEN ''r'' THEN ''ordinary table''
            WHEN ''S'' THEN ''sequence''
            WHEN ''t'' THEN ''TOAST table''
            WHEN ''v'' THEN ''view'' 
            WHEN ''m'' THEN ''materialized view'' 
            WHEN ''c'' THEN ''composite type'' 
            WHEN ''f'' THEN ''foreign table'' 
            WHEN ''p'' THEN ''partitioned table''
            ELSE ''unknown''
        END AS index_type,
        NULL AS index_definition,
        pg_relation_size(c_tbl.oid) / 1024.0 AS size_kb,
        GREATEST(c_tbl.reltuples, 0) AS estimated_tuples,
        GREATEST(stat.last_vacuum, stat.last_autovacuum, stat.last_analyze, stat.last_autoanalyze) AS estimated_tuples_as_of,
        CAST(NULL AS BOOLEAN) AS is_unique,
        CAST(NULL AS BOOLEAN) AS is_primary,
        c_tbl.oid AS table_oid,
        CAST(NULL AS INTEGER) AS index_oid,
		c_tbl.relkind,
        c_tbl.reltoastrelid,
		stat.n_mod_since_analyze, stat.n_ins_since_vacuum, stat.last_vacuum, stat.last_autovacuum, stat.last_analyze, stat.last_autoanalyze
    FROM pg_catalog.pg_inherits inh 
    JOIN pg_catalog.pg_class c_tbl ON inh.inhrelid = c_tbl.oid
    JOIN pg_catalog.pg_namespace nm ON
        c_tbl.relnamespace = nm.oid
    LEFT JOIN
        pg_catalog.pg_stat_user_tables stat ON
        stat.relid = c_tbl.oid
	WHERE c_tbl.relkind NOT IN (''i'', ''I'', ''t'')
    AND EXISTS (SELECT 1 FROM ci_indexes WHERE inhparent = table_oid)         --Only add in the inheritents of a table you are looking at already
    AND NOT EXISTS (SELECT 1 FROM ci_indexes WHERE c_tbl.oid = table_oid);';  --Don't add it in twice if you asked for null and got all tables above

    EXECUTE sql_to_execute;


    -- Build SQL for Indexes
    sql_to_execute := '
    INSERT INTO ci_indexes (schema_name, table_name, index_name, index_type, index_definition, size_kb, estimated_tuples, estimated_tuples_as_of, 
		dead_tuples, last_autovacuum, last_manual_nonfull_vacuum, is_unique, is_primary, table_oid, index_oid, relkind)
    SELECT
        c_tbl.schema_name AS schema_name,
        c_tbl.table_name AS table_name,
        c_ix.relname AS index_name,
        am.amname AS index_type,
        pg_get_indexdef(c_ix.oid) || '';'' AS index_definition,
        pg_relation_size(c_ix.oid) / 1024.0 AS size_kb,
        GREATEST(COALESCE(c_ix.reltuples, c_tbl.estimated_tuples, 0), 0) AS estimated_tuples,
        GREATEST(stat.last_vacuum, stat.last_autovacuum, stat.last_analyze, stat.last_autoanalyze) AS estimated_tuples_as_of,
        c_tbl.dead_tuples,
		stat.last_autovacuum,
		stat.last_vacuum,
        indisunique AS is_unique,
        indisprimary AS is_primary,
        c_tbl.table_oid AS table_oid,
        c_ix.oid AS index_oid,
        c_ix.relkind
    FROM
        ci_indexes c_tbl
    JOIN 
        pg_catalog.pg_index i ON
        c_tbl.table_oid = i.indrelid
    JOIN
        pg_catalog.pg_class c_ix ON
        i.indexrelid = c_ix.oid
    LEFT JOIN
        pg_catalog.pg_am am ON
        am.oid = c_ix.relam
    LEFT JOIN
        pg_catalog.pg_stat_all_indexes psai ON
        psai.indexrelid = i.indexrelid
    LEFT JOIN
        pg_catalog.pg_stat_user_tables stat ON
        stat.relid = i.indrelid
	WHERE c_tbl.relkind NOT IN (''i'', ''I'', ''t'');';

    EXECUTE sql_to_execute;

	-- Update partitioned index data to include all child indexes and tables
	UPDATE ci_indexes tbl
		SET size_kb = child.size_kb,
			estimated_tuples = CASE WHEN tbl.estimated_tuples <= 0
			                                                THEN child.reltuples
			                                                ELSE tbl.estimated_tuples END,
			dead_tuples = CASE WHEN tbl.dead_tuples <= 0
			                                                THEN child.dead_tuples
			                                                ELSE tbl.dead_tuples END
	FROM (SELECT inh.inhparent, SUM(pg_relation_size(child.oid) / 1024.0) AS size_kb,
			SUM(GREATEST(COALESCE(child.reltuples, 0), 0)) AS reltuples,
			SUM(COALESCE(stat.n_dead_tup, 0)) AS dead_tuples
		FROM pg_catalog.pg_inherits inh 
		JOIN pg_catalog.pg_class child ON inh.inhrelid = child.oid
		LEFT OUTER JOIN pg_catalog.pg_stat_user_tables stat ON inh.inhrelid = stat.relid
		GROUP BY inh.inhparent
		) child
	WHERE tbl.relkind IN ('p', 'I')
	  AND tbl.size_kb = 0
	  AND COALESCE(tbl.index_oid, tbl.table_oid) = child.inhparent;

	-- Update partitioned indexes if necessary to match the table's dead_tuples:
	UPDATE ci_indexes ix
		SET dead_tuples = COALESCE(tbl_stats.dead_tuples, 0)
	FROM (SELECT tbl.table_oid, SUM(COALESCE(tbl.dead_tuples, 0)) AS dead_tuples
		FROM ci_indexes tbl
		WHERE tbl.relkind = 'p'
		GROUP BY tbl.table_oid) tbl_stats
	WHERE ix.relkind = 'I'
	  AND ix.table_oid = tbl_stats.table_oid
	  AND ix.dead_tuples <= 0;


	-- Set the drop_object_command column's contents.
	UPDATE ci_indexes ix
		SET drop_object_command = CASE
		    WHEN ix.index_type = 'ordinary table' THEN 'DROP TABLE IF EXISTS ' || quote_ident(ix.schema_name) || '.' || quote_ident(ix.table_name) || '; -- CASCADE ' 
		    WHEN ix.index_type = 'sequence' THEN 'DROP SEQUENCE IF EXISTS ' || quote_ident(ix.schema_name) || '.' || quote_ident(ix.table_name) || '; -- CASCADE ' 
		    WHEN ix.index_type = 'view' THEN 'DROP VIEW IF EXISTS ' || quote_ident(ix.schema_name) || '.' || quote_ident(ix.table_name) || '; -- CASCADE ' 
		    WHEN ix.index_type = 'materialized view' THEN 'DROP MATERIALIZED VIEW IF EXISTS ' || quote_ident(ix.schema_name) || '.' || quote_ident(ix.table_name) || '; -- CASCADE ' 
		    WHEN ix.index_type = 'composite type' THEN 'DROP TYPE IF EXISTS ' || quote_ident(ix.schema_name) || '.' || quote_ident(ix.table_name) || '; -- CASCADE ' 
		    WHEN ix.index_type = 'foreign table' THEN 'DROP FOREIGN TABLE IF EXISTS ' || quote_ident(ix.schema_name) || '.' || quote_ident(ix.table_name) || '; -- CASCADE ' 
		    WHEN ix.index_type = 'partitioned table' THEN 'DROP TABLE IF EXISTS ' || quote_ident(ix.schema_name) || '.' || quote_ident(ix.table_name) || '; -- CASCADE ' 
		    WHEN ix.index_type IN ('brin', 'btree', 'gin', 'gist', 'hash', 'spgist')
		        			THEN 'DROP INDEX IF EXISTS ' || quote_ident(ix.schema_name) || '.' || quote_ident(ix.index_name) || '; -- CASCADE ' 
		    ELSE '' -- Not dropping TOAST tables or unknown types
	END;


	-- Process warnings starting with priority 100, Outdated Statistics.

	INSERT INTO ci_indexes_warnings (table_oid, index_oid, priority, warning_summary, warning_details, url)
	SELECT i.table_oid, i.index_oid, 100, 
		'Outdated Statistics' AS warning_summary,
		'Query plans may have invalid estimates. ' 
			|| i.estimated_tuples::varchar || ' estimated tuples from pg_class.reltuples. ' 
			|| i.n_ins_since_vacuum::varchar || ' tuples ins_since_last_vacuum. ' 
			|| ' last_manual_nonfull_vacuum on ' || COALESCE(i.last_manual_nonfull_vacuum::date::varchar, '(never)')
			|| '. last_autovacuum on ' || COALESCE(i.last_autovacuum::date::varchar, '(never)') || '. '
			|| i.n_mod_since_analyze::varchar || ' mod_since_analyze.' 
			|| ' last_analyze on ' || COALESCE(i.last_analyze::date::varchar, '(never)')
			|| '. last_autoanalyze on ' || COALESCE(i.last_autoanalyze::date::varchar, '(never)') AS warning_details,
	'https://smartpostgres.com/problems/outdated_statistics' AS url
	FROM ci_indexes i
    WHERE ABS(i.estimated_tuples::numeric) * 0.1 < GREATEST(i.n_ins_since_vacuum, i.n_mod_since_analyze);


    -- Return the result set
    RETURN QUERY
    SELECT quote_ident(ci.schema_name) as schema_name, 
			quote_ident(ci.table_name) as table_name,
			quote_ident(ci.index_name) as index_name, 
			ci.index_type, ci.index_definition, ci.size_kb, ci.estimated_tuples,
           ci.estimated_tuples_as_of, 
			ci.dead_tuples, ci.last_autovacuum, ci.last_manual_nonfull_vacuum,
		   ci.is_unique, ci.is_primary,
           ci.table_oid, ci.index_oid,
			w.priority, w.warning_summary, w.warning_details, w.url,
			ci.drop_object_command
    FROM ci_indexes ci
	LEFT OUTER JOIN ci_indexes_warnings w 
		ON ci.table_oid = w.table_oid
		AND (ci.index_oid = w.index_oid OR (ci.index_oid IS NULL AND w.index_oid IS NULL))
    ORDER BY 1, 2, 3, w.priority, w.warning_summary;

    DROP TABLE ci_indexes;
    DROP TABLE ci_indexes_warnings;
END;
$$;