# Database Performance Review Checklist

*Systematic approach to identifying and resolving database performance issues*

---

## 🎯 Performance Assessment Overview

### ✅ Symptoms Identification
- [ ] **Slow query complaints** from users documented
- [ ] **Response time degradation** measured and quantified
- [ ] **Error rate increases** tracked and analyzed
- [ ] **Resource utilization** patterns identified
- [ ] **Performance baseline** established for comparison

### ✅ Impact Analysis
- [ ] **Affected users/features** identified and prioritized
- [ ] **Business impact** assessed (revenue, user experience)
- [ ] **Peak usage times** identified when issues are worst
- [ ] **Growth trends** analyzed to predict future issues
- [ ] **SLA breaches** documented and evaluated

---

## 📊 Data Collection and Monitoring

### ✅ Query Performance Analysis
- [ ] **Slow query log** enabled and analyzed
- [ ] **Query execution plans** reviewed with EXPLAIN ANALYZE
- [ ] **Query frequency** analyzed to identify hot spots
- [ ] **Lock contention** measured and documented
- [ ] **Transaction duration** measured for long-running operations

```sql
-- Enable slow query logging
ALTER SYSTEM SET log_min_duration_statement = 1000; -- Log queries > 1 second
SELECT pg_reload_conf();

-- Find slowest queries
SELECT query, calls, total_time, mean_time, rows
FROM pg_stat_statements 
ORDER BY total_time DESC 
LIMIT 10;

-- Analyze specific query
EXPLAIN (ANALYZE, BUFFERS) SELECT ...;
```

### ✅ Index Analysis
- [ ] **Missing indexes** identified on frequently queried columns
- [ ] **Unused indexes** found and marked for removal
- [ ] **Index effectiveness** measured with usage statistics
- [ ] **Index bloat** measured and cleanup planned
- [ ] **Composite index opportunities** identified

```sql
-- Find unused indexes
SELECT schemaname, tablename, indexname, idx_tup_read, idx_tup_fetch
FROM pg_stat_user_indexes 
WHERE idx_tup_read = 0 AND idx_tup_fetch = 0;

-- Find missing indexes (tables with sequential scans)
SELECT schemaname, tablename, seq_scan, seq_tup_read, 
       seq_tup_read / seq_scan AS avg_seq_tup_read
FROM pg_stat_user_tables 
WHERE seq_scan > 100 
ORDER BY seq_tup_read DESC;

-- Check index usage
SELECT tablename, indexname, idx_scan, idx_tup_read, idx_tup_fetch
FROM pg_stat_user_indexes 
ORDER BY idx_scan DESC;
```

### ✅ Table and Database Statistics
- [ ] **Table sizes** measured and growth trends analyzed
- [ ] **Row counts** tracked for large tables
- [ ] **Database bloat** measured and vacuum needs assessed
- [ ] **Statistics freshness** checked and update scheduled
- [ ] **Partitioning opportunities** evaluated for large tables

```sql
-- Check table sizes
SELECT schemaname, tablename, 
       pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size,
       pg_total_relation_size(schemaname||'.'||tablename) as bytes
FROM pg_tables 
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

-- Check table bloat
SELECT tablename, n_dead_tup, n_live_tup, 
       round(n_dead_tup * 100.0 / (n_live_tup + n_dead_tup), 2) AS dead_ratio
FROM pg_stat_user_tables 
WHERE n_live_tup > 0
ORDER BY dead_ratio DESC;

-- Check statistics age
SELECT schemaname, tablename, last_vacuum, last_autovacuum, 
       last_analyze, last_autoanalyze
FROM pg_stat_user_tables;
```

---

## 🔍 Root Cause Analysis

### ✅ Query Optimization
- [ ] **Query patterns** analyzed for optimization opportunities
- [ ] **Join strategies** evaluated and optimized
- [ ] **WHERE clause efficiency** improved with better indexes
- [ ] **SELECT * usage** eliminated where possible
- [ ] **Subquery optimization** applied where beneficial

### ✅ Schema Design Issues
- [ ] **Normalization issues** identified and addressed
- [ ] **Data type efficiency** reviewed (oversized columns)
- [ ] **Foreign key relationships** optimized
- [ ] **Constraint effectiveness** evaluated
- [ ] **Table partitioning** considered for very large tables

