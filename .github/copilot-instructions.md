# SQL Data Platform Project

## Project Overview

This is an enterprise data platform built on **Azure SQL Managed Instance** using **T-SQL** and following the **medallion architecture** pattern. The platform serves a construction company with multiple subsidiaries, integrating data from 7+ source systems into a unified analytics layer.

## Architecture Layers

### Bronze Layer (Raw Databases)
- **Purpose**: Source-aligned raw data storage
- **Content**: Exact replicas from source systems
- **Database Naming**: `raw-[org]` (e.g., `raw-ac`, `raw-ae`)
- **Schema Naming**: `[source_system]` (e.g., `procore`, `dynamics`, `cmic`, `deltek`)
- **Table Naming**: `[source_system].[EntityName]`
- **Examples**:
  - `[raw-ac].[procore].[daily_log_completion]`
  - `[raw-ac].[dynamics].[opportunities]`
  - `[raw-ae].[deltek].[project]`

### Silver Layer (EDW Database)
- **Purpose**: Enterprise Data Warehouse — conformed, cleansed data
- **Methodology**: Bill Inmon approach (3NF normalized)
- **Database**: `EDW` (single database)
- **Schema Naming**: `[org]_[subject]` (e.g., `ac_dailylog`, `ac_correspondences`, `ae_project`, `corp_pursuit`)
- **Table Naming**: `[SourceSystem]_[EntityName]`
- **Examples**:
  - `[EDW].[ac_dailylog].[Procore_Completion]`
  - `[EDW].[corp_pursuit].[CRM_Opportunities]`
  - `[EDW].[ae_project].[Deltek_Project]`

> **Note**: `ac` = Acme Construction (primary), `ae` = Acme Engineering (subsidiary), `corp` = Corporate

### Gold Layer (Reporting Databases)
- **Purpose**: Dimensional models optimized for reporting and analytics
- **Methodology**: Ralph Kimball approach (star schema)
- **Database Naming**: `reporting-[org]` (e.g., `reporting-ac`, `reporting-ae`)
- **Schema Types**:
  - `dim` — Dimension tables (e.g., `[dim].[Project]`, `[dim].[Accounts]`)
  - `fact` — Fact tables (e.g., `[fact].[DailyLogCompletion]`, `[fact].[Billings]`)
  - `bridge` — Bridge tables for many-to-many relationships
  - `budget` — Budget-specific tables
  - `goals` — Goals and targets tables
  - `map` — Mapping tables
  - `gantt` — Schedule/Gantt chart tables
- **Examples**:
  - `[reporting-ac].[dim].[Project]`
  - `[reporting-ac].[fact].[DailyLogCompletion]`
  - `[reporting-ac].[bridge].[ProjectUser]`

---

## Database Catalog

| Layer | Database | Org | Schemas | Purpose |
|-------|----------|-----|---------|----------|
| Bronze | `raw-ac` | Acme Construction | `procore`, `dynamics`, `cmic`, `hammertech`, `bridgit`, `ukg`, `ref` | Raw data from primary source systems |
| Bronze | `raw-ae` | Acme Engineering | `deltek`, `procore`, `dynamics`, `hammertech`, `ref` | Raw data from subsidiary source systems |
| Bronze | `raw-ext` | — | (various) | External data sources |
| Silver | `EDW` | All | `ac_*`, `ae_*`, `corp_*`, `create`, `merge`, `pipe`, `metadata` | Conformed enterprise data warehouse |
| Gold | `reporting-ac` | Acme Construction | `dim`, `fact`, `bridge`, `budget`, `goals`, `map`, `gantt`, `create`, `merge` | Primary dimensional reporting |
| Gold | `reporting-ae` | Acme Engineering | `dim`, `fact`, `bridge`, `create`, `merge` | Subsidiary dimensional reporting |

---

## Source Systems

Data flows from external source systems through the medallion architecture. Each source system has a consistent naming pattern:

| Source System | Raw Schema | EDW Prefix | Description |
|---------------|------------|------------|-------------|
| Procore | `procore` | `Procore_` | Construction project management (daily logs, RFIs, submittals) |
| Microsoft Dynamics CRM | `dynamics` | `CRM_` | Sales opportunities, accounts, contacts |
| CMiC | `cmic` | `CMIC_` | Construction ERP (jobs, cost codes, contracts) |
| Deltek | `deltek` | `Deltek_` | Project accounting (primarily subsidiary) |
| Hammertech | `hammertech` | `Hammertech_` | Safety management (incidents, inspections) |
| Bridgit | `bridgit` | `Bridgit_` | Resource and workforce planning |
| UKG | `ukg` | `UKG_` | HR and workforce management |

