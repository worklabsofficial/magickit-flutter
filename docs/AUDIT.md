# MagicKit project health audit

**Date:** 25 September 2026
**Branch audited:** `main` at `82180a6` (`chore: update version to 1.1.1`)
**Scope:** documentation only. No library or app source was changed for this audit.
**Toolchain used to measure `main`:** Flutter 3.47.5 (stable, framework revision `6a19cca564`, 17 September 2026), Dart 3.13.4, melos 7.4.0 (the version resolved inside this workspace). Setup followed the Flutter pin in draft PR #6.

This is a snapshot so the owner can set priorities. It is not a redesign proposal.

## 1. What the project is

MagicKit is a small Flutter UI kit plus a code-generation CLI, published as two packages from one pub workspace.

The repo root (`magickit_workspace`) is a Dart pub workspace (`sdk: >=3.5.0 <4.0.0`) orchestrated by melos. It is not itself a Flutter app. There is no root README.

| Package | Role | Version | Publishable |
| --- | --- | --- | --- |
| `packages/magickit` | Flutter widget library. Atomic design, theme tokens, one barrel export. | 1.1.1 | Yes. Live on pub.dev. |
| `packages/magickit_cli` | Dart CLI (`magickit`). Scaffolding, registry, AI slicing, ObjectBox storage codegen. | 1.1.1 | Yes. Live on pub.dev. Executable `magickit`. |
| `example` (`magickit_example`) | Hand-rolled widget gallery ("Widget Book"). Depends on the local `magickit` package through the workspace. | 1.0.0+1 | No (`publish_to: none`). |

Rough size of Dart under `lib/`: `magickit` 7,093 lines, `magickit_cli` 11,788 lines, `example` 2,579 lines. The CLI is larger than the UI kit, and it has no tests.

### UI kit architecture

`package:magickit/magickit.dart` is the whole public API. Everything under `lib/src/` is exported from that barrel, so `src/` is public in practice.

Design tokens are plain Dart objects, gathered into `MagicTheme` (`ThemeExtension`). Apps register `MagicTheme.light()` / `MagicTheme.dark()` on `ThemeData.extensions`. `MagicColors` is also a `ThemeExtension`, but `MagicColors.of` reads colors from `MagicTheme`, not from a separately registered `MagicColors` extension.

`MagicContextExtensions` on `BuildContext` exposes `theme`, `colors`, `typography`, `spacing`, `radius`, `shadows`, `animations`, and `breakpoints`.

| Layer | Files | Widgets and types |
| --- | --- | --- |
| Tokens | 8 | `MagicColors`, `MagicTypography`, `MagicSpacing`, `MagicRadius`, `MagicShadows`, `MagicAnimations`, `MagicBreakpoints` / `MagicBreakpointType`, `MagicTheme` |
| Atoms | 15 | `MagicAvatar`, `MagicBadge`, `MagicButton`, `MagicCheckbox`, `MagicDivider`, `MagicIcon`, `MagicImage`, `MagicInput`, `MagicPinInput`, `MagicProgress`, `MagicRadio`, `MagicShimmer`, `MagicSlider`, `MagicRangeSlider` (same file as the slider), `MagicSwitch`, `MagicText` |
| Molecules | 13 | `MagicCard`, `MagicCarousel`, `MagicChip`, `MagicDialog`, `MagicDropdown`, `MagicEmptyState`, `MagicFormField`, `MagicListTile`, `MagicRating`, `MagicSearchBar`, `MagicSnackbar`, `MagicStepper`, `MagicTooltip` |
| Organisms | 10 | `MagicAppBar`, `MagicBottomSheet`, `MagicDataTable`, `MagicDrawer`, `MagicForm`, `MagicGridView`, `MagicListView`, `MagicNavBar`, `MagicRefreshLayout`, `MagicTabBar` |

Each component file carries a `{@magickit ...}` doc block (name, category, use case, visual keywords). `analysis_options.yaml` ignores `doc_directive_unknown` for that custom directive. `magickit registry` turns those blocks into:

- `lib/src/registry/component_registry.yaml`
- `lib/src/registry/ai_context_bundle.md`

