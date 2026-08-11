---
applyTo: "**/*.sql"
---

# SQL Coding Standards

## Keyword Formatting
- UPPERCASE for all SQL keywords: `SELECT`, `FROM`, `WHERE`, `JOIN`, `INSERT`, `UPDATE`, `DELETE`
- UPPERCASE for data types: `VARCHAR`, `INT`, `BIGINT`, `DATE`, `DATETIME2`, `BIT`, `DECIMAL`
- UPPERCASE for constraints: `PRIMARY KEY`, `NOT NULL`, `UNIQUE`

## Query Structure
- Use explicit column names (never `SELECT *`)
- Qualify column names with table alias when using multiple tables
- Use meaningful aliases (prefer `dlc` over `t1`)
- Use CTEs instead of nested subqueries

## CTE Naming
- Prefix all CTEs with underscore: `_Projects`, `_TransformedData`
- Use PascalCase after the underscore
- Example: `WITH _FilteredProjects AS`, `WITH _AggregatedMetrics AS`

## Column Naming
- PascalCase in EDW and reporting: `CompletionID`, `ProjectNumber`
- snake_case in raw databases: `completion_id`, `project_number`
- Prefix booleans with `Is` or `Has`

## Security
- **Always parameterize queries** to prevent SQL injection
- Never embed credentials in scripts
- Use `sp_executesql` for dynamic SQL (never string concatenation)

```sql
-- ❌ VULNERABLE
DECLARE @sql NVARCHAR(MAX) = 'SELECT * FROM Users WHERE Username = ''' + @username + '''';

-- ✅ SECURE
DECLARE @sql NVARCHAR(MAX) = 'SELECT * FROM Users WHERE Username = @username';
EXEC sp_executesql @sql, N'@username VARCHAR(255)', @username = @username;
```

## Transaction Management
- Use `SET XACT_ABORT ON` for automatic rollback on errors
- Check `@@TRANCOUNT > 0` before ROLLBACK in CATCH blocks
- Keep transactions as short as possible
- Include `SET NOCOUNT ON` in stored procedures

## Performance
- Avoid functions on indexed columns in WHERE clauses
- Use `EXISTS` instead of `IN` for large subqueries
- Use `TOP` or `OFFSET-FETCH` for pagination

```sql
-- ❌ Can't use index
WHERE YEAR(OrderDate) = 2024

-- ✅ Can use index
WHERE OrderDate >= '2024-01-01' AND OrderDate < '2025-01-01'
```

## Code Review Checklist
- [ ] All queries parameterized (no SQL injection)
- [ ] Indexes support query patterns
- [ ] TRY/CATCH error handling present
- [ ] Transaction management with proper rollback
- [ ] No hardcoded credentials
- [ ] Consistent naming conventions
- [ ] Comments explain complex logic
- [ ] Audit logging for ETL procedures
