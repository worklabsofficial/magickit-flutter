# Releasing magickit_cli

Only `packages/magickit_cli` is published from this repository. The `magickit` UI kit is a separate package and is not bumped or published by this process.

Publishing uses pub.dev automated publishing (GitHub Actions OIDC). The workflow is `.github/workflows/publish-magickit-cli.yml`. It runs only when a tag matching `magickit-cli-vX.Y.Z` is pushed. It does not run on pull requests, and it does not use a long-lived pub.dev token.

## One-time setup

Do this once per package, before the first automated publish. The first version of a brand-new package still has to be uploaded manually; after that, tags publish it.

### pub.dev

On the package admin page (`https://pub.dev/packages/magickit_cli/admin`):

1. Enable **publishing from GitHub Actions**.
2. Repository: `worklabsofficial/magickit-flutter`.
3. Tag pattern: `magickit-cli-v{{version}}`.
4. Require the GitHub Actions environment named `pub.dev`.

### GitHub

1. In this repository, create an environment named `pub.dev` (Settings → Environments).
2. Add yourself as a required reviewer on that environment.
3. Leave the workflow without secrets. Authentication is the OIDC token requested by `id-token: write`.

The publish job will wait in Actions until that environment is approved.

## Release steps

1. Open a release pull request from the latest `main`.
2. Bump `version` in `packages/magickit_cli/pubspec.yaml`.
3. Regenerate the compiled-in version from the CLI package directory:

   ```bash
   cd packages/magickit_cli
   dart run tool/generate_version.dart
   ```

   That writes `packages/magickit_cli/lib/src/version.g.dart`, which `magickit version` and `magickit --version` read.
4. Move `## [Unreleased]` in `packages/magickit_cli/CHANGELOG.md` to `## [X.Y.Z] - YYYY-MM-DD` and leave an empty `[Unreleased]` section above it.
5. Merge the pull request to `main`.
6. Check out that merge commit and push the tag. Do not tag a side branch.

   ```bash
   git checkout main
   git pull origin main
   git tag magickit-cli-vX.Y.Z
   git push origin magickit-cli-vX.Y.Z
   ```

   The version after `magickit-cli-v` must be identical to `version:` in `packages/magickit_cli/pubspec.yaml`. For 1.2.0 the tag is `magickit-cli-v1.2.0`.
7. Open the **Publish magickit_cli** run in Actions and approve the `pub.dev` environment. The workflow refuses to publish if the tag and pubspec versions differ, then calls the Dart team's reusable publish workflow (`dart pub publish --dry-run`, then `dart pub publish -f`) from `packages/magickit_cli`.

`packages/magickit_cli` is a member of the repo pub workspace (`resolution: workspace`). Commands run in that directory resolve the workspace at the repository root, so the workflow does not need a separate `melos bootstrap`. The reusable workflow installs Flutter before `dart pub get`, which the Flutter workspace members need. Leave `resolution: workspace` in the source pubspec. `dart pub publish --dry-run` from `packages/magickit_cli` validates the package against that workspace.
