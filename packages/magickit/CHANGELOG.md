# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.1] - 2026-05-10

### Added

- **BuildContext extensions** (`MagicContextExtensions`) for theme tokens:
  - `context.colors` → `MagicColors`
  - `context.theme` → `MagicTheme`
  - `context.typography` → `MagicTypography`
  - `context.spacing` → `MagicSpacing`
  - `context.radius` → `MagicRadius`
  - `context.shadows` → `MagicShadows`
  - `context.animations` → `MagicAnimations`
  - `context.breakpoints` → `MagicBreakpoints` width token

## [1.1.0] - 2026-05-10

### Added

- **MagicGridView** — responsive grid layout
- **MagicListView** — list with lazy loading
- **MagicRefreshLayout** — pull-to-refresh wrapper
- **MagicPinInput**, **MagicProgress**, **MagicSlider**, **MagicRangeSlider**
- **MagicCarousel**, **MagicEmptyState**, **MagicRating**, **MagicStepper**
- **MagicBreakpoints** — breakpoint widths and `MagicBreakpointType` (`mobile`, `tablet`, `desktop`, `wide`), plus `MagicTheme.breakpoint` and `MagicTheme.isDark`
- **MagicAnimations** — animation duration and curve tokens
- Example app coverage for the new components

### Changed

- **MagicColors** — custom colors through `extras`, with `lerp` support
- **MagicTheme.lerp** — interpolates colors across theme changes

## [1.0.0] - 2026-03-14

### Added

- Initial stable release
- Atomic design structure (tokens, atoms, molecules, organisms)
- Core design tokens (colors, typography, spacing, radius, shadows) and `MagicTheme`
- UI component library
