# Product Vision - Schema2Delphi

`Schema2Delphi` is an AST-driven code generation utility that compiles standard JSON Schemas and serializes them into ready-to-use, type-safe Delphi class or record units.

## The Problem

Integrating JSON payloads in Delphi historically required manual DTO (Data Transfer Object) writing, which is error-prone, time-consuming, and hard to maintain as schemas change. While general JSON schema validators check payloads at runtime, they do not provide compile-time safety or auto-completion for Delphi developers.

## The Solution

`Schema2Delphi` automates the creation of Delphi structures by parsing JSON schemas using the core validator's parsing engine, traversing its compiled keyword AST, and translating it into a Delphi Code AST. It outputs Pascal source units containing classes or records that match the schema's properties, enums, required validation rules, and formats.

## Key Features

1. **Dual Generation Modes**:
   - **gmClass**: Generates standard heap-allocated Pascal classes, providing property encapsulation (`read`/`write` properties mapping to private `F` fields), default instance creators, and automatic nested-object lifetime management.
   - **gmRecord**: Generates lightweight stack-allocated Pascal records.

2. **Topological Order for Records**:
   - Since Delphi records do not support forward declarations, `Schema2Delphi` performs topological sorting to emit deepest nested records first, ensuring seamless compilability.

3. **Memory Safety & Leak Protection**:
   - Automatically generates comprehensive destructors in class mode, traversing object arrays with clean loops to free all nested elements safely without leaking heap memory.

4. **Delphi Reserved Keyword Sanitization**:
   - Automatically identifies Delphi keywords (e.g. `type`, `unit`, `record`, `message`) in schema properties and prefixes them (e.g. `AType`, `AUnit`). It attaches a `[JSONName('original')]` serialization attribute so that REST clients can translate them back and forward correctly.

5. **Type-Safe Enum Generation**:
   - Converts JSON Schema string or integer enums into scoped Delphi enum types, prefixing identifiers appropriately to avoid naming collisions.

6. **Nullable Primitive Wrapping**:
   - Maps nullable JSON fields (e.g., `["integer", "null"]`) into generic wrapper templates (e.g., `TNullableValue<T>`), keeping primitive data types nullable-aware.

7. **Validation Attribute Mapping**:
   - Maps validation constraints (e.g. `maxLength`, `description`, `pattern`, `minimum`, `maximum`) directly to Delphi custom attributes to preserve validation logic at the property level.
