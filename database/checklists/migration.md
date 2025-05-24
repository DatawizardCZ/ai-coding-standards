# Migration Checklist

*Safe database migration practices for production deployments*

---

## 📋 Pre-Migration Planning

### ✅ Migration Design
- [ ] **Migration purpose** clearly defined and documented
- [ ] **Breaking changes** identified and documented
- [ ] **Backwards compatibility** considered and maintained
- [ ] **Data impact** assessed (how much data will be affected)
- [ ] **Performance impact** estimated (duration, blocking operations)
- [ ] **Rollback plan** documented and tested

### ✅ Environment Preparation
- [ ] **Development environment** migration tested successfully
- [ ] **Staging environment** migration tested with production-like data
- [ ] **Backup strategy** confirmed and tested
- [ ] **Downtime window** scheduled if needed
- [ ] **Team coordination** planned (who runs what, when)

### ✅ Dependencies and Prerequisites
- [ ] **Application compatibility** verified (old app works with new schema)
- [ ] **Required extensions** available in target environment
- [ ] **Permissions** verified for all required operations
- [ ] **Disk space** sufficient for migration operations
- [ ] **Foreign key dependencies** mapped and considered

---

## 🔒 Safety Checks

### ✅ Migration File Validation
- [ ] **Migration filename** follows convention (`YYYY_MM_DD_HH_MM_description.sql`)
- [ ] **Transaction wrapper** included (`BEGIN;` ... `COMMIT;`)
- [ ] **Idempotency checks** included (IF NOT EXISTS, IF EXISTS)
- [ ] **Safety validations** included (check prerequisites exist)
- [ ] **Error handling** implemented for critical operations

### ✅ Backup and Recovery
- [ ] **Full database backup** completed before migration
- [ ] **Backup integrity** verified (can restore successfully)
- [ ] **Point-in-time recovery** tested if using streaming replication
- [ ] **Backup retention** planned (how long to keep pre-migration backup)

### ✅ Testing Strategy
- [ ] **Test data** prepared that covers edge cases
- [ ] **Expected results** documented for validation
- [ ] **Performance benchmarks** established for comparison
- [ ] **Rollback procedure** tested in staging environment

---

## 🚀 Migration Execution

### ✅ Pre-Execution Validation
- [ ] **Database state** verified (expected tables/data exist)
- [ ] **Active connections** checked (consider maintenance mode)
- [ ] **Long-running queries** identified and handled
- [ ] **Replication lag** checked if using replicas
- [ ] **Monitoring** set up to track migration progress

### ✅ Execution Steps
- [ ] **Migration script** executed with proper user privileges
- [ ] **Progress monitoring** active during execution
- [ ] **Error logs** monitored for issues
- [ ] **Performance metrics** tracked during execution
- [ ] **Intermediate validations** performed for long migrations

### ✅ Large Table Migrations
For tables with > 1M rows:
- [ ] **Batch processing** implemented to avoid long locks
- [ ] **Progress tracking** implemented for long operations
- [ ] **Concurrent index creation** used (`CREATE INDEX CONCURRENTLY`)
- [ ] **Constraint validation** deferred where possible
- [ ] **Lock timeout** configured to prevent indefinite blocking

```sql
-- Example batch processing
DO $$
DECLARE
    batch_size INTEGER := 10000;
    affected_rows INTEGER;
BEGIN
    LOOP
        UPDATE large_table 
        SET new_column = calculated_value 
        WHERE new_column IS NULL 
        AND id IN (
            SELECT id FROM large_table 
            WHERE new_column IS NULL 
            LIMIT batch_size
        );
        
        GET DIAGNOSTICS affected_rows = ROW_COUNT;
        EXIT WHEN affected_rows = 0;
        
        RAISE NOTICE 'Updated % rows', affected_rows;
        COMMIT;
    END LOOP;
END $$;
```

---

## ✅ Post-Migration Validation

### ✅ Data Integrity Checks
- [ ] **Row counts** verified (before vs after migration)
- [ ] **Data consistency** checked with sample queries
- [ ] **Foreign key integrity** verified
- [ ] **Constraint violations** checked (none should exist)
- [ ] **Index integrity** verified with REINDEX if needed

```sql
-- Example validation queries
-- Check row counts
SELECT 'before_migration' as period, COUNT(*) FROM table_name_backup
UNION ALL
SELECT 'after_migration' as period, COUNT(*) FROM table_name;

-- Check for constraint violations
SELECT conname, conrelid::regclass 
FROM pg_constraint 
WHERE NOT convalidated;

-- Verify foreign key integrity
SELECT COUNT(*) FROM child_table c
LEFT JOIN parent_table p ON c.parent_id = p.id
WHERE p.id IS NULL AND c.parent_id IS NOT NULL;
```

### ✅ Performance Validation
- [ ] **Query performance** compared to pre-migration benchmarks
- [ ] **Index usage** verified with EXPLAIN ANALYZE
- [ ] **Table statistics** updated with ANALYZE
- [ ] **Slow query log** checked for new performance issues
- [ ] **Connection pool** tested under normal load

