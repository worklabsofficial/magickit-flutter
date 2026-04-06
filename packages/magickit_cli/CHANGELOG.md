# Changelog

## 1.0.3

- **storage**: Tambah command `magickit storage` untuk setup ObjectBox local storage
  - `storage init` — inject dependencies, generate store, injector, database manager, example entity, auto-run `flutter pub get` + `build_runner`
  - `storage generate` — generate semua entity models, helpers, store, dan injector dari `storage/` folder
  - `storage generate --build-runner` — generate + auto run `build_runner`
  - `storage info` — tampilkan database path, entity list, generated files
  - `DatabaseManager` — class untuk export/import database ke JSON
  - `storageInjector()` — single function untuk init ObjectBox + register semua helpers via get_it
  - Auto-update `injector.dart` dengan markers `MAGICKIT:IMPORT` / `MAGICKIT:INJECTOR`
- **fix**: `toPascalCase` preserve existing PascalCase input
- **fix**: `fromJson` fallback ke `DateTime.now()` untuk non-nullable DateTime
- **fix**: Helper import `objectbox.g.dart` untuk akses `Entity_` query classes

## 1.0.2

- **chore**: Menambahkan informasi lisensi Apache-2.0 di `pubspec.yaml`
- **fix**: Meningkatkan metode `readUiKitVersion` untuk pengambilan versi yang lebih akurat dari `pubspec.yaml`

## 1.0.1

- **slicing**: Restructure menjadi subcommands (`prompt`, `image`, `figma`)
- **slicing prompt**: Generate unified `.md` prompt file — tinggal upload gambar + copy-paste ke AI
- **slicing image**: Direct ke AI dari gambar UI
- **slicing figma**: Direct ke AI dari Figma MCP selection JSON
- **registry**: `ai_context_bundle.md` (Format 2) — constructor signatures, types, default values, tags, file paths
- **registry**: Auto-discover magickit package bundle dari `package_config.json`
- **registry**: Merge local + package components tanpa duplikasi
- **slicing**: Hapus config duplicate dari `magickit.yaml` (`output`, `prompt_output`, `use_local_components`, `use_package_components`, `registry_output`) — semua pakai CLI defaults
- **slicing**: Task description dari positional argument (contoh: `magickit slicing prompt "slicing ui home page"`)

## 1.0.0

- Initial stable release.
