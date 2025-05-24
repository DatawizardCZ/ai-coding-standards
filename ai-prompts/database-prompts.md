# Database AI Prompts

*Effective prompts for AI assistance with database development tasks*

---

## 🏗️ Schema Design Prompts

### Creating New Tables
```
I need to create a new table for [PURPOSE/BUSINESS_REQUIREMENT].

Requirements:
- [LIST SPECIFIC REQUIREMENTS]
- [USER ACCESS PATTERNS]
- [EXPECTED DATA VOLUME]
- [RELATIONSHIPS TO OTHER TABLES]

Please create the table following these standards:
- Use PostgreSQL/Supabase best practices
- Follow snake_case naming conventions
- Include proper constraints and validation
- Add appropriate indexes for performance
- Create RLS policies for security
- Include audit fields (created_at, updated_at)

Reference standards: [LINK TO STANDARDS DOC]
Existing schema: [LINK TO SCHEMA DOC]
```

### Schema Optimization
```
Review this database schema for optimization opportunities:

[PASTE SCHEMA/TABLE DEFINITIONS]

Current issues:
- [PERFORMANCE PROBLEMS]
- [DATA INTEGRITY CONCERNS]
- [SCALABILITY CHALLENGES]

Please analyze and suggest:
1. Index optimizations
2. Constraint improvements
3. Normalization/denormalization opportunities
4. Performance bottleneck solutions
5. Security enhancements

Focus on: [SPECIFIC AREA OF CONCERN]
```

---

## 🔧 Query Optimization Prompts

### Slow Query Analysis
```
This query is performing poorly in production:

```sql
[PASTE SLOW QUERY]
```

Current performance:
- Execution time: [X seconds]
- Rows processed: [X rows]
- Frequency: [X times per minute]

Schema context:
[PASTE RELEVANT TABLE DEFINITIONS]

Please:
1. Analyze why the query is slow
2. Suggest optimizations (rewrite, indexes, etc.)
3. Provide the optimized version
4. Explain the performance improvement strategy
5. Suggest indexes if needed

Environment: PostgreSQL [VERSION] / Supabase
```

### Query Planning Help
```
I need help writing an efficient query for:

Business requirement: [DESCRIBE WHAT YOU NEED]

Tables involved:
- [TABLE 1]: [brief description]
- [TABLE 2]: [brief description]

Data volume:
- [TABLE 1]: ~[X] rows
- [TABLE 2]: ~[X] rows

Performance requirements:
- Must return results in < [X] seconds
- Will be called [X] times per minute
- Needs to support [CONCURRENT USERS]

Please provide:
1. Optimized SQL query
2. Necessary indexes
3. Expected performance characteristics
4. Alternative approaches if applicable
```

---

## 🔐 Security and RLS Prompts

### RLS Policy Design
```
I need to create Row Level Security policies for this table:

```sql
[PASTE TABLE DEFINITION]
```

Access requirements:
- [USER ROLE 1]: [access description]
- [USER ROLE 2]: [access description]
- [SPECIAL CONDITIONS]: [any time-based, status-based access]

User context available:
- auth.uid() - current user ID
- User profiles table with roles: [describe structure]

Please create:
1. Appropriate RLS policies for each user type
2. Performance-optimized policy conditions
3. Security validation for edge cases
4. Indexes to support the policies

Follow Supabase RLS best practices.
```

### Security Review
```
Please review this database schema for security vulnerabilities:

[PASTE SCHEMA OR SPECIFIC CONCERNS]

Focus areas:
- Row Level Security implementation
- Data exposure risks
- Permission escalation possibilities
- Audit trail completeness
- Sensitive data protection

Current security setup:
- [DESCRIBE CURRENT RLS POLICIES]
- [USER ROLE SYSTEM]
- [AUTHENTICATION METHOD]

Provide specific recommendations for improvements.
```

---

## 📊 Performance Analysis Prompts

