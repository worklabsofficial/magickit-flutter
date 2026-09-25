# magickit_cli

MagicKit CLI: Flutter scaffolding and code generation. The executable name is `magickit`.

## Install

Activate it globally:

```bash
dart pub global activate magickit_cli
```

From this repository, during development:

```bash
dart pub global activate --source path packages/magickit_cli
```

## Usage

```bash
magickit --version
magickit <command> [arguments]
magickit <command> --help
```

`magickit --version` prints the CLI version. `magickit version` prints the CLI version and the UI kit version.

`page`, `kickstart`, `l10n`, and every `slicing` subcommand require a `magickit.yaml` from `magickit init`. `page` and `kickstart` also require `lib/core/dependency_injection/injector.dart`. `api` requires the init scaffold (`magickit.yaml`, base classes, `TokenManager`, and `injector.dart`).

## Commands

### doctor

Checks Flutter, Dart, a `magickit` dependency in `pubspec.yaml`, and `magickit.yaml`.

```bash
magickit doctor
```

### init

Writes `magickit.yaml` and the project folders (assets, l10n templates, `lib/core` base classes, injector, network, and storage helpers). If `magickit.yaml` already exists, the command leaves it in place.

```bash
magickit init
```

### page

Generates a page and its routes inside a feature. Requires `magickit init`.

```bash
magickit page <feature> <page>
magickit page auth login --path-params id
magickit page product detail --query-params sort,rating
```

Options:

- `--path-params` — comma-separated path parameters
- `--query-params` — comma-separated query parameters

### kickstart

Generates a starter app: splash, onboarding, login, and main navigation. Requires `magickit init`.

```bash
magickit kickstart
```

### api

Generates feature code from JSON definitions in `remote/`.

```bash
magickit api
magickit api <feature>
magickit api <feature> <page>
magickit api --force --dry-run --verbose
```

Options:

- `--force` — overwrite generated files
- `--dry-run` — print the plan and skip writes
- `--verbose`, `-v` — print `$ref` and type resolution

Base URLs come from `magickit.yaml` (`magickit.api.base_urls`) or `remote/shared/base_urls.json`.

### assets

Scans an assets directory and generates `MagicAssets`. Configuration is `magickit.assets` in `magickit.yaml`:

- `input` — default `assets/`
- `output` — default `lib/core/assets/assets.gen.dart`
- `exclude`
- `group`
- `strip_prefix` — when the key is omitted, the generator strips `ic_` and `img_`

```bash
magickit assets
```

### l10n

Scans locale JSON and generates `AppLocalizations`. Requires `magickit init`. Configuration is `magickit.l10n`:

- `input` — default `assets/l10n/`
- `output` — default `lib/core/assets/l10n/`
- `default_locale` — default `id`

```bash
magickit l10n
```

### component

Scaffolds a widget that follows the MagicKit annotation convention.

```bash
magickit component rating_star --type atom
magickit component card_promo --type molecule --output lib/core/components/src
```

Options:

- `--type`, `-t` — `atom`, `molecule`, or `organism` (required)
- `--output`, `-o` — base output directory (default `lib/core/components/src` when `lib/core` exists, otherwise `lib/components/src`)
- `--package`, `-p` — package name imported for `ThemeExtension` (default `magickit`)

The command stops when the destination file already exists.

### registry

Scans `{@magickit}` annotations and writes a component registry plus an AI context bundle.

```bash
magickit registry
magickit registry --source lib/ --output lib/src/registry/
magickit registry --no-ai-bundle
```

Options:

- `--source`, `-s` — source directory (default `lib/`)
- `--output`, `-o` — output directory (default `lib/core/components/src/registry/` when `lib/core/components` exists, `lib/components/src/registry/` when `lib/components` exists, otherwise `lib/src/registry/`)
- `--ai-bundle` — write `ai_context_bundle.md` (default on). `--no-ai-bundle` skips it

Output files:

- `component_registry.yaml`
- `ai_context_bundle.md` — constructor signatures, types, and tags

### slicing

Turns a screenshot or a Figma MCP selection into Flutter code. Subcommands: `prompt`, `image`, `figma`. Running `magickit slicing` with no subcommand prints usage and exits.

```bash
magickit slicing prompt "slicing ui home page"
magickit slicing image --source ui.png
magickit slicing image --source ui.png --provider gemini
magickit slicing figma --selection selection.json
magickit slicing figma --selection selection.json --provider anthropic
```

| Subcommand | Role |
| --- | --- |
| `slicing prompt [task]` | Writes `lib/generated/slicing_prompt.md` for a manual upload |
| `slicing image` | Sends an image to the AI provider and writes `lib/generated/sliced_ui.dart` |
| `slicing figma` | Sends a Figma MCP selection JSON file to the AI provider and writes `lib/generated/sliced_ui.dart` |

`prompt` options:

- positional task text (default `slicing ui`)
- `--package-components` / `--no-package-components` — include the magickit package bundle (default on)

`image` options:

- `--source`, `-s` — PNG, JPG, WEBP, or GIF path (required)
- `--provider` — `anthropic` or `gemini`
- `--package-components` / `--no-package-components` (default on)

`figma` options:

- `--selection`, `-s` — path to the Figma MCP selection JSON (required)
- `--provider` — `anthropic` or `gemini`
- `--package-components` / `--no-package-components` (default on)