**Example Transformation**:
- Raw: `[raw-ac].[procore].[daily_log_completion]`
- EDW: `[EDW].[ac_dailylog].[Procore_Completion]`
- Reporting: `[reporting-ac].[fact].[DailyLogCompletion]`

---

## Data Lineage Paths

Example end-to-end data flows through the medallion architecture:

| Domain | Bronze (Raw) | Silver (EDW) | Gold (Reporting) |
|--------|--------------|--------------|------------------|
| Daily Logs | `raw-ac.procore.daily_log_completion` | `EDW.ac_dailylog.Procore_Completion` | `reporting-ac.fact.DailyLogCompletion` |
| Opportunities | `raw-ac.dynamics.opportunities` | `EDW.corp_pursuit.CRM_Opportunities` | `reporting-ac.fact.Opportunities` |
| Projects | `raw-ac.procore.projects` | `EDW.ac_project.Procore_Projects` | `reporting-ac.dim.Project` |
| Safety Incidents | `raw-ac.hammertech.incidents` | `EDW.ac_safety.HammerTech_Incidents` | `reporting-ac.fact.SafetyIncidents` |
| Subsidiary Projects | `raw-ae.deltek.project` | `EDW.ae_project.Deltek_Projects` | `reporting-ae.dim.Project` |

---

## ETL Procedure Naming

ETL procedures live in `[create]` and `[merge]` schemas within EDW and reporting databases.

### Naming Convention Difference

| Schema | Separator | Pattern | Example |
|--------|-----------|---------|----------|
| `[create]` | Underscore `_` | `[create].[schema_SourceSystem_Entity]` | `[create].[ac_dailylog_Procore_Completion]` |
| `[merge]` | Dot `.` | `[merge].[schema.SourceSystem_Entity]` | `[merge].[ac_dailylog.Procore_Completion]` |

### Procedure Purpose

| Schema | Purpose | When Used |
|--------|---------|------------|
| `[create]` | Initial table creation + full data load | First-time setup, table rebuilds |
| `[merge]` | Incremental updates with HASHBYTES change detection | Daily/scheduled ETL runs |

**Example EDW Procedures**:
```sql
-- Initial load (CREATE)
EXEC [EDW].[create].[ac_dailylog_Procore_Completion];

-- Incremental update (MERGE)
EXEC [EDW].[merge].[ac_dailylog.Procore_Completion];
```

**Example Reporting Procedures**:
```sql
-- Initial load (CREATE)
EXEC [reporting-ac].[create].[Fact_DailyLogCompletion];

-- Incremental update (MERGE)
EXEC [reporting-ac].[merge].[Fact.DailyLogCompletion];
```

---

## Construction Industry Data Domains

This platform manages construction-specific data across these subject areas:

| Subject Domain | Primary Source | EDW Schema | Example Entities |
|----------------|----------------|------------|------------------|
| **Project** | Multiple (Procore, CMiC, CRM, Bridgit, Hammertech) | `ac_project`, `ae_project` | Projects, ProjectSubcontractors, ExecutionProjects |
| **DailyLog** | Procore | `ac_dailylog` | Completion, Equipment, Manpower, Weather |
| **Pursuit/Sales** | Dynamics CRM | `corp_pursuit` | Opportunities |
| **JobCosting** | CMiC | `ac_jobcosting` | Costs, Forecasts, Projections, EarnedRevenue |
| **Contract** | CMiC | `ac_contract` | AsContracted, AsSold |
| **AccountsPayable** | CMiC | `ac_accountspayable` | SubcontractorCommitments, Vouchers |
| **AccountsReceivable** | CMiC | `ac_accountsreceivable` | Billings, BillingsByPeriod, InvoicePayments |
| **GeneralLedger** | CMiC | `ac_generalledger` | LedgerDetails |
| **FinanceRef** | CMiC | `ac_finance_ref` | Reference tables |
| **ChangeManagement** | CMiC | `ac_changemanagement` | ChangeOrders |
| **Quality** | Procore, Hammertech | `ac_quality` | Inspections, Observations, InspectionAssignees, PTPs |
| **DocumentControl** | Procore | `ac_documentcontrol` | RFIs, Submittals |
| **Correspondences** | Procore | `ac_correspondences` | Correspondences |
| **ResourcePlanning** | Bridgit | `ac_resourceplanning` | ResourceAllocations |
| **People** | UKG | `ac_people` | Employees |
| **SystemUser** | Procore | `ac_systemuser` | Users |
| **Safety** | Hammertech | `ac_safety` | Incidents, IncidentsSubcontractors |
| **Subsidiary Finance** | Deltek | `ae_finance` | AccountBudget, Accounts, Invoices, LedgerDetails |
| **Subsidiary People** | Deltek | `ae_people` | Employees, LaborDetail, TimeKeeping |
| **Subsidiary Project** | Deltek | `ae_project` | Projects, ProjectETC, ProjectSummary |


