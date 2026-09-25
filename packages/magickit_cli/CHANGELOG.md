# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- **storage** — optional relation `backlink` generates ObjectBox `@Backlink`, with lookup and setter helpers, id-based export/import, and optional `onDelete` (`cascade` or `nullify`).

### Fixed

- **storage** — `magickit init` generates an async `configureDependencies()`, and `main` awaits it. `storage init` and `storage generate` upgrade existing apps that still use the synchronous signature.
- **storage** — `storageInjector()` skips GetIt types that are already registered, and `ObjectBoxStore.close()` clears the singleton.
- **storage** — invalid schemas (broken JSON, unknown types, Dart keywords, illegal indexes, bad relations, missing targets) fail before files are written. Indexed `DateTime` helpers use `equalsDate`.
- **storage** — regeneration reports skips instead of claiming a write, leaves files alone unless they are generated or `--force` is set, and deletes stale generated models and helpers whose JSON was removed.
- **storage** — `build_runner` failures print stdout and stderr and exit non-zero. `--delete-conflicting-outputs` is passed only for build_runner older than 2.7.0.
- **storage** — `getDatabaseSize()` returns the main database file size in bytes. `storage info` no longer prints guessed device paths.

### Changed

- **storage** — documented as Android and iOS only.

## [1.1.1] - 2026-05-10

### Fixed

- **version** — version reading for the CLI and the UI kit

## [1.1.0] - 2026-05-10

### Added

- **version** — `magickit version` prints the UI kit and CLI versions
- Version helpers that read and write the version in `pubspec.yaml`
- **snippets** — `magickit snippets` installs VS Code snippets for MagicKit components
  - `snippets install` writes `.vscode/magickit.code-snippets` (`--global` writes the VS Code user snippets directory)
  - `snippets list` prints the snippet catalog

### Changed

- **slicing** — bundle lookup, with errors when the bundle cannot be read
- Bundle discovery through `package_config.json`
- Usage guidelines embedded in slicing prompts

## [1.0.3] - 2026-04-06

### Added

- **storage** — `magickit storage` for ObjectBox local storage
  - `storage init` injects dependencies and generates the store, injector, database manager, and an example entity, then runs `flutter pub get` and `build_runner`
  - `storage generate` generates entity models, helpers, the store, and the injector from the `storage/` folder
  - `storage generate --build-runner` generates files and runs `build_runner`
  - `storage info` prints the database path, entities, and generated files
  - `DatabaseManager` exports and imports the database as JSON
  - `storageInjector()` initializes ObjectBox and registers helpers with `get_it`
  - Updates `injector.dart` between the `MAGICKIT:IMPORT` and `MAGICKIT:INJECTOR` markers

### Fixed

- `toPascalCase` keeps input that is already PascalCase
- `fromJson` uses `DateTime.now()` when a non-nullable `DateTime` is missing
- Generated helpers import `objectbox.g.dart` so `Entity_` query classes resolve

## [1.0.2] - 2026-04-05

### Changed

- Apache-2.0 license metadata in `pubspec.yaml`

### Fixed

- `readUiKitVersion` reads the UI kit version from `pubspec.yaml`

## [1.0.1] - 2026-04-05

Tagged as `magickit-cli-v1.0.1`. This version was not published to pub.dev.

### Added

- **slicing** subcommands `prompt`, `image`, and `figma`
- **slicing prompt** writes one `.md` prompt file to upload with a screenshot
- **slicing image** sends a UI image to the AI provider
- **slicing figma** sends a Figma MCP selection JSON file to the AI provider
- **registry** writes `ai_context_bundle.md` with constructor signatures, types, default values, tags, and file paths
- **registry** discovers the magickit package bundle from `package_config.json` and merges it with local components

### Changed

- Slicing output paths and component-bundle switches use CLI defaults. The task text is the positional argument, for example `magickit slicing prompt "slicing ui home page"`

## [1.0.0] - 2026-03-14

### Added

- Initial stable release
