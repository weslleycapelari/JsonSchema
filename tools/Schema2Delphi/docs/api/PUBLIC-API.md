# Public API Reference - Schema2Delphi

This document outlines the public interface, configuration types, and generation APIs provided by the `Schema2Delphi` tool.

---

## 1. High-Level Utilities ([Schema2Delphi.Utils.pas](../../src/Schema2Delphi.Utils.pas))

These utility overloads serve as the primary entry points for client code:

### Overload 1 (Default Settings)

```pascal
function GenerateClassFromSchema(const pSchema: TJSONObject; const pClassName, pUnitName: string): string;
```

- **`pSchema`**: The parsed JSON schema object.
- **`pClassName`**: Name of the root class or record.
- **`pUnitName`**: Output unit name (the generated Pascal file header will output `unit <pUnitName>;`).
- **Returns**: String containing the complete Pascal source code.

### Overload 2 (Custom Config)

```pascal
function GenerateClassFromSchema(const pSchema: TJSONObject; const pClassName, pUnitName: string; const pConfig: TCodeGeneratorConfig): string;
```

- **`pConfig`**: Custom generator configuration record.

---

## 2. Configuration Options ([Schema2Delphi.Common.pas](../../src/Schema2Delphi.Common.pas))

### `TCodeGeneratorConfig`

Controls how output Pascal code is structured.

- **`GenerationMode`**: `TGenerationMode` (defaults to `gmClass`).
  - `gmClass`: Generates Pascal classes (using property backing fields and destructors).
  - `gmRecord`: Generates lightweight, stack-allocated records.
- **`CustomUses`**: String containing comma-separated unit names (e.g. `'System.JSON, Rest.JsonReflect'`) to inject into the generated unit's uses clause.
- **`UseNullableTypes`**: Boolean. If `True`, wraps nullable schema fields into a nullable type template.
- **`NullableTypeTemplate`**: String template for nullable types (defaults to `'TNullableValue<%s>'`).
- **`DraftVersion`**: `TDraftVersion` specifying which JSON Schema draft parsing rules to apply (e.g. `TDraftVersion.dvDraft2020_12`).

---

## 3. Code Generation Context ([Schema2Delphi.Common.pas](../../src/Schema2Delphi.Common.pas))

### `IGenerationContext`

Interface implemented by the generation engine. Used by subcomponents (`TSchemaTypeMapper`, `ProcessPropertyAttributes`) to query and update state.

- **`GetConfig`**: Returns the active `TCodeGeneratorConfig`.
- **`GetUnit`**: Returns the target AST `TDelphiUnit` instance.
- **`HasClassNameBeenGenerated(const pClassName: string): Boolean`**: Checks if a class name has already been used to prevent duplicates.
- **`EnqueueClass(const pClassName: string; pCompiled: ICompiledSchema)`**: Enqueues a nested schema definition for class code generation.
- **`TryGetProcessedClass(pCompiled: ICompiledSchema; out pClassName: string): Boolean`**: Looks up if a subschema has already been compiled into a Delphi class.
- **`RegisterProcessedClass(pCompiled: ICompiledSchema; const pClassName: string)`**: Registers a compiled subschema target.
- **`TryGetProcessedEnum(pCompiled: ICompiledSchema; out pTypeName: string): Boolean`**: Checks if an enum subschema has already been created.
- **`RegisterProcessedEnum(pCompiled: ICompiledSchema; const pTypeName: string)`**: Registers an enum type.
- **`GenerateCode(pRootSchema: TJSONObject; const pRootClassName, pUnitName, pRootBaseURI: string): string`**: Initiates parsing and walks the AST.
