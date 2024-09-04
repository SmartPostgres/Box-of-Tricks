create or replace function check_indexes (
	v_schema_name varchar,
	v_table_name varchar
)
returns table (schema_name varchar, table_name varchar, index_name varchar, index_type varchar,
	index_definition varchar, size_kb integer, estimated_tuples_from_pg_class_reltuples integer,
	estimated_tuples_as_of timestamp with time zone, is_unique boolean, is_primary boolean,
	table_oid integer, index_oid integer)
language plpgsql
as $$
begin

create temporary table ci_indexes
	(schema_name varchar, table_name varchar, index_name varchar, index_type varchar,
	index_definition varchar, size_kb integer, estimated_tuples_from_pg_class_reltuples integer,
	estimated_tuples_as_of timestamp with time zone, is_unique boolean, is_primary boolean,
	table_oid integer, index_oid integer, relkind char);

/* Tables & materialized views */
insert into ci_indexes
	(schema_name, table_name, index_name, index_type,
	index_definition, size_kb, estimated_tuples_from_pg_class_reltuples,
	estimated_tuples_as_of, is_unique, is_primary,
	table_oid, index_oid, relkind)
select
	nm.nspname as schema_name,
	c_tbl.relname as table_name,
	NULL as index_name,
	case c_tbl.relkind
		when 'r' then 'ordinary table'
		when 'S' then 'sequence'
		when 't' then 'TOAST table'
		when 'v' then 'view' 
		when 'm' then 'materialized view' 
		when 'c' then 'composite type' 
		when 'f' then 'foreign table' 
		when 'p' then 'partitioned table'
		else 'unknown'	end as index_type,
	NULL as index_definition,
	pg_relation_size(c_tbl.oid) / 1024.0 as size_kb,
	c_tbl.reltuples as estimated_tuples_from_pg_class_reltuples,
	greatest(stat.last_vacuum, stat.last_autovacuum, stat.last_analyze, stat.last_autoanalyze) as estimated_tuples_as_of,
	CAST(null as boolean) as is_unique,
	CAST(null as boolean) as is_primary,
	/* When we implement a Warnings column, these will be useful for diagnosing vacuum & analyze issues
	stat.n_ins_since_vacuum,
	stat.n_live_tup as tbl_n_live_tup,
	stat.n_dead_tup as tbl_n_dead_tup,
	stat.n_mod_since_analyze as tbl_n_mod_since_analyze,
	NULL AS number_of_scans,
	NULL AS tuples_read,
	NULL AS tuples_fetched, */
	c_tbl.oid as table_oid,
	cast(null as integer) as index_oid,
	c_tbl.relkind
from
	pg_catalog.pg_class c_tbl
join pg_catalog.pg_namespace nm on
	c_tbl.relnamespace = nm.oid
left outer join
    pg_catalog.pg_stat_user_tables stat on
	stat.relid = c_tbl.oid
where
	/* c_tbl.relname = 'toast_big_data' and */
	nm.nspname in ('duplicate', 'public')
	and c_tbl.relkind not in ('i', 'I', 't');	

/* TOAST Tables */
insert into ci_indexes
	(schema_name, table_name, index_name, index_type,
	index_definition, size_kb, estimated_tuples_from_pg_class_reltuples,
	estimated_tuples_as_of, is_unique, is_primary,
	table_oid, index_oid, relkind)
select
	nm.nspname as schema_name,
	c_tbl.relname as table_name,
	c_toast_tbl.relname as index_name,
	'toast' as index_type,
	NULL as index_definition,
	pg_relation_size(c_toast_tbl.oid) / 1024.0 as size_kb,
	null as estimated_tuples_from_pg_class_reltuples,
	null as estimated_tuples_as_of,
	NULL as is_unique,
	NULL as is_primary,
	/* When we implement a Warnings column, these will be useful for diagnosing vacuum & analyze issues
	stat.n_ins_since_vacuum,
	stat.n_live_tup as tbl_n_live_tup,
	stat.n_dead_tup as tbl_n_dead_tup,
	stat.n_mod_since_analyze as tbl_n_mod_since_analyze,
	idx_scan AS number_of_scans,
	idx_tup_read AS tuples_read,
	idx_tup_fetch AS tuples_fetched, */
	c_tbl.oid as table_oid,
	c_toast_tbl.oid as index_oid,
	c_toast_tbl.relkind as relkind
from
	pg_catalog.pg_class c_tbl
join pg_catalog.pg_namespace nm on
	c_tbl.relnamespace = nm.oid
join 
	pg_catalog.pg_class c_toast_tbl
	on c_tbl.reltoastrelid = c_toast_tbl.oid
where
	/* c_tbl.relname = 'toast_big_data' and */
	nm.nspname in ('duplicate', 'public')
	and c_tbl.relkind not in ('i', 'I');	
	
/* Indexes */
insert into ci_indexes
	(schema_name, table_name, index_name, index_type,
	index_definition, size_kb, estimated_tuples_from_pg_class_reltuples,
	estimated_tuples_as_of, is_unique, is_primary,
	table_oid, index_oid, relkind)
select
	nm.nspname as schema_name,
	c_tbl.relname as table_name,
	c_ix.relname as index_name,
	am.amname as index_type,
	pg_get_indexdef(c_ix.oid) as index_definition,
	pg_relation_size(i.indexrelid) / 1024.0 as size_kb,
	coalesce(c_ix.reltuples, c_tbl.reltuples) as estimated_tuples_from_pg_class_reltuples,
	greatest(stat.last_vacuum, stat.last_autovacuum, stat.last_analyze, stat.last_autoanalyze) as estimated_tuples_as_of,
	indisunique as is_unique,
	indisprimary as is_primary,
	/* When we implement a Warnings column, these will be useful for diagnosing vacuum & analyze issues
	stat.n_ins_since_vacuum,
	stat.n_live_tup as tbl_n_live_tup,
	stat.n_dead_tup as tbl_n_dead_tup,
	stat.n_mod_since_analyze as tbl_n_mod_since_analyze,
	idx_scan AS number_of_scans,
	idx_tup_read AS tuples_read,
	idx_tup_fetch AS tuples_fetched, */
	c_tbl.oid as table_oid,
	c_ix.oid as index_oid,
	c_ix.relkind
from
	pg_catalog.pg_class c_tbl
join pg_catalog.pg_namespace nm on
	c_tbl.relnamespace = nm.oid
join 
	pg_catalog.pg_index i on
	c_tbl.oid = i.indrelid
join
    pg_catalog.pg_class c_ix on
	i.indexrelid = c_ix.oid
left outer join
    pg_catalog.pg_am am on
	am.oid = c_ix.relam
left outer join
    pg_catalog.pg_stat_all_indexes psai on
	psai.indexrelid = i.indexrelid
left outer join
    pg_catalog.pg_stat_user_tables stat on
	stat.relid = i.indrelid
where
	/* c_tbl.relname = 'toast_big_data' and */
	nm.nspname in ('duplicate', 'public')
	and c_tbl.relkind not in ('i', 'I');
	
return query
	select ci.schema_name, ci.table_name, ci.index_name, ci.index_type,
	ci.index_definition, ci.size_kb, ci.estimated_tuples_from_pg_class_reltuples,
	ci.estimated_tuples_as_of, ci.is_unique, ci.is_primary,
	ci.table_oid, ci.index_oid
	from ci_indexes ci
	order by 1, 2, 3;


drop table ci_indexes;
end;
$$;