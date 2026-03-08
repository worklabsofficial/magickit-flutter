# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

MagicKit adalah Flutter UI Kit + CLI toolkit monorepo dengan dua package terpisah:

| Package | Tujuan |
|---------|--------|
| `packages/magickit` | UI Kit — widget library, zero external dependencies |
| `packages/magickit_cli` | CLI tools — code generator & development utilities |

`example/` berisi demo app yang menggunakan `magickit` via path dependency.

## Repository Structure

```
magickit-flutter/
├── packages/
│   ├── magickit/                        # UI Kit package
│   │   ├── lib/
│   │   │   ├── magickit.dart            # Barrel export tunggal
│   │   │   └── src/
│   │   │       ├── tokens/              # Design system primitives
│   │   │       │   ├── magic_colors.dart
│   │   │       │   ├── magic_typography.dart
│   │   │       │   ├── magic_spacing.dart
│   │   │       │   ├── magic_radius.dart
│   │   │       │   ├── magic_shadows.dart
│   │   │       │   └── magic_theme.dart  # ThemeExtension, entry point
│   │   │       ├── atoms/               # 12 widget dasar
│   │   │       ├── molecules/           # 9 widget komposisi
│   │   │       ├── organisms/           # 7 widget kompleks
│   │   │       └── registry/            # Generated registry files
│   │   └── test/
│   └── magickit_cli/                    # CLI package
│       ├── bin/
│       │   └── magickit.dart            # Entrypoint CLI
│       └── lib/src/
│           ├── runner.dart              # CommandRunner + help output
│           ├── commands/                # Satu file per command
│           ├── generators/              # Pure logic string/file generation
│           ├── services/
│           │   └── anthropic_service.dart  # HTTP wrapper Claude API
│           └── utils/
│               ├── logger.dart          # Singleton mason_logger
│               └── string_utils.dart    # toCamelCase, toPascalCase, toSnakeCase
├── example/                             # Demo app (path dependency ke magickit)
├── melos.yaml                           # Monorepo config
└── pubspec.yaml                         # Root workspace pubspec (wajib untuk Melos 7.x)
```

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

### Setup project baru sebelum test CLI:
```bash
cd /path/to/your-project
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
  theme: ThemeData(
    extensions: [
      MagicTheme(
        colors: MagicColors.light(),
        typography: MagicTypography(),
        spacing: MagicSpacing(),
        radius: MagicRadius(),
        shadows: MagicShadows(),
      ),
    ],
  ),
)
// di dalam widget:
final theme = MagicTheme.of(context);
theme.colors.primary
theme.spacing.md
theme.radius.sm
theme.typography.heading1
```

**Widget Hierarchy (Atomic Design):**

| Layer | Folder | Jumlah | Contoh |
|-------|--------|--------|--------|
| Tokens | `lib/src/tokens/` | 6 class | MagicColors, MagicTypography, MagicSpacing, MagicRadius, MagicShadows, MagicTheme |
| Atoms | `lib/src/atoms/` | 12 widget | Button, Text, Input, Icon, Avatar, Badge, Checkbox, Radio, Switch, Divider, Image, Shimmer |
| Molecules | `lib/src/molecules/` | 9 widget | Card, Chip, Dialog, Dropdown, FormField, ListTile, SearchBar, Snackbar, Tooltip |
| Organisms | `lib/src/organisms/` | 7 widget | AppBar, BottomSheet, DataTable, Drawer, Form, NavBar, TabBar |

**Component Annotation System:**
Setiap widget wajib memiliki annotation ini di doc comment (digunakan `magickit registry` untuk generate `component_registry.yaml`):
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
commands/     → parse args, validasi input, baca config, call generator, write output
generators/   → pure logic: string templates + file generation (tidak ada I/O langsung)
services/     → external API calls (AnthropicService untuk slicing)
utils/        → string_utils.dart (toCamelCase, toPascalCase, toSnakeCase)
               logger.dart (singleton mason_logger instance)
