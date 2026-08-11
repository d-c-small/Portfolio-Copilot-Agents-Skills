---
name: find-raw-table-references
description: 'Find tables and procedures in your EDW layer that reference specific raw layer tables. Use when asked to "trace EDW dependencies", "find what references a raw table", "identify which procedures use a raw table", or "trace data lineage between layers".'
---

# Find EDW-to-Raw References Skill

Discover dependencies between raw Bronze layer tables and EDW Silver layer procedures. Trace upstream data lineage and assess the impact of raw layer schema changes.

## Quick Reference

```sql
-- Find EDW procedures referencing a raw table
-- Execute in EDW database
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
  AND (sm.definition LIKE '%[raw-hq].[projecthub].[field_activity_completion]%'
       OR sm.definition LIKE '%raw-hq.projecthub.field_activity_completion%')
ORDER BY ProcSchema DESC, ProcName;
```

## ⚠️ Avoiding False Positives

A broad wildcard query once returned **147 procedures** for a raw table reference. After switching to fully-qualified patterns, only **2 procedures** actually referenced it. The other 145 were false positives from comments/headers.

Always use **fully-qualified three-part references** (`[database].[schema].[table]`).

## Workflow

1. **Identify input**: Raw database name + schema + table name
2. **Run summary count** by procedure schema
3. **Get detailed list** with procedure definitions
4. **Optionally check column-level** references for rename/drop impact

## Best Practices

1. Always use fully-qualified patterns
2. Search both `create` and `merge` schemas
3. Verify results by inspecting FROM/JOIN references in procedure code
4. Document dependencies when planning schema changes
5. Run in non-production first
