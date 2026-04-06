# AGENTS.md — MagicKit Flutter Monorepo

## Project Overview
MagicKit is a Flutter monorepo with two packages:
| Package | Purpose |
|---------|---------|
| `packages/magickit` | UI Kit — widget library, zero external dependencies |
| `packages/magickit_cli` | CLI tools — code generator & development utilities |
| `example/` | Demo app using `magickit` via path dependency |

## Build / Lint / Test Commands

### Monorepo (Melos)
```bash
melos bootstrap              # Install all dependencies (run after clone)
melos analyze                # Analyze all packages
melos test                   # Run all tests
melos test:flutter           # Run Flutter tests only
melos test:dart              # Run Dart tests only
melos format                 # Format all packages
melos clean                  # Clean build artifacts
```

### Per-Package
```bash
flutter analyze packages/magickit
dart analyze packages/magickit_cli
flutter pub get --directory=packages/magickit
flutter pub get --directory=packages/magickit_cli
```

### Running a Single Test
```bash
# Flutter package (magickit)
flutter test packages/magickit/test/widget_test.dart
flutter test packages/magickit/test/widget_test.dart --name "MagicButton"

# Dart package (magickit_cli)
dart test packages/magickit_cli/test/command_test.dart
dart test packages/magickit_cli/test/command_test.dart --name "init command"

# Run specific test line
flutter test packages/magickit/test/widget_test.dart --line 42
```

### CLI Development
```bash
dart pub global activate --source path packages/magickit_cli
dart run packages/magickit_cli/bin/magickit.dart <command>
```

## Code Style Guidelines

### Imports
- Order: `dart:` → `package:` → relative imports
- Use relative imports within the same package (`../tokens/magic_theme.dart`)
- No external dependencies in `packages/magickit` — Flutter SDK only
- `packages/magickit_cli` uses: `args`, `mason_logger`, `yaml`, `path`, `http`

### Naming Conventions
- **Widget classes**: `Magic` prefix — `MagicButton`, `MagicCard`
- **Token classes**: `Magic` prefix — `MagicColors`, `MagicTypography`
- **Files**: snake_case — `magic_button.dart`
- **Enums**: `MagicButtonVariant`, `MagicButtonSize`
- **Generated files**: `*.gen.dart`

### Formatting
- Use `dart format .` — enforced via melos
- 2-space indentation, 80-char line length (flutter_lints default)

### Types & Patterns
- Prefer `const` constructors wherever possible
- Use `required` for mandatory named parameters, `final` for immutable fields
- Prefer pattern matching with `switch` expressions over if-else chains
- Use `ThemeExtension` pattern for design tokens — never hardcode values in widgets
- Access tokens via `MagicTheme.of(context)` — the single entry point

### Widget Architecture (Atomic Design)
| Layer | Folder | Purpose |
|-------|--------|---------|
| Tokens | `lib/src/tokens/` | Design system primitives |
| Atoms | `lib/src/atoms/` | 12 basic widgets |
| Molecules | `lib/src/molecules/` | 9 composition widgets |
| Organisms | `lib/src/organisms/` | 7 complex widgets |

### Component Annotation (Required for new widgets)
Every widget must have this annotation for registry generation:
```dart
/// {@magickit}
/// name: MagicButton
/// category: atom
/// use_case: Tombol aksi utama, submit form, navigasi
/// visual_keywords: button, tombol, CTA, submit, aksi
/// {@end}
```

### Error Handling
- Use `assert()` for developer errors with clear messages + usage examples
- CLI: use `mason_logger` for user-facing output, exit codes for failures
- Never swallow exceptions — let them propagate with context

### Lint Rules
- **magickit**: `flutter_lints` + `prefer_const_constructors`, `prefer_const_declarations`, `avoid_unnecessary_containers`, `use_key_in_widget_constructors`
- **magickit_cli**: `lints/recommended`
- `doc_directive_unknown` suppressed in magickit (for custom {@magickit} annotation)

### Adding a New Widget
1. Create file in correct atomic folder (`atoms/`, `molecules/`, `organisms/`)
2. Add `{@magickit}` annotation with metadata
3. Export from `lib/magickit.dart`
4. Run `magickit registry` to update component registry

### CLI Architecture
- **commands/** → parse args, validate, read config, call generator, write output
- **generators/** → pure logic: string templates (no direct I/O)
- **services/** → external API calls (AnthropicService, GeminiService)
- **utils/** → `logger.dart` (singleton mason_logger), `string_utils.dart`

### Storage (ObjectBox) Commands
- `magickit storage init` → Setup ObjectBox: inject deps, create Store
- `magickit storage add <entity>` → Generate `@Entity` model from `storage/<entity>.json`
- `magickit storage table <create|drop|clear> <entity>` → Table operations
- `magickit storage generate` → Generate all entities from `storage/` folder

#### Entity Schema Format (`storage/<entity>.json`)
```json
{
  "entity": "User",
  "table": "users",
  "fields": [
    { "name": "id", "type": "int", "id": true },
    { "name": "name", "type": "String" },
    { "name": "email", "type": "String", "unique": true },
    { "name": "createdAt", "type": "DateTime" }
  ],
  "indexes": ["email"],
  "relations": [{ "name": "posts", "type": "ToMany", "target": "Post" }]
}
```

#### Generated Files
| File | Purpose |
|------|---------|
| `lib/core/storage/objectbox/objectbox_store.dart` | Store singleton with box references |
| `lib/core/storage/objectbox/storage_injector.dart` | Single injector: `await ObjectBoxStore.create()` + register all helpers |
| `lib/core/storage/objectbox/models/<entity>_model.dart` | `@Entity()` class with `@Id()`, `@Index()`, etc. |
| `lib/core/storage/objectbox/helpers/<entity>_storage_helper.dart` | Typed CRUD helper (put, get, getAll, update, delete, clear, search) |
| `lib/objectbox.g.dart` | Generated by `build_runner` (ObjectBox codegen) |

#### DI Integration
All storage helpers are registered via a single `storageInjector()` function in `storage_injector.dart`. This function:
1. Initializes `ObjectBoxStore.create()`
2. Registers all `*StorageHelper` classes with get_it

The main `injector.dart` imports `storage_injector.dart` and calls `await storageInjector()`. `configureDependencies()` becomes `async`.