### Performance Troubleshooting
```
I'm experiencing database performance issues:

Symptoms:
- [DESCRIBE PERFORMANCE PROBLEMS]
- [AFFECTED OPERATIONS]
- [TIME PATTERNS - when it's worse]

Environment:
- PostgreSQL [VERSION]
- Database size: [X GB]
- Concurrent users: ~[X]
- Peak query load: [X queries/second]

Current slow queries:
```sql
[PASTE TOP 3 SLOWEST QUERIES]
```

Available data:
- [PASTE pg_stat_statements OUTPUT IF AVAILABLE]
- [CURRENT INDEX USAGE STATS]
- [TABLE SIZE INFORMATION]

Please analyze and provide:
1. Root cause analysis
2. Immediate fixes for quick wins
3. Long-term optimization strategy
4. Monitoring recommendations
5. Preventive measures

Priority: [HIGH/MEDIUM/LOW]
```

### Index Strategy
```
Help me design an indexing strategy for this table:

```sql
[PASTE TABLE DEFINITION]
```

Query patterns:
- [MOST COMMON QUERIES - with frequency]
- [FILTER CONDITIONS USED]
- [JOIN PATTERNS]
- [ORDER BY clauses]

Current performance issues:
- [DESCRIBE SLOW OPERATIONS]

Table characteristics:
- Current size: [X rows]
- Growth rate: [X rows/day]
- Read/write ratio: [X:Y]
- Update frequency: [describe update patterns]

Please recommend:
1. Essential indexes for performance
2. Composite indexes for complex queries
3. Partial indexes for filtered data
4. Indexes to avoid (potential waste)
5. Maintenance considerations
```

---

## 🚀 Migration Prompts

### Migration Planning
```
I need to create a database migration for:

Change description: [DESCRIBE THE CHANGE]

Current schema:
```sql
[PASTE CURRENT TABLE/SCHEMA]
```

Desired end state:
- [DESCRIBE TARGET SCHEMA]
- [NEW REQUIREMENTS]
- [COMPATIBILITY NEEDS]

Constraints:
- Production data volume: [X rows affected]
- Downtime tolerance: [X minutes max]
- Backwards compatibility: [REQUIRED/NOT REQUIRED]
- Data preservation: [CRITICAL FIELDS TO PRESERVE]

Please provide:
1. Step-by-step migration plan
2. Safe migration SQL with rollback
3. Data validation steps
4. Performance impact assessment
5. Risk mitigation strategies

Environment: PostgreSQL/Supabase
```

### Data Migration
```
I need to migrate data from this structure:

Old schema:
```sql
[PASTE OLD SCHEMA]
```

To this new structure:
```sql
[PASTE NEW SCHEMA]
```

Data transformation needs:
- [FIELD MAPPING REQUIREMENTS]
- [DATA CLEANING NEEDS]
- [BUSINESS RULE CHANGES]

Challenges:
- [DATA QUALITY ISSUES]
- [VOLUME CONCERNS]
- [DEPENDENCY ISSUES]

Please provide:
1. Data transformation SQL
2. Validation queries to ensure accuracy
3. Batch processing approach for large data
4. Error handling strategy
5. Rollback procedures
```

---

## 🔍 Debugging and Analysis Prompts

### Query Debugging
```
This query is not returning expected results:

```sql
[PASTE PROBLEMATIC QUERY]
```

Expected result: [DESCRIBE WHAT YOU EXPECT]
Actual result: [DESCRIBE WHAT YOU GET]

Test data context:
- [DESCRIBE RELEVANT TEST DATA]
- [TABLE RELATIONSHIPS]
- [DATA CONSTRAINTS]

Schema:
```sql
[PASTE RELEVANT TABLE DEFINITIONS]
```

Please:
1. Identify the logic error
2. Provide corrected query
3. Explain why the original failed
4. Suggest test cases to prevent similar issues
```

### Performance Investigation
```
I need help investigating why this operation is slow:

Operation: [DESCRIBE THE SLOW OPERATION]

Context:
- This used to be fast, now it's slow
- Changed around: [TIME WHEN IT STARTED]
- Recent changes: [DESCRIBE RECENT CHANGES]

Current execution plan:
```
[PASTE EXPLAIN ANALYZE OUTPUT IF AVAILABLE]
```

Schema involved:
```sql
[PASTE RELEVANT TABLES]
```

Please investigate:
1. What likely caused the performance degradation
2. How to identify the root cause
3. Steps to restore previous performance
4. Monitoring to prevent future issues
```

