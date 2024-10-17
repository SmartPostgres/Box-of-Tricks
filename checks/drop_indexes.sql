--drop function drop_indexes;

CREATE OR REPLACE FUNCTION drop_indexes (
    v_schema_name TEXT,
    v_table_name TEXT,
    v_drop_primary_keys BOOLEAN DEFAULT FALSE,
    v_force_drop_with_constraints BOOLEAN DEFAULT FALSE,
    v_drop_concurrently BOOLEAN DEFAULT FALSE,
    v_list_indexes_being_dropped BOOLEAN DEFAULT FALSE,
    v_print_drops_but_dont_execute BOOLEAN DEFAULT FALSE) 
RETURNS TABLE (
    status TEXT,
    index_being_dropped TEXT,
    drop_index_query TEXT
)
LANGUAGE PLPGSQL
AS
$$
DECLARE
    sql_to_execute TEXT;
DECLARE
    Status TEXT;
BEGIN
    /*Begin by testing parameters
     *Remove these checks if the expected workflow allows for NULL
     *All code below will be written with NULL in mind as it should be safe
     *  that way you can remove these checks if null should be a valid option
     */
    IF v_schema_name IS NULL THEN
        Status := COALESCE(Status, '') || CASE WHEN COALESCE(Status, '') != '' THEN '|' ELSE 'ERROR: ' END || 'Schema Name MUST be passed in';
    END IF;
    IF v_table_name IS NULL THEN
        Status := COALESCE(Status, '') || CASE WHEN COALESCE(Status, '') != '' THEN '|' ELSE 'ERROR: ' END || 'Table Name MUST be passed in';
    END IF;
    IF v_print_drops_but_dont_execute = TRUE AND v_list_indexes_being_dropped = FALSE THEN
        Status := COALESCE(Status, '') || CASE WHEN COALESCE(Status, '') != '' THEN '|' ELSE 'ERROR: ' END || 'If printing DROP Statements indexes MUST be listed';
        --Optional Alternative if instead of a message we just want to fix this case
        --v_list_indexes_being_dropped = TRUE
    END IF;
    IF v_print_drops_but_dont_execute = FALSE AND v_drop_concurrently = TRUE THEN
        Status := COALESCE(Status, '') || CASE WHEN COALESCE(Status, '') != '' THEN '|' ELSE 'ERROR: ' END || 
            'CONCURRENTLY cannot run inside of a transaction block. Set v_print_drops_but_dont_execute to run the statements manually';
    END IF;
    --End Parameter sanitization

    DROP TABLE IF EXISTS temp_indexes_to_drop;
    CREATE TEMPORARY TABLE temp_indexes_to_drop (
        index_being_dropped TEXT,
        drop_index_query TEXT,
        execute_status TEXT
    );

    --Only start querying if we are not in an error state
    IF COALESCE(Status, '') NOT LIKE '%ERROR%' THEN
        sql_to_execute := '
        INSERT INTO temp_indexes_to_drop (index_being_dropped, drop_index_query)
        SELECT quote_ident(nm.nspname) || ''.'' || quote_ident(c_tbl.relname) || ''.'' || quote_ident(c_idx.relname),
            CASE 
                WHEN i.indisprimary = TRUE OR c.oid IS NOT NULL THEN 
                    ''ALTER TABLE '' || quote_ident(nm.nspname) || ''.'' || quote_ident(c_tbl.relname) || '' DROP CONSTRAINT '' || quote_ident(c_idx.relname) || 
                    CASE WHEN ' || v_force_drop_with_constraints || ' = TRUE THEN '' CASCADE'' ELSE '''' END
                ELSE 
                    ''DROP INDEX '' || 
                    CASE WHEN ' || v_drop_concurrently || ' = TRUE THEN ''CONCURRENTLY '' ELSE '''' END || 
					quote_ident(nm.nspname) || ''.'' ||
                    quote_ident(c_idx.relname) || 
                    CASE WHEN ' || v_force_drop_with_constraints || ' = TRUE THEN '' CASCADE'' ELSE '''' END
              END || '';''
        FROM pg_catalog.pg_class c_tbl
        JOIN pg_catalog.pg_namespace nm 
            ON c_tbl.relnamespace = nm.oid
        JOIN pg_catalog.pg_index i 
            ON c_tbl.oid = i.indrelid
                AND (i.indisprimary = FALSE OR i.indisprimary = ' || v_drop_primary_keys || ')
        JOIN pg_catalog.pg_class c_idx
            ON i.indexrelid = c_idx.oid
        LEFT JOIN pg_constraint c 
            ON i.indexrelid = c.conindid
        WHERE (nm.nspname = ' || COALESCE(quote_literal(v_schema_name), 'nm.nspname') || ')
            AND (c_tbl.relname = ' || COALESCE(quote_literal(v_table_name), 'c_tbl.relname') || ');';
    
        EXECUTE sql_to_execute;
    END IF;

    IF v_print_drops_but_dont_execute = FALSE THEN
        FOR sql_to_execute IN
            SELECT ti.drop_index_query
            FROM temp_indexes_to_drop ti
        LOOP
            BEGIN
                EXECUTE sql_to_execute;

                UPDATE temp_indexes_to_drop AS ti
                SET execute_status = 'Success'
                WHERE ti.drop_index_query = sql_to_execute;
            EXCEPTION
                WHEN OTHERS THEN
                    UPDATE temp_indexes_to_drop AS ti
                    SET execute_status = SQLERRM
                    WHERE ti.drop_index_query = sql_to_execute;
            END;
        END LOOP;
    END IF;


    RETURN QUERY
    SELECT DISTINCT COALESCE(CASE WHEN v_print_drops_but_dont_execute = TRUE AND t_indexes.index_being_dropped != '' THEN 'PRINT ONLY' END, execute_status, 'Success') status, 
        t_indexes.index_being_dropped,
        t_indexes.drop_index_query
    FROM (
        SELECT execute_status, ti.index_being_dropped, ti.drop_index_query
        FROM temp_indexes_to_drop ti
        WHERE execute_status != 'Success' --We will always display errors even if not listing
            OR v_list_indexes_being_dropped = TRUE
        --Union to ensure we get at least one row even when the table is empty or we are not listing
        UNION
        SELECT Status AS execute_status, NULL index_being_dropped, NULL drop_index_query
        WHERE NOT EXISTS (
            SELECT 1 FROM temp_indexes_to_drop 
            WHERE execute_status != 'Success' 
                OR v_list_indexes_being_dropped = TRUE)
        ) t_indexes;

    DROP TABLE IF EXISTS temp_indexes_to_drop;
END;
$$;