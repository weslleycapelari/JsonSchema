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

The following tools have been completed, standardized under the architecture template, and compiled successfully with passing tests:

- **[SchemaMockGen](../../tools/SchemaMockGen/README.md)**: Generates valid mock JSON instances based on schema constraints.
- **[Schema2Delphi](../../tools/Schema2Delphi/README.md)**: Generates Delphi DTO classes and records from JSON schemas.
- **[SchemaValidator](../../tools/SchemaValidator/README.md)**: Validates JSON instance files against schemas using the core engine.
- **[Delphi2Schema](../../tools/Delphi2Schema/README.md)**: Scan Delphi classes or records using Extended RTTI and automatically export matching JSON Schema files.
- **[Schema2DDL](../../tools/Schema2DDL/README.md)**: Translate a JSON Schema into relational SQL DDL scripts.
- **[Schema2REST](../../tools/Schema2REST/README.md)**: Scan JSON schemas representing API endpoints and automatically generate a Horse router or DMVC controller with payload validation.
- **[JSON2Schema](../../tools/JSON2Schema/README.md)**: Infer an intelligent JSON Schema by scanning JSON examples.
- **[Schema2Doc](../../tools/Schema2Doc/README.md)**: Generate Markdown or HTML documentation from JSON Schema definitions.
- **[SchemaLinter](../../tools/SchemaLinter/README.md)**: Run static analysis checks on JSON Schemas to detect logic conflicts, regex ReDoS risks, deprecated keywords, and documentation gaps.
- **[SchemaBundler](../../tools/SchemaBundler/README.md)**: Bundle split multi-file JSON schemas containing external file references into a single, self-contained schema file.
- **[SchemaMigrator](../../tools/SchemaMigrator/README.md)**: Migrate legacy JSON Schemas (Draft 4/6/7) to modern specifications (Draft 2020-12).
- **[SchemaOptimizer](../../tools/SchemaOptimizer/README.md)**: Analyze and optimize JSON schemas by pruning unused definitions, merging non-conflicting properties, and flattening logical blocks.

---

## 3. Remaining Tool Roadmap (Phased Execution)

### Phase 3: IDE Integration & Testing Support

#### 5. VisualTestSuiteRunner (Visual Test Suite Client)

- **Concept**: A graphical DUnit/FMX test visualizer that loads the official JSON Schema Test Suite and displays a visual tree structure of keywords and their compliance status.
- **Structure**:
  - `tools/VisualTestSuiteRunner/VisualTestSuiteRunnerCLI.dpr`
  - `tools/VisualTestSuiteRunner/VisualTestSuiteRunnerVCL.dpr`
  - `tools/VisualTestSuiteRunner/VisualTestSuiteRunner.groupproj`

#### 6. RADStudioJsonSchemaWizard (Delphi IDE Extension)

- **Concept**: A Delphi IDE package plugin (`.bpl`) adding visual context-menus in RAD Studio. It allows developers to validate active JSON editor buffers or generate Delphi classes on the fly without leaving the IDE.
- **Structure**:
  - `tools/RADStudioJsonSchemaWizard/RADStudioJsonSchemaWizard.dpk` (IDE Package)

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
