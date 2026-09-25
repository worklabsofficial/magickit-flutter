# magickit

MagicKit is a Flutter widget library organized with atomic design: tokens, atoms, molecules, and organisms.

## Requirements

- Flutter `>=3.22.0`
- Dart SDK `>=3.5.0 <4.0.0`

## Install

```yaml
dependencies:
  magickit: ^1.1.1
```

## Quick start

Register `MagicTheme` on `ThemeData.extensions`, then build with the exported widgets.

```dart
import 'package:flutter/material.dart';
import 'package:magickit/magickit.dart';

void main() {
  runApp(const MagicKitApp());
}

class MagicKitApp extends StatelessWidget {
  const MagicKitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        extensions: [MagicTheme.light()],
      ),
      darkTheme: ThemeData(
        extensions: [MagicTheme.dark()],
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Column(
        children: [
          MagicText(
            'Hello MagicKit',
            style: MagicTextStyle.h2,
          ),
          MagicButton(
            label: 'Continue',
            onPressed: _noop,
          ),
        ],
      ),
    );
  }
}

void _noop() {}
```

`MagicButton.onPressed` is required. Pass `null` to render the button as disabled.

`MagicTheme.light` and `MagicTheme.dark` accept an optional `fontFamily`.

## Theme tokens

Read tokens from the theme extension or from `MagicContextExtensions` on `BuildContext`.

| Token | Extension | Static access |
| --- | --- | --- |
| `MagicTheme` | `context.theme` | `MagicTheme.of(context)` |
| `MagicColors` | `context.colors` | `MagicColors.of(context)` |
| `MagicTypography` | `context.typography` | `context.theme.typography` |
| `MagicSpacing` | `context.spacing` | `context.theme.spacing` |
| `MagicRadius` | `context.radius` | `context.theme.radius` |
| `MagicShadows` | `context.shadows` | `context.theme.shadows` |
| `MagicAnimations` | `context.animations` | `context.theme.animations` |
| `MagicBreakpoints` | `context.breakpoints` | `context.theme.breakpoints` |

`context.breakpoints` is the width token (`mobile` 480, `tablet` 768, `desktop` 1024, `wide` 1440). It is the configured widths, and it is separate from the current screen type.

Color fields on `MagicColors`: `primary`, `primaryContainer`, `secondary`, `secondaryContainer`, `surface`, `background`, `error`, `onPrimary`, `onSecondary`, `onSurface`, `onBackground`, `onError`, `outline`, `disabled`, `disabledForeground`. Extra named colors live on `extras` and are read with `colors.extra('name')`.

Spacing (`xs` `sm` `md` `lg` `xl` `xxl`): 4, 8, 16, 24, 32, 48.

Radius (`xs` `sm` `md` `lg` `xl` `full`): 4, 8, 12, 16, 24, 999.

Shadows: `none`, `sm`, `md`, `lg`, `xl`.

Animation durations: `fastest`, `fast`, `normal`, `slow`, `slowest`. Curves: `curveDefault`, `curveDecelerate`, `curveAccelerate`, `curveEmphasized`, `curveBounce`, `curveSpring`.

Typography styles: `heading1` through `heading6`, `bodyLarge`, `bodyMedium`, `bodySmall`, `caption`, `label`. `MagicText` maps those onto `MagicTextStyle` (`h1`–`h6`, `bodyLarge`, `bodyMedium`, `bodySmall`, `caption`, `label`).

```dart
import 'package:flutter/material.dart';
import 'package:magickit/magickit.dart';

class TokenReadout extends StatelessWidget {
  const TokenReadout({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = context.theme;
    final typography = context.typography;
    final spacing = context.spacing;
    final radius = context.radius;
    final shadows = context.shadows;
    final animations = context.animations;
    final breakpoints = context.breakpoints;

    final isDark = MagicTheme.isDark(context);
    final breakpoint = MagicTheme.breakpoint(context);

    return Padding(
      padding: EdgeInsets.all(spacing.md),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(radius.md),
          boxShadow: shadows.sm,
        ),
        child: MagicText(
          '${theme.colors.primary} ${typography.bodyMedium.fontSize} '
          '${animations.normal.inMilliseconds} ${breakpoints.mobile} '
          '$isDark $breakpoint',
          style: MagicTextStyle.bodyMedium,
        ),
      ),
    );
  }
}
```

`MagicTheme.isDark(context)` reads `ThemeData.brightness`. `MagicTheme.breakpoint(context)` returns a `MagicBreakpointType`: `mobile`, `tablet`, `desktop`, or `wide`.

## Breakpoints

`MagicBreakpointType` values are `mobile`, `tablet`, `desktop`, and `wide`.

`MagicBreakpoints.typeOf`, `isMobile`, `isTablet`, `isDesktop`, `isWide`, `responsive`, `columns`, and `contentMaxWidth` classify the screen with the default widths (480 / 768 / 1024 / 1440). They do not read a custom `MagicBreakpoints` instance from the theme. Use `context.breakpoints.resolve(width)` when the theme widths should apply.

`isDesktop` is true for both `desktop` and `wide`. `isWide` is true only for `wide`.

