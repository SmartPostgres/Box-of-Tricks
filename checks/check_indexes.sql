CREATE OR REPLACE FUNCTION check_indexes (
    v_schema_name VARCHAR,
    v_table_name VARCHAR
)
RETURNS TABLE (
    schema_name VARCHAR,
    table_name VARCHAR,
    index_name VARCHAR,
    index_type VARCHAR,
    index_definition VARCHAR,
    size_kb INTEGER,
    estimated_tuples_from_pg_class_reltuples INTEGER,
    estimated_tuples_as_of TIMESTAMPTZ,
    is_unique BOOLEAN,
    is_primary BOOLEAN,
    table_oid INTEGER,
    index_oid INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
    sql_tables_views TEXT;
    sql_toast_tables TEXT;
    sql_indexes TEXT;
BEGIN
    CREATE TEMPORARY TABLE ci_indexes
    (
        schema_name VARCHAR,
        table_name VARCHAR,
        index_name VARCHAR,
        index_type VARCHAR,
        index_definition VARCHAR,
        size_kb INTEGER,
        estimated_tuples_from_pg_class_reltuples INTEGER,
        estimated_tuples_as_of TIMESTAMPTZ,
        is_unique BOOLEAN,
        is_primary BOOLEAN,
        table_oid INTEGER,
        index_oid INTEGER,
        relkind CHAR
    );

    -- Build SQL for Tables & Materialized Views
    sql_tables_views := '
    INSERT INTO ci_indexes (schema_name, table_name, index_name, index_type, index_definition, size_kb, estimated_tuples_from_pg_class_reltuples, estimated_tuples_as_of, is_unique, is_primary, table_oid, index_oid, relkind)
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
        c_tbl.reltuples AS estimated_tuples_from_pg_class_reltuples,
        GREATEST(stat.last_vacuum, stat.last_autovacuum, stat.last_analyze, stat.last_autoanalyze) AS estimated_tuples_as_of,
        CAST(NULL AS BOOLEAN) AS is_unique,
        CAST(NULL AS BOOLEAN) AS is_primary,
        c_tbl.oid AS table_oid,
        CAST(NULL AS INTEGER) AS index_oid,
        c_tbl.relkind
    FROM
        pg_catalog.pg_class c_tbl
    JOIN pg_catalog.pg_namespace nm ON
        c_tbl.relnamespace = nm.oid
    LEFT JOIN
        pg_catalog.pg_stat_user_tables stat ON
        stat.relid = c_tbl.oid
    WHERE
        nm.nspname IN (''duplicate'', ''public'')
        AND c_tbl.relkind NOT IN (''i'', ''I'', ''t'');';

    -- Build SQL for TOAST Tables
    sql_toast_tables := '
    INSERT INTO ci_indexes (schema_name, table_name, index_name, index_type, index_definition, size_kb, estimated_tuples_from_pg_class_reltuples, estimated_tuples_as_of, is_unique, is_primary, table_oid, index_oid, relkind)
    SELECT
        nm.nspname AS schema_name,
        c_tbl.relname AS table_name,
        c_toast_tbl.relname AS index_name,
        ''toast'' AS index_type,
        NULL AS index_definition,
        pg_relation_size(c_toast_tbl.oid) / 1024.0 AS size_kb,
        NULL AS estimated_tuples_from_pg_class_reltuples,
        NULL AS estimated_tuples_as_of,
        NULL AS is_unique,
        NULL AS is_primary,
        c_tbl.oid AS table_oid,
        c_toast_tbl.oid AS index_oid,
        c_toast_tbl.relkind AS relkind
    FROM
        pg_catalog.pg_class c_tbl
    JOIN pg_catalog.pg_namespace nm ON
        c_tbl.relnamespace = nm.oid
    JOIN 
        pg_catalog.pg_class c_toast_tbl
        ON c_tbl.reltoastrelid = c_toast_tbl.oid
    WHERE
        nm.nspname IN (''duplicate'', ''public'')
        AND c_tbl.relkind NOT IN (''i'', ''I'');';

    -- Build SQL for Indexes
    sql_indexes := '
    INSERT INTO ci_indexes (schema_name, table_name, index_name, index_type, index_definition, size_kb, estimated_tuples_from_pg_class_reltuples, estimated_tuples_as_of, is_unique, is_primary, table_oid, index_oid, relkind)
    SELECT
        nm.nspname AS schema_name,
        c_tbl.relname AS table_name,
        c_ix.relname AS index_name,
        am.amname AS index_type,
        pg_get_indexdef(c_ix.oid) AS index_definition,
        pg_relation_size(i.indexrelid) / 1024.0 AS size_kb,
        COALESCE(c_ix.reltuples, c_tbl.reltuples) AS estimated_tuples_from_pg_class_reltuples,
        GREATEST(stat.last_vacuum, stat.last_autovacuum, stat.last_analyze, stat.last_autoanalyze) AS estimated_tuples_as_of,
        indisunique AS is_unique,
        indisprimary AS is_primary,
        c_tbl.oid AS table_oid,
        c_ix.oid AS index_oid,
        c_ix.relkind
    FROM
        pg_catalog.pg_class c_tbl
    JOIN pg_catalog.pg_namespace nm ON
        c_tbl.relnamespace = nm.oid
    JOIN 
        pg_catalog.pg_index i ON
        c_tbl.oid = i.indrelid
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
    WHERE
        nm.nspname IN (''duplicate'', ''public'')
        AND c_tbl.relkind NOT IN (''i'', ''I'');';

    -- Execute the dynamically built SQL statements
    EXECUTE sql_tables_views;
    EXECUTE sql_toast_tables;
    EXECUTE sql_indexes;

    -- Return the result set
    RETURN QUERY
    SELECT ci.schema_name, ci.table_name, ci.index_name, ci.index_type,
           ci.index_definition, ci.size_kb, ci.estimated_tuples_from_pg_class_reltuples,
           ci.estimated_tuples_as_of, ci.is_unique, ci.is_primary,
           ci.table_oid, ci.index_oid
    FROM ci_indexes ci
    ORDER BY 1, 2, 3;

    DROP TABLE ci_indexes;
END;
$$;
