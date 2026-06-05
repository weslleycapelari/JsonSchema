# ADR-0003: Pure Interface-Based Reference Counting

## Status

Approved

## Context

The modular type mapper helper (`TSchemaTypeMapper`) needs to query the active generation context to check if a class has been processed, register new enums, or enqueue nested objects. To avoid circular unit references, we passed the context as an interface `IGenerationContext`.

However, since `TJsonSchemaCodeGenerator` implemented this interface but was instantiated using a class-type reference variable (`lCodeGenerator: TJsonSchemaCodeGenerator`) inside the utility functions, passing it as an interface parameter (`pContext: IGenerationContext`) triggered Delphi's automatic reference-counting (ARC) mechanism. Upon returning from the call, the compiler's temporary interface reference count fell to zero, which implicitly destroyed the generator instance, leading to Access Violations on subsequent operations.

## Decision

We decided to expose the main `GenerateCode` method directly inside the `IGenerationContext` interface and mandate that the orchestrator is instantiated and held exclusively as an interface reference:

```pascal
var
  lCodeGenerator: IGenerationContext;
begin
  lCodeGenerator := TJsonSchemaCodeGenerator.Create(pConfig);
  Result := lCodeGenerator.GenerateCode(pSchema, ...);
end;
```

## Consequences

- **Pros**:
  - Leverages Delphi's built-in reference counting safely, guaranteeing automated memory cleanup without risk of premature destruction or Access Violations.
  - Removes the need for explicit `try..finally lCodeGenerator.Free; end;` blocks in callers.
- **Cons**:
  - Requires that all public entry points of the generator go through the interface rather than the concrete class.
