-- ============================================================================
-- Find EDW-to-Reporting Dependencies Example
-- ============================================================================
-- Run this in the reporting database
-- Searches for reporting procedures referencing [EDW].[hq_fieldops].[ProjectHub_Completion]
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
      sm.definition LIKE '%[EDW].[hq_fieldops].[ProjectHub_Completion]%'
      OR sm.definition LIKE '%[EDW].[hq_fieldops].ProjectHub_Completion%'
      OR sm.definition LIKE '%[EDW].hq_fieldops.[ProjectHub_Completion]%'
      OR sm.definition LIKE '%EDW.hq_fieldops.ProjectHub_Completion%'
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
      sm.definition LIKE '%[EDW].[hq_fieldops].[ProjectHub_Completion]%'
      OR sm.definition LIKE '%[EDW].[hq_fieldops].ProjectHub_Completion%'
      OR sm.definition LIKE '%[EDW].hq_fieldops.[ProjectHub_Completion]%'
      OR sm.definition LIKE '%EDW.hq_fieldops.ProjectHub_Completion%'
  )
ORDER BY OBJECT_SCHEMA_NAME(sm.object_id) DESC, OBJECT_NAME(sm.object_id);
