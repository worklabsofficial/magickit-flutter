# Releasing

This repository publishes two packages with pub.dev automated publishing (GitHub Actions OIDC). Neither workflow runs on pull requests or uses a long-lived pub.dev token.

| Package | Directory | Workflow | Tag |
| --- | --- | --- | --- |
| `magickit_cli` | `packages/magickit_cli` | `.github/workflows/publish-magickit-cli.yml` | `magickit-cli-vX.Y.Z` |
| `magickit` | `packages/magickit` | `.github/workflows/publish-magickit.yml` | `magickit-vX.Y.Z` |

`magickit-v*` does not match `magickit-cli-v*` tags, and the reverse is also true. Pushing one tag publishes only that package.

## One-time setup

Do this once per package, before the first automated publish. The first version of a brand-new package still has to be uploaded manually; after that, tags publish it. `magickit_cli` is already on automated publishing. `magickit` still needs the pub.dev admin steps below.

### pub.dev

On each package admin page, enable **publishing from GitHub Actions**:

| Package | Admin page | Tag pattern |
| --- | --- | --- |
| `magickit_cli` | `https://pub.dev/packages/magickit_cli/admin` | `magickit-cli-v{{version}}` |
| `magickit` | `https://pub.dev/packages/magickit/admin` | `magickit-v{{version}}` |

For both:

1. Repository: `worklabsofficial/magickit-flutter`.
2. Require the GitHub Actions environment named `pub.dev`.

### GitHub

The environment `pub.dev` already exists (Settings → Environments), with a required reviewer and no secrets. Authentication is the OIDC token requested by `id-token: write`.

If that environment limits which tags can deploy, allow both `magickit-cli-v*` and `magickit-v*`. A rule that only lists the CLI tags rejects the UI kit job before a reviewer can approve it.

The publish job waits in Actions until that environment is approved.

## Release steps

1. Open a release pull request from the latest `main`.
2. Bump `version` in that package's `pubspec.yaml` (`packages/magickit_cli/pubspec.yaml` or `packages/magickit/pubspec.yaml`).
3. Regenerate the compiled-in version from the package directory:

   ```bash
   cd packages/magickit_cli   # or packages/magickit
   dart run tool/generate_version.dart
   ```

   That writes `lib/src/version.g.dart`. `magickit version` and `magickit --version` read the CLI file. The UI kit reads its own file.
4. Move `## [Unreleased]` in that package's `CHANGELOG.md` to `## [X.Y.Z] - YYYY-MM-DD` and leave an empty `[Unreleased]` section above it.
5. Merge the pull request to `main`.
6. Check out that merge commit and push one tag. Do not tag a side branch.

   ```bash
   git checkout main
   git pull origin main
   git tag magickit-cli-vX.Y.Z   # or magickit-vX.Y.Z
   git push origin magickit-cli-vX.Y.Z
   ```

   The version after the tag prefix must be identical to `version:` in that package's `pubspec.yaml`.
7. Open the matching **Publish magickit_cli** or **Publish magickit** run in Actions and approve the `pub.dev` environment. The workflow refuses to publish if the tag and pubspec versions differ, then calls the Dart team's reusable publish workflow (`dart pub publish --dry-run`, then `dart pub publish -f`) from that package directory.

Both packages are members of the repo pub workspace (`resolution: workspace`). Commands run in the package directory resolve the workspace at the repository root, so the workflow does not need a separate `melos bootstrap`. The reusable workflow installs Flutter before `dart pub get`, which the Flutter workspace members need. Leave `resolution: workspace` in the source pubspec.
