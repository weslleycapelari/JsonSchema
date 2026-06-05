# Schema2Doc - Technical Documentation

`Schema2Doc` compiles metadata from a JSON Schema file and renders clean Markdown tables or fully-contained styled HTML files describing fields and constraints.

## Generation Formats

- **Markdown (`dfMarkdown`)**: Renders property tables with details on type, required status, formats, default values, and description. Handles nested objects as sub-sections.
- **HTML (`dfHTML`)**: Generates complete HTML5 page layouts with visual type badges, interactive clean theme styles, and mobile responsiveness.

## CLI Options

```bash
Schema2DocCLI.exe -s <schema_path> [-o <output_path>] [-f <format>] [-t <title>]
```

Options:

- `-s, --schema`: Path to the input JSON Schema file.
- `-o, --output`: Output file path.
- `-f, --format`: Output format, either `markdown` or `html`.
- `-t, --title`: Title string override.
