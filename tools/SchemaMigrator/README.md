# SchemaMigrator

`SchemaMigrator` is a tool for migrating JSON Schemas between different draft versions. It automates conversions from older specifications (like Draft 4 or Draft 7) up to modern specifications like Draft 2020-12.

## Features

- **Keyword Mapping**: Automatically translates renamed or deprecated keywords (e.g. `dependencies` to `dependentRequired`/`dependentSchemas`, `definitions` to `$defs`).
- **Boolean Schema Conversions**: Upgrades legacy style empty schemas or logical constraints to modern boolean literals where applicable.
- **Id Keyword Adjustments**: Safely translates legacy `id` definitions into `$id` and handles base URI adjustments.
- **Structure Prettifying**: Re-orders keywords to put core metadata and schema identifiers at the top of the schema file.
