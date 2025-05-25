# Database Table Documentation Generation Instructions

## Overview
These instructions guide an AI assistant in converting JSON database metadata into comprehensive markdown table documentation. The JSON input contains structured database analysis results across multiple sections.

## Input JSON Structure

The input JSON is an array of objects, each containing:
- `section_name`: Identifies the type of metadata
- `section_type`: Category (metadata, security, relationships, data)
- `result_json`: The actual data content

### Expected Sections
1. **table_structure** - Column definitions and data types
2. **constraints** - Primary keys, unique constraints, foreign keys
3. **foreign_keys** - Detailed foreign key relationships
4. **indexes** - Index definitions and purposes
5. **table_statistics** - Usage and maintenance stats
6. **row_count** - Current row count
7. **table_size** - Storage size information
8. **rls_status** - Row Level Security configuration
9. **rls_policies** - RLS policy details (if any)
10. **child_tables** - Tables that reference this table
11. **parent_tables** - Tables this table references
12. **all_data** - Sample or complete table data

## Parsing Instructions

### 1. Extract Basic Table Information
From various sections, gather:
- Table name (from `table_statistics.tablename` or infer from context)
- Schema name (from `rls_status.schema_name`)
- Current row count (from `row_count.exact_row_count`)
- Table size (from `table_size`)

### 2. Parse Table Schema
From `table_structure.result_json`, create a table with columns:
- **Column**: `column_name`
- **Data Type**: `data_type` (include `character_maximum_length` if applicable)
- **Nullable**: `is_nullable` (YES/NO)
- **Default**: `column_default` (show `-` if null)
- **Description**: Generate based on column name and context

**Data Type Formatting Rules:**
- For `character varying`: Show as `VARCHAR(length)` if length exists
- For `timestamp with time zone`: Show as `TIMESTAMPTZ`
- For types with no length: Show as-is (UUID, INTEGER, BOOLEAN, TEXT, JSONB)

### 3. Parse Constraints
From `constraints.result_json`, group by `constraint_type`:

**Primary Keys:**
- List columns with `constraint_type = "PRIMARY KEY"`

**Unique Constraints:**
- List non-primary key unique constraints
- Group columns that share the same `constraint_name`

**Foreign Keys:**
- Use `foreign_keys.result_json` for detailed information
- Format: `column_name → referenced_table.referenced_column`

### 4. Parse Indexes
From `indexes.result_json`:
- Extract `index_name` and `index_definition`
- Determine index type from definition (UNIQUE, BTREE, etc.)
- Infer purpose based on column names and patterns

### 5. Parse Relationships
From `parent_tables` and `child_tables`:
- **Parent Tables**: Tables this table references via foreign keys
- **Child Tables**: Tables that reference this table

### 6. Analyze Data Patterns
From `all_data.result_json` (if available):
- Identify business domain from data patterns
- Extract unique values for enum-like columns
- Analyze permission structures if JSONB permissions exist
- Identify hierarchical patterns (level fields, etc.)

## Output Markdown Structure

### Required Sections

#### 1. Overview
```markdown
# [Table Name] Table Documentation

## Overview
[Brief description of table purpose based on data analysis]

**Table Name:** `schema.table_name`
**Current Rows:** [row_count]
**Table Size:** [table_size.table_size]
**Total Size (including indexes):** [table_size.total_size]
```

#### 2. Table Schema
```markdown
## Table Schema

| Column | Data Type | Nullable | Default | Description |
|--------|-----------|----------|---------|-------------|
[Generate rows from table_structure data]
```

#### 3. Constraints
```markdown
## Constraints

### Primary Key
- [constraint_name] on [columns]

### Unique Constraints
- [constraint_name] on [columns] - [purpose description]

### Foreign Keys
- [constraint_name]: [column] → [referenced_table.referenced_column]
```

#### 4. Indexes
```markdown
## Indexes

| Index Name | Type | Columns | Purpose |
|------------|------|---------|---------|
[Generate from indexes data with inferred purposes]
```

