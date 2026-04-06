# magickit_cli

MagicKit CLI - development tools & code generator untuk Flutter.

## Install

Aktifkan secara global:

```bash
dart pub global activate magickit_cli
```

Untuk development dari monorepo:

```bash
dart pub global activate --source path packages/magickit_cli
```

## Usage

```bash
magickit <command> [arguments]
magickit <command> --help
```

## Commands

### doctor
Cek environment (Flutter/Dart), dependency, dan konfigurasi.

```bash
magickit doctor
```

### init
Generate `magickit.yaml` dan struktur folder project.

```bash
magickit init
```

### page
Generate page + routing di dalam feature.

```bash
magickit page <feature> <page>
magickit page auth login --path-params id
magickit page product detail --query-params sort,rating
```

Options:
- `--path-params` parameter path (comma-separated)
- `--query-params` parameter query (comma-separated)

### api
Generate full-stack feature code dari folder `remote/`.

```bash
magickit api
magickit api <feature>
magickit api <feature> <page>
magickit api --force --verbose
```

Options:
- `--force` overwrite file yang sudah ada
- `--dry-run` simulasi tanpa menulis file
- `--verbose` detail resolusi (ref/type)

### assets
Scan `assets/` dan generate `MagicAssets`.

```bash
magickit assets
```

Konfigurasi lewat `magickit.yaml`:
- `assets.input`
- `assets.output`
- `assets.exclude`
- `assets.group`
- `assets.strip_prefix`

### l10n
Scan `assets/l10n/` dan generate `AppLocalizations`.

```bash
magickit l10n
```

Konfigurasi lewat `magickit.yaml`:
- `l10n.input`
- `l10n.output`
- `l10n.default_locale`

### component
Scaffold komponen baru mengikuti MagicKit convention.

```bash
magickit component rating_star --type atom
magickit component card_promo --type molecule --output lib/core/components/src
```

Options:
- `--type` (`atom|molecule|organism`) wajib
- `--output` base output directory
- `--package` nama package untuk ThemeExtension (default `magickit`)

### registry
Scan annotations dan generate registry + AI bundle.

```bash
magickit registry
magickit registry --source lib/ --output lib/src/registry/
magickit registry --no-ai-bundle
```

Options:
- `--source` direktori source code
- `--output` direktori output
- `--ai-bundle` (default on), pakai `--no-ai-bundle` untuk disable

### registry
Scan annotations dan generate registry + AI context bundle.

```bash
magickit registry
magickit registry --source lib/ --output lib/src/registry/
magickit registry --no-ai-bundle
```

Options:
- `--source` direktori source code
- `--output` direktori output
- `--ai-bundle` (default on), pakai `--no-ai-bundle` untuk disable

Output:
- `component_registry.yaml` — machine-readable component list
- `ai_context_bundle.md` — AI context dengan constructor signatures, types, dan tags

### slicing
Konversi gambar/Figma menjadi Flutter code via AI.

```bash
# Generate prompt file untuk upload manual ke AI
magickit slicing prompt "slicing ui home page"
magickit slicing prompt "slicing ui login form"

# Direct ke AI dari gambar
magickit slicing image --source ui.png
magickit slicing image --source ui.png --provider gemini

# Direct ke AI dari Figma MCP selection
magickit slicing figma --selection selection.json
magickit slicing figma --selection selection.json --provider anthropic
```

**Subcommands:**

| Command | Deskripsi |
|---|---|
| `slicing prompt <task>` | Generate `.md` prompt file — tinggal upload gambar + copy-paste ke AI |
| `slicing image` | Direct ke AI dari gambar UI |
| `slicing figma` | Direct ke AI dari Figma MCP selection JSON |

**Options (semua subcommand):**
- `--provider` (`anthropic|gemini`) — override default dari `magickit.yaml`
- `--source` path gambar (untuk `image` subcommand)
- `--selection` path JSON selection (untuk `figma` subcommand)
- `--[no-]package-components` gunakan bundle komponen dari package magickit (default on)

**Cara pakai `slicing prompt`:**
1. Jalankan `magickit registry` di project
2. Jalankan `magickit slicing prompt "deskripsi task"`
3. Buka Claude/Codex desktop
4. Upload gambar ke AI
5. Copy-paste isi file `.md` yang di-generate
6. AI akan generate Flutter code

Butuh API key (untuk `image` dan `figma` subcommands):
- `ANTHROPIC_API_KEY` atau `GEMINI_API_KEY`
- `FIGMA_API_KEY` bila pakai Figma

### kickstart
Generate starter app (splash, onboarding, login, main navigation).

```bash
magickit kickstart
```

### storage
Manage ObjectBox local storage — init, generate models, database info.

```bash
magickit storage init
magickit storage generate
magickit storage generate --build-runner
magickit storage info
```

**Subcommands:**

| Command | Deskripsi |
|---|---|
| `storage init` | Setup ObjectBox: inject deps, generate store, injector, database manager, example entity, auto-run `pub get` + `build_runner` |
| `storage generate` | Generate semua entity models, helpers, store, injector dari `storage/` folder |
| `storage generate --build-runner` | Generate + auto run `build_runner` |
| `storage info` | Tampilkan database path, entity list, generated files |

**Entity Schema Format (`storage/<entity>.json`):**

```json
{
  "entity": "User",
  "table": "users",
  "fields": [
    { "name": "id", "type": "int", "id": true },
    { "name": "name", "type": "String" },
    { "name": "email", "type": "String", "unique": true },
    { "name": "createdAt", "type": "DateTime" },
    { "name": "isActive", "type": "bool" }
  ],
  "indexes": ["email"],
  "relations": [{ "name": "posts", "type": "ToMany", "target": "Post" }]
}
```

**Generated Files:**

| File | Purpose |
|------|---------|
| `lib/core/storage/objectbox/objectbox_store.dart` | Store singleton dengan box references |
| `lib/core/storage/objectbox/storage_injector.dart` | `storageInjector()` — init ObjectBox + register semua helpers |
| `lib/core/storage/objectbox/database_manager.dart` | Export/import database ke JSON |
| `lib/core/storage/objectbox/models/<entity>_model.dart` | `@Entity()` class dengan `@Id()`, `@Index()`, dll |
| `lib/core/storage/objectbox/helpers/<entity>_storage_helper.dart` | Typed CRUD helper (put, get, getAll, update, delete, clear, search) |
| `lib/objectbox.g.dart` | Generated oleh `build_runner` (ObjectBox codegen) |

**Cara Pakai:**

```bash
# 1. Setup ObjectBox (sekali)
magickit storage init

# 2. Buat entity schema
cat > storage/user.json << EOF
{
  "entity": "User",
  "fields": [
    { "name": "id", "type": "int", "id": true },
    { "name": "name", "type": "String" }
  ]
}
EOF

# 3. Generate code + build_runner
magickit storage generate --build-runner

# 4. Pakai di code
final helper = getIt<UserStorageHelper>();
helper.put(User(name: 'John'));
final users = helper.getAll();
```

**DatabaseManager (Export/Import):**

```dart
final db = DatabaseManager();

// Export semua data ke JSON
await db.export('/path/to/backup.json');

// Import dari JSON
await db.import('/path/to/backup.json');

// Stats
print(db.getStats()); // {User: 42}
```

### version
Lihat versi CLI dan UI Kit.

```bash
magickit version
magickit version --update
```

`--update` akan meng-update `magickit_cli` ke versi terbaru dari pub.dev.

## Contributing

Silakan buat issue atau pull request di repository.
