---
name: quality-review
description: Runs a high-level architectural and standards audit on a file, folder, or project using the MAS (Multi-Agent System) of specialized guardians.
---

# Supreme Architectural Audit & Refactor

Purpose:
Perform a deep, multi-dimensional review of the selected Delphi code scope. You must act as the "Supreme Orchestrator", invoking the specialized knowledge of all repository guardians.

Guardians to Consult:

1. **Ebook Standards Maestro**: For syntax, naming prefixes (l, p, F), and formatting.
2. **YAGNI Guardian**: To remove speculative code and premature abstractions.
3. **KISS Guardian**: To simplify convoluted logic and "clever" code.
4. **DRY Architect**: To centralize duplicated business knowledge and rules.
5. **SOLID Architect**: To decouple classes, inject dependencies, and fix "God Classes".
6. **Clean Code Guardian**: To fix method sizes, bad names, and "Code Smells".

Workflow:

## PHASE 1: DIAGNOSIS (The Report)

Analyze the requested scope (file, folder, or workspace) and generate a report with the following structure:

1. **Executive Summary**: A high-level health score for the code (0-100%).
2. **Critical Violations**: List everything that MUST be fixed (Break/Continue, "with", global vars, memory leaks, unsafe exceptions).
3. **Architectural Debt**: Identify violations of SOLID, DRY, YAGNI, and KISS.
4. **Style & Cleanliness**: Identify naming issues and readability "smells".
5. **Refactoring Roadmap**: A step-by-step plan on how to clean this code safely.

---

## PHASE 2: EXECUTION (The Fix)

If the user requests changes (or adds the flag `--apply`), follow these rules:

- **Incremental Change**: Apply changes one dimension at a time (e.g., first Naming/Syntax, then SRP extraction, then DIP).
- **Safety First**: Do NOT change the business logic or JSON Schema validation rules.
- **Test Alignment**: For every extracted class or complex refactor, suggest the corresponding Unit Test structure.
- **Format**: Provide the final, clean Delphi code following the Delphi Standards strictly.

Instructions for the Agent:

- If reviewing a **Folder or Project**, start by summarizing the overall structure and naming the most problematic units first.
- If the file is too large (+1000 lines), break your report into class-level or method-level sections.
- Always use the Delphi Standards as your "Single Source of Truth" for Delphi syntax.

Confirmation Gate:
After the report, ask: "Would you like me to apply the suggested refactorings for `File/Class Name`? Please specify if you want a full refactor or just a specific pillar (e.g., only Naming)."
