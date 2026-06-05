# Developer Tools Roadmap

This roadmap outlines the plan to build, align, and integrate a complete developer tools ecosystem around the core Delphi JSON Schema validation engine.

---

## 1. Unified Tool Architecture Standard

To maintain consistency and ensure ease of distribution, every auxiliary tool developed in the `tools/` directory must strictly follow this Delphi architecture template:

| Component | Naming Pattern | Description |
| :--- | :--- | :--- |
| **Group Project** | `<ToolName>.groupproj` | MSBuild project group to clean and compile the CLI and VCL in one command. |
| **CLI Program** | `<ToolName>CLI.dpr` / `.dproj` | Suffix `CLI`. Standalone console binary for piping and CI/CD automation. |
| **VCL GUI Program** | `<ToolName>VCL.dpr` / `.dproj` | Suffix `VCL`. Modern themed (`Vcl.XPMan`) desktop form for interactive usage. |
| **Shared Source** | Located under `src/` | Shared units for CLI argument parsers, core engines, and GUI main forms. |
| **Test Suites** | Located under `test/` | Automated console/GUI DUnit runners verifying options, pipes, and engines. |

---

## 2. Current Status

The following tools have been completed, standardized under the architecture above, and compiled successfully with passing tests:

- **[SchemaMockGen](../../tools/SchemaMockGen/)** (Completed):
  - Generates valid mock JSON instances based on schema constraints.
  - Linked via `SchemaMockGen.groupproj`, including `SchemaMockGenCLI` and `SchemaMockGenVCL`.
- **[Schema2Delphi](../../tools/Schema2Delphi/)** (Completed):
  - Generates robust Delphi DTO classes and records from JSON schemas.
  - Linked via `Schema2Delphi.groupproj`, including `Schema2DelphiCLI` and `Schema2DelphiVCL`.
- **[SchemaValidator](../../tools/SchemaValidator/)** (Completed):
  - Validates JSON instance files against schemas using the core engine.
  - Linked via `SchemaValidator.groupproj`, including `SchemaValidatorCLI` and `SchemaValidatorVCL`.

---

## 3. Remaining Tool Roadmap (Phased Execution)

### Phase 1: Code Generation & Database Mapping (High Priority)

Focuses on resolving core developer data-mapping tasks between Delphi and relational structures.

#### 1. Delphi2Schema (Code To Schema)

- **Concept**: Scan Delphi classes or records using Extended RTTI and automatically export matching JSON Schema files. Mappings translate basic types, arrays, lists, nested objects, and custom validation attributes (e.g. `[JSONSchemaRequired]`, `[JSONSchemaRange(1, 100)]`) into schema constraints.
- **Structure**:
  - `tools/Delphi2Schema/Delphi2SchemaCLI.dpr`
  - `tools/Delphi2Schema/Delphi2SchemaVCL.dpr`
  - `tools/Delphi2Schema/Delphi2Schema.groupproj`

#### 2. Schema2DDL (Schema To Database)

- **Concept**: Translate a JSON Schema into relational SQL DDL scripts (Firebird, PostgreSQL, MS SQL, Oracle) to automatically create matching database schemas.
  - Objects map to database tables, properties to SQL columns with matching types.
  - String arrays and sub-objects map to sub-tables linked via FOREIGN KEYs.
- **Structure**:
  - `tools/Schema2DDL/Schema2DDLCLI.dpr`
  - `tools/Schema2DDL/Schema2DDLVCL.dpr`
  - `tools/Schema2DDL/Schema2DDL.groupproj`

#### 3. Schema2REST (Schema To REST Client)

- **Concept**: Scan JSON schemas representing API endpoints and automatically generate a complete Delphi REST client consumer unit using the native `REST.Client` library.
- **Structure**:
  - `tools/Schema2REST/Schema2RESTCLI.dpr`
  - `tools/Schema2REST/Schema2RESTVCL.dpr`
  - `tools/Schema2REST/Schema2REST.groupproj`

---

### Phase 2: Schema Manipulation & Migration

Focuses on utilities for compiling, packaging, and optimizing raw schemas.

#### 4. SchemaBundler (Schema Packager)

- **Concept**: Bundle large, multi-file JSON schemas containing external references (`$ref` pointing to local files or remote URLs) into a single, self-contained schema file. It does this by collecting resources under a centralized `$defs` block and correcting pointers locally.
- **Structure**:
  - `tools/SchemaBundler/SchemaBundlerCLI.dpr`
  - `tools/SchemaBundler/SchemaBundlerVCL.dpr`
  - `tools/SchemaBundler/SchemaBundler.groupproj`