---

## 🛠️ Development Assistance Prompts

### API Integration
```
I need to create database functions for this API endpoint:

Endpoint: [API ENDPOINT DESCRIPTION]
Method: [GET/POST/PUT/DELETE]

Requirements:
- [BUSINESS LOGIC REQUIREMENTS]
- [DATA VALIDATION NEEDS]
- [SECURITY REQUIREMENTS]
- [PERFORMANCE REQUIREMENTS]

Input parameters:
- [PARAMETER 1]: [type and description]
- [PARAMETER 2]: [type and description]

Expected output:
- [OUTPUT FORMAT DESCRIPTION]

Database context:
```sql
[PASTE RELEVANT SCHEMA]
```

Please create:
1. PostgreSQL function(s) with proper error handling
2. Input validation and security checks
3. Optimized queries for performance
4. Return format suitable for API
5. Usage examples and test cases

Platform: Supabase
```

### Business Logic Implementation
```
I need to implement this business rule in the database:

Business rule: [DESCRIBE THE BUSINESS REQUIREMENT]

Current schema:
```sql
[PASTE RELEVANT TABLES]
```

Implementation preferences:
- [TRIGGER vs FUNCTION vs APPLICATION LOGIC]
- [PERFORMANCE CONSIDERATIONS]
- [ERROR HANDLING REQUIREMENTS]

Edge cases to handle:
- [EDGE CASE 1]
- [EDGE CASE 2]

Please provide:
1. Recommended implementation approach
2. SQL code (functions, triggers, constraints)
3. Error handling strategy
4. Test cases for validation
5. Performance considerations
```

---

## 📈 Analytics and Reporting Prompts

### Analytics Query Development
```
I need to create analytics queries for:

Business question: [WHAT BUSINESS QUESTION TO ANSWER]

Available data:
```sql
[PASTE RELEVANT TABLE SCHEMAS]
```

Requirements:
- Time period: [SPECIFIC TIME RANGES]
- Grouping: [HOW TO GROUP DATA]
- Metrics needed: [SPECIFIC CALCULATIONS]
- Performance: [ACCEPTABLE QUERY TIME]

Sample questions:
- [EXAMPLE QUESTION 1]
- [EXAMPLE QUESTION 2]

Please provide:
1. Optimized SQL queries for each metric
2. Explanation of the calculations
3. Indexes needed for performance
4. Alternative approaches for complex calculations
5. Suggestions for data visualization
```

### Reporting Optimization
```
This reporting query is too slow for dashboard use:

```sql
[PASTE CURRENT SLOW QUERY]
```

Current performance: [X seconds]
Target performance: < [X seconds]
Query frequency: [X times per hour]

Business requirements:
- [WHAT THE REPORT SHOWS]
- [ACCURACY REQUIREMENTS]
- [REAL-TIME vs BATCH ACCEPTABLE]

Please suggest:
1. Query optimizations
2. Materialized view strategies
3. Incremental calculation approaches
4. Caching strategies
5. Index optimizations

Balance between accuracy and performance is: [PREFERENCE]
```

---

## 🔄 Code Review Prompts

### Schema Review
```
Please review this database schema design:

```sql
[PASTE SCHEMA]
```

Context:
- Purpose: [WHAT THIS SCHEMA IS FOR]
- Expected scale: [DATA VOLUME AND USER COUNT]
- Performance requirements: [RESPONSE TIME NEEDS]

Review focus:
- [ ] Naming conventions
- [ ] Data types and constraints
- [ ] Index strategy
- [ ] Security (RLS policies)
- [ ] Normalization appropriateness
- [ ] Performance considerations

Please provide:
1. Issues found with severity levels
2. Specific recommendations for improvements
3. Best practice compliance assessment
4. Potential future scalability concerns
```

