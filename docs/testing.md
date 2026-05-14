# Testing Guide

This document explains the current test harness, available features, and how to run tests after the GUI/Console split.

## Overview

The test suite is organized into two runners that share the same core execution logic.

- GUI runner: DUnit workflow for interactive execution.
- Console runner: CLI workflow with progress bars, failure-only output, filtering, and report generation.
- Shared source: common units used by both runners.
- Shared fixtures: JSON Schema test fixtures under a single schemas root.

## Test Folder Layout

- test/gui: DUnit GUI project.
- test/console: CLI project.
- test/src: shared units used by both runners.
- test/schemas/tests: official-style draft test fixtures.
- test/schemas/remotes: remote fixtures served over HTTP for reference tests.

## Shared Components

### test/src/TestJsonSchema.RunDrafts.pas

Responsibilities:

- Registers DUnit tests for Draft 6, Draft 7, Draft 2019-09, and Draft 2020-12.
- Discovers fixture files and builds suites by draft and file.
- Provides ExecuteForConsole for non-verbose CLI execution.
- Emits progress and failure callbacks to the console host.
- Supports fail-fast behavior.

### test/src/TestJsonSchema.Paths.pas

Responsibilities:

- Resolves root paths relative to the compiled executable.
- Exposes helpers for:
  - test root
  - schemas root
  - schemas/tests root
  - schemas/remotes root

### test/src/TestJsonSchema.RemoteFiles.pas

Responsibilities:

- Starts a local HTTP server for remote reference fixtures.
- Serves files from test/schemas/remotes.
- Used by both GUI and Console runners.

Default local server:

- Host: localhost
- Port: 1234

## GUI Runner

Project:

- test/gui/TestJsonSchema.dproj

Entry point behavior:

- Registers default draft suites.
- Runs registered tests with DUnit test runner.

Typical usage:

1. Open test/gui/TestJsonSchema.dproj in Delphi.
2. Build and run.
3. Execute suites from the DUnit UI.

## Console Runner

Project:

- test/console/TestJsonSchemaConsole.dproj

The console runner executes through ExecuteForConsole and adds a CLI interface with:

- General progress bar: processed tests over total tests.
- Pass-rate bar: pass percentage over processed tests.
- Failure-only streaming output with details.
- Optional quiet mode.
- Optional fail-fast mode.
- Optional report file generation.

### Command-Line Options

- -d or --draft: run a specific draft only.
- -f or --file: run a specific file name or relative path filter.
- -q or --quiet: suppress live bars and failure detail lines.
- --fail-fast or --failfast: stop on first failure.
- -r or --report: write a failure report to file.

Accepted draft values:

- draft6 or 6
- draft7 or 7
- draft2019-09 or 2019-09
- draft2020-12 or 2020-12

### Usage Examples

Run all drafts:

    TestJsonSchemaConsole.exe

Run one draft:

    TestJsonSchemaConsole.exe --draft=draft2020-12

Run one fixture file across drafts:

    TestJsonSchemaConsole.exe --file=type.json

Run one draft and one file:

    TestJsonSchemaConsole.exe --draft=7 --file=maxLength.json

Fail fast:

    TestJsonSchemaConsole.exe --draft=draft7 --fail-fast

Quiet mode with report output:

    TestJsonSchemaConsole.exe --quiet --report=reports/failures.json

### Exit Codes

- 0: all executed tests passed.
- 1: at least one test failed, or an execution error occurred.

## Failure Output Contract

For each failing test (when not using quiet mode), the console includes:

- Draft
- Fixture file
- Test case description
- Schema path (when available)
- Instance path (when available)
- Error message
- Expected validity and actual validity

## Report Output

Report generation is controlled by -r or --report.

Format selection:

- .json extension: JSON array report.
- Any other extension: plain text report.

JSON fields per failure record:

- draft
- file
- test
- schemaPath
- instancePath
- error
- expectedValid
- actualValid

## How Test Discovery Works

- Draft folder is selected from test/schemas/tests.
- JSON files are recursively discovered.
- Each fixture is expected to contain test sets with:
  - schema
  - tests array
- Each test item is expected to contain:
  - description
  - data
  - valid

## Adding New Tests

1. Choose the target draft folder under test/schemas/tests.
2. Add or update a .json fixture file.
3. Keep fixture structure aligned with existing suite format.
4. Run GUI or Console runner to validate behavior.

If behavior changes across drafts, add coverage for each impacted draft.

## Needs Confirmation

- Exact CI/build commands are environment-specific and not enforced by this repository.
- The documented execution behavior above is based on the current runtime code in test/gui, test/console, and test/src.
