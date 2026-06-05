# Schema2Doc - Architectural Planning

## Overview

`Schema2Doc` converts a JSON Schema model into structured documentation using a templating engine.

## Component Architecture

```mermaid
flowchart TD
    A[JSON Schema] --> B[Schema Schema Walker]
    B --> C[Model Extractor]
    C --> D[Template Engine]
    D --> E[HTML/Markdown Output]
```

### 1. Model Extractor

- Traverses the schema structures to build a flattened document tree.
- Resolves all local references to display nested types inline or as links.

### 2. Template Renderer

- Uses pre-built templates (Markdown or HTML/CSS) to render documentation sections.
- Formats type constraints cleanly (e.g. `string (min: 5, max: 20)` instead of separate JSON properties).
