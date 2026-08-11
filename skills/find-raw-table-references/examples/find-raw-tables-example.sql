-- ============================================================================
-- Find EDW-to-Raw Dependencies Example
-- ============================================================================
-- Run this in the EDW database
-- Searches for EDW procedures referencing [raw-hq].[salespro].[opportunities]
-- ============================================================================

-- STEP 1: Summary count by procedure schema
SELECT 
    OBJECT_SCHEMA_NAME(sm.object_id) AS ProcedureSchema,
    COUNT(*) AS ProcedureCount
FROM sys.sql_modules sm
INNER JOIN sys.objects o ON sm.object_id = o.object_id
WHERE o.type = 'P'
  AND OBJECT_SCHEMA_NAME(sm.object_id) IN ('create', 'merge')
  AND (
      sm.definition LIKE '%[raw-hq].[salespro].[opportunities]%'
      OR sm.definition LIKE '%[raw-hq].[salespro].opportunities%'
      OR sm.definition LIKE '%[raw-hq].salespro.[opportunities]%'
      OR sm.definition LIKE '%raw-hq.salespro.opportunities%'
  )
GROUP BY OBJECT_SCHEMA_NAME(sm.object_id)
ORDER BY ProcedureSchema DESC;

-- STEP 2: Detailed list of referencing procedures
SELECT 
    OBJECT_SCHEMA_NAME(sm.object_id) AS ProcedureSchema,
    OBJECT_NAME(sm.object_id) AS ProcedureName,
    CASE OBJECT_SCHEMA_NAME(sm.object_id)
        WHEN 'create' THEN '[CREATE] - Initial Load'
        WHEN 'merge' THEN '[MERGE] - Incremental Update'
    END AS ProcedureType,
    SUBSTRING(sm.definition, 1, 500) AS ProcedureDefinition
FROM sys.sql_modules sm
INNER JOIN sys.objects o ON sm.object_id = o.object_id
WHERE o.type IN ('P', 'PC')
  AND OBJECT_SCHEMA_NAME(sm.object_id) IN ('create', 'merge')
  AND (
      sm.definition LIKE '%[raw-hq].[salespro].[opportunities]%'
      OR sm.definition LIKE '%[raw-hq].[salespro].opportunities%'
      OR sm.definition LIKE '%[raw-hq].salespro.[opportunities]%'
      OR sm.definition LIKE '%raw-hq.salespro.opportunities%'
  )
ORDER BY OBJECT_SCHEMA_NAME(sm.object_id) DESC, OBJECT_NAME(sm.object_id);

-- STEP 3: Check specific column references
SELECT 
    OBJECT_SCHEMA_NAME(sm.object_id) AS ProcedureSchema,
    OBJECT_NAME(sm.object_id) AS ProcedureName,
    CASE WHEN sm.definition LIKE '%opportunity_id%' THEN 'opportunity_id referenced'
         WHEN sm.definition LIKE '%account_name%' THEN 'account_name referenced'
         ELSE 'Column not referenced'
    END AS ColumnReference
FROM sys.sql_modules sm
INNER JOIN sys.objects o ON sm.object_id = o.object_id
WHERE o.type IN ('P', 'PC')
  AND OBJECT_SCHEMA_NAME(sm.object_id) IN ('create', 'merge')
  AND sm.definition LIKE '%[raw-hq].[salespro].[opportunities]%'
  AND (sm.definition LIKE '%opportunity_id%' OR sm.definition LIKE '%account_name%')
ORDER BY OBJECT_SCHEMA_NAME(sm.object_id) DESC;
