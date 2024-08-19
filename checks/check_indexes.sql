create or replace function check_indexes (
	database_name varchar,
	schema_name varchar,
	table_name varchar
)
language plpgsql
as $$
begin 
	
SELECT
	nm.nspname AS schema_name,
	c_tbl.relname AS table_name,
	c_ix.relname AS index_name,
	am.amname AS index_type,
	ix.indexdef,
	pg_size_pretty(pg_relation_size(i.indexrelid)) AS index_size,
	indisunique AS is_unique,
	indisprimary AS is_primary,
	--idx_scan AS number_of_scans,
	--idx_tup_read AS tuples_read,
	--idx_tup_fetch AS tuples_fetched,
	stat.last_vacuum AS last_manual_vacuum,
	stat.last_autovacuum AS last_auto_vacuum,
	stat.last_analyze AS last_manual_analyze,
	stat.last_autoanalyze AS last_auto_analyze,
	stat.n_ins_since_vacuum,
	stat.n_live_tup AS tbl_n_live_tup,
	stat.n_dead_tup AS tbl_n_dead_tup,
	stat.n_mod_since_analyze AS tbl_n_mod_since_analyze,
	c_tbl.oid AS table_oid,
	c_ix.oid AS index_oid
FROM
	pg_catalog.pg_index i
JOIN
    pg_catalog.pg_class c_ix ON
	c_ix.oid = i.indexrelid
JOIN pg_catalog.pg_class c_tbl ON
	i.indrelid = c_tbl.oid
JOIN pg_catalog.pg_namespace nm ON
	c_tbl.relnamespace = nm.oid
JOIN pg_catalog.pg_indexes ix ON
	nm.nspname = ix.schemaname
	AND c_tbl.relname = ix.tablename
	AND c_ix.relname = ix.indexname
JOIN
    pg_catalog.pg_am am ON
	am.oid = c_ix.relam
left outer JOIN
    pg_catalog.pg_stat_all_indexes psai ON
	psai.indexrelid = i.indexrelid
LEFT outer JOIN
    pg_catalog.pg_stat_user_tables stat ON
	stat.relid = i.indrelid
WHERE
	c_tbl.relname = 'users'
ORDER BY
	nm.nspname,
	c_tbl.relname,
	c_ix.relname;
	

end;$$;
