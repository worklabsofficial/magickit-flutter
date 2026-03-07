# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

MagicKit adalah Flutter UI Kit + CLI toolkit monorepo dengan dua package terpisah:

| Package | Tujuan |
|---------|--------|
| `packages/magickit` | UI Kit — widget library, zero external dependencies |
| `packages/magickit_cli` | CLI tools — code generator & development utilities |

`example/` berisi demo app yang menggunakan `magickit` via path dependency.

## Common Commands

### Monorepo (Melos)
```bash
melos bootstrap          # Install semua dependencies setelah clone
melos analyze            # Analyze semua packages sekaligus
melos test               # Run tests di semua packages
melos format             # Format semua packages
melos clean              # Clean build artifacts
```

### Per-Package
```bash
# Analyze
flutter analyze packages/magickit
dart analyze packages/magickit_cli

# Install deps manual (jika melos bootstrap gagal)
flutter pub get --directory=packages/magickit
flutter pub get --directory=packages/magickit_cli
flutter pub get --directory=example

# Test per-package
flutter test packages/magickit
dart test packages/magickit_cli

# Run single test
flutter test packages/magickit/test/widget_test.dart
```

### CLI Development
```bash
# Aktivasi CLI dari source (development mode)
dart pub global activate --source path packages/magickit_cli

# Jalankan langsung tanpa aktivasi
dart run packages/magickit_cli/bin/magickit.dart <command>
```

### Example App
```bash
cd example
flutter run -d chrome          # Web
flutter run -d <device-id>     # iOS Simulator atau Android
flutter devices                # Lihat device yang tersedia
```

### magickit.yaml wajib di root project user sebelum test CLI:
```bash
cd /tmp/test-project
magickit init       # generate magickit.yaml
magickit doctor     # cek environment
```

## Architecture

### `packages/magickit` — UI Kit

**Design Token Flow:**
```
MagicColors / MagicTypography / MagicSpacing / MagicRadius / MagicShadows
        └──→ MagicTheme (ThemeExtension)
                └──→ MagicTheme.of(context) di setiap widget
```

`MagicTheme` adalah satu-satunya cara widget mengakses tokens — tidak ada hardcoded values. Selalu register di `ThemeData.extensions` sebelum digunakan:
```dart
MaterialApp(
  theme: ThemeData(extensions: [MagicTheme.light()]),
)
```

**Widget Hierarchy (Atomic Design):**
- `lib/src/tokens/` — Design system primitives
- `lib/src/atoms/` — 12 widget dasar (Button, Text, Input, Icon, Avatar, Badge, Checkbox, Radio, Switch, Divider, Image, Shimmer)
- `lib/src/molecules/` — 9 widget komposisi (Card, Chip, Dialog, Dropdown, FormField, ListTile, SearchBar, Snackbar, Tooltip)
- `lib/src/organisms/` — 7 widget kompleks (AppBar, BottomSheet, DataTable, Drawer, Form, NavBar, TabBar)
- `lib/magickit.dart` — barrel export tunggal

**Component Annotation System:**
Setiap widget wajib memiliki annotation ini di doc comment (digunakan `magickit registry` untuk generate component_registry.yaml):
```dart
/// {@magickit}
/// name: MagicButton
/// category: atom
/// use_case: Tombol aksi utama, submit form, navigasi
/// visual_keywords: button, tombol, CTA, submit, aksi
/// {@end}
class MagicButton extends StatelessWidget { ... }
```
`doc_directive_unknown` di-suppress di `analysis_options.yaml` karena ini custom annotation bukan Dart doc directive.

### `packages/magickit_cli` — CLI

**Command → Generator pattern:**
```
commands/          → parse args, baca config, call generator, write output
generators/        → pure logic (string templates, file generation)
services/          → external API (AnthropicService untuk slicing)
utils/             → string_utils.dart (toCamelCase, toPascalCase, toSnakeCase)
                     logger.dart (singleton mason_logger instance)
```

**Config via `magickit.yaml`** di root project user. Semua command baca config ini, fallback ke defaults jika tidak ada.

**CLI Commands:**
| Command | Generator | Output |
|---------|-----------|--------|
| `init` | — | `magickit.yaml` |
| `assets` | `AssetGenerator` | `lib/generated/assets.gen.dart` |
| `l10n` | `L10nGenerator` | `lib/generated/l10n/` |
| `registry` | `RegistryGenerator` | `lib/src/registry/component_registry.yaml` + `ai_context_bundle.txt` |
| `page <name>` | `PageGenerator` | `lib/features/<name>/` (clean arch boilerplate) |
| `api` | `ApiGenerator` | `lib/data/models/*_model.dart` (JSON → Dart) |
| `component <name>` | `ComponentGenerator` | widget scaffold dengan `{@magickit}` annotation |
| `theme` | — | update `magickit.yaml` |
| `slicing` | `AnthropicService` | Flutter code via Claude vision API |
| `doctor` | — | diagnostic report |

**`magickit slicing` memerlukan:**
```bash
export ANTHROPIC_API_KEY=sk-ant-...   # wajib
export FIGMA_API_KEY=figd_...         # hanya untuk --figma flag
```

## Key Conventions

**Naming:**
- Widget class: `Magic` prefix — `MagicButton`, `MagicCard`
- Token class: `Magic` prefix — `MagicColors`, `MagicTypography`
- File: snake_case — `magic_button.dart`
- Enum: `MagicButtonVariant`, `MagicButtonSize`
- Generated files: `*.gen.dart`

**Menambah widget baru:**
1. Buat file di folder atomic yang tepat (`atoms/`, `molecules/`, `organisms/`)
2. Tambahkan `{@magickit}` annotation
3. Export dari `lib/magickit.dart`
4. Jalankan `magickit registry` untuk update component registry

**`packages/magickit` zero external dependencies** — hanya Flutter SDK. Jangan tambahkan dependency eksternal ke package ini.

**`MagicRadio` menggunakan custom implementation** (bukan Flutter's `Radio` widget) karena `Radio.groupValue` dan `Radio.onChanged` deprecated di Flutter 3.32+.

## Melos Note

Melos 7.x memerlukan `pubspec.yaml` di root workspace (bukan hanya `melos.yaml`). File ini sudah ada di root.