### ✅ Application-Level Issues
- [ ] **N+1 query problems** identified and resolved
- [ ] **Connection pooling** effectiveness evaluated
- [ ] **Transaction boundaries** optimized
- [ ] **Batch processing** opportunities identified
- [ ] **Caching strategies** evaluated and implemented

---

## ⚡ Performance Optimization Actions

### ✅ Index Optimization
- [ ] **Missing indexes** created based on query patterns
- [ ] **Composite indexes** created for multi-column WHERE clauses
- [ ] **Partial indexes** created for frequently filtered subsets
- [ ] **Unused indexes** removed to reduce maintenance overhead
- [ ] **Index maintenance** scheduled (REINDEX if needed)

```sql
-- Create performance indexes
CREATE INDEX CONCURRENTLY idx_orders_customer_status 
ON orders(customer_id, status) WHERE deleted_at IS NULL;

CREATE INDEX CONCURRENTLY idx_users_active_last_login 
ON users(last_login_at) WHERE is_active = true;

-- Remove unused index
DROP INDEX CONCURRENTLY idx_unused_column;
```

### ✅ Query Optimization
- [ ] **Slow queries** rewritten for better performance
- [ ] **Query hints** applied where appropriate
- [ ] **Join order** optimized for better execution plans
- [ ] **Aggregation queries** optimized with better GROUP BY
- [ ] **LIMIT/OFFSET** pagination replaced with cursor-based pagination

### ✅ Database Configuration
- [ ] **PostgreSQL configuration** tuned for workload
- [ ] **Memory allocation** optimized (shared_buffers, work_mem)
- [ ] **Connection limits** adjusted based on usage patterns
- [ ] **Vacuum and analyze** settings tuned
- [ ] **Checkpoint settings** optimized for write performance

```sql
-- Key configuration parameters to review
SHOW shared_buffers;        -- Should be ~25% of RAM
SHOW effective_cache_size;  -- Should be ~75% of RAM
SHOW work_mem;             -- Per-operation memory limit
SHOW maintenance_work_mem; -- For maintenance operations
SHOW max_connections;      -- Balance with connection pooling
```

---

## 🔧 Implementation and Testing

### ✅ Change Implementation
- [ ] **Performance changes** implemented in development first
- [ ] **A/B testing** conducted to measure improvements
- [ ] **Rollback plan** prepared for each optimization
- [ ] **Monitoring** enhanced to track optimization effects
- [ ] **Documentation** updated with changes made

### ✅ Validation Testing
- [ ] **Before/after benchmarks** conducted and compared
- [ ] **Load testing** performed with realistic workloads
- [ ] **Edge case testing** completed for new optimizations
- [ ] **Regression testing** performed to ensure no degradation
- [ ] **User acceptance testing** completed for user-facing improvements

### ✅ Production Deployment
- [ ] **Gradual rollout** planned for major optimizations
- [ ] **Real-time monitoring** active during deployment
- [ ] **Performance metrics** tracked continuously
- [ ] **User feedback** collected and analyzed
- [ ] **Success criteria** defined and measured

---

## 📈 Ongoing Monitoring and Maintenance

### ✅ Performance Monitoring Setup
- [ ] **Automated alerts** configured for performance degradation
- [ ] **Regular performance reports** scheduled and distributed
- [ ] **Capacity planning** updated based on growth trends
- [ ] **Performance budgets** established for new features
- [ ] **Baseline metrics** updated with new normal performance

### ✅ Maintenance Schedule
- [ ] **Regular VACUUM** scheduled for high-churn tables
- [ ] **Statistics updates** automated with ANALYZE
- [ ] **Index maintenance** scheduled monthly/quarterly
- [ ] **Configuration reviews** planned quarterly
- [ ] **Performance reviews** scheduled monthly

### ✅ Preventive Measures
- [ ] **Query review process** established for new features
- [ ] **Performance testing** integrated into CI/CD pipeline
- [ ] **Database design reviews** required for schema changes
- [ ] **Capacity monitoring** automated with alerts
- [ ] **Knowledge sharing** sessions scheduled for team

---

