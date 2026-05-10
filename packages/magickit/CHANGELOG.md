# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- BuildContext Extensions for direct theme token access from context

## [1.1.1] - 2026-05-10

### Added
- **BuildContext Extensions** - Direct access to theme tokens from BuildContext:
  - `context.colors` → MagicColors instance
  - `context.theme` → MagicTheme instance
  - `context.typography` → MagicTypography instance
  - `context.spacing` → MagicSpacing instance
  - `context.radius` → MagicRadius instance
  - `context.shadows` → MagicShadows instance
  - `context.animations` → MagicAnimations instance
  - `context.breakpoints` → MagicBreakpoints instance
  - `context.isDark` → Boolean for dark mode detection
  - `context.breakpoint` → Current breakpoint type (xs, sm, md, lg, xl)

## [1.1.0] - 2026-05-01

### Added
- **MagicGridView** - Responsive grid layout component
- **MagicListView** - List view with lazy loading support
- **MagicRefreshLayout** - Pull-to-refresh wrapper
- **MagicColors** - Custom color palette with lerp animation support
- **MagicTheme** - Enhanced theme system with lerp method for smooth transitions
- **MagicForm** - Async onSubmit support
- **MagicDivider** - Divider with automatic and adaptive spacing
- **MagicText** - Text component with adaptive spacing
- **MagicBreakpoints** - Responsive breakpoint system
- **MagicAnimations** - Animation tokens

### Changed
- Enhanced MagicColors with custom color palette management
- Updated lerp method in MagicTheme for smoother transitions
- All tokens now use ThemeExtension pattern

## [1.0.0] - 2026-04-01

### Added
- Initial stable release
- Atomic design structure (Tokens, Atoms, Molecules, Organisms)
- Core design tokens (Colors, Typography, Spacing, Radius, Shadows)
- UI components library