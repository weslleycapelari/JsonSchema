# Delphi2Schema - API & CLI Usage Guide

`Delphi2Schema` exports JSON Schema contracts from annotated Delphi classes and records. This guide shows how to run the CLI console tool, control options, and document your models using attributes.

## 1. CLI Usage Reference

The CLI program is named `Delphi2SchemaCLI.exe` and is located in the release archive or `.bin/` build directory.

### Command Syntax

```bash
Delphi2SchemaCLI -t <type_name> [-b <bpl_path>] [-o <output_path>] [options]
```

### Argument Reference

* `-t, --type <name>`: The name of the class or record type to scan (e.g. `TSampleUser`). **Required**.
* `-b, --bpl <path>`: Path to a compiled Delphi runtime package (`.bpl`) containing custom type definitions. If omitted, only built-in types (and samples like `TSampleUser`) are scanned.
* `-o, --output <path>`: Output destination for the generated schema. Writes directly to **Stdout** if not specified.
* `-f, --fields`: Scan member fields instead of public/published properties.
* `-p, --properties`: Scan member properties (default behavior).
* `--no-enum-names`: Output enumeration options as integer values (using `minimum` and `maximum` range) instead of string names.
* `-h, --help`: Display the CLI help manual.

### Examples

**Exporting built-in sample user to a file:**

```bash
Delphi2SchemaCLI.exe -t TSampleUser -o user_schema.json
```

**Loading a runtime package (.bpl) and exporting a custom class:**

```bash
Delphi2SchemaCLI.exe --bpl C:\Projects\MyPackage.bpl -t TMyInvoice -o invoice.json
```

**Exporting enums as integers instead of names:**

```bash
Delphi2SchemaCLI.exe -t TSampleUser --no-enum-names
```

---

## 2. VCL GUI App

For a visual experience, double-click `Delphi2SchemaVCL.exe`. It allows you to:

1. Select and load any runtime Delphi package (`.bpl`).
2. Pick any class qualified name from the dropdown.
3. Configure scanning options interactively using checkboxes.
4. Preview the formatted JSON Schema in real-time.

---

## 3. Annotating Classes with Custom Attributes

Import the `Delphi2Schema.Attributes` unit in your source code to annotate your fields and properties. The engine maps these annotations to standard JSON Schema properties:

| Delphi Attribute | Maps to JSON Schema Keyword | Usage Example |
| :--- | :--- | :--- |
| `[JSONSchemaIgnore]` | Excludes the property/field entirely | `[JSONSchemaIgnore] property Salt: string;` |
| `[JSONSchemaTitle('Title')]` | Sets the schema `title` | `[JSONSchemaTitle('User')]` |
| `[JSONSchemaDescription('Desc')]` | Sets the schema `description` | `[JSONSchemaDescription('A profile')]` |
| `[JSONSchemaRequired]` | Adds member to the parent `required` array | `[JSONSchemaRequired] property Email: string;` |
| `[JSONSchemaMinimum(val)]` | Sets numeric `minimum` limit | `[JSONSchemaMinimum(18)] property Age: Integer;` |
| `[JSONSchemaMaximum(val)]` | Sets numeric `maximum` limit | `[JSONSchemaMaximum(100)] property Age: Integer;` |
| `[JSONSchemaMinLength(len)]` | Sets string `minLength` limit | `[JSONSchemaMinLength(3)] property Name: string;` |
| `[JSONSchemaMaxLength(len)]` | Sets string `maxLength` limit | `[JSONSchemaMaxLength(50)] property Name: string;` |
| `[JSONSchemaPattern('regex')]` | Sets string regex validation `pattern` | `[JSONSchemaPattern('^\d{5}$')] property Zip: string;` |
| `[JSONSchemaFormat('fmt')]` | Sets standard string `format` constraints | `[JSONSchemaFormat('email')] property Email: string;` |
| `[JSONSchemaEnumNames('names')]` | Overrides native enum names | `[JSONSchemaEnumNames('Yes, No')] property Active: TMyEnum;` |