### ✅ Application Integration
- [ ] **Application startup** tested successfully
- [ ] **Critical user paths** tested manually
- [ ] **API endpoints** returning expected data
- [ ] **Database connections** stable and performant
- [ ] **Error logs** clean (no new database-related errors)

---

## 🔄 Rollback Procedures

### ✅ Rollback Readiness
- [ ] **Rollback script** prepared and tested
- [ ] **Data restoration** procedure documented
- [ ] **Application compatibility** verified for rollback
- [ ] **Rollback triggers** defined (what conditions require rollback)
- [ ] **Communication plan** ready for rollback scenario

### ✅ Rollback Execution (if needed)
- [ ] **Application traffic** stopped or redirected
- [ ] **Database connections** terminated safely
- [ ] **Rollback script** executed with monitoring
- [ ] **Data integrity** verified after rollback
- [ ] **Application** restarted and tested
- [ ] **Team notification** sent about rollback completion

---

## 📊 Monitoring and Maintenance

### ✅ Immediate Monitoring (first 24 hours)
- [ ] **Query performance** monitored continuously
- [ ] **Error rates** tracked and investigated
- [ ] **Database metrics** (connections, locks, I/O) monitored
- [ ] **Application metrics** checked for anomalies
- [ ] **User feedback** collected and addressed

### ✅ Ongoing Maintenance
- [ ] **Statistics updated** with ANALYZE on affected tables
- [ ] **Vacuum operations** scheduled if large data changes occurred
- [ ] **Index maintenance** planned for heavily modified tables
- [ ] **Documentation** updated with migration details
- [ ] **Post-mortem** conducted if issues occurred

---

## 🚨 Red Flags - Stop Migration If:

- **Database locks** lasting longer than expected timeout
- **Disk space** approaching critical levels during migration
- **Replication lag** growing uncontrollably
- **Application errors** spiking unexpectedly
- **Critical business processes** unable to operate
- **Data corruption** detected during validation

---

## 📋 Migration Types Specific Checks

### ✅ Schema Changes
- [ ] **ALTER TABLE** operations tested on large tables
- [ ] **Column additions** done as nullable first
- [ ] **Data type changes** validated for all existing data
- [ ] **Constraint additions** done with validation strategy

### ✅ Data Migrations
- [ ] **Data transformation** logic tested thoroughly
- [ ] **NULL handling** considered for all operations
- [ ] **Duplicate data** handling strategy implemented
- [ ] **Data validation** rules applied consistently

### ✅ Index Changes
- [ ] **Index creation** done concurrently when possible
- [ ] **Old indexes** dropped after new ones are verified
- [ ] **Query plans** updated to use new indexes
- [ ] **Index bloat** monitored after creation

### ✅ Security Changes
- [ ] **RLS policies** tested with different user roles
- [ ] **Permission changes** validated thoroughly
- [ ] **Access patterns** verified post-migration
- [ ] **Audit trail** maintained for security changes

---

## 📝 Documentation Requirements

### ✅ Migration Documentation
- [ ] **Migration summary** written with business impact
- [ ] **Technical details** documented for future reference
- [ ] **Performance impact** measured and recorded
- [ ] **Lessons learned** documented for team knowledge
- [ ] **Schema changes** updated in documentation

### ✅ Communication
- [ ] **Stakeholders** notified of successful completion
- [ ] **Development team** briefed on any changes
- [ ] **Support team** informed of potential issues to watch
- [ ] **Migration log** shared with relevant teams

---

## 🎯 Success Criteria

Migration is considered successful when:

- ✅ **All validation checks** pass
- ✅ **Application performance** maintained or improved
- ✅ **No data loss** or corruption detected
- ✅ **User experience** unaffected or improved
- ✅ **Error rates** remain within normal bounds
- ✅ **Team confidence** high in the changes

---

## 📞 Emergency Contacts

Document who to contact for:

- **Database emergencies**: [DBA team contact]
- **Application issues**: [Dev team lead]
- **Infrastructure problems**: [DevOps team]
- **Business impact**: [Product owner]
- **Security concerns**: [Security team]

---

## 🔧 Useful Commands for Migration Validation

```sql
-- Check migration status
SELECT version FROM schema_migrations ORDER BY version DESC LIMIT 5;

-- Monitor long-running queries
SELECT pid, now() - pg_stat_activity.query_start AS duration, query 
FROM pg_stat_activity 
WHERE (now() - pg_stat_activity.query_start) > interval '5 minutes';

-- Check database size changes
SELECT pg_size_pretty(pg_database_size(current_database()));

-- Monitor locks
SELECT mode, locktype, database, relation::regclass, transactionid, pid 
FROM pg_locks 
WHERE NOT granted;

-- Check replication lag (if applicable)
SELECT client_addr, state, sync_state, 
       pg_wal_lsn_diff(pg_current_wal_lsn(), sent_lsn) AS pending_bytes
FROM pg_stat_replication;
```

---

*Remember: Migrations should be boring. If a migration is exciting, something probably went wrong.*
