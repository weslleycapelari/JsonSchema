# ADR-0023 - Unevaluated Properties and Items Tracking

## Status

Accepted

## Context

In Draft 2019-09, the keywords `unevaluatedProperties` and `unevaluatedItems` evaluate only those properties/items of a JSON instance that have not been validated by other applicator keywords (such as `properties`, `patternProperties`, `additionalProperties`, `items`, `additionalItems`, `allOf`, `anyOf`, `oneOf`). Unlike `additionalProperties` which only checks sibling keywords in the same schema object, `unevaluatedProperties` must look across the entire validation run, including nested schemas and dynamically resolved references, requiring a stateful validation scope tracking mechanism.

## Decision

We implemented a validation scope stack and merging algorithm inside `TValidationContext`:

1. **Validation Scope (`TScope`)**:
   - Represents a validation boundary. It houses dictionaries tracking evaluated properties and items for each JSON instance:
     - `PropertyEvaluations: TDictionary<TJSONValue, TList<string>>`
     - `ItemEvaluations: TDictionary<TJSONValue, TList<Integer>>`
   - Exposes `MarkProperty`, `MarkItem`, `IsPropertyMarked`, and `IsItemMarked` methods.

2. **Scope Stack**:
   - Added `FScopeStack: TList<TScope>` to `TValidationContext`.
   - `TCompiledSchema.Validate` pushes a new scope prior to execution and pops it in a `finally` block.

3. **Scope Merging**:
   - Implemented `TScope.Merge(const pSource: TScope)` to copy evaluation records.
   - Refactored `TValidationContext.PopScope(const pKeep: Boolean)`. If the validation of the current schema was successful (`pKeep` is `True`), the popped scope's evaluations are merged into the parent scope. If validation failed (e.g. a sub-schema inside an unsuccessful `anyOf` block), the popped scope is discarded, ensuring failed evaluations do not affect downstream validation.

4. **Keyword Evaluation**:
   - Refactored property/item validation keywords (e.g. `properties`, `items`, `contains`) to call `TValidationContext.MarkPropertyEvaluated` / `MarkItemEvaluated` upon successful checks.
   - Implemented `TUnevaluatedPropertiesKeyword` and `TUnevaluatedItemsKeyword` to run last, evaluating only the properties/items that are not marked as evaluated in the current scope.

## Consequences

- **Specification Compliance**: Fully complies with Draft 2019-09 and Draft 2020-12 dynamic evaluation rules.
- **Accuracy**: Isolation of failed sub-schema evaluations ensures that only valid schema branches contribute to the set of evaluated properties and items.
- **Resource Management**: Scope objects are cleanly freed during popping via `try..finally` blocks, avoiding memory leaks.
