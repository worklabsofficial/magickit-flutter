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

### slicing
Konversi gambar/Figma menjadi Flutter code via AI.

```bash
magickit slicing --image ui.png
magickit slicing --figma https://www.figma.com/file/...
magickit slicing --provider gemini --output lib/generated/sliced_ui.dart
magickit slicing --print-prompt
```

Options:
- `--provider` (`anthropic|gemini`)
- `--image` path gambar
- `--figma` URL file Figma
- `--figma-selection` path JSON selection dari Figma MCP
- `--output` path output Dart file
- `--print-prompt` cetak prompt ke stdout
- `--export-prompt` simpan prompt ke file
- `--package-components`/`--no-package-components`

Butuh API key:
- `ANTHROPIC_API_KEY` atau `GEMINI_API_KEY`
- `FIGMA_API_KEY` bila pakai Figma

### kickstart
Generate starter app (splash, onboarding, login, main navigation).

```bash
magickit kickstart
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
