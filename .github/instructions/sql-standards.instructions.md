---
applyTo: "**/*.sql"
---

# SQL Coding Standards

## Code Style Guidelines

### Keyword Formatting
- Use UPPERCASE for all SQL keywords: `SELECT`, `FROM`, `WHERE`, `JOIN`, `INSERT`, `UPDATE`, `DELETE`, `CREATE`, `ALTER`, `DROP`
- Use UPPERCASE for data types: `VARCHAR`, `INT`, `BIGINT`, `DATE`, `DATETIME2`, `BIT`, `DECIMAL`
- Use UPPERCASE for constraints: `PRIMARY KEY`, `FOREIGN KEY`, `NOT NULL`, `UNIQUE`, `CHECK`

### Indentation and Readability
- Use consistent indentation (4 spaces or 1 tab) for nested queries and conditions
- Break long queries into multiple lines for readability
- Organize clauses consistently: `SELECT`, `FROM`, `JOIN`, `WHERE`, `GROUP BY`, `HAVING`, `ORDER BY`
- Place each clause on a new line for complex queries
- Align related elements vertically when it improves readability

### Query Structure
- Use explicit column names in SELECT statements instead of `SELECT *`
- Qualify column names with table name or alias when using multiple tables
- Use meaningful table aliases (prefer `dlc` over `t1`, `p` over `t2`)
- Limit the use of subqueries when joins can be used instead
- Use CTEs (Common Table Expressions) for complex logic instead of nested subqueries

### CTE Naming
- Prefix all CTEs with underscore: `_Projects`, `_CompletedDailyLogs`, `_TransformedData`
- Use PascalCase after the underscore for readability
- Use descriptive names that indicate the CTE's purpose or the data it contains
- Example: `WITH _FilteredProjects AS`, `WITH _AggregatedMetrics AS`

### Column and Object Naming
- Use PascalCase for column names in EDW and reporting databases: `DailyLogCompletionID`, `ProjectNumber`, `CompletedByName`
- Use snake_case for raw database columns: `daily_log_completion_id`, `project_number`
- Use descriptive names that indicate the column's purpose
- Prefix boolean columns with `Is`, `Has`, or use clear names like `Completed`, `Distributable`

### Comments and Documentation
- Include comments to explain complex logic
- Add inline comments for non-obvious business rules
- Document assumptions and data quality considerations
- Use `--` for single-line comments
- Use `/* */` for multi-line comment blocks

### Example of Good Formatting
```sql
SELECT
    dlc.DailyLogCompletionID,
    dlc.PCProjectID,
    p.ProjectNumber,
    dlc.LogDate,
    dlc.Completed,
    u.login AS CompletedByEmail
FROM [ac_dailylog].[Procore_Completion] dlc
    LEFT JOIN [raw-ac].[procore].[projects] p 
        ON dlc.PCProjectID = p.project_id
    LEFT JOIN [raw-ac].[procore].[users] u 
        ON dlc.CompletedByID = u.user_id
WHERE dlc.Completed = 1
    AND dlc.LogDate >= '2024-01-01'
ORDER BY dlc.LogDate DESC;
```

## Parameter Handling

### Parameter Naming
- Prefix all parameters with `@`
- Use camelCase for parameter names: `@ProjectId`, `@StartDate`, `@CompanyCode`
- Use descriptive names that indicate the parameter's purpose

### Parameter Organization
- Declare required parameters first, optional parameters later
- Provide default values for optional parameters using `= NULL` or specific defaults
- Group related parameters together

### Parameter Validation
- Validate parameter values before use
- Check for NULL values when parameters are required
- Implement range checks for numeric parameters
- Validate date ranges to prevent invalid queries

### Example Parameter Declaration
```sql
CREATE PROCEDURE [schema].[ProcedureName]
    @projectId BIGINT,                    -- Required parameter
    @startDate DATE,                      -- Required parameter
    @endDate DATE = NULL,                 -- Optional parameter with default
    @companyCode VARCHAR(10),             -- Optional parameter with no default
    @includeInactive BIT = 0              -- Optional parameter with default
AS
BEGIN
    -- Validate required parameters
    IF @projectId IS NULL
        RAISERROR('Parameter @projectId cannot be NULL', 16, 1);
    
    IF @startDate IS NULL
        RAISERROR('Parameter @startDate cannot be NULL', 16, 1);
    
    -- Set default for optional parameters
    IF @endDate IS NULL
        SET @endDate = GETDATE();
    
    -- Procedure logic here
END
```

