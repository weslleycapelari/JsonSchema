# Security Policy

This document outlines the security procedures, supported versions, and design-level hardening measures implemented in the Delphi JSON Schema library to protect users and systems from potential exploits.

## Supported Versions

Only the latest major version receives security updates and vulnerability patches.

| Version | Supported | Notes                                                                |
| ------- | --------- | -------------------------------------------------------------------- |
| v2.x.x  | ✅ Yes    | Active development and security maintenance (with refactored tools). |
| v1.x.x  | ❌ No     | End of Life (EOL). Please upgrade.                                   |
| v0.x.x  | ❌ No     | End of Life (EOL). Please upgrade.                                   |

## Reporting a Vulnerability

If you discover a security vulnerability in this project, **do not open a public issue**. Instead, follow these steps:

1. Send an email to the repository owner/maintainer (or use the security contact address specified in the GitHub repository metadata).
2. Include a detailed description of the vulnerability, steps to reproduce, and a minimal proof of concept (PoC) schema or JSON instance.
3. We will acknowledge your report within 48 hours and work with you to analyze and patch the issue.
4. We practice Coordinated Vulnerability Disclosure (CVD). A patch will be developed and tested before a public security advisory (and CVE identifier, if applicable) is published.

---

## Security Design & Hardening

JSON Schema validation involves processing untrusted, dynamic inputs (both schemas and instances). To prevent common classes of vulnerabilities, this library adheres to the following security design rules:

### 1. SSRF and Path Traversal in Reference Resolution

* **Local Reference Scoping**: When resolving local `$ref` URIs using the `file://` scheme, the resolver must block path traversal attempts (e.g. `file:///../../../etc/passwd` or `..\..\..\windows\win.ini`). Paths are canonicalized and validated to ensure they do not escape the designated base directory.
* **Remote Reference Filtering**: Resolving remote references (`http://` or `https://`) can expose systems to Server-Side Request Forgery (SSRF). Users are encouraged to pre-populate the schema registry with local copies of remote schemas or configure strict domain/IP allowlists on their network layer.

### 2. Regular Expression Denial of Service (ReDoS)

* The `pattern` keyword validates strings against regular expressions. Hostile schemas containing complex or backtracking regular expressions (e.g., `(a+)+`) can cause high CPU utilization.
* Delphi uses `System.RegularExpressions` (PCRE underneath on most platforms). It is recommended to run validation with timeouts or restrict schema authors to trusted sources.

### 3. Stack Overflow in Circular References

* Schemas containing recursive definitions (circular `$ref` references) can cause infinite loops during parsing or validation.
* The compiler and registry track the resolution stack depth. If reference resolution exceeds the maximum allowed recursion depth (default: `100`), processing is aborted with an error to prevent stack overflow crashes.

### 4. Code and DDL Injection in Generators

* Our auxiliary tools (`Schema2REST`, `Schema2DDL`, `Schema2Delphi`) generate Delphi units or SQL scripts.
* To prevent injection attacks:
  * **SQL DDL Generator (`Schema2DDL`)**: Escapes identifier names and quotes strings to prevent SQL Injection when running generated scripts.
  * **REST Endpoint Generator (`Schema2REST`)**: Escapes single quotes (`'`) by doubling them when writing the raw schema string constant into the generated Pascal file, preventing Delphi code injection.
