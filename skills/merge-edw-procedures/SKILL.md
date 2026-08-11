---
name: merge-edw-procedures
description: Guide for building [merge] schema stored procedures using MERGE with hash-based change detection and audit logging. Use this when the user says "Build a MERGE schema stored procedure" or when building MERGE schema stored procedures for incremental updates with transaction management and audit trail logging.
---

# EDW MERGE Stored Procedures Skill

This skill guides you through creating [merge] schema stored procedures for the EDW Silver layer. MERGE procedures perform incremental updates using hash-based change detection and full audit logging.

## Naming Convention

**Pattern:** `merge.[org]_[subject].[SourceSystem]_[Entity]`

**Examples:**
- `merge.hq_fieldops.ProjectHub_Completion`
- `merge.sub_finance.AcctVision_Account`

## Key Differences from CREATE Procedures

| Aspect | CREATE | MERGE |
|--------|--------|-------|
| SET options | `SET NOCOUNT ON` | `SET NOCOUNT ON` + `SET XACT_ABORT ON` |
| Transaction handling | None | BEGIN TRY / BEGIN CATCH |
| Audit logging | None | Logs to `[EDW].[pipe].[ETL_AuditLog]` |
| Error handling | None | Catches and logs errors |
| Data operation | INSERT all rows | MERGE with change detection |
| Row tracking | None | Tracks INSERT/UPDATE/DELETE counts |

## Required Components

### Variable Declarations
```sql
DECLARE @ProcedureName NVARCHAR(255) = OBJECT_NAME(@@PROCID)
DECLARE @AuditLogID BIGINT
DECLARE @RowsInserted INT = 0
DECLARE @RowsUpdated INT = 0
DECLARE @RowsDeleted INT = 0
DECLARE @ErrorMessage NVARCHAR(MAX)
DECLARE @ErrorNumber INT
DECLARE @ErrorSeverity INT
DECLARE @ErrorState INT
DECLARE @MergeOutput TABLE (Action NVARCHAR(10))
```

### Audit Logging Flow

| Step | Action | Audit Status |
|------|--------|--------------|
| Start | INSERT audit entry | 'Started' |
| Success | UPDATE audit entry | 'Success' |
| Skipped | UPDATE audit entry | 'Skipped' |
| Error | UPDATE audit entry | 'Failed' |

### MERGE Operation (all three conditions required)
```sql
WHEN MATCHED AND target.LoadHash <> source.LoadHash THEN UPDATE ...
WHEN NOT MATCHED BY TARGET THEN INSERT ...
WHEN NOT MATCHED BY SOURCE THEN DELETE
OUTPUT $action INTO @MergeOutput;
```

## Validation Checklist

- [ ] SET NOCOUNT ON and SET XACT_ABORT ON present
- [ ] All 9 variables declared plus @MergeOutput table variable
- [ ] Audit log INSERT before transaction with SCOPE_IDENTITY()
- [ ] BEGIN TRY / BEGIN TRANSACTION structure
- [ ] Fail-safe IF EXISTS check on source
- [ ] MERGE uses correct primary key in ON clause
- [ ] WHEN MATCHED checks LoadHash inequality
- [ ] WHEN NOT MATCHED BY SOURCE includes DELETE
- [ ] OUTPUT $action INTO @MergeOutput
- [ ] Row counts extracted from @MergeOutput
- [ ] CATCH block includes @@TRANCOUNT > 0 check before ROLLBACK
- [ ] Audit log updated with Failed status in CATCH
- [ ] RAISERROR at end of CATCH

## Related Skills

- **create-edw-procedures** - For initial table creation (must exist before MERGE can run)
- **merge-reporting-procedures** - For MERGE procedures in the Gold reporting layer
