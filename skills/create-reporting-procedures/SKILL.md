---
name: create-reporting-procedures
description: Guide for building [create] schema reporting layer stored procedures. Use this when the user says "Build a CREATE reporting layer procedure" or when building CREATE procedures that perform initial table creation and full data load from the EDW Silver layer to the Gold Reporting layer.
---

# CREATE Reporting Layer Stored Procedures Skill

This skill guides you through generating a [create] schema reporting procedure for the Gold layer using dimensional modeling (Kimball approach).

## Naming Convention

**Dimensions:** `create.Dim_[Entity]` | **Facts:** `create.Fact_[Entity]`

## Key Differences from EDW Layer

| Aspect | EDW Layer | Reporting Layer |
|--------|-----------|-----------------|
| **Methodology** | Bill Inmon (3NF) | Ralph Kimball (star schema) |
| **Naming** | `[org_subject]` schemas | `[dim]` or `[fact]` schemas |
| **Data Source** | Raw Bronze tables | EDW Silver tables |
| **Hash null placeholder** | `.` (dot) | `''` (empty string) |

## Required Components

1. SET ANSI_NULLS ON / SET QUOTED_IDENTIFIER ON (before CREATE PROCEDURE)
2. SET NOCOUNT ON (inside procedure body)
3. DROP TABLE IF EXISTS
4. CREATE TABLE with proper schema (dim or fact), LoadHash, LoadDateTime, UpdateDateTime
5. INSERT INTO...SELECT with HASHBYTES calculation
6. GO statement at end

## Validation Checklist

- [ ] SET ANSI_NULLS ON and SET QUOTED_IDENTIFIER ON before CREATE PROCEDURE
- [ ] SET NOCOUNT ON inside procedure body
- [ ] DROP TABLE IF EXISTS
- [ ] CREATE TABLE with proper schema (dim or fact) and primary key
- [ ] LoadHash VARBINARY(32), LoadDateTime DATETIME2(7), UpdateDateTime DATETIME2(7) NULL
- [ ] Hash uses CONCAT_WS with '' as null placeholder (reporting convention)
- [ ] Procedure naming follows pattern: `create.[Dim/Fact]_[Entity]`
- [ ] GO statement at end

## Related Skills

Use **merge-reporting-procedures** skill for incremental updates after initial load.
