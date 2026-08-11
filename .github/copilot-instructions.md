# SQL Data Platform Project

## Project Overview

This is an enterprise data platform built on **Azure SQL Managed Instance** using **T-SQL** and following the **medallion architecture** pattern. The platform integrates data from 7+ source systems across a multi-subsidiary organization into a unified analytics layer.

## Architecture Layers

### Bronze Layer (Raw Databases)
- **Purpose**: Source-aligned raw data storage
- **Database Naming**: `raw-[org]` (e.g., `raw-hq`, `raw-sub`)
- **Schema Naming**: `[source_system]` (e.g., `projecthub`, `salespro`, `financeone`)
- **Examples**: `[raw-hq].[projecthub].[field_activity_completion]`

### Silver Layer (EDW Database)
- **Purpose**: Enterprise Data Warehouse — conformed, cleansed data
- **Methodology**: Bill Inmon approach (3NF normalized)
- **Database**: `EDW` (single database)
- **Schema Naming**: `[org]_[subject]` (e.g., `hq_fieldops`, `hq_finance`, `sub_project`)
- **Examples**: `[EDW].[hq_fieldops].[ProjectHub_Completion]`

> **Note**: `hq` = Headquarters (primary), `sub` = Subsidiary, `corp` = Corporate

### Gold Layer (Reporting Databases)
- **Purpose**: Dimensional models optimized for reporting and analytics
- **Methodology**: Ralph Kimball approach (star schema)
- **Database Naming**: `reporting-[org]` (e.g., `reporting-hq`, `reporting-sub`)
- **Schema Types**: `dim`, `fact`, `bridge`, `budget`, `goals`, `map`
- **Examples**: `[reporting-hq].[fact].[FieldActivityCompletion]`

---

## Source Systems

| Source System | Raw Schema | EDW Prefix | Description |
|---------------|------------|------------|-------------|
| ProjectHub | `projecthub` | `ProjectHub_` | Project & field operations management |
| SalesPro | `salespro` | `SalesPro_` | CRM — opportunities, accounts, contacts |
| FinanceOne | `financeone` | `FinanceOne_` | ERP — jobs, cost codes, contracts |
| AcctVision | `acctvision` | `AcctVision_` | Project accounting (subsidiary) |
| SafeTrack | `safetrack` | `SafeTrack_` | Safety & compliance management |
| StaffPlan | `staffplan` | `StaffPlan_` | Resource & workforce planning |
| PeopleCore | `peoplecore` | `PeopleCore_` | HR and workforce management |

---

## ETL Procedure Naming

| Schema | Separator | Pattern | Example |
|--------|-----------|---------|----------|
| `[create]` | Underscore `_` | `[create].[schema_SourceSystem_Entity]` | `[create].[hq_fieldops_ProjectHub_Completion]` |
| `[merge]` | Dot `.` | `[merge].[schema.SourceSystem_Entity]` | `[merge].[hq_fieldops.ProjectHub_Completion]` |

---

## Data Domains

| Domain | Primary Source | EDW Schema | Example Entities |
|--------|----------------|------------|------------------|
| **FieldOps** | ProjectHub | `hq_fieldops` | Completion, Equipment, Manpower |
| **Sales** | SalesPro | `corp_sales` | Opportunities, Accounts |
| **Finance** | FinanceOne | `hq_finance` | Costs, Forecasts, Revenue |
| **Compliance** | SafeTrack | `hq_compliance` | Audits, Incidents |
| **Resources** | StaffPlan | `hq_resources` | Allocations, Schedules |
| **People** | PeopleCore | `hq_people` | Employees, Timekeeping |
| **SubFinance** | AcctVision | `sub_finance` | Projects, Budgets, Invoices |

---

## Critical Project Rules

### Never Do This
- ❌ Modify databases
- ❌ Execute scripts
- ❌ Drop tables or truncate data
- ❌ Embed credentials in SQL scripts
- ❌ Use dynamic SQL without parameterization

### Always Do This
- ✅ Include error handling (TRY/CATCH) in procedures
- ✅ Implement fail-safe checks before MERGE (prevent accidental deletes)
- ✅ Use SET NOCOUNT ON in stored procedures
- ✅ Parameterize all queries to prevent SQL injection

---

## ETL Audit Log

- **Table**: `[EDW].[pipe].[ETL_AuditLog]`
- **Used by**: All [MERGE] procedures in EDW and Reporting layers
- **Tracks**: ProcedureName, StartDateTime, EndDateTime, Status, RowsInserted/Updated/Deleted, Errors

| Layer | [CREATE] Logs? | [MERGE] Logs? |
|-------|----------------|---------------|
| Bronze | ❌ | ❌ |
| Silver (EDW) | ❌ | ✅ |
| Gold (Reporting) | ❌ | ✅ |

---

## Performance Considerations

- Use appropriate indexes for frequently queried columns
- Avoid functions on indexed columns in WHERE clauses
- Use batch processing for large data operations
- Implement appropriate transaction isolation levels
- Monitor long-running transactions that may lock tables