```

**Config via `magickit.yaml`** di root project user. Semua command baca config ini, fallback ke defaults jika tidak ada.

## CLI Commands — Referensi Lengkap

### `magickit init`
Generate `magickit.yaml` di root project. Wajib dijalankan pertama kali sebelum command lain.
```bash
magickit init
```
Output: `magickit.yaml`

---

### `magickit doctor`
Cek environment, dependencies, dan konfigurasi project. Berguna untuk debugging setup.
```bash
magickit doctor
```
Checks: Flutter/Dart SDK, magickit.yaml, struktur folder project.

---

### `magickit assets`
Scan folder `assets/` dan generate Dart class dengan static references.
```bash
magickit assets
```
Output: `lib/generated/assets.gen.dart`

Contoh output:
```dart
class Assets {
  static const String logo = 'assets/images/logo.png';
  static const String onboarding1 = 'assets/images/onboarding1.png';
}
```

---

### `magickit l10n`
Scan folder `lang/` (JSON/ARB) dan generate class `AppLocalizations` + per-locale maps.
```bash
magickit l10n
```
Output: `lib/generated/l10n/`

---

### `magickit registry`
Scan semua file widget yang memiliki annotation `{@magickit}` dan generate component registry untuk referensi AI.
```bash
magickit registry
```
Output:
- `lib/src/registry/component_registry.yaml` — machine-readable component list
- `lib/src/registry/ai_context_bundle.txt` — system prompt bundle untuk `magickit slicing`

---

### `magickit page <feature> <page>`
Generate page baru di dalam feature dengan MagicCubit architecture boilerplate.
```bash
magickit page <feature_name> <page_name> [options]

# Contoh
magickit page auth login
magickit page product product_detail --path-params id
magickit page search results --query-params sort,rating
magickit page orders order_list --with-bloc
```

**Options:**
| Flag | Keterangan |
|------|------------|
| `--path-params <x,y>` | Path parameters (comma-separated), misal: `id` |
| `--query-params <x,y>` | Query parameters (comma-separated), misal: `sort,rating` |
| `--with-bloc` | Tambah Bloc layer untuk complex case (event-driven, debounce, stream) |

**Output** di `lib/features/<feature>/<page>/`:
```
<page>/
├── data/
│   ├── datasources/
│   ├── models/
│   └── repositories/
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── usecases/
├── presentation/
│   ├── cubit/
│   │   ├── <page>_cubit.dart
│   │   └── <page>_state.dart
│   └── pages/
│       └── <page>_page.dart
└── dependency_injection/
    └── <page>_dependency_injection.dart
```
Auto-register ke `lib/core/dependency_injection/injection.dart` dan update route files feature terkait.

---

### `magickit feature <feature_name>`
Generate route group untuk sebuah feature (route_names, routes, route_extensions).
```bash
magickit feature <feature_name>

# Contoh
magickit feature auth
magickit feature product
```

**Output** di `lib/features/<feature>/routes/`:
```
routes/
├── <feature>_route_names.dart    # Konstanta nama dan path route
├── <feature>_routes.dart         # List<RouteBase> untuk go_router
└── <feature>_route_extensions.dart  # BuildContext extensions (pushXxx)
```
Auto-update `lib/core/routes/route_config.dart`, `route_names.dart`, dan `route_extensions.dart`.

---

### `magickit kickstart`
Generate starter app lengkap: splash, onboarding, login, dan main navigation. Memerlukan `magickit init` sudah dijalankan terlebih dahulu.
```bash
magickit kickstart
```

**Output:** Generates features `startup`, `auth`, `main` lengkap dengan implementasi:
- `SplashPage` — auto navigate setelah 2 detik (cek onboarding/login state)
- `OnboardingPage` — 3 slides dengan PageView
- `LoginPage` — form dengan validasi email/password (demo: `test@mail.com` / `123456`)
- `MainNavigationPage` — bottom navigation (Home + Profile)
- `HomePage` — halaman home dengan card
- `ProfilePage` — profil dengan logout dialog
- `main.dart` — updated dengan routing, theming, dan localization

Prerequisite: `lib/core/dependency_injection/injection.dart` harus sudah ada (dari `magickit init`).

---

### `magickit api`
Scan JSON schema files dan generate Dart model classes dengan `fromJson`/`toJson`.
```bash
magickit api [options]

