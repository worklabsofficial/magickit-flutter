## AVAILABLE GLOBAL COMPONENTS

The project uses a shared component library called `magickit`. When generating Flutter code, ALWAYS prefer using these existing components over creating new widgets from scratch.

### Import Statement:
```dart
import 'package:magickit/magickit.dart';
// This import gives access to all MagicKit components
```

### Atoms (12)

#### `MagicCheckbox`

Checkbox untuk multi-select, persetujuan, toggle item

- **Category**: atom
- **Type**: StatelessWidget
- **Tags**: atom, input, action, stateless

**File**: `src/atoms/magic_checkbox.dart`

**Constructors:**

```dart
MagicCheckbox(
  required bool? value,
  required ValueChanged<bool?> onChanged,
  String? label,
  bool tristate = false,
  bool enabled = true
)
```

**Keywords:** checkbox, checklist, pilihan, centang, multi-select

#### `MagicDivider`

Garis pemisah antar section

- **Category**: atom
- **Type**: StatelessWidget
- **Tags**: atom, stateless

**File**: `src/atoms/magic_divider.dart`

**Constructors:**

```dart
MagicDivider(
  Axis? axis,
  double? thickness,
  Color? color,
  double indent = 0,
  double endIndent = 0
)
```

**Keywords:** divider, garis, separator, pemisah, hr

#### `MagicRadio`

Radio button untuk single-select dari beberapa pilihan

- **Category**: atom
- **Tags**: atom, input, action, stateless

**File**: `src/atoms/magic_radio.dart`

**Constructors:**

```dart
MagicRadio(
  required T value,
  required T groupValue,
  required ValueChanged<T?> onChanged,
  String? label,
  bool enabled = true
)
```

**Keywords:** radio, single select, pilihan tunggal, option

#### `MagicBadge`

Label kecil untuk status, tag, kategori, notifikasi count

- **Category**: atom
- **Type**: StatelessWidget
- **Tags**: atom, stateless

**File**: `src/atoms/magic_badge.dart`

**Constructors:**

```dart
MagicBadge(
  required String label,
  MagicBadgeVariant variant = MagicBadgeVariant.soft,
  Color? color,
  IconData? icon
)
```

**Keywords:** badge, label, tag, chip, status, pill

#### `MagicSwitch`

Toggle switch untuk mengaktifkan/menonaktifkan fitur atau pengaturan

- **Category**: atom
- **Type**: StatelessWidget
- **Tags**: atom, input, action, stateless

**File**: `src/atoms/magic_switch.dart`

**Constructors:**

```dart
MagicSwitch(
  required bool value,
  required ValueChanged<bool> onChanged,
  String? label,
  bool enabled = true
)
```

**Keywords:** switch, toggle, on off, aktifkan, nonaktifkan

#### `MagicImage`

Menampilkan gambar dari URL atau asset dengan loading dan error state

- **Category**: atom
- **Type**: StatelessWidget
- **Tags**: atom, media, stateless

**File**: `src/atoms/magic_image.dart`

**Constructors:**

```dart
MagicImage(
  required String src,
  BoxFit fit = BoxFit.cover,
  double? width,
  double? height,
  BorderRadius? borderRadius,
  Widget? errorWidget
)
```

**Keywords:** image, gambar, foto, picture, thumbnail

#### `MagicIcon`

Menampilkan icon dengan warna dari theme tokens

- **Category**: atom
- **Type**: StatelessWidget
- **Tags**: atom, stateless

**File**: `src/atoms/magic_icon.dart`

**Keywords:** icon, ikon, symbol, glyph

#### `MagicInput`

Text field untuk input data user, form, pencarian

- **Category**: atom
- **Type**: StatelessWidget
- **Tags**: atom, input, action, form, stateless

**File**: `src/atoms/magic_input.dart`

**Constructors:**

```dart
MagicInput(
  String? hint,
  TextEditingController? controller,
  dynamic validator,
  Widget? prefixIcon,
  Widget? suffixIcon,
  bool obscureText = false,
  TextInputType? keyboardType,
  TextInputAction? textInputAction,
  ValueChanged<String>? onChanged,
  VoidCallback? onTap,
  bool enabled = true,
  String? label,
  String? errorText,
  int? maxLines = 1,
  FocusNode? focusNode,
  bool autofocus = false
)
```

**Keywords:** input, text field, form, kolom, isian

#### `MagicText`

Menampilkan teks dengan design token typography

- **Category**: atom
- **Type**: StatelessWidget
- **Tags**: atom, stateless

**File**: `src/atoms/magic_text.dart`

**Keywords:** text, teks, typography, heading, body, caption, label

#### `MagicAvatar`

Menampilkan avatar user dengan fallback initials

- **Category**: atom
- **Type**: StatelessWidget
- **Tags**: atom, media, stateless

**File**: `src/atoms/magic_avatar.dart`

**Constructors:**

```dart
MagicAvatar(
  String? imageUrl,
  MagicAvatarSize size = MagicAvatarSize.md,
  String? fallbackInitial,
  Color? backgroundColor
)
```

