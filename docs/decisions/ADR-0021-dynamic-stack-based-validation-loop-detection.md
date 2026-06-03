# ADR-0021 - Dynamic Stack-Based Validation Loop Detection

## Status

Accepted

## Context

Reference resolution keywords (such as `$ref` and `$recursiveRef`) originally utilized simple object-level boolean flags (`FValidating: Boolean`) inside the keyword validator instances. While this was sufficient to prevent stack overflow for direct circular references, it introduced false validation passes (premature loop exits) in complex nested schemas. For example, when validation walked down a tree and evaluated the same sub-schema class instance against different nested nodes of the JSON data structure (e.g. `two levels, no match` in dynamic referencing), the boolean guard incorrectly triggered a loop detection because the keyword validator instance was reused, blocking correct evaluations.

## Decision

We replaced the simplistic boolean flags with a thread-local validation context stack:

1. **Active Schema Frame Tracking**:
   - Declared a `TActiveSchema` record in `JsonSchema.Core.ValidationContext.pas` containing:
     - `SchemaObj: TJSONObject` (the raw schema context).
     - `Compiled: ICompiledSchema` (the compiled validator object).
     - `Instance: TJSONValue` (the specific JSON instance being validated at this node).
   - Updated `TCompiledSchema.Validate` to push the active schema frame onto `TValidationContext.FSchemaStack` prior to evaluating keyword rules and pop it afterwards.

2. **Contextual Loop Detection**:
   - Implemented `TValidationContext.IsCurrentlyValidating(SchemaObj, Instance)` to verify if the exact same schema object and JSON instance pointer exist concurrently in the validation stack.
   - Refactored `TRefKeyword.Validate` and `TRecursiveRefKeyword.Validate` to terminate validation (returning `ValidResult`) only if `IsCurrentlyValidating` returns `True`.

## Consequences

- **Specification Compliance**: Correctly supports dynamic schema validation on complex tree structures, resolving nested validation failures.
- **Robustness**: Terminating loops based on schema context and target instance values eliminates both infinite loops (preventing `EStackOverflow` crashes) and premature validation exits.
- **Thread Safety**: The active stack is managed within thread-local storage (`class threadvar FCurrent`), preventing cross-thread validation collision.
