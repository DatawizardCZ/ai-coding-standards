# Database Table Documentation Generator

A comprehensive system for automatically generating professional markdown documentation from database metadata JSON files. Transform raw database analysis into readable, maintainable documentation that serves both technical and business stakeholders.

## 🚀 Quick Start

1. **Install the PostgreSQL function** in your database (see [Installation](#-installation))
2. **Generate metadata** for any table: `SELECT * FROM get_table_documentation('your_table_name');`
3. **Copy the JSON output** and use it with an AI assistant following our instructions
4. **Get professional markdown documentation** in seconds!

```sql
-- Example: Generate docs for a 'users' table
SELECT * FROM get_table_documentation('users');
```

## 📋 Table of Contents

- [Features](#-features)
- [Installation](#-installation)
- [Input Format](#-input-format)
- [Usage](#-usage)
- [Output Structure](#-output-structure)
- [Examples](#-examples)
- [Best Practices](#-best-practices)
- [Troubleshooting](#-troubleshooting)
- [Contributing](#-contributing)

## ✨ Features

- **Comprehensive Analysis**: Processes table structure, constraints, indexes, relationships, and sample data
- **Business Context Inference**: Automatically detects domain patterns and business rules
- **Security Documentation**: Analyzes RLS policies and security considerations
- **Performance Insights**: Documents indexing strategies and optimization opportunities
- **Relationship Mapping**: Clear parent/child table relationships
- **SQL Examples**: Generates practical usage examples
- **Professional Output**: Clean, structured markdown suitable for technical documentation

## 🔧 Installation

### Prerequisites
- PostgreSQL database (9.5+)
- Appropriate database permissions to create functions
- Access to `information_schema` and `pg_*` system catalogs

### Step 1: Create the Documentation Function

Execute the following SQL in your PostgreSQL database:

```sql
CREATE OR REPLACE FUNCTION get_table_documentation(table_name_param TEXT)
RETURNS TABLE(
    section_name TEXT,
    section_type TEXT,
    result_json JSONB
)
LANGUAGE plpgsql
AS $
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
$;
```

### Step 2: Test the Installation

```sql
-- Test with a simple table
SELECT section_name, section_type FROM get_table_documentation('your_table_name');

-- Generate complete documentation
SELECT * FROM get_table_documentation('your_table_name');
```

### Step 3: Handle Large Tables (Optional)

For tables with many rows, consider creating a modified version that limits sample data:

```sql
-- Create a version that limits sample data to 100 rows
CREATE OR REPLACE FUNCTION get_table_documentation_sample(
    table_name_param TEXT, 
    sample_limit INTEGER DEFAULT 100
)
-- ... (same function but modify the last query to include LIMIT)
```

## 📊 Input Format

The system uses a PostgreSQL function that automatically generates JSON in the expected format:

```sql
-- Generate metadata for any table
SELECT * FROM get_table_documentation('table_name');
```

The function returns a table with these columns:
- `section_name`: Identifies the type of metadata  
- `section_type`: Category (metadata, security, relationships, data)
- `result_json`: The actual data content in JSONB format

### Generated Sections

The `get_table_documentation()` function automatically generates all these sections:

| Section Name | Type | Description |
|--------------|------|-------------|
| `table_structure` | metadata | Column definitions and data types |
| `constraints` | metadata | Primary keys, unique constraints, foreign keys |
| `foreign_keys` | metadata | Detailed foreign key relationships |
| `indexes` | metadata | Index definitions |
| `table_statistics` | metadata | Usage and maintenance statistics |
| `row_count` | metadata | Current table row count |
| `table_size` | metadata | Storage size information |
| `rls_status` | security | Row Level Security configuration |
| `rls_policies` | security | RLS policy details (if any) |
| `child_tables` | relationships | Tables referencing this table |
| `parent_tables` | relationships | Tables this table references |
| `all_data` | data | Complete table data (⚠️ **Warning**: Can be large!)

## 🛠️ Usage

## 🛠️ Usage

### Method 1: Complete Workflow (Recommended)

**Step 1: Generate JSON metadata**
```sql
-- For small-medium tables (< 10,000 rows)
SELECT * FROM get_table_documentation('roles');

-- For large tables, consider data sampling
SELECT * FROM get_table_documentation('users') 
WHERE section_name != 'all_data'
UNION ALL
SELECT 'all_data', 'data', jsonb_agg(to_jsonb(t.*))
FROM (SELECT * FROM users LIMIT 100) t;
```

**Step 2: Copy JSON output and use with AI**
```
I have PostgreSQL table metadata. Please generate comprehensive markdown documentation using the provided instructions.

[Paste the JSON array output here]
```

**Step 3: Get instant documentation**
The AI assistant will generate professional markdown documentation following the template.

### Method 2: Automated Approach

**Shell Script Example:**
```bash
#!/bin/bash
TABLE_NAME=$1
DB_CONNECTION="postgresql://user:pass@localhost/dbname"

# Generate JSON
psql $DB_CONNECTION -c "
SELECT json_agg(
    json_build_object(
        'section_name', section_name,
        'section_type', section_type, 
        'result_json', result_json
    )
) FROM get_table_documentation('$TABLE_NAME');
" -t > "${TABLE_NAME}_metadata.json"

echo "Generated ${TABLE_NAME}_metadata.json"
echo "Now use this with your AI assistant to generate documentation."
```

### Method 3: Programmatic Integration

**Python Example:**
```python
import psycopg2
import json

def generate_table_docs(table_name, connection_string):
    conn = psycopg2.connect(connection_string)
    cursor = conn.cursor()
    
    query = """
    SELECT json_agg(
        json_build_object(
            'section_name', section_name,
            'section_type', section_type,
            'result_json', result_json
        )
    ) FROM get_table_documentation(%s);
    """
    
    cursor.execute(query, (table_name,))
    result = cursor.fetchone()[0]
    
    return json.dumps(result, indent=2)

# Usage
metadata_json = generate_table_docs('roles', 'postgresql://...')
print("Copy this JSON to your AI assistant:")
print(metadata_json)
```

## 📄 Output Structure

The generated documentation follows this structure:

```markdown
# [Table Name] Table Documentation

## Overview
Basic table information and statistics

## Table Schema
Complete column definitions table

## Constraints
Primary keys, unique constraints, foreign keys

## Indexes
Performance optimization documentation

## Relationships
Parent and child table mappings

## [Business Domain] System (if applicable)
Domain-specific analysis (e.g., permissions, hierarchies)

## Security Considerations
RLS status and security recommendations

## Usage Examples
Practical SQL examples

## Maintenance Notes
Performance and maintenance insights
```

## 📝 Examples

### Example: Complete Roles Table Analysis

**Input:**
```sql
SELECT * FROM get_table_documentation('roles');
```

**Output:** (Abbreviated JSON)
```json
[
  {
    "section_name": "table_structure",
    "section_type": "metadata", 
    "result_json": [
      {
        "column_name": "id",
        "data_type": "uuid",
        "is_nullable": "NO",
        "column_default": "gen_random_uuid()"
      }
    ]
  },
  {
    "section_name": "all_data",
    "section_type": "data",
    "result_json": [
      {
        "id": "730ba0ee-56c3-43e2-a66f-75e289962b84",
        "name": "owner",
        "level": 100,
        "permissions": ["*"]
      }
    ]
  }
]
```

### Example Output

See [example-output.md](examples/roles-table-docs.md) for a complete generated documentation example.

## 🎯 Best Practices

### Data Collection

- **Use the provided PostgreSQL function** for consistent metadata extraction
- **Be cautious with large tables** - the `all_data` section includes ALL rows
- **Test on small tables first** to understand the output format
- **Consider creating a sample version** for tables with >10,000 rows

### Large Table Handling

**Option 1: Exclude all_data section**
```sql
SELECT * FROM get_table_documentation('large_table') 
WHERE section_name != 'all_data';
```

**Option 2: Sample data**
```sql
-- Get everything except all_data, then add sample
SELECT * FROM get_table_documentation('large_table') 
WHERE section_name != 'all_data'
UNION ALL
SELECT 'all_data'::TEXT, 'data'::TEXT, 
       jsonb_agg(to_jsonb(t.*))
FROM (SELECT * FROM large_table LIMIT 50) t;
```

**Option 3: Create a sampling function**
```sql
CREATE OR REPLACE FUNCTION get_table_documentation_with_sample(
    table_name_param TEXT, 
    sample_size INTEGER DEFAULT 100
)
-- Modify the original function to limit the final query
```

### Documentation Generation

- **Review generated content** for accuracy and completeness
- **Add custom sections** for domain-specific requirements
- **Update examples** to match your specific use cases
- **Maintain consistency** across multiple table documentations

### Maintenance

- **Regenerate documentation** when schema changes occur
- **Update sample data** to reflect current business rules
- **Review security sections** regularly
- **Keep examples current** with application usage patterns

## 🔧 Troubleshooting

### Common Issues

**Function Not Found**
```
Issue: get_table_documentation() function doesn't exist
Solution: Install the function using the SQL in the Installation section
```

**No Data Returned**
```
Issue: Function returns empty results
Solution: Check table name spelling, ensure table is in 'public' schema
```

**Large Table Performance**
```
Issue: Function hangs on large tables
Solution: Use sampling approach or exclude all_data section
```

**Permission Errors**
```
Issue: Cannot access system catalogs
Solution: Grant appropriate permissions or run as superuser
```

### Validation Checklist

- [ ] PostgreSQL function is installed and working
- [ ] Table name exists and is accessible
- [ ] Function returns all expected sections
- [ ] JSON output is valid and complete
- [ ] No sensitive information in sample data
- [ ] Table size is reasonable for full data extraction

## 🏗️ PostgreSQL Function Details

### Function Signature
```sql
get_table_documentation(table_name_param TEXT)
RETURNS TABLE(section_name TEXT, section_type TEXT, result_json JSONB)
```

### What It Analyzes

1. **Table Structure** - All columns with data types, constraints, defaults
2. **Constraints** - Primary keys, unique constraints, foreign keys  
3. **Foreign Key Details** - Complete relationship mappings
4. **Indexes** - All indexes with their definitions
5. **Statistics** - Usage stats from `pg_stat_user_tables`
6. **Row Count** - Exact current row count
7. **Storage Size** - Table, index, and total sizes
8. **Security** - Row Level Security status and policies
9. **Relationships** - Parent and child table mappings
10. **Data** - Complete table contents (⚠️ **Use carefully**)

### Customization Options

**Schema Support:**
Currently hardcoded to `public` schema. To support other schemas:
```sql
-- Modify the function to accept schema parameter
CREATE OR REPLACE FUNCTION get_table_documentation(
    table_name_param TEXT,
    schema_name_param TEXT DEFAULT 'public'
)
-- Then update all WHERE clauses to use schema_name_param
```

**Performance Optimization:**
```sql
-- Create an optimized version for large tables
CREATE OR REPLACE FUNCTION get_table_documentation_fast(
    table_name_param TEXT,
    include_data BOOLEAN DEFAULT FALSE,
    data_limit INTEGER DEFAULT 100
)
-- Include conditional logic for the all_data section
```

## 📚 File Structure

```
database-docs-generator/
├── README.md                          # This file
├── ai-instructions.md                 # Detailed AI processing instructions
├── sql/
│   ├── get_table_documentation.sql   # Main PostgreSQL function
│   ├── get_table_documentation_sample.sql # Version with sampling
│   └── install.sql                   # Installation script
├── examples/
│   ├── input-sample.json            # Example JSON output
│   ├── roles-table-docs.md          # Example generated documentation
│   └── users-table-docs.md          # Another example
├── scripts/
│   ├── generate-docs.sh             # Shell script automation
│   ├── generate-docs.py             # Python automation script
│   └── batch-generate.sql           # SQL for multiple tables
└── templates/
    └── documentation-template.md    # Base template structure
```

## 🤝 Contributing

1. **Fork the repository**
2. **Create a feature branch** (`git checkout -b feature/amazing-feature`)
3. **Add your improvements** (new database support, template enhancements)
4. **Test with sample data** to ensure quality output
5. **Submit a pull request**

### Contribution Ideas

- Support for additional database systems
- Enhanced business logic detection
- Custom output formats (HTML, PDF)
- Integration with documentation platforms
- Automated CI/CD documentation updates

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🔗 Related Projects

- [Database Schema Exporters](https://github.com/topics/database-schema)
- [Documentation Generators](https://github.com/topics/documentation-generator)
- [Database Analysis Tools](https://github.com/topics/database-analysis)

## 💡 Use Cases

- **API Documentation**: Document database schemas for API development
- **Onboarding**: Help new developers understand existing database structures
- **Compliance**: Maintain up-to-date documentation for audits
- **Migration Planning**: Document current state before schema changes
- **Knowledge Sharing**: Share database knowledge across teams

## 📞 Support

- **Issues**: Report bugs and request features via GitHub Issues
- **Discussions**: Join conversations in GitHub Discussions
- **Documentation**: Check the [Wiki](wiki) for detailed guides
- **Examples**: Browse the `examples/` directory for sample usage

---

**Made with ❤️ for better database documentation**

*Last updated: 2025-05-25*
