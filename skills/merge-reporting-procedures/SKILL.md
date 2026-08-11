---
name: merge-reporting-procedures
description: Guide for building [merge] schema reporting layer stored procedures using MERGE with hash-based change detection and audit logging. Use this when the user says "Build a MERGE reporting procedure" or when building MERGE procedures for incremental updates to reporting tables with transaction management and audit trail logging.
---

# MERGE Reporting Layer Stored Procedures Skill

This skill guides you through creating [merge] schema reporting procedures for the Gold layer. MERGE procedures perform incremental updates using hash-based change detection and audit logging.

## Naming Convention

**Facts:** `[merge].[Fact.[Entity]]` | **Dimensions:** `[merge].[Dim.[Entity]]`

## Required Components

Same structure as EDW MERGE procedures with these differences:
- SET ANSI_NULLS ON / SET QUOTED_IDENTIFIER ON before CREATE PROCEDURE
- Source is EDW Silver tables (not raw Bronze)
- Target schemas are `[fact]` or `[dim]` (not `[org_subject]`)
- Hash null placeholder is `''` (empty string, not `.`)
- GO statement at end

## Validation Checklist

- [ ] SET ANSI_NULLS ON and SET QUOTED_IDENTIFIER ON before CREATE PROCEDURE
- [ ] SET NOCOUNT ON and SET XACT_ABORT ON inside procedure body
- [ ] All 9 variables declared plus @MergeOutput table variable
- [ ] Audit log INSERT before transaction with SCOPE_IDENTITY()
- [ ] BEGIN TRY / BEGIN TRANSACTION structure
- [ ] Fail-safe IF EXISTS check on source EDW table
- [ ] MERGE uses correct primary key in ON clause
- [ ] WHEN MATCHED checks LoadHash inequality
- [ ] WHEN NOT MATCHED BY TARGET inserts all columns
- [ ] WHEN NOT MATCHED BY SOURCE deletes
- [ ] OUTPUT $action INTO @MergeOutput
- [ ] CATCH block with @@TRANCOUNT > 0 check
- [ ] RAISERROR at end of CATCH
- [ ] GO statement at end
- [ ] Procedure naming follows pattern: `merge.[Fact/Dim].[Entity]`

## Related Skills

- **create-reporting-procedures** - For initial table creation
- **merge-edw-procedures** - For MERGE procedures in the Silver EDW layer
- **find-edw-reporting-dependencies** - To trace which EDW tables feed into reporting