## Critical Project Rules

### Never Do This
- ❌ Modify databases
- ❌ Execute scripts
- ❌ Drop tables or truncate data
- ❌ Create procedures that modify system tables
- ❌ Embed credentials in SQL scripts
- ❌ Use dynamic SQL without parameterization

### Always Do This
- ✅ Include error handling (TRY/CATCH) when necessary in procedures
- ✅ Implement fail-safe checks before MERGE (prevent accidental deletes)
- ✅ Use SET NOCOUNT ON in stored procedures
- ✅ Parameterize all queries to prevent SQL injection

---

## ETL Audit Log

### Overview
The ETL Audit Log is a centralized tracking system for all data movement operations in the medallion architecture. It provides end-to-end visibility into ETL procedure execution, including timing, row counts, and error details.

### Location & Schema
- **Database**: `[EDW]`
- **Schema**: `[pipe]`
- **Table**: `[EDW].[pipe].[ETL_AuditLog]`

### Table Structure

| Column | Data Type | Description |
|--------|-----------|-------------|
| `AuditLogID` | BIGINT (PK) | Unique identifier for audit log entry |
| `ProcedureName` | NVARCHAR(255) | Full procedure name (e.g., `merge.ac_dailylog_Procore_Completion`) |
| `StartDateTime` | DATETIME2(7) | When the procedure began execution |
| `EndDateTime` | DATETIME2(7) | When the procedure completed (NULL if still running) |
| `Status` | NVARCHAR(50) | Execution status: `Started`, `Success`, `Failed`, `Skipped` |
| `RowsInserted` | INT | Number of rows inserted by MERGE operation |
| `RowsUpdated` | INT | Number of rows updated by MERGE operation |
| `RowsDeleted` | INT | Number of rows deleted by MERGE operation |
| `ErrorMessage` | NVARCHAR(MAX) | Error description (NULL if successful) |
| `ErrorNumber` | INT | SQL Server error number (NULL if successful) |
| `ErrorSeverity` | INT | SQL Server error severity level (NULL if successful) |
| `ErrorState` | INT | SQL Server error state (NULL if successful) |
| `db` | NVARCHAR(100) | Database name where procedure executed |

### When Audit Logging Is Used

| Layer | Operation | Logs to Audit Table? |
|-------|-----------|---------------------|
| Bronze (Raw) | [CREATE] | ❌ No |
| Bronze (Raw) | [MERGE] | ❌ No |
| Silver (EDW) | [CREATE] | ❌ No |
| Silver (EDW) | [MERGE] | ✅ **Yes** |
| Gold (Reporting) | [CREATE] | ❌ No |
| Gold (Reporting) | [MERGE] | ✅ **Yes** |

**Note**: [MERGE] procedures in both the EDW (Silver) and Reporting (Gold) layers log to the audit table. This captures incremental updates where traceability is critical for data governance.

### Example Audit Log Queries

**View recent procedure executions:**
```sql
SELECT TOP 100
    AuditLogID,
    ProcedureName,
    StartDateTime,
    EndDateTime,
    Status,
    RowsInserted,
    RowsUpdated,
    RowsDeleted
FROM [EDW].[pipe].[ETL_AuditLog]
ORDER BY StartDateTime DESC;
```

**Find failed procedures:**
```sql
SELECT
    ProcedureName,
    StartDateTime,
    ErrorMessage,
    ErrorNumber
FROM [EDW].[pipe].[ETL_AuditLog]
WHERE Status = 'Failed'
ORDER BY StartDateTime DESC;
```

**Monitor procedure performance:**
```sql
SELECT
    ProcedureName,
    CONVERT(TIME, DATEADD(SECOND, DATEDIFF(SECOND, StartDateTime, EndDateTime), 0)) AS ExecutionTime,
    RowsInserted + RowsUpdated + RowsDeleted AS TotalRowsAffected,
    StartDateTime
FROM [EDW].[pipe].[ETL_AuditLog]
WHERE Status = 'Success'
ORDER BY StartDateTime DESC;
```

---

## Performance Considerations

- Use appropriate indexes for frequently queried columns
- Avoid functions on indexed columns in WHERE clauses
- Use batch processing for large data operations
- Implement appropriate transaction isolation levels
- Monitor long-running transactions that may lock tables
