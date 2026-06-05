# SchemaValidatorCLI - Command Line Usage

This document describes how to use `SchemaValidatorCLI` to validate JSON instance documents against JSON Schemas, including configuration options, exit codes, output formatting, and redirection patterns.

## Options and Parameters

| Short Option | Long Option | Description | Allowed Values / Defaults |
| :--- | :--- | :--- | :--- |
| `-s` | `--schema` | Path to the JSON Schema file (Required). | File path |
| `-i` | `--instance` | Path to the JSON Instance file (Optional). | File path (Reads from `stdin` if omitted) |
| `-d` | `--draft` | Force schema draft version version. | `6`, `7`, `2019-09`, `2020-12` (Default: Auto-detects or fallback `2020-12`) |
| `-l` | `--locale` | Locale for translated error messages. | `en`, `pt` (Default: `en`) |
| `-f` | `--format` | Output report format. | `text`, `json`, `junit` (Default: `text`) |
| | `--no-format` | Disable schema format validation. | Flag |
| `-h` | `--help` | Display usage manual on stderr. | Flag |

---

## Exit Codes

`SchemaValidatorCLI` returns standard OS exit codes, making it perfect for pipeline integrations:

- **`0`**: Validation Success. The instance fully conforms to the schema.
- **`1`**: Validation Failure. The instance is valid JSON, but violates schema constraints.
- **`2`**: Runtime/Parsing Error. Triggered by missing parameters, file not found, or malformed JSON (schema or instance).

---

## Output Reporting Formats

### 1. Plain Text Format (`-f text` / Default)

Prints a simple summary of validation status and list of errors.

**Success Output**:

```text
Validation succeeded.
```

**Failure Output**:

```text
Validation failed! 2 error(s) found:
[Keyword: type] Invalid type. Expected: integer, actual: string (Resolution: Ensure the value matches the requested type)
[Keyword: minimum] Value must be greater than or equal to 10 (Resolution: Adjust value to respect the minimum limit constraint)
```

### 2. JSON Format (`-f json`)

Assembles a structured JSON array representing error details for easy programmatic parsing.

**Failure Output**:

```json
[
  {
    "keyword": "type",
    "instancePath": "",
    "schemaPath": "",
    "message": "Invalid type. Expected: integer, actual: string",
    "resolution": "Ensure the value matches the requested type"
  }
]
```

### 3. JUnit XML Format (`-f junit`)

Generates standard XML suite records for CI/CD test dashboards (e.g. Jenkins, Azure DevOps).

**Failure Output**:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<testsuite name="JSON Schema Validation" tests="1" failures="1" errors="0" time="0.00">
  <testcase name="Validate customer.json" classname="SchemaValidatorCLI" time="0.00">
    <failure message="Validation failed. 1 error(s) found."><![CDATA[Validation failed. 1 error(s) found:
  - [Keyword: type] Invalid type. Expected: integer, actual: string
]]></failure>
  </testcase>
</testsuite>
```

---

## Piping and Redirection Examples

### Standard File-to-File Validation

```bash
SchemaValidatorCLI.exe -s schema.json -i instance.json
```

### Piping via Stdin

If the `-i` parameter is omitted, the CLI reads the instance payload from standard input:

**PowerShell**:

```powershell
Get-Content instance.json | SchemaValidatorCLI.exe -s schema.json
```

**Linux / Bash**:

```bash
cat instance.json | ./SchemaValidatorCLI -s schema.json
```

### Checking Exit Code in Scripts

**PowerShell**:

```powershell
./SchemaValidatorCLI.exe -s schema.json -i instance.json
if ($LASTEXITCODE -eq 0) {
    Write-Host "JSON conforms to schema!"
} else {
    Write-Error "JSON validation failed (Exit Code: $LASTEXITCODE)"
}
```

**Bash**:

```bash
./SchemaValidatorCLI -s schema.json -i instance.json
exit_code=$?
if [ $exit_code -eq 0 ]; then
    echo "JSON conforms to schema!"
elif [ $exit_code -eq 1 ]; then
    echo "Validation failed!"
else
    echo "Runtime error encountered!"
fi
```
