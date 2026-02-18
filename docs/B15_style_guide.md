# B.15 - Re-Word Game Dart/Flutter Style Guide

This guide defines naming and structure conventions for the `reword_game` Flutter client.

## Goals

- Keep the codebase consistent and predictable.
- Follow Dart/Flutter ecosystem standards.
- Minimize churn in a working app.

---

## 1) Naming conventions

### Files

- Use `snake_case.dart` for all Dart files.
- Keep names intent-revealing and stable.
- Prefer descriptive names over abbreviations.

Examples:

- `error_boundary.dart` ✅
- `game_top_bar_component.dart` ✅
- `ErrorBoundary.dart` ❌

### Directories

- Use lowercase directory names.
- Use `snake_case` only when multi-word readability is needed.
- Keep domain grouping stable (components/dialogs/managers/etc.).

Current high-level `lib/` domains are valid:

- `components`, `dialogs`, `logic`, `managers`, `models`, `providers`, `screens`, `services`, `styles`, `utils`

### Types (classes/enums)

- Use `PascalCase`.

Examples:

- `ErrorBoundary`, `GameManager`, `LogLevel`

### Methods, fields, variables

- Use `lowerCamelCase`.
- Private members keep leading underscore (`_`).

Examples:

- `initState`, `dispose`, `build`, `_handleReportedErrorChanged`

---

## 2) Flutter lifecycle contract methods

Framework lifecycle methods must keep exact Dart/Flutter signatures and casing.

Examples:

- `initState()`
- `dispose()`
- `didChangeDependencies()`
- `build(BuildContext context)`

Do **not** rename these to C#-style naming (`InitState`, `Dispose`, etc.), or overrides will break.

---

## 3) Formatting policy

- Use standard Dart formatting (`dart format`) as source of truth.
- Do not maintain a custom brace style that conflicts with formatter output.
- Keep style decisions tool-compatible to reduce PR churn.

---

## 4) Project-specific guidance

### `components/` usage

`components/` is the approved location for reusable UI building blocks, including wrappers like `error_boundary.dart`.

### Renaming policy for this project

- Prefer incremental, low-risk renames.
- Avoid broad repo-wide style churn.
- Batch changes in reviewable slices and verify imports/references each time.

---

## 5) B.15 execution approach

1. Audit naming/folder consistency first.
2. Produce candidate rename/deletion list with risk level.
3. Apply only explicitly approved changes.
4. Re-run audit after each pass.
