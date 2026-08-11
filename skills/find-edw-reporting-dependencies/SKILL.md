---
name: find-edw-reporting-dependencies
description: 'Find reporting layer procedures that reference specific EDW (Silver) layer tables. Use when asked to "find downstream dependencies", "trace EDW to reporting", "what reporting procedures reference this EDW table", "impact analysis for EDW changes", or "what breaks if I change this EDW table".'
---

# Find EDW-to-Reporting Dependencies Skill

Discover dependencies between your EDW Silver layer and Reporting Gold layer. Trace downstream data lineage and assess the impact of EDW schema changes on reporting procedures.

## Quick Reference

```sql
-- Find reporting procedures referencing an EDW table
-- Execute in the reporting database
-- WARNING: Only use fully-qualified patterns to avoid false positives!
SELECT 
    OBJECT_SCHEMA_NAME(sm.object_id) AS ProcSchema,
    OBJECT_NAME(sm.object_id) AS ProcName,
    CASE OBJECT_SCHEMA_NAME(sm.object_id) 
        WHEN 'create' THEN '[CREATE]' WHEN 'merge' THEN '[MERGE]' 
    END AS ProcType
FROM sys.sql_modules sm
INNER JOIN sys.objects o ON sm.object_id = o.object_id
WHERE o.type = 'P'
  AND OBJECT_SCHEMA_NAME(sm.object_id) IN ('create', 'merge')
  AND (sm.definition LIKE '%[EDW].[hq_fieldops].[ProjectHub_Completion]%'
       OR sm.definition LIKE '%EDW.hq_fieldops.ProjectHub_Completion%')
ORDER BY ProcSchema DESC, ProcName;
```

## ⚠️ Avoiding False Positives

Overly broad patterns like `LIKE '%[EDW]%[table_name]%'` match table names in comments, headers, and variable names. Always use **fully-qualified three-part references** to find actual FROM/JOIN usage.

## Workflow

1. **Identify input**: EDW schema name + table name
2. **Run summary count** by procedure schema (create vs merge)
3. **Get detailed list** of referencing procedures
4. **Optionally check column-level references** for specific column impact

## Best Practices

1. Always use fully-qualified patterns to avoid false positives
2. Search both `create` and `merge` schemas
3. Verify results by inspecting procedure definitions for FROM/JOIN references
4. Run in non-production first to validate impact before deploying changes
