
BEGIN
    -- 1. TABLE STRUCTURE
    RETURN QUERY
    SELECT 
        'table_structure'::TEXT as section_name,
        'metadata'::TEXT as section_type,
        jsonb_agg(
            jsonb_build_object(
                'column_name', cols.column_name,
                'data_type', cols.data_type,
                'character_maximum_length', cols.character_maximum_length,
                'is_nullable', cols.is_nullable,
                'column_default', cols.column_default,
                'ordinal_position', cols.ordinal_position
            )
        ) as result_json
    FROM information_schema.columns cols
    WHERE cols.table_name = table_name_param 
        AND cols.table_schema = 'public';

    -- 2. CONSTRAINTS
    RETURN QUERY
    SELECT 
        'constraints'::TEXT as section_name,
        'metadata'::TEXT as section_type,
        jsonb_agg(
            jsonb_build_object(
                'constraint_name', tc.constraint_name,
                'constraint_type', tc.constraint_type,
                'column_name', kcu.column_name
            )
        ) as result_json
    FROM information_schema.table_constraints tc
    JOIN information_schema.key_column_usage kcu 
        ON tc.constraint_name = kcu.constraint_name
    WHERE tc.table_name = table_name_param 
        AND tc.table_schema = 'public';

    -- 3. FOREIGN KEYS
    RETURN QUERY
    SELECT 
        'foreign_keys'::TEXT as section_name,
        'metadata'::TEXT as section_type,
        jsonb_agg(
            jsonb_build_object(
                'constraint_name', tc.constraint_name,
                'foreign_key_column', kcu.column_name,
                'referenced_table', ccu.table_name,
                'referenced_column', ccu.column_name
            )
        ) as result_json
    FROM information_schema.table_constraints tc
    JOIN information_schema.key_column_usage kcu 
        ON tc.constraint_name = kcu.constraint_name
    JOIN information_schema.constraint_column_usage ccu 
        ON ccu.constraint_name = tc.constraint_name
    WHERE tc.table_name = table_name_param 
        AND tc.table_schema = 'public'
        AND tc.constraint_type = 'FOREIGN KEY';

    -- 4. INDEXES
    RETURN QUERY
    SELECT 
        'indexes'::TEXT as section_name,
        'metadata'::TEXT as section_type,
        jsonb_agg(
            jsonb_build_object(
                'index_name', indexname,
                'index_definition', indexdef
            )
        ) as result_json
    FROM pg_indexes 
    WHERE tablename = table_name_param 
        AND schemaname = 'public';

    -- 5. TABLE STATISTICS
    RETURN QUERY
    SELECT 
        'table_statistics'::TEXT as section_name,
        'metadata'::TEXT as section_type,
        to_jsonb(stats) as result_json
    FROM (
        SELECT 
            schemaname,
            relname as tablename,
            n_tup_ins as total_inserts,
            n_tup_upd as total_updates,
            n_tup_del as total_deletes,
            n_tup_ins - n_tup_del as estimated_current_rows,
            last_vacuum,
            last_autovacuum,
            last_analyze,
            last_autoanalyze
        FROM pg_stat_user_tables 
        WHERE relname = table_name_param
    ) stats;

    -- 6. EXACT ROW COUNT
    RETURN QUERY
    EXECUTE format('
        SELECT 
            ''row_count''::TEXT as section_name,
            ''metadata''::TEXT as section_type,
            jsonb_build_object(''exact_row_count'', COUNT(*)) as result_json
        FROM %I
    ', table_name_param);

    -- 7. TABLE SIZE
    RETURN QUERY
    EXECUTE format('
        SELECT 
            ''table_size''::TEXT as section_name,
            ''metadata''::TEXT as section_type,
            jsonb_build_object(
                ''total_size'', pg_size_pretty(pg_total_relation_size(%L)),
                ''table_size'', pg_size_pretty(pg_relation_size(%L)),
                ''index_size'', pg_size_pretty(pg_total_relation_size(%L) - pg_relation_size(%L))
            ) as result_json
    ', table_name_param, table_name_param, table_name_param, table_name_param);

    -- 8. RLS INFORMATION
    RETURN QUERY
    SELECT 
        'rls_status'::TEXT as section_name,
        'security'::TEXT as section_type,
        jsonb_build_object(
            'rls_enabled', rowsecurity,
            'schema_name', schemaname,
            'table_name', tablename
        ) as result_json
    FROM pg_tables 
    WHERE tablename = table_name_param 
        AND schemaname = 'public';

    -- 9. RLS POLICIES
    RETURN QUERY
    SELECT 
        'rls_policies'::TEXT as section_name,
        'security'::TEXT as section_type,
        jsonb_agg(
            jsonb_build_object(
                'policy_name', policyname,
                'permissive', permissive,
                'roles', roles,
                'command', cmd,
                'qual', qual,
                'with_check', with_check
            )
        ) as result_json
    FROM pg_policies 
    WHERE tablename = table_name_param 
        AND schemaname = 'public';

    -- 10. CHILD TABLES (tables that reference this table)
    RETURN QUERY
    SELECT 
        'child_tables'::TEXT as section_name,
        'relationships'::TEXT as section_type,
        jsonb_agg(
            jsonb_build_object(
                'referencing_table', tc.table_name,
                'referencing_column', kcu.column_name,
                'referenced_column_in_target', ccu.column_name
            )
        ) as result_json
    FROM information_schema.table_constraints tc
    JOIN information_schema.key_column_usage kcu 
        ON tc.constraint_name = kcu.constraint_name
    JOIN information_schema.constraint_column_usage ccu 
        ON ccu.constraint_name = tc.constraint_name
    WHERE ccu.table_name = table_name_param 
        AND tc.constraint_type = 'FOREIGN KEY'
        AND tc.table_schema = 'public';

    -- 11. PARENT TABLES (tables that this table references)
    RETURN QUERY
    SELECT 
        'parent_tables'::TEXT as section_name,
        'relationships'::TEXT as section_type,
        jsonb_agg(
            jsonb_build_object(
                'referenced_table', ccu.table_name,
                'referenced_column', ccu.column_name,
                'referencing_column_in_target', kcu.column_name
            )
        ) as result_json
    FROM information_schema.table_constraints tc
    JOIN information_schema.key_column_usage kcu 
        ON tc.constraint_name = kcu.constraint_name
    JOIN information_schema.constraint_column_usage ccu 
        ON ccu.constraint_name = tc.constraint_name
    WHERE tc.table_name = table_name_param 
        AND tc.constraint_type = 'FOREIGN KEY'
        AND tc.table_schema = 'public';

    -- 12. ALL TABLE DATA (be careful with large tables!)
    RETURN QUERY
    EXECUTE format('
        SELECT 
            ''all_data''::TEXT as section_name,
            ''data''::TEXT as section_type,
            jsonb_agg(to_jsonb(t.*)) as result_json
        FROM %I t
    ', table_name_param);

END;
