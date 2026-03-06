import 'package:flutter/material.dart';
import '../atoms/magic_shimmer.dart';
import '../atoms/magic_text.dart';
import '../tokens/magic_theme.dart';

class MagicDataColumn {
  final String label;
  final bool sortable;
  final double? width;
  final TextAlign alignment;

  const MagicDataColumn({
    required this.label,
    this.sortable = false,
    this.width,
    this.alignment = TextAlign.start,
  });
}

class MagicDataRow {
  final List<Widget> cells;
  final VoidCallback? onTap;
  final bool selected;

  const MagicDataRow({
    required this.cells,
    this.onTap,
    this.selected = false,
  });
}

/// {@magickit}
/// name: MagicDataTable
/// category: organism
/// use_case: Tabel data dengan header sortable, row selection, dan empty/loading state
/// visual_keywords: table, tabel, data table, grid, daftar data
/// {@end}
class MagicDataTable extends StatelessWidget {
  final List<MagicDataColumn> columns;
  final List<MagicDataRow> rows;
  final bool isLoading;
  final String emptyMessage;
  final int? sortColumnIndex;
  final bool sortAscending;
  final void Function(int columnIndex, bool ascending)? onSort;

  /// Jumlah shimmer rows saat [isLoading] = true.
  final int shimmerRowCount;

  const MagicDataTable({
    super.key,
    required this.columns,
    required this.rows,
    this.isLoading = false,
    this.emptyMessage = 'Tidak ada data',
    this.sortColumnIndex,
    this.sortAscending = true,
    this.onSort,
    this.shimmerRowCount = 5,
  });

  @override
  Widget build(BuildContext context) {
    final theme = MagicTheme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colors.surface,
        borderRadius: BorderRadius.circular(theme.radius.md),
        border: Border.all(color: theme.colors.outline),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(theme.radius.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(theme),
            _buildBody(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(MagicTheme theme) {
    return Container(
      color: theme.colors.background,
      child: Row(
        children: columns.asMap().entries.map((entry) {
          final i = entry.key;
          final col = entry.value;
          final isSorted = sortColumnIndex == i;

          Widget label = Text(
            col.label,
            textAlign: col.alignment,
            style: theme.typography.label.copyWith(
              color: theme.colors.onBackground.withValues(alpha: 0.7),
              fontWeight: FontWeight.w600,
            ),
          );

          if (col.sortable) {
            label = GestureDetector(
              onTap: () => onSort?.call(
                i,
                isSorted ? !sortAscending : true,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  label,
                  SizedBox(width: theme.spacing.xs),
                  Icon(
                    isSorted
                        ? (sortAscending
                            ? Icons.arrow_upward
                            : Icons.arrow_downward)
                        : Icons.unfold_more,
                    size: 14,
                    color: isSorted
                        ? theme.colors.primary
                        : theme.colors.onBackground.withValues(alpha: 0.4),
                  ),
                ],
              ),
            );
          }

          return _cell(
            label,
            col.width,
            padding: EdgeInsets.symmetric(
              horizontal: theme.spacing.md,
              vertical: theme.spacing.sm + 2,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBody(MagicTheme theme) {
    if (isLoading) {
      return Column(
        children: List.generate(
          shimmerRowCount,
          (i) => _buildShimmerRow(theme, i),
        ),
      );
    }

    if (rows.isEmpty) {
      return Padding(
        padding: EdgeInsets.all(theme.spacing.xxl),
        child: Center(
          child: MagicText(
            emptyMessage,
            style: MagicTextStyle.bodyMedium,
            color: theme.colors.onSurface.withValues(alpha: 0.4),
          ),
        ),
      );
    }

    return Column(
      children: rows.asMap().entries.map((entry) {
        final i = entry.key;
        return _buildRow(theme, entry.value, i);
      }).toList(),
    );
  }

  Widget _buildRow(MagicTheme theme, MagicDataRow row, int index) {
    final isEven = index.isEven;
    Widget content = Row(
      children: row.cells.asMap().entries.map((e) {
        final col = e.key < columns.length ? columns[e.key] : null;
        return _cell(
          DefaultTextStyle(
            style: theme.typography.bodySmall.copyWith(
              color: theme.colors.onSurface,
            ),
            child: e.value,
          ),
          col?.width,
          padding: EdgeInsets.symmetric(
            horizontal: theme.spacing.md,
            vertical: theme.spacing.sm + 2,
          ),
        );
      }).toList(),
    );

    Color rowColor = row.selected
        ? theme.colors.primary.withValues(alpha: 0.08)
        : isEven
            ? theme.colors.surface
            : theme.colors.background.withValues(alpha: 0.5);

    if (row.onTap != null) {
      return InkWell(
        onTap: row.onTap,
        child: Container(
          color: rowColor,
          child: Column(
            children: [
              content,
              Divider(height: 1, color: theme.colors.outline),
            ],
          ),
        ),
      );
    }

    return Container(
      color: rowColor,
      child: Column(
        children: [
          content,
          Divider(height: 1, color: theme.colors.outline),
        ],
      ),
    );
  }

  Widget _buildShimmerRow(MagicTheme theme, int index) {
    return Container(
      color: index.isEven ? theme.colors.surface : Colors.transparent,
      child: Column(
        children: [
          Row(
            children: columns.map((col) {
              return _cell(
                MagicShimmer(height: 16, width: col.width != null ? col.width! * 0.6 : 80),
                col.width,
                padding: EdgeInsets.symmetric(
                  horizontal: theme.spacing.md,
                  vertical: theme.spacing.sm + 6,
                ),
              );
            }).toList(),
          ),
          Divider(height: 1, color: theme.colors.outline),
        ],
      ),
    );
  }

  Widget _cell(Widget child, double? width, {EdgeInsets? padding}) {
    Widget content = Padding(
      padding: padding ?? const EdgeInsets.all(12),
      child: child,
    );

    if (width != null) {
      return SizedBox(width: width, child: content);
    }

    return Expanded(child: content);
  }
}