### Query Review
```
Please review these database queries for production readiness:

```sql
[PASTE QUERIES TO REVIEW]
```

Usage context:
- Frequency: [HOW OFTEN THESE RUN]
- Data volume: [TYPICAL DATA SIZE]
- User impact: [CRITICAL/NORMAL/LOW]

Review criteria:
- [ ] Performance efficiency
- [ ] Security (SQL injection, data exposure)
- [ ] Maintainability
- [ ] Error handling
- [ ] Best practices compliance

Please assess and provide:
1. Security vulnerabilities
2. Performance bottlenecks
3. Maintainability issues
4. Recommended improvements
5. Production readiness score
```

---

## 🧪 Testing Prompts

### Test Data Generation
```
I need to generate realistic test data for:

Tables:
```sql
[PASTE TABLE SCHEMAS]
```

Requirements:
- Volume: [X rows per table]
- Realistic relationships: [DESCRIBE FK RELATIONSHIPS]
- Data patterns: [DESCRIBE REALISTIC PATTERNS]
- Edge cases: [SPECIFIC EDGE CASES TO INCLUDE]

Business context:
- [DESCRIBE WHAT THE DATA REPRESENTS]

Please provide:
1. SQL scripts to generate test data
2. Realistic data distributions
3. Proper foreign key relationships
4. Edge cases and boundary conditions
5. Data cleanup scripts
```

### Performance Testing
```
Help me create performance tests for:

Operations to test:
- [OPERATION 1]: [expected frequency]
- [OPERATION 2]: [expected frequency]

Load requirements:
- Concurrent users: [X]
- Peak transactions: [X per second]
- Data volume: [X records]

Test scenarios needed:
- [NORMAL LOAD SCENARIO]
- [PEAK LOAD SCENARIO]
- [STRESS TEST SCENARIO]

Please provide:
1. Test queries for each scenario
2. Metrics to measure and track
3. Performance baselines to establish
4. Load testing strategy
5. Success criteria definition
```

---

## 💡 Best Practices and Learning Prompts

### Learning and Explanation
```
Please explain this database concept with practical examples:

Topic: [SPECIFIC DATABASE CONCEPT]

My current understanding: [WHAT YOU ALREADY KNOW]

Learning goals:
- [WHAT YOU WANT TO UNDERSTAND BETTER]
- [PRACTICAL APPLICATION NEEDS]

Context: Working with PostgreSQL/Supabase

Please provide:
1. Clear explanation with examples
2. When and why to use this concept
3. Common mistakes to avoid
4. Practical implementation examples
5. Related concepts to explore
```

### Architecture Advice
```
I'm designing the database architecture for:

Project: [PROJECT DESCRIPTION]

Requirements:
- User base: [EXPECTED USERS]
- Data volume: [EXPECTED DATA SIZE]
- Read/write patterns: [DESCRIBE USAGE PATTERNS]
- Scalability needs: [GROWTH EXPECTATIONS]

Current thinking:
- [YOUR CURRENT ARCHITECTURE IDEAS]

Constraints:
- Budget: [BUDGET CONSIDERATIONS]
- Technology: [TECH STACK LIMITATIONS]
- Timeline: [DEVELOPMENT TIMELINE]

Please advise on:
1. Overall architecture recommendations
2. Table design strategies
3. Scaling considerations
4. Technology choices
5. Potential pitfalls to avoid
```

---

## 🎯 Prompt Best Practices

### For Better AI Responses:
1. **Be specific** about your environment (PostgreSQL version, Supabase, etc.)
2. **Provide context** about data volume, performance requirements
3. **Include relevant schema** or table definitions
4. **Specify constraints** like downtime tolerance, backwards compatibility
5. **Ask for explanations** not just code - understand the reasoning
6. **Request alternatives** when multiple approaches are possible
7. **Include error handling** requirements in your requests

### Template Structure:
```
Context: [What you're working on]
Current situation: [What you have now]
Goal: [What you want to achieve]
Constraints: [Limitations and requirements]
Specific questions: [Numbered list of specific asks]
```

---

*Remember: The quality of AI assistance depends heavily on the quality and specificity of your prompts. Always provide enough context for the AI to give you relevant, actionable advice.*
