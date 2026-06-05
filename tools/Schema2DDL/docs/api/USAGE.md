# Schema2DDL - API & CLI Usage Guide

`Schema2DDL` translates JSON Schema definitions into relational SQL DDL scripts. This guide shows how to run the CLI console tool, control options, and choose database dialects.

## 1. CLI Usage Reference

The CLI program is named `Schema2DDLCLI.exe` and is located in the release archive or `.bin/` build directory.

### Command Syntax

```bash
Schema2DDLCLI -s <schema_path> [-d <dialect>] [-o <output_path>] [options]
```

### Argument Reference

* `-s, --schema <path>`: Path to the input JSON Schema file. **Required**.
* `-d, --dialect <name>`: Target database dialect. Options: `PostgreSQL` (or `pg`), `Firebird` (or `fb`), `SQLite` (or `sqlite`), `SQLServer` (or `mssql`). Default is `PostgreSQL`.
* `-o, --output <path>`: Output destination for the generated SQL script. Writes directly to **Stdout** if not specified.
* `-t, --table <name>`: Custom main table name. If omitted, uses the schema's `title` keyword.
* `--drop`: Prepend `DROP TABLE IF EXISTS` statement to the output script.
* `--no-auto-inc`: Disable automatic auto-increment constraints on primary keys.
* `-q, --quote`: Enclose database identifiers in double quotes (or dialect-specific brackets).
* `-h, --help`: Display the CLI help manual.

### Examples

**Export PostgreSQL DDL from a schema:**

```bash
Schema2DDLCLI.exe -s customer_schema.json -d PostgreSQL -o create_customer.sql
```

**Generate SQLite DDL with dropped tables and quoted columns:**

```bash
Schema2DDLCLI.exe -s products.json -d SQLite --drop -q
```

---

## 2. VCL GUI App

For a visual experience, double-click `Schema2DDLVCL.exe`. It allows you to:

1. Select the target database from a dropdown.
2. Interactively toggle table drops, quoting, and auto-increment.
3. Paste JSON Schema text directly and click **Generate DDL** to preview the output in real-time.
4. Copy the generated SQL script to the Clipboard or export it to a `.sql` file.
