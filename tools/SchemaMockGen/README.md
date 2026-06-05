# SchemaMockGen

`SchemaMockGen` is a constraint-driven **Schema-to-Data** generator that produces valid JSON instance documents conforming to a given JSON Schema. It is ideal for seeding databases, generating test payloads, or simulating API responses.

## Features

- **Constraint Compliance**: Generates data that adheres strictly to constraints (like `minimum`/`maximum` for numbers, `minLength`/`maxLength` for strings, and `pattern` regex).
- **Format-Aware Generation**: Automatically generates realistic mock values for standard formats like `email`, `ipv4`, `ipv6`, `date-time`, and `uuid`.
- **Logical Keyword Handling**: Handles complex keywords like `allOf`, `anyOf`, `oneOf`, and conditional `if-then-else` schemas.
- **Deterministic Seeding**: Supports passing a random generator seed to reproduce the exact same set of mock data.
