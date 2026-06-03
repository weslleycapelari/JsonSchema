# Coding Standards

## Delphi style baseline

- Use 2 spaces for indentation.
- Do not use tabs in source files.
- Keep lines to a maximum of 150 columns.
- Use one space after commas.
- Use one space around assignment operators.
- Avoid vertically aligning parameters or assignments with extra spacing.

## Language usage

- Keep reserved words lowercase.
- Keep primitive type names in canonical casing.
- Prefer `case` over long `if` chains when appropriate.
- Avoid `with`.
- Avoid `Break` and `Continue`.
- Use `Exit` only as a guard clause.

## Naming

- Prefix fields with `F`.
- Prefix local variables with `l`.
- Keep names descriptive and consistent with the existing codebase.
- Avoid abbreviations that make the code harder to read.

## Error handling

- Use `try..finally` for owned resources.
- Do not release unrelated resources in a single `finally` block.
- Use `try..except` only when there is a real handling path.
- Do not swallow exceptions.

## Documentation

- Write code comments and XML documentation in English.
- Use a responsibility header block at the top of each unit.
- Keep XML documentation compact when it fits in one line.
- Use multiline XML tags with inner indentation when the text is longer.
- Do not place `{$REGION}` in `interface` sections.

## Architecture rules reflected in code

- Keep the public facade small.
- Keep keyword parsing close to the keyword unit.
- Keep translation separate from validation.
- Keep schema registry and reference resolution centralized.

## What to avoid

- Monolithic validator classes.
- Hardcoded keyword name chains in runtime logic.
- Broad refactors that are not necessary for the requested change.
- Documenting unverified runtime support as confirmed behavior.