**Keywords:** avatar, profil, user, profile picture, foto

#### `MagicShimmer`

Loading placeholder dengan animasi shimmer untuk skeleton screen

- **Category**: atom
- **Type**: StatefulWidget
- **Tags**: atom, animation, stateful

**File**: `src/atoms/magic_shimmer.dart`

**Constructors:**

```dart
MagicShimmer(
  double? width,
  double? height,
  BorderRadius? borderRadius
)
```

**Keywords:** shimmer, skeleton, loading, placeholder, loading state

#### `MagicButton`

Tombol aksi utama, submit form, navigasi

- **Category**: atom
- **Type**: StatelessWidget
- **Tags**: atom, action, stateless

**File**: `src/atoms/magic_button.dart`

**Constructors:**

```dart
MagicButton(
  required String label,
  required VoidCallback? onPressed,
  MagicButtonVariant variant = MagicButtonVariant.primary,
  MagicButtonSize size = MagicButtonSize.medium,
  bool isLoading = false,
  IconData? icon
)
```

**Keywords:** button, tombol, CTA, submit, aksi

### Molecules (9)

#### `MagicTooltip`

Tooltip informatif yang muncul saat hover atau long-press

- **Category**: molecule
- **Type**: StatelessWidget
- **Tags**: molecule, stateless

**File**: `src/molecules/magic_tooltip.dart`

**Constructors:**

```dart
MagicTooltip(
  required String message,
  required Widget child,
  bool preferBelow = true,
  Duration waitDuration = const Duration(milliseconds: 500)
)
```

**Keywords:** tooltip, hint, info, keterangan, hover

#### `MagicFormField`

Wrapper form field dengan label, helper text, dan error message

- **Category**: molecule
- **Type**: StatelessWidget
- **Tags**: molecule, form, stateless

**File**: `src/molecules/magic_form_field.dart`

**Constructors:**

```dart
MagicFormField(
  required String label,
  required Widget child,
  String? errorText,
  String? helperText,
  bool isRequired = false
)
```

**Keywords:** form field, label, input field, form, error, helper

#### `MagicSearchBar`

Input pencarian dengan tombol clear dan submit

- **Category**: molecule
- **Type**: StatefulWidget
- **Tags**: molecule, input, action, stateful

**File**: `src/molecules/magic_search_bar.dart`

**Constructors:**

```dart
MagicSearchBar(
  TextEditingController? controller,
  ValueChanged<String>? onSearch,
  ValueChanged<String>? onChanged,
  String hint = 'Cari...',
  bool autofocus = false,
  VoidCallback? onClear,
  bool enabled = true
)
```

**Keywords:** search, cari, pencarian, search bar, find

#### `MagicChip`

Tag atau filter chip yang bisa dipilih atau dihapus

- **Category**: molecule
- **Type**: StatelessWidget
- **Tags**: molecule, action, stateless

**File**: `src/molecules/magic_chip.dart`

**Constructors:**

```dart
MagicChip(
  required String label,
  VoidCallback? onTap,
  bool selected = false,
  VoidCallback? onDeleted,
  Widget? avatar,
  Color? color,
  bool enabled = true
)
```

**Keywords:** chip, tag, filter, label, badge, kategori

#### `MagicSnackbar`

 Gunakan [MagicSnackbar.show] untuk menampilkan snackbar.  ```dart MagicSnackbar.show( context, message: 'Data berhasil disimpan', variant: MagicSnackbarVariant.success, ); ```

- **Category**: molecule
- **Tags**: molecule, action

**File**: `src/molecules/magic_snackbar.dart`

**Keywords:** snackbar, toast, notifikasi, pesan, alert

#### `MagicCard`

Container card dengan shadow dan border radius untuk mengelompokkan konten

- **Category**: molecule
- **Type**: StatelessWidget
- **Tags**: molecule, action, stateless

**File**: `src/molecules/magic_card.dart`

**Constructors:**

```dart
MagicCard(
  required Widget child,
  EdgeInsetsGeometry? padding,
  MagicCardElevation elevation = MagicCardElevation.sm,
  BorderRadius? borderRadius,
  Color? color,
  VoidCallback? onTap,
  Border? border
)
```

**Keywords:** card, container, box, panel, kotak, grup konten

#### `MagicDropdown`

Selector dropdown untuk memilih satu opsi dari daftar

- **Category**: molecule
- **Tags**: molecule, input, form, stateless

**File**: `src/molecules/magic_dropdown.dart`

**Constructors:**

```dart
MagicDropdown(
  required dynamic items,
  required T value,
  required dynamic onChanged,
  dynamic hint,
  dynamic enabled = true,
  dynamic errorText
)
```

**Keywords:** dropdown, select, pilihan, selector, combobox

#### `MagicDialog`

Dialog popup untuk konfirmasi, informasi, atau input tambahan

- **Category**: molecule
- **Type**: StatelessWidget
- **Tags**: molecule, action, modal, stateless

**File**: `src/molecules/magic_dialog.dart`

**Constructors:**

```dart
MagicDialog(
  String? title,
  required Widget content,
  List<Widget>? actions,
  bool showClose = true,
  double? width
)
```

