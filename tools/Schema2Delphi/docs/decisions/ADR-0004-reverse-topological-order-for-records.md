# ADR-0004: Reverse Topological Order for Records

## Status

Approved

## Context

When generating code in record mode (`gmRecord`), nested structures (such as arrays of records or record properties) reference other generated records. E.g. record `TPerson` has a field `FFriends: TArray<TFriends>`.

Unlike Delphi classes, which support forward declarations:

```pascal
type
  TPerson = class; // Forward declaration
  TFriends = class;
```

Delphi records **do not** support forward declarations. If the compiler encounters record `TPerson` containing a reference to `TFriends` before `TFriends` is declared, compilation fails with an `Undeclared identifier` error.

## Decision

We decided to generate records in a reversed topological dependency order:

- The code generator tracks when classes/records are enqueued and processed.
- For classes (`gmClass`), we emit forward declarations and write the definitions in standard queue order.
- For records (`gmRecord`), we serialize the declarations in reverse order (e.g. from the last processed element back to the first). This guarantees that nested child records (leaves) are declared before the parent records referencing them, eliminating compilation issues.

## Consequences

- **Pros**:
  - Ensures 100% clean, error-free compilation of generated records without needing forward declaration syntax.
- **Cons**:
  - The root record is printed at the bottom of the type section instead of the top, which is slightly less intuitive for human reading.
