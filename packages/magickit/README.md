# magickit

MagicKit UI Kit - Flutter widget library dengan atomic design pattern.

## Install

Tambahkan ke `pubspec.yaml`:

```yaml
dependencies:
  magickit: ^1.0.0
```

## Theme Setup

```dart
MaterialApp(
  theme: ThemeData(
    extensions: [MagicTheme.light()],
  ),
  darkTheme: ThemeData(
    extensions: [MagicTheme.dark()],
  ),
  home: const MyApp(),
);
```

## Usage

```dart
import 'package:magickit/magickit.dart';

MagicButton(
  label: 'Continue',
  onPressed: () {},
);

const MagicText(
  'Hello MagicKit',
  style: MagicTextStyle.h2,
);
```

## Atomic Structure

Struktur komponen mengikuti atomic design:

Tokens:
- MagicColors
- MagicTypography
- MagicSpacing
- MagicRadius
- MagicShadows
- MagicTheme

Atoms:
- MagicAvatar
- MagicBadge
- MagicButton
- MagicCheckbox
- MagicDivider
- MagicIcon
- MagicImage
- MagicInput
- MagicRadio
- MagicShimmer
- MagicSwitch
- MagicText

Molecules:
- MagicCard
- MagicChip
- MagicDialog
- MagicDropdown
- MagicFormField
- MagicListTile
- MagicSearchBar
- MagicSnackbar
- MagicTooltip

Organisms:
- MagicAppBar
- MagicBottomSheet
- MagicDataTable
- MagicDrawer
- MagicForm
- MagicNavBar
- MagicTabBar

## Package Structure

```text
lib/
  magickit.dart
  src/
    tokens/
    atoms/
    molecules/
    organisms/
    registry/
```

Registry:
- `lib/src/registry/component_registry.yaml`
- `lib/src/registry/ai_context_bundle.txt`

## MagicKit CLI

Untuk scaffolding, generator, dan tooling gunakan `magickit_cli`.
Lihat `packages/magickit_cli/README.md` untuk daftar command dan contoh.

## Contributing

Silakan buat issue atau pull request di repository.