**Keywords:** dialog, modal, popup, alert, konfirmasi

#### `MagicListTile`

Item dalam daftar dengan leading, title, subtitle, dan trailing

- **Category**: molecule
- **Type**: StatelessWidget
- **Tags**: molecule, action, list, stateless

**File**: `src/molecules/magic_list_tile.dart`

**Constructors:**

```dart
MagicListTile(
  required String title,
  String? subtitle,
  Widget? leading,
  Widget? trailing,
  VoidCallback? onTap,
  bool selected = false,
  bool enabled = true,
  bool showDivider = false
)
```

**Keywords:** list tile, list item, row, item, daftar

### Organisms (7)

#### `MagicDataTable`

Tabel data dengan header sortable, row selection, dan empty/loading state

- **Category**: organism
- **Type**: StatelessWidget
- **Tags**: organism, action, stateless

**File**: `src/organisms/magic_data_table.dart`

**Constructors:**

```dart
MagicDataTable(
  required List<MagicDataColumn> columns,
  required List<MagicDataRow> rows,
  bool isLoading = false,
  String emptyMessage = 'Tidak ada data',
  int? sortColumnIndex,
  bool sortAscending = true,
  dynamic onSort,
  int shimmerRowCount = 5
)
```

**Keywords:** table, tabel, data table, grid, daftar data

#### `MagicBottomSheet`

Bottom sheet modal untuk menu aksi, filter, atau konten tambahan

- **Category**: organism
- **Type**: StatelessWidget
- **Tags**: organism, action, modal, scroll, stateless

**File**: `src/organisms/magic_bottom_sheet.dart`

**Constructors:**

```dart
MagicBottomSheet(
  required Widget child,
  bool isDismissible = true,
  String? title,
  bool showHandle = true
)
```

**Keywords:** bottom sheet, modal, sheet, action sheet, drawer bawah

#### `MagicNavBar`

Bottom navigation bar untuk navigasi antar halaman utama

- **Category**: organism
- **Type**: StatelessWidget
- **Tags**: organism, action, stateless

**File**: `src/organisms/magic_nav_bar.dart`

**Constructors:**

```dart
MagicNavBar(
  required dynamic items,
  required dynamic currentIndex,
  required dynamic onTap,
  dynamic showLabelOnlyActive = false
)
```

**Keywords:** nav bar, navigation, bottom bar, tab bar, menu bawah

#### `MagicDrawer`

Side drawer untuk navigasi samping dengan header dan daftar menu

- **Category**: organism
- **Type**: StatelessWidget
- **Tags**: organism, action, list, modal, stateless

**File**: `src/organisms/magic_drawer.dart`

**Constructors:**

```dart
MagicDrawer(
  dynamic header,
  required dynamic items,
  dynamic footer,
  dynamic width = 280
)
```

**Keywords:** drawer, sidebar, menu samping, navigation drawer, side menu

#### `MagicTabBar`

Tab bar untuk navigasi antar section konten dalam satu halaman

- **Category**: organism
- **Type**: StatelessWidget
- **Tags**: organism, scroll, stateless

**File**: `src/organisms/magic_tab_bar.dart`

**Constructors:**

```dart
MagicTabBar(
  required List<MagicTab> tabs,
  required TabController controller,
  bool isScrollable = false
)
```

**Keywords:** tab bar, tabs, tab, section, navigasi konten

#### `MagicForm`

Form wrapper dengan validasi otomatis dan submit button

- **Category**: organism
- **Type**: StatefulWidget
- **Tags**: organism, action, form, stateful

**File**: `src/organisms/magic_form.dart`

**Constructors:**

```dart
MagicForm(
  required List<Widget> children,
  dynamic onSubmit,
  String submitLabel = 'Submit',
  AutovalidateMode autovalidateMode = AutovalidateMode.onUserInteraction,
  bool hideSubmitButton = false,
  GlobalKey<FormState>? formKey
)
```

**Keywords:** form, formulir, input form, submit, validasi

#### `MagicAppBar`

App bar utama dengan title, actions, dan back button yang themed

- **Category**: organism
- **Type**: StatelessWidget
- **Tags**: organism, stateless

**File**: `src/organisms/magic_app_bar.dart`

**Constructors:**

```dart
MagicAppBar(
  String? title,
  Widget? titleWidget,
  List<Widget>? actions,
  Widget? leading,
  bool centerTitle = false,
  Color? backgroundColor,
  double elevation = 0,
  PreferredSizeWidget? bottom,
  bool showBorder = true
)
```

**Keywords:** app bar, header, navigation bar, title bar, toolbar

## USAGE GUIDELINES

1. **Always check this list first** before creating new widgets
2. **Use the exact class names** shown above
3. **Use named constructors** when available (e.g., MagicButton.primary)
4. **Import via `package:magickit/magickit.dart`** for all components
5. **Use MagicTheme.of(context)** to access design tokens (colors, spacing, typography, radius, shadows)
6. **Never hardcode values** — always use theme tokens
7. **Follow the parameter patterns** shown in constructors
