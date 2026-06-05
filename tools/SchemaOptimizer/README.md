# SchemaOptimizer

`SchemaOptimizer` is a schema optimization tool designed to analyze, simplify, and compact JSON Schemas. It reduces schema size, removes redundant logic, and speeds up validation execution.

## Features

- **Combinator Simplification**: Simplifies redundant logical constructs (e.g., merging nested `allOf` blocks or removing redundant `anyOf` schemas).
- **Dead Code Elimination**: Scans the schema and removes unused definitions (`$defs` or `definitions` that are never referenced).
- **Constraint Merging**: Merges overlapping constraints on the same types (e.g. multiple `minimum` constraints merged into the strictest one).
- **Constant Evaluation**: Evaluates statically determinable parts of the schema (like `allOf` containing empty schemas or always-true boolean values).