#### 5. JSON2Schema (Schema Inference)

- **Concept**: Infer an intelligent JSON Schema by scanning one or more example JSON files. It auto-detects formats (dates, emails, URIs), constraints (maxLength, minimum), and optional vs. required fields.
- **Structure**:
  - `tools/JSON2Schema/JSON2SchemaCLI.dpr`
  - `tools/JSON2Schema/JSON2SchemaVCL.dpr`
  - `tools/JSON2Schema/JSON2Schema.groupproj`

#### 6. SchemaMigrator (Draft Version Migration)

- **Concept**: Upgrade legacy JSON schemas to modern draft dialects (e.g. converting Draft 4/7 schemas to Draft 2020-12 by updating `dependencies` to `dependentRequired`/`dependentSchemas`, renaming `definitions` to `$defs`, etc.).
- **Structure**:
  - `tools/SchemaMigrator/SchemaMigratorCLI.dpr`
  - `tools/SchemaMigrator/SchemaMigratorVCL.dpr`
  - `tools/SchemaMigrator/SchemaMigrator.groupproj`

#### 7. SchemaOptimizer (Schema Simplification)

- **Concept**: Analyze and optimize JSON schemas by removing unused `$defs` definitions, merging redundant type constraints (e.g., simplifying unnecessary nested `allOf` blocks), and flattening equivalent subschemas.
- **Structure**:
  - `tools/SchemaOptimizer/SchemaOptimizerCLI.dpr`
  - `tools/SchemaOptimizer/SchemaOptimizerVCL.dpr`
  - `tools/SchemaOptimizer/SchemaOptimizer.groupproj`

---

### Phase 3: Static Analysis & Documentation

#### 8. SchemaLinter (Schema Static Analyzer)

- **Concept**: Run static analysis checks on JSON Schemas to detect bad design practices, including:
  - Missing annotations (`title`, `description`) in properties.
  - Complex regex patterns (`pattern`) susceptible to Catastrophic Backtracking.
  - Conflicting constraints (e.g. `minimum` greater than `maximum`).
- **Structure**:
  - `tools/SchemaLinter/SchemaLinterCLI.dpr`
  - `tools/SchemaLinter/SchemaLinterVCL.dpr`
  - `tools/SchemaLinter/SchemaLinter.groupproj`

#### 9. Schema2Doc (Documentation Generator)

- **Concept**: Generate detailed, interactive, and human-readable documentation (Markdown, HTML, or PDF) describing schemas, including property trees, rules, and example payloads.
- **Structure**:
  - `tools/Schema2Doc/Schema2DocCLI.dpr`
  - `tools/Schema2Doc/Schema2DocVCL.dpr`
  - `tools/Schema2Doc/Schema2Doc.groupproj`

---

### Phase 4: IDE Integration & Testing Support

#### 10. VisualTestSuiteRunner (Visual Test Suite Client)

- **Concept**: A graphical DUnit/FMX test visualizer that loads the official JSON Schema Test Suite and displays a visual tree structure of keywords and their compliance status.
- **Structure**:
  - `tools/VisualTestSuiteRunner/VisualTestSuiteRunnerCLI.dpr`
  - `tools/VisualTestSuiteRunner/VisualTestSuiteRunnerVCL.dpr`
  - `tools/VisualTestSuiteRunner/VisualTestSuiteRunner.groupproj`

#### 11. RADStudioJsonSchemaWizard (Delphi IDE Extension)

- **Concept**: A Delphi IDE package plugin (`.bpl`) adding visual context-menus in RAD Studio. It allows developers to validate active JSON editor buffers or generate Delphi classes on the fly without leaving the IDE.
- **Structure**:
  - `tools/RADStudioJsonSchemaWizard/RADStudioJsonSchemaWizard.dpk` (IDE Package)

---

## 4. Implementation Guidelines

When picking a new tool to implement:

1. **Rear-to-Front Development**: Build the core functional engine in a shared unit under `src/` first, before writing CLI argument parsers or VCL forms.
2. **Double compilation**: Ensure both the CLI and VCL compile successfully from the group project.
3. **Themes by Default**: Always import `Vcl.XPMan` inside the uses block of your VCL `.dpr` to ensure correct native visual themes.
4. **Local and Global Docs**: Update the setups, tests, and indexes once the tool is built.
5. **Git Pre-Commit**: Add the new tool group project to the automated `scripts/Build-And-Archive-Tools.ps1` script so it automatically builds, packages, and stages its ZIP release during git commits.
