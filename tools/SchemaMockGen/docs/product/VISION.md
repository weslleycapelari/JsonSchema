# SchemaMockGen - Product Vision

`SchemaMockGen` is a constraint-driven **Schema-to-Data** mock generator. It parses JSON Schema definitions and generates conforming mock JSON instance documents. It consists of two companion interfaces: a command-line interface (CLI) for shell scripting and automation pipelines, and a VCL Desktop GUI for interactive development.

## Core Features

- **Pipeline & Scripting Ready (CLI)**: Runs validation workflows, accepts redirected inputs/outputs, and returns standard exit codes (`0` for successful mock generation, `2` for errors).
- **Interactive UI (VCL Desktop)**: Provides a graphical user interface to easily browse schema files, input random seed/count parameters, and preview generated mock payloads in real time.
- **Seeded Randomness**: Uses a custom deterministic Linear Congruential Generator (LCG) seed. By specifying a seed, developers can generate identical, reproducible mock datasets across different machines.
- **Constraint Conformity**: Walks type definitions (`null`, `boolean`, `integer`, `number`, `string`, `array`, `object`) and enforces keywords such as `minimum`, `maximum`, `minLength`, `maxLength`, `const`, `enum`, `items`, `required`, and logical combinators (`anyOf`, `oneOf`).
- **Format Presets**: Generates realistic string formats for common presets including `email`, `date-time`, `uuid`, `ipv4`, and `ipv6`.
