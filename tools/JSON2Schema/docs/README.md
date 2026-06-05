# JSON2Schema - Technical Documentation

`JSON2Schema` reads arbitrary JSON instance documents and infers a valid matching JSON Schema structure. It is designed to accelerate writing JSON Schemas from existing API payloads or system configurations.

## Inference Rules

- **Objects (`TJSONObject`)**: Mapped to `"type": "object"` containing the `"properties"` dictionary. If `--required` is enabled, all properties are listed inside `"required"`.
- **Arrays (`TJSONArray`)**: Mapped to `"type": "array"`. Homogeneous arrays result in a single schema inside `"items"`. Heterogeneous arrays use `"anyOf"` specifying all unique sub-types.
- **Numbers (`TJSONNumber`)**: Numbers without decimal points or exponent symbols map to `"type": "integer"`. Other numbers map to `"type": "number"`.
- **Booleans**: Map to `"type": "boolean"`.
- **Nulls**: Map to `"type": "null"`.
- **Strings (`TJSONString`)**: Map to `"type": "string"`. If `"InferFormats"` is active, format is checked against date-time (ISO 8601), date (YYYY-MM-DD), email, or UUIDv4 regex matches.

## Command-Line Usage

```bash
JSON2SchemaCLI.exe -i <input_json_path> [-o <output_schema_path>] [-d <draft_url>] [--required] [--no-format]
```

## VCL Graphical Interface

- **Input Editor**: Colleague text sample JSON payload.
- **Configurations**: Toggle checkboxes to include all properties in `"required"` array or toggle format regex-based parsing on strings. Select schema draft identifier.
- **Output Editor**: Read-only monospace pretty formatted JSON Schema ready to copy or export directly.
