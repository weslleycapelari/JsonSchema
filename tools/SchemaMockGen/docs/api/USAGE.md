# SchemaMockGen - Usage Guide

This guide describes how to use `SchemaMockGen` (CLI) and `SchemaMockGenGUI` (VCL) to generate mock data.

---

## 1. Command-Line Interface (CLI)

`SchemaMockGen` is pipeline-friendly and runs natively inside terminal environments.

### Options and Parameters

| Short Option | Long Option | Description | Allowed Values / Defaults |
| :--- | :--- | :--- | :--- |
| `-s` | `--schema` | Path to the JSON Schema file (Required). | File path |
| `-o` | `--output` | Path to save the generated mock JSON file (Optional). | File path (Prints to stdout if omitted) |
| `-e` | `--seed` | Deterministic generation seed (Optional). | `Int64` number >= 0 (Default: Random) |
| `-n` | `--count` | Number of mock instances to generate (Optional). | Integer >= 1 (Default: `1`) |
| `-h` | `--help` | Display usage manual. | Flag |

### Exit Codes

- **`0`**: Success. Mock JSON generated and outputted.
- **`2`**: Error. Missing schema path, file read failure, or malformed JSON schema.

### CLI Examples

**Generate Mock JSON to stdout**:

```bash
SchemaMockGen.exe -s product.schema.json
```

**Generate Conforming JSON to a specific output file**:

```bash
SchemaMockGen.exe -s product.schema.json -o mock_product.json
```

**Generate Deterministic/Repeatable Mock Data using a Seed**:
By specifying the seed `-e 12345`, the CLI will always generate the exact same JSON:

```bash
SchemaMockGen.exe -s product.schema.json -e 12345
```

**Generate multiple mock instances (returns a JSON Array of instances)**:

```bash
SchemaMockGen.exe -s product.schema.json -n 5
```

---

## 2. VCL Desktop GUI Interface

`SchemaMockGenGUI` provides an interactive desktop form for testing schemas.

### GUI Steps

1. Double click **`SchemaMockGenGUI.exe`** to open the program.
2. Click **Browse...** to select your schema `.json` file.
3. Configure settings:
   - **Seed**: Enter a positive integer to get deterministic outputs, or click **Random Seed** to generate a randomized seed. Enter `-1` to let the engine randomize it at run time.
   - **Count**: Specify the number of mock instances you want to generate.
4. Click **Generate Mock**.
5. The generated JSON will appear in the Consolas-styled memo box in the lower area.
6. Click **Save to File...** to write the memo contents to a file.