The gallery in `example/lib/widgetbook/` is not the [widgetbook](https://pub.dev/packages/widgetbook) package. It is a `TabBar` of Atoms / Molecules / Organisms with one example screen per component (38 example files). `example/.metadata` records only the iOS platform. There is no `android/`, `web/`, `macos/`, `linux/`, or `windows/` directory.

### How the CLI fits

`bin/magickit.dart` builds a `MagicKitRunner` and registers the commands. The runner's styled help is hand-maintained and can drift from the real command list.

| Command | What it does |
| --- | --- |
| `doctor` | Checks Flutter, Dart, a `magickit` dependency, and `magickit.yaml`. |
| `init` | Writes `magickit.yaml` and a starter project skeleton. |
| `page` | Generates a page plus routing inside a feature. |
| `kickstart` | Generates splash, onboarding, login, and main navigation. |
| `api` | Generates a data/domain/presentation stack from a `remote/` folder. |
| `assets` | Scans `assets/` into a `MagicAssets` class. |
| `l10n` | Scans locale files into `AppLocalizations`. |
| `component` | Scaffolds a new atom, molecule, or organism. |
| `registry` | Scans `{@magickit}` annotations into the YAML registry and the AI bundle. |
| `slicing` | `prompt`, `image`, and `figma` subcommands. Turns a UI description, image, or Figma selection into Flutter code via Gemini or Anthropic. |
| `snippets` | Installs VS Code snippets for the components. |
| `storage` | ObjectBox init, entity codegen, and `build_runner`. |
| `version` | Prints CLI and UI-kit versions. `--update` runs `dart pub global activate magickit_cli`. |

The UI kit does not call the network. The CLI does: slicing posts prompts and images to Gemini or Anthropic, and several commands spawn `flutter` / `dart` / `build_runner`. API keys are read from the environment or from `magickit.yaml` (`ai_api_key`, `figma_api_key`). The `init` template writes those keys as empty strings in a project file, which is easy to commit later.

`magickit version` for the UI kit looks for this monorepo (`melos.yaml`, then `packages/magickit/lib/src/version.g.dart`). A globally activated CLI, used outside this repo, reports the UI-kit version as `unknown`.

## 2. Current health

Commands were run on `main` after `flutter pub get` at the workspace root.

### `melos run analyze` — pass

Exit code 0. Three info-level lints, no warnings, no errors.

| Package | Result |
| --- | --- |
| `magickit` | 1 info. `prefer_initializing_formals` in `lib/src/organisms/magic_grid_view.dart:153` (masonry constructor assigns `itemExtentBuilder` in the initializer list). |
| `magickit_cli` | 2 infos. `unnecessary_brace_in_string_interps` in `lib/src/commands/snippets_command.dart:90` and `:107`. |
| `magickit_example` | No issues. |

`flutter pub get` on Flutter 3.47.5 also rewrote `pubspec.lock` (newer transitive versions) and inserted `analyzer.exclude` blocks into `packages/magickit/analysis_options.yaml` and `example/analysis_options.yaml`. Those edits were reverted and are not part of this pull request. A future install on this SDK will dirty the tree the same way unless those excludes are committed on purpose.

### `melos run test` — fail

Exit code 1. There is nothing to run.

| Script | Result |
| --- | --- |
| `melos run test:flutter` | Failed in both Flutter packages. `flutter test` exits 1 with `Test directory "test" not found` for `magickit` and `example`. |
| `melos run test:dart` | Failed in `magickit_cli`. `dart test` exits 65 because `test/` does not exist. |

`flutter_test` and `package:test` are dev dependencies and are unused. The only test file in the repo is `example/ios/RunnerTests/RunnerTests.swift`, an empty XCTest stub. Melos does not run it. There is no coverage configuration and no golden tests.

Coverage gap: the entire public surface. Tokens, theme lookup, every widget, and every CLI generator are untested. The risky untested area is the CLI (`api_generator.dart` is on the order of 2,000 lines of string templates, plus `kickstart`, `storage`, and `slicing`), because a bad template ships into other people's apps.

### Example web build — fail on `main`

`flutter build web` in `example/` exits 1:

```text
This project is not configured for the web.
To configure this project for the web, run flutter create . --platforms web
```

The example was created as an iOS-only Flutter app (`.metadata` lists `ios` only).

A throwaway copy outside the repo, with only `flutter create . --platforms web` added, compiled the existing gallery: `Built build/web` in about 30 seconds. The wasm dry run succeeded. That copy was not committed. The Dart code is web-capable; `main` is missing the platform folder. Draft PR #6 adds that folder.

### Pub.dev, as of this audit

Both packages resolve for a normal app. A throwaway Flutter project depending on `magickit: ^1.1.1` completed `flutter pub get` on this SDK.

| | `magickit` | `magickit_cli` |
| --- | --- | --- |
| Latest | 1.1.1, published 10 May 2026 | 1.1.1, published 10 May 2026 |
| Publisher | `worklabs.web.id` | `worklabs.web.id` |
| Pub points | 130 / 160 | 130 / 160 |
| Likes | 0 | 0 |
| Downloads, 30 days | 9 | 8 |
| Notable tag | `license:unknown` | `license:unknown` |

Earlier `magickit` versions on pub.dev: 1.0.0 (14 March 2026), 1.1.0 (10 May 2026). Nothing has been published since 1.1.1. Git tags exist only for `magickit-cli-v1.0.1`, `v1.0.2`, and `v1.0.3`. There is no tag for 1.1.x of either package.

## 3. Open work

### PR #5 — close

https://github.com/worklabsofficial/magickit-flutter/pull/5

- Open since 30 April 2026. Not a draft. One commit on `test/issue-4`: adds `TEST.md` (14 lines) "for testing the automated workflow pipeline."
- Body says `Closes #4`. Issue #4 no longer exists (GitHub returns HTTP 410, "This issue was deleted"), so the link closes nothing. The issue list currently shows a single closed issue, #2.
- The owner's review on the PR already says to remove `TEST.md` after the test, to keep the repo clean.
- The notification workflow this PR was exercising is already on `main`, and the Actions run for this PR itself succeeded. Merging would only add a leftover smoke-test file.

### PR #6 — needs changes, then merge

https://github.com/worklabsofficial/magickit-flutter/pull/6

Draft. Branch `cursor/setup-dev-environment-aeb0`. One commit. No reviews. It adds:

- `.cursor/environment.json` and `.cursor/install.sh` (Flutter 3.47.5, Dart 3.13.4, melos on `PATH`, `flutter pub get`)
- `example/web/` so the gallery can run headless

The install approach works. This audit used the same Flutter pin, and `melos run analyze` passed. The web scaffold is the missing piece for `flutter build web` on `main`. Do not close the PR.

Change it before merge:

1. The widgetbook terminal command is `flutter run -d web-server --web-port 8090 --web-hostname 0.0.0.0` with no working directory. Cloud-agent terminals start at the repo root. The root package is the pub workspace, not the Flutter app. The command needs to run in `example/` (`cd example && flutter run ...`). The PR description says the server was verified; that verification was likely from `example/`, which the committed command does not do.
2. `flutter pub get` on 3.47.5 rewrites `analysis_options.yaml` and can rewrite `pubspec.lock`. A fresh agent install will show a dirty tree. Either commit the analyzer `exclude` blocks on purpose, or keep the install script from surprising the worktree.

After those two fixes, mark the draft ready and merge it. It is the practical way to demo the gallery and to give the next agent a working toolchain.

## 4. CI/CD and tooling

### GitHub Actions

One workflow: `.github/workflows/notify-ucupagent.yml` ("Notify Ucup Agent"). It runs on issue `opened` / `reopened` / `edited` and the same pull-request types. It does not run on push. It does not analyze, test, build, or publish.

Recent runs: the four earliest commits that introduced the workflow failed in 0 seconds. After the Python rewrite, runs succeed (issue #4's notification, PR #5, and both PR #6 events).

There is no auto-fix pipeline in this repository. The workflow posts a Telegram message that tells a person to reply to the ucupagent bot with `/gh-issues <repo>`. Any fix that follows happens outside GitHub Actions.

### Credential in the workflow

The Telegram bot token and chat id are hardcoded in that workflow file. They are in git history on `main`, so they are public. Rotate the bot token now, then move the token and chat id to GitHub Actions secrets. This audit does not repeat the secret.

The message uses `parse_mode: HTML` and interpolates issue and PR titles without escaping. A title containing `<` can break the Telegram parse. That is secondary to rotating the token.

### Versioning and publishing

Melos scripts (duplicated in `melos.yaml` and the root `pubspec.yaml`, currently identical):

- `pub:dry` — `melos publish -y` (dry run is the default)
- `pub:release` — `melos publish --no-dry-run -y`
- `analyze`, `test`, `test:flutter`, `test:dart`, `format`, `clean`

Publishing is manual. There is no tag or publish workflow. Package versions are hand-bumped, with `tool/generate_version.dart` writing `lib/src/version.g.dart` (both packages are at `1.1.1`, and `.gitignore` keeps those two generated files).

### pub.dev readiness

Present for both publishable packages: `description`, `homepage`, `repository`, `issue_tracker`, `license: Apache-2.0`, an SDK constraint, a README, a CHANGELOG, and a `LICENSE` file. The CLI declares `executables: magickit`.

Gaps that match a 130/160 score:

- The `LICENSE` files are the Apache 2.0 text indented with leading spaces. pub.dev tags both packages `license:unknown`. A detector that expects the canonical header at column 0 will miss them. The pubspec `license` field is set correctly.
- The published `magickit` 1.1.1 pubspec still contains `resolution: workspace`. A consumer `flutter pub get` of `magickit: ^1.1.1` succeeded on Flutter 3.47.5, so this is not currently blocking installs. It is still a workspace-only key that should not ship in the archive.
- The gallery lives at the repo root as `example/`, with `publish_to: none`. It is not `packages/magickit/example`, so the published UI-kit archive has no example. Pana's example check looks inside the package.
- No `topics`, no screenshots, no funding link.
- The README that is live on pub.dev documents extension members that do not exist (see below). That is user-facing on the package page.
- `magickit` CHANGELOG follows Keep a Changelog. The `[Unreleased]` section repeats the 1.1.1 BuildContext notes. The CLI CHANGELOG has no dates and is looser.
- `example/README.md` is still the Flutter template line "A new Flutter project."
- `doctor` tells a user who has not added the dependency to use `magickit: ^0.1.0`. The first published version is 1.0.0. Current is 1.1.1.

## 5. Code quality

### Dependencies

`flutter pub outdated` on this SDK:

| Package | Locked | Latest | Notes |
| --- | --- | --- | --- |
| `mason_logger` | 0.3.3 | 0.3.6 | Direct. Within `^0.3.2`. Lockfile is behind. |
| `yaml` | 3.1.3 | 3.1.4 | Direct. Within `^3.1.2`. Lockfile is behind. |
| `flutter_lints` | 4.0.0 | 6.0.0 | Dev dependency of `magickit` and `example`. Constraint `^4.0.0` blocks the upgrade. |
| `lints` | 4.0.0 | 6.1.0 | Dev dependency of the CLI. Constraint `^4.0.0` blocks the upgrade. |
| `melos` | 7.4.0 | 8.9.0 | Root dev dependency `^7.0.0`. |
| `args`, `http`, `path`, `test` | current within range | — | No direct-version alarm. |

33 packages have newer versions that the current constraints will not take, mostly transitive. Runtime dependencies of the UI kit are only the Flutter SDK. The staleness that matters is the lint major (4 versus 6) and melos 7 versus 8, plus a lockfile that `pub get` on Flutter 3.47.5 already wants to move.

### Deprecated APIs

The widget library does not use removed Material widgets (`FlatButton`, `RaisedButton`, `WillPopScope`) and it uses `WidgetStateProperty`, which is the current button-style API. `Color.withOpacity` does not appear in `magickit`.

It does appear in the `kickstart` template (`packages/magickit_cli/lib/src/commands/kickstart_command.dart`). New apps generated today will contain a call Flutter has deprecated in favor of `withValues`.

### Documentation that does not match the code

These are the sharpest product bugs, because the published README and CHANGELOG tell users to write code that does not compile.

1. README and CHANGELOG 1.1.1 document `context.breakpoint` and `context.isDark`. `MagicContextExtensions` does not define them. `MagicTheme.isDark` and `MagicTheme.breakpoint` exist as static methods. The extension has `breakpoints` (the token object), not `breakpoint`.
2. CHANGELOG says `context.breakpoint` returns `xs`, `sm`, `md`, `lg`, `xl`. `MagicBreakpointType` is `mobile`, `tablet`, `desktop`, `wide`.
3. The `MagicBreakpoints` dartdoc sample calls `MagicBreakpoints.of(context)`. That method does not exist. The static API is `typeOf`, `isMobile`, `isTablet`, `isDesktop`, `isWide`, and `responsive`.
4. `MagicBreakpoints.typeOf` always does `const MagicBreakpoints().resolve(width)`. Custom thresholds stored on `MagicTheme.breakpoints` are ignored by `typeOf`, `responsive`, `MagicGridView`, and the static helpers.
5. The `magickit` README catalog omits widgets that are exported and registered: `MagicPinInput`, `MagicProgress`, `MagicSlider`, `MagicRangeSlider`, `MagicCarousel`, `MagicEmptyState`, `MagicRating`, `MagicStepper`, `MagicGridView`, `MagicListView`, `MagicRefreshLayout`, plus tokens `MagicAnimations` and `MagicBreakpoints`.
6. That README points at `lib/src/registry/ai_context_bundle.txt`. The file is `ai_context_bundle.md`. The CLI already looks for the `.md` name.
7. The CLI README documents the `registry` command twice, back to back.

### Other risky spots

- `MagicTheme.of` explains a missing theme inside `assert`, then returns `theme!`. Release builds strip asserts, so a missing `MagicTheme` becomes a null-check throw with no setup hint.
- `MagicTheme.lerp` interpolates colors only. Typography, spacing, radius, shadows, animations, and breakpoints snap at `t == 1`. Light and dark themes today share those tokens, so the gap shows up when someone customizes them.
- Accessibility is thin. A search for `Semantics` in the UI kit hits comments on `MagicRefreshLayout` and no `Semantics` widgets. Buttons and inputs inherit some semantics from Material. Icon-only controls, the pin input, the rating, and the carousel do not add labels of their own.
- `MagicForm` captures `formKey` in `initState` and does not update it if the parent replaces the key.
- Slicing sends UI images and prompts to a third-party model. Keys in `magickit.yaml` are a commit hazard. There is no test that the request body stays free of the key in logs.
- `version --update` activates whatever `magickit_cli` is latest on pub.dev, with no version pin and no confirmation of which binary will run afterward.
- Lint configuration is `flutter_lints` / `lints` recommended, plus four extra rules on the UI kit (`prefer_const_constructors`, `prefer_const_declarations`, `avoid_unnecessary_containers`, `use_key_in_widget_constructors`). That is a light bar, and it is two major versions behind current `flutter_lints`.
- No root README, no CONTRIBUTING, no issue or PR templates, no CODEOWNERS. `.github/` contains only the Telegram workflow.

The widget implementations that were read (`MagicButton`, `MagicForm`, `MagicListView`, `MagicTheme`, the gallery shell) are straightforward Flutter. The library is not in a broken-analyze state. The health problem is trust: no tests, docs that over-claim the API, a public bot token, and no CI gate.

## 6. Prioritized roadmap

Ordered for the owner. S is a focused change in a few files. M crosses packages or needs a new workflow plus tests. L is a multi-component pass.

| # | Task | Why | Size |
| --- | --- | --- | --- |
| 1 | Rotate the Telegram bot token and move the token and chat id to GitHub Actions secrets. Escape HTML in the message. | The live credential is in `main` history. Rotation is the only fix. | S |
| 2 | Close PR #5 without merging. | `TEST.md` is a finished smoke test. Issue #4 is gone. The PR's own review says to delete the file. | S |
| 3 | Fix PR #6's widgetbook command so it runs in `example/`, then merge the web platform and the Cloud Agent install. | `flutter build web` fails on `main` only because the platform folder is missing. The gallery already compiles once that folder exists. | S |
| 4 | Make the published API true. Add `context.isDark` and `context.breakpoint`, or delete them from the README and CHANGELOG. Fix `MagicBreakpoints.of`, the `xs/sm/md/lg/xl` names, the component catalog, and `ai_context_bundle.txt`. Point `doctor` at `^1.1.1`. | The package page currently teaches code that does not compile. | S |
| 5 | Make `MagicBreakpoints.typeOf` read `MagicTheme.breakpoints` when a theme is present. | Custom breakpoints on the theme are silently ignored by layout helpers. | S |
| 6 | Add a GitHub Actions workflow that runs `melos run analyze` and `melos run test` on pull requests. | The only workflow today notifies Telegram. A red analyze would not block a merge. | S |
| 7 | Add the first real tests: theme lookup, breakpoint resolution, one atom (`MagicButton` disabled / loading), and CLI `version` plus one generator against a temp directory. Keep `melos run test` green, including the "no test directory" exit codes. | Coverage is zero, and the test scripts fail closed. This is the seed, not full coverage. | M |
| 8 | pub.dev cleanup: un-indent `LICENSE` so the license is detected, add `topics` and a screenshot, put an example inside `packages/magickit` (or document why the workspace example is enough), strip `resolution: workspace` from published pubspecs, clear the duplicate `[Unreleased]` notes, replace the example README. | Both packages sit at 130/160 with `license:unknown`, and the UI kit ships without an example. | M |
| 9 | Bump `flutter_lints` and `lints` to the current major, and melos when the workspace is ready. Re-run analyze. Stop `kickstart` from emitting `withOpacity`. | The lint bar is two majors behind the SDK this audit used. Generated apps inherit a deprecated API. | M |
| 10 | Accessibility labels on icon-only and custom controls, plus widget tests for the gallery's atoms. | A UI kit with no semantics tests will regress contrast and screen readers without anyone noticing. | L |

Items 1–5 are the ones that change risk or honesty without a large rewrite. Items 6–7 are what make the next feature safe to land. Items 8–10 are the pub.dev and product-quality work once the gate exists.