# Contoh
magickit api
magickit api --input schemas/ --output lib/models/
magickit api --repository
```

**Options:**
| Flag | Default | Keterangan |
|------|---------|------------|
| `-i, --input <dir>` | `api_schemas/` | Direktori input JSON schema files |
| `-o, --output <dir>` | `lib/data/models/` | Direktori output model files |
| `-r, --repository` | false | Generate repository stub untuk setiap model |

Contoh input `api_schemas/user.json`:
```json
{
  "id": 1,
  "name": "John",
  "email": "john@mail.com",
  "address": { "city": "Jakarta", "zip": "12345" }
}
```
Output: `lib/data/models/user_model.dart` dengan nested class, `copyWith`, `fromJson`, `toJson`.

---

### `magickit component <name>`
Scaffold widget baru mengikuti MagicKit convention dengan annotation `{@magickit}`.
```bash
magickit component <name> --type <atom|molecule|organism> [options]

# Contoh
magickit component rating_star --type atom
magickit component user_card --type molecule
magickit component dashboard_header --type organism
```

**Options:**
| Flag | Default | Keterangan |
|------|---------|------------|
| `-t, --type <atom\|molecule\|organism>` | (wajib) | Tipe komponen atomic design |
| `-o, --output <dir>` | `lib/src` | Base output direktori |
| `-p, --package <name>` | `magickit` | Nama package untuk ThemeExtension import |

Output: `lib/src/<atoms|molecules|organisms>/magic_<name>.dart` — widget scaffold siap diisi implementasi.

---

### `magickit theme`
Update design tokens (warna, font) di `magickit.yaml`. Minimal satu opsi diperlukan.
```bash
magickit theme [options]

# Contoh
magickit theme --primary "#2d4af5"
magickit theme --primary "#2d4af5" --font "DM Sans"
magickit theme --background "#FAFAFA" --secondary "#1A1A2E"
```

**Options:**
| Flag | Keterangan |
|------|------------|
| `--primary <hex>` | Primary color (format: `#RRGGBB`) |
| `--secondary <hex>` | Secondary color |
| `--background <hex>` | Background color |
| `--font <name>` | Font family (misal: `"DM Sans"`) |
| `--mono-font <name>` | Mono font family (misal: `"DM Mono"`) |

---

### `magickit slicing`
AI-powered: konversi gambar atau Figma design menjadi Flutter code menggunakan Claude AI + MagicKit context.
```bash
magickit slicing --image <path>                    # dari screenshot
magickit slicing --figma <url>                     # dari Figma
magickit slicing --image ui.png --output lib/ui/login_ui.dart

# Contoh lengkap
magickit slicing --image designs/login.png --output lib/features/auth/widgets/login_form.dart
magickit slicing --figma "https://www.figma.com/file/XXXXXX/nama-file"
```

**Options:**
| Flag | Default | Keterangan |
|------|---------|------------|
| `-i, --image <path>` | — | Path ke file PNG/JPG/WEBP |
| `-f, --figma <url>` | — | Figma file URL (format: `/file/` atau `/design/`) |
| `-o, --output <path>` | `lib/generated/sliced_ui.dart` | Path output Dart file |
| `-m, --model <name>` | `claude-sonnet-4-6` | Claude model yang digunakan |
| `-b, --bundle <path>` | auto-detect | Path ke `ai_context_bundle.txt` |

**Environment variables yang diperlukan:**
```bash
export ANTHROPIC_API_KEY=sk-ant-...   # wajib untuk semua slicing
export FIGMA_API_KEY=figd_...         # hanya untuk --figma flag
```

Jalankan `magickit registry` terlebih dahulu agar AI mendapat full MagicKit context via `ai_context_bundle.txt`.

---

### `magickit version`
Tampilkan versi CLI dan UI Kit yang terinstall.
```bash
magickit version
```

---

### `magickit help [command]`
Tampilkan bantuan umum atau bantuan detail untuk sebuah command.
```bash
magickit help
magickit help page
magickit help slicing
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