## 🚨 Critical Performance Issues

### ✅ Emergency Response
If experiencing critical performance issues:
- [ ] **Immediate impact assessment** completed
- [ ] **Quick wins** identified and implemented (kill long queries, etc.)
- [ ] **Emergency optimizations** applied (missing indexes, etc.)
- [ ] **Scaling decisions** made (read replicas, connection pooling)
- [ ] **Communication** maintained with stakeholders

### ✅ High-Impact Quick Fixes
- [ ] **Kill long-running queries** blocking other operations
- [ ] **Add missing indexes** for frequently used WHERE clauses
- [ ] **Increase connection pool size** if connection exhaustion
- [ ] **Enable query caching** for read-heavy workloads
- [ ] **Partition large tables** causing full table scans

```sql
-- Emergency commands
-- Kill long-running queries (be careful!)
SELECT pg_terminate_backend(pid) 
FROM pg_stat_activity 
WHERE state = 'active' 
  AND query_start < now() - interval '30 minutes'
  AND query NOT LIKE '%pg_stat_activity%';

-- Quick index creation
CREATE INDEX CONCURRENTLY idx_emergency_fix ON large_table(frequently_queried_column);
```

---

## 📊 Performance Metrics to Track

### ✅ Database Metrics
- [ ] **Query response times** (average, 95th percentile)
- [ ] **Throughput** (queries per second, transactions per second)
- [ ] **Connection utilization** (active vs available connections)
- [ ] **Resource usage** (CPU, memory, disk I/O)
- [ ] **Lock contention** (lock wait times, deadlocks)

### ✅ Application Metrics
- [ ] **Page load times** for database-dependent pages
- [ ] **API response times** for database-heavy endpoints
- [ ] **Error rates** related to database timeouts
- [ ] **User satisfaction** metrics (if available)
- [ ] **Business metrics** (conversion rates, user engagement)

---

## 🎯 Success Criteria

Performance optimization is successful when:

- ✅ **Query response times** improved by target percentage
- ✅ **User complaints** about performance significantly reduced
- ✅ **System resources** operating within acceptable ranges
- ✅ **SLA targets** consistently met or exceeded
- ✅ **Scalability** improved for anticipated growth
- ✅ **Cost efficiency** maintained or improved

---

## 📝 Documentation and Communication

### ✅ Performance Report
- [ ] **Current state assessment** documented with metrics
- [ ] **Optimizations implemented** listed with impact measurements
- [ ] **Remaining issues** prioritized with effort estimates
- [ ] **Recommendations** provided for future improvements
- [ ] **Cost-benefit analysis** completed for major changes

### ✅ Team Knowledge Sharing
- [ ] **Lessons learned** documented and shared
- [ ] **Best practices** updated based on discoveries
- [ ] **Tool improvements** suggested for better monitoring
- [ ] **Training needs** identified for team members
- [ ] **Process improvements** suggested for preventing future issues

---

## 🔗 Useful Tools and Queries

```sql
-- Monitor current activity
SELECT pid, now() - pg_stat_activity.query_start AS duration, query, state
FROM pg_stat_activity 
WHERE state != 'idle' 
ORDER BY duration DESC;

-- Check for blocking queries
SELECT blocked_locks.pid AS blocked_pid,
       blocked_activity.usename AS blocked_user,
       blocking_locks.pid AS blocking_pid,
       blocking_activity.usename AS blocking_user,
       blocked_activity.query AS blocked_statement,
       blocking_activity.query AS current_statement_in_blocking_process
FROM pg_catalog.pg_locks blocked_locks
JOIN pg_catalog.pg_stat_activity blocked_activity ON blocked_activity.pid = blocked_locks.pid
JOIN pg_catalog.pg_locks blocking_locks ON blocking_locks.locktype = blocked_locks.locktype
JOIN pg_catalog.pg_stat_activity blocking_activity ON blocking_activity.pid = blocking_locks.pid
WHERE NOT blocked_locks.granted AND blocking_locks.granted;

-- Database size and growth
SELECT pg_size_pretty(pg_database_size(current_database())) as current_size;
```

---

*Remember: Performance optimization is an ongoing process. Regular monitoring and proactive maintenance prevent most performance crises.*