## Security Best Practices

### SQL Injection Prevention
- **Always parameterize queries** to prevent SQL injection
- Use prepared statements when executing dynamic SQL with `sp_executesql`
- Never concatenate user input directly into SQL strings
- Validate and sanitize all input parameters

### Credential Management
- Never embed credentials in SQL scripts
- Use Windows Authentication or Azure AD authentication when possible
- Store connection strings in secure configuration management
- Use SQL Server roles and permissions, not hardcoded credentials

### Example Secure Dynamic SQL
```sql
-- ❌ VULNERABLE - Never do this
DECLARE @sql NVARCHAR(MAX) = 'SELECT * FROM Users WHERE Username = ''' + @username + '''';
EXEC(@sql);

-- ✅ SECURE - Always use parameterized queries
DECLARE @sql NVARCHAR(MAX) = 'SELECT * FROM Users WHERE Username = @username';
EXEC sp_executesql @sql, N'@username VARCHAR(255)', @username = @username;
```

## Transaction Management

### Transaction Basics
- Explicitly begin and commit transactions using `BEGIN TRANSACTION` and `COMMIT TRANSACTION`
- Use `ROLLBACK TRANSACTION` in error handlers to undo changes
- Include `SET XACT_ABORT ON` to automatically rollback on errors
- Always check `@@TRANCOUNT` before rollback to avoid errors

### Isolation Levels
- Use appropriate isolation levels based on requirements:
  - `READ COMMITTED` (default) - prevents dirty reads
  - `READ UNCOMMITTED` - allows dirty reads, use with caution
  - `REPEATABLE READ` - prevents non-repeatable reads
  - `SERIALIZABLE` - highest isolation, may impact performance
  - `SNAPSHOT` - uses row versioning, good for read-heavy workloads

### Best Practices
- Keep transactions as short as possible
- Avoid long-running transactions that lock tables
- Use batch processing for large data operations
- Release locks as soon as possible by committing quickly
- Include `SET NOCOUNT ON` for stored procedures that modify data to reduce network traffic

### Transaction Template
```sql
BEGIN TRY
    BEGIN TRANSACTION;
    
    -- Your data modification statements here
    UPDATE [schema].[table]
    SET Column = Value
    WHERE Condition;
    
    INSERT INTO [schema].[table] (
        Column1, 
        Column2
    ) VALUES (
        Value1, 
        Value2
    );
    
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
    
    -- Log error details
    DECLARE @ErrorMessage NVARCHAR(MAX) = ERROR_MESSAGE();
    DECLARE @ErrorNumber INT = ERROR_NUMBER();
    
    -- Re-throw error
    RAISERROR(@ErrorMessage, 16, 1);
END CATCH
```

## Performance Optimization

### Indexing Guidelines
- Create indexes on columns frequently used in WHERE clauses
- Index foreign key columns for join performance
- Consider covering indexes for frequently executed queries
- Avoid over-indexing (impacts INSERT/UPDATE/DELETE performance)

### Query Optimization
- Avoid using functions on indexed columns in WHERE clauses (prevents index usage)
- Use `EXISTS` instead of `IN` for large subqueries
- Use `JOIN` instead of subqueries when possible
- Avoid `SELECT *` - specify only needed columns
- Use `TOP` or `OFFSET-FETCH` for pagination

### Avoid These Performance Killers
```sql
-- ❌ Function on indexed column (can't use index)
WHERE YEAR(OrderDate) = 2024

-- ✅ Use this instead (can use index)
WHERE OrderDate >= '2024-01-01' AND OrderDate < '2025-01-01'

-- ❌ Leading wildcard prevents index usage
WHERE ProductName LIKE '%widget%'

-- ✅ If possible, use this (can use index)
WHERE ProductName LIKE 'widget%'
```

## Code Review Checklist

When reviewing SQL code, verify:
- [ ] SQL injection vulnerabilities - all queries parameterized
- [ ] Proper use of parameterization for dynamic SQL
- [ ] Indexes support query patterns
- [ ] Error handling with TRY/CATCH blocks
- [ ] Transaction management with proper rollback
- [ ] No hardcoded credentials or sensitive data
- [ ] Consistent naming conventions followed
- [ ] Comments explain complex logic
- [ ] Performance considerations addressed
- [ ] Audit logging implemented (for ETL procedures)