`--provider` overrides `magickit.slicing.ai_provider`. When the flag is omitted, the provider is `ai_provider` from `magickit.yaml`, or `anthropic`. Passing `--provider` also selects the built-in model (`claude-sonnet-4-6` or `gemini-2.5-flash`). Otherwise the model is `magickit.slicing.model` when that value is set.

`magickit init` also writes `output`, `prompt_output`, `use_local_components`, `use_package_components`, and `registry_output` under `magickit.slicing`. The slicing commands ignore those keys. Output paths are the paths above, and the package bundle follows `--package-components`.

`prompt` workflow:

1. Run `magickit registry` in the app when you have local components.
2. Run `magickit slicing prompt "task description"`.
3. Open the desktop AI client, upload the screenshot, and paste `lib/generated/slicing_prompt.md`.

#### API keys

`slicing image` and `slicing figma` need an AI provider key. `slicing prompt` does not call an API.

The key is the first non-empty value of:

1. `magickit.slicing.gemini_api_key` or `magickit.slicing.anthropic_api_key` in `magickit.yaml`, matching the provider
2. `magickit.slicing.ai_api_key`, then `magickit.slicing.api_key`
3. `GEMINI_API_KEY` or `ANTHROPIC_API_KEY` in the environment

`slicing figma` reads the local JSON file from `--selection`. It sends that file to the same AI provider. Keep keys in the environment, or keep `magickit.yaml` out of version control when it contains a key. Do not commit API keys.

`magickit init` writes empty `ai_api_key` and `figma_api_key` fields under `magickit.slicing`. The slicing commands read `ai_api_key` (and the provider-specific keys above). They do not read `figma_api_key`.

### snippets

Installs or lists VS Code snippets. A subcommand is required.

```bash
magickit snippets install
magickit snippets install --global
magickit snippets install --output .vscode/magickit.code-snippets
magickit snippets list
```

`install` options:

- `--output`, `-o` — snippets file (default `.vscode/magickit.code-snippets`)
- `--global`, `-g` — write the VS Code user snippets directory instead of `--output`

### storage

ObjectBox helpers from JSON entity files in `storage/`.

```bash
magickit storage init
magickit storage generate
magickit storage generate --force
magickit storage generate --build-runner
magickit storage info
```

| Subcommand | Role |
| --- | --- |
| `storage init` | Adds ObjectBox dependencies, writes the store, injector, database manager, and `storage/example_entity.json`, then runs `flutter pub get` and `build_runner` |
| `storage generate` | Regenerates models, helpers, the store, the injector, and the database manager from `storage/` |
| `storage info` | Prints the database path, entities, and generated files |

`generate` options:

- `--force` — overwrite generated files
- `--build-runner` — run `build_runner` after writing files

Entity file `storage/<entity>.json`:

```json
{
  "entity": "User",
  "table": "users",
  "fields": [
    { "name": "id", "type": "int", "id": true },
    { "name": "name", "type": "String" },
    { "name": "email", "type": "String", "unique": true },
    { "name": "createdAt", "type": "DateTime" },
    { "name": "isActive", "type": "bool" },
    { "name": "bio", "type": "String", "nullable": true }
  ],
  "indexes": ["email"],
  "relations": [{ "name": "posts", "type": "ToMany", "target": "Post" }]
}
```

Field `type` values: `String`, `int`, `double`, `bool`, `DateTime`, `List`, `Map` (matched case-insensitively). `nullable` and `unique` are booleans. Relation `type` is `ToOne` or `ToMany`.

Generated files:

| File | Purpose |
| --- | --- |
| `lib/core/storage/objectbox/objectbox_store.dart` | Store singleton and box fields |
| `lib/core/storage/objectbox/storage_injector.dart` | `storageInjector()` — opens ObjectBox and registers helpers on `GetIt.instance` |
| `lib/core/storage/objectbox/database_manager.dart` | `DatabaseManager` export, import, `clear`, and `getStats` |
| `lib/core/storage/objectbox/models/<entity>_model.dart` | `@Entity` class |
| `lib/core/storage/objectbox/helpers/<entity>_storage_helper.dart` | CRUD helper (`put`, `get`, `getAll`, `update`, `delete`, `clear`, `search`) |
| `lib/objectbox.g.dart` | ObjectBox output from `build_runner` |

The injector written by `init` declares `final getIt = GetIt.instance`. `storageInjector()` registers each helper with `GetIt.instance.registerFactory`.

For a schema whose only required field is `name`:

```json
{
  "entity": "User",
  "fields": [
    { "name": "id", "type": "int", "id": true },
    { "name": "name", "type": "String" }
  ]
}
```

the generated helper is called as `getIt<UserStorageHelper>()`, `helper.put(User(name: 'John'))`, and `helper.getAll()`. `put` returns the object id.

`DatabaseManager` is generated in `database_manager.dart` with `export(String filePath)`, `import(String filePath)`, `clear()`, and `getStats()`. `getStats()` returns `Map<String, int>` keyed by entity name.

### version

Prints the CLI version and the UI kit version.

```bash
magickit version
magickit version --update
```

`--update` (`-u`) runs `dart pub global activate magickit_cli`.

## Contributing

Open an issue or a pull request on the repository.

## License

Apache-2.0