```dart
import 'package:flutter/material.dart';
import 'package:magickit/magickit.dart';

class ResponsiveColumns extends StatelessWidget {
  const ResponsiveColumns({super.key});

  @override
  Widget build(BuildContext context) {
    final type = MagicBreakpoints.typeOf(context);
    final columns = MagicBreakpoints.responsive<int>(
      context,
      mobile: 1,
      tablet: 2,
      desktop: 3,
      wide: 4,
    );

    if (MagicBreakpoints.isMobile(context)) {
      return MagicText('mobile $columns', style: MagicTextStyle.bodyMedium);
    }
    if (MagicBreakpoints.isTablet(context)) {
      return MagicText('tablet $columns', style: MagicTextStyle.bodyMedium);
    }
    if (MagicBreakpoints.isWide(context)) {
      return MagicText('wide $columns', style: MagicTextStyle.bodyMedium);
    }
    return MagicText(
      '${type.name} $columns',
      style: MagicTextStyle.bodyMedium,
    );
  }
}
```

## Components

Everything below is exported from `package:magickit/magickit.dart`.

### Tokens

- `MagicColors` — color tokens, `light` / `dark` factories, `extra`
- `MagicTypography` — text styles
- `MagicSpacing` — spacing scale and `MagicSpacing.auto`
- `MagicRadius` — corner radii
- `MagicShadows` — elevation shadows
- `MagicAnimations` — durations and curves
- `MagicBreakpoints`, `MagicBreakpointType` — responsive widths and screen type
- `MagicTheme` — `ThemeExtension` that holds the tokens

### Atoms

- `MagicAvatar` (`MagicAvatarSize`) — image or initial
- `MagicBadge` (`MagicBadgeVariant`) — status label
- `MagicButton` (`MagicButtonVariant`, `MagicButtonSize`) — labeled action
- `MagicCheckbox` — checkbox with an optional label
- `MagicDivider` — separator
- `MagicIcon` — themed icon
- `MagicImage` — network or asset image
- `MagicInput` — text field
- `MagicPinInput` (`MagicPinInputShape`) — PIN or OTP boxes
- `MagicProgress` (`MagicProgressType`, `MagicProgressVariant`) — linear or circular progress
- `MagicRadio` — single-select option
- `MagicShimmer` — skeleton placeholder
- `MagicSlider` (`MagicSliderVariant`) — single-value slider
- `MagicRangeSlider` — min/max slider (`RangeValues`)
- `MagicSwitch` — toggle with an optional label
- `MagicText` (`MagicTextStyle`) — text bound to typography tokens

### Molecules

- `MagicCard` (`MagicCardElevation`) — padded surface
- `MagicCarousel` (`MagicCarouselIndicatorType`) — paged items; also `MagicCarousel.banner` and `MagicCarousel.gallery`
- `MagicChip` — selectable or deletable tag
- `MagicDialog` — dialog content; show it with `MagicDialog.show` or `MagicDialog.confirm`
- `MagicDropdown`, `MagicDropdownItem` — single-select menu
- `MagicEmptyState` — empty, no-results, error, and offline states (`noData`, `noResults`, `error`, `offline`)
- `MagicFormField` — label, helper, and error around a child field
- `MagicListTile` — leading, title, subtitle, trailing
- `MagicRating` (`MagicRatingType`) — stars, hearts, or thumbs; also `MagicRating.display`
- `MagicSearchBar` — search field with clear
- `MagicSnackbar` (`MagicSnackbarVariant`) — `MagicSnackbar.show`
- `MagicStepper`, `MagicStepData` (`MagicStepStatus`, `MagicStepperType`) — stepped progress
- `MagicTooltip` — tooltip around a child

### Organisms

- `MagicAppBar` — themed app bar
- `MagicBottomSheet` — sheet content; show it with `MagicBottomSheet.show`
- `MagicDataTable`, `MagicDataColumn`, `MagicDataRow` — data table
- `MagicDrawer`, `MagicDrawerItem` — navigation drawer
- `MagicForm` — form with an optional async `onSubmit`
- `MagicGridView` (`MagicGridType`) — fixed, responsive, or masonry grid
- `MagicListView` — list with load-more, refresh, and empty state
- `MagicNavBar`, `MagicNavBarItem` — bottom navigation
- `MagicRefreshLayout` (`MagicRefreshType`, `MagicRefreshState`) — pull-to-refresh; also `MagicRefreshLayout.ios`
- `MagicTabBar`, `MagicTab` — tab bar for a `TabController`

`MagicContextExtensions` on `BuildContext` is exported from the same library.

## Package layout

```text
lib/
  magickit.dart
  src/
    extensions/
    tokens/
    atoms/
    molecules/
    organisms/
    registry/
```

Registry files shipped with the package:

- `lib/src/registry/component_registry.yaml`
- `lib/src/registry/ai_context_bundle.md`

## MagicKit CLI

Scaffolding and generators live in the `magickit_cli` package (`dart pub global activate magickit_cli`). In this repository the command reference is `packages/magickit_cli/README.md`.

## Contributing

Open an issue or a pull request on the repository.

## License

Apache-2.0