#### 5. Relationships
```markdown
## Relationships

### Parent Tables
- **[table_name]**: [relationship description]

### Child Tables
- **[table_name]**: [relationship description]
```

### Optional Sections (Include if Data Available)

#### 6. Business Logic Analysis
If the data suggests specific business patterns:
```markdown
## [Domain] System
[Analysis of business rules, hierarchies, permission systems, etc.]
```

#### 7. Security Considerations
```markdown
## Security Considerations

### Row Level Security (RLS)
- **Status**: [ENABLED/DISABLED]
- **Policies**: [List policies or "None configured"]
```

#### 8. Sample Data / Default Values
If `all_data` contains meaningful examples:
```markdown
## Default [Entities]

| [Key Columns] | Description |
|---------------|-------------|
[Extract meaningful sample data]
```

#### 9. Usage Examples
```markdown
## Usage Examples

### [Common Operation 1]
```sql
[Generated SQL example]
```

### [Common Operation 2]
```sql
[Generated SQL example]
```
```

#### 10. Maintenance Notes
```markdown
## Maintenance Notes

- **Statistics**: [From table_statistics]
- **Growth**: [From table_statistics insert/update/delete counts]
- **Performance**: [Analysis of indexing strategy]
```

## Content Generation Rules

### 1. Descriptions and Purposes
- **Column Descriptions**: Infer from column names, data types, and sample data
- **Index Purposes**: Derive from column combinations and naming patterns
- **Constraint Purposes**: Explain business rules implied by unique constraints

### 2. Business Context Analysis
- **Domain Detection**: Analyze table/column names and data patterns
- **Hierarchy Recognition**: Look for `level`, `parent_id`, or similar patterns
- **Permission Systems**: Analyze JSONB permission arrays
- **Audit Patterns**: Identify `created_at`, `updated_at`, `created_by` patterns

### 3. SQL Example Generation
Generate practical examples based on:
- Common CRUD operations for the business domain
- Queries that utilize the available indexes
- Filtering patterns that match the data structure

### 4. Tone and Style
- **Professional but accessible**: Technical accuracy with clear explanations
- **Context-aware**: Adapt language to the business domain
- **Actionable**: Include practical usage guidance
- **Complete**: Cover all aspects of the table structure and usage

### 5. Data-Driven Insights
- **Performance Notes**: Comment on index efficiency and query patterns
- **Security Observations**: Note RLS status and recommend security measures
- **Scalability Considerations**: Analyze current size vs. expected growth
- **Data Quality**: Comment on constraints and validation rules

## Error Handling

### Missing Sections
- If critical sections are missing, note limitations in the documentation
- Provide partial analysis with available data
- Suggest what additional information would be helpful

### Data Inconsistencies
- Cross-reference foreign key definitions with constraints
- Validate that parent/child relationships match foreign key definitions
- Note any discrepancies in the documentation

### Incomplete Data
- Work with available sections
- Clearly mark sections as "Limited data available"
- Focus on providing value with existing information

## Quality Checklist

Before finalizing documentation, ensure:
- [ ] All available JSON sections are utilized
- [ ] Table schema is complete and properly formatted
- [ ] Relationships are clearly explained
- [ ] Business context is accurately inferred
- [ ] SQL examples are syntactically correct
- [ ] Security considerations are addressed
- [ ] Performance implications are discussed
- [ ] Documentation is well-structured and readable

## Example Usage

When receiving JSON metadata, follow this process:
1. **Parse and validate** the JSON structure
2. **Extract core information** (table name, size, columns)
3. **Analyze relationships** and constraints
4. **Infer business context** from data patterns
5. **Generate comprehensive documentation** following the template
6. **Review and refine** for completeness and accuracy

The goal is to transform raw database metadata into documentation that serves both technical and business stakeholders, providing complete understanding of the table's structure, purpose, and usage patterns.
