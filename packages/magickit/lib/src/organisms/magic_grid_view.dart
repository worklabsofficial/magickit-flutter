import 'package:flutter/material.dart';
import '../molecules/magic_empty_state.dart';
import '../tokens/magic_breakpoints.dart';
import '../tokens/magic_theme.dart';

/// Tipe grid layout.
enum MagicGridType {
  /// Grid dengan jumlah kolom tetap
  fixed,

  /// Responsive grid (kolom menyesuaikan lebar layar)
  responsive,

  /// Masonry/waterfall layout (tinggi item berbeda - SliverChildBuilder)
  masonry,
}

/// {@magickit}
/// name: MagicGridView
/// category: organism
/// use_case: Grid layout dengan infinite scroll, responsive columns, pull-to-refresh
/// visual_keywords: grid, gallery, masonry, waterfall, responsive, kolom
/// {@end}
class MagicGridView<T> extends StatelessWidget {
  /// Daftar item yang ditampilkan.
  final List<T> items;

  /// Builder untuk setiap item.
  final Widget Function(BuildContext context, T item, int index) itemBuilder;

  /// Callback saat scroll mencapai akhir (untuk load more).
  final VoidCallback? onLoadMore;

  /// Apakah sedang loading data tambahan.
  final bool isLoadingMore;

  /// Callback untuk pull-to-refresh.
  final Future<void> Function()? onRefresh;

  /// Apakah masih ada data yang bisa di-load.
  final bool hasMore;

  /// Tipe grid layout.
  final MagicGridType gridType;

  /// Jumlah kolom (untuk fixed grid).
  final int columns;

  /// Responsive columns berdasarkan breakpoint.
  final int? mobileColumns;
  final int? tabletColumns;
  final int? desktopColumns;

  /// Spacing antar item (main axis).
  final double mainAxisSpacing;

  /// Spacing antar kolom (cross axis).
  final double crossAxisSpacing;

  /// Aspect ratio untuk setiap item (untuk fixed/responsive grid).
  final double childAspectRatio;

  /// Controller opsional.
  final ScrollController? controller;

  /// Padding grid.
  final EdgeInsetsGeometry? padding;

  /// Shimmer/builder untuk loading state.
  final Widget Function(BuildContext context)? loadingBuilder;

  /// Apakah sedang loading initial data.
  final bool isLoading;

  /// Empty state widget.
  final Widget? emptyWidget;

  /// Pesan empty state default.
  final String emptyTitle;

  /// Physics scroll.
  final ScrollPhysics? physics;

  /// Shrinkwrap.
  final bool shrinkWrap;

  /// Threshold untuk trigger load more (dalam pixel dari bawah).
  final double loadMoreThreshold;

  /// Builder untuk custom height per item (untuk masonry layout).
  /// Return height untuk item di index tertentu.
  final double Function(BuildContext context, T item, int index)?
      itemExtentBuilder;

  const MagicGridView({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.onLoadMore,
    this.isLoadingMore = false,
    this.onRefresh,
    this.hasMore = true,
    this.gridType = MagicGridType.responsive,
    this.columns = 2,
    this.mobileColumns,
    this.tabletColumns,
    this.desktopColumns,
    this.mainAxisSpacing = 8,
    this.crossAxisSpacing = 8,
    this.childAspectRatio = 1.0,
    this.controller,
    this.padding,
    this.loadingBuilder,
    this.isLoading = false,
    this.emptyWidget,
    this.emptyTitle = 'Belum ada data',
    this.physics,
    this.shrinkWrap = false,
    this.loadMoreThreshold = 200,
    this.itemExtentBuilder,
  });

  /// Masonry grid dengan tinggi item berbeda-beda.
  ///
  /// [itemExtentBuilder] menentukan tinggi setiap item.
  const MagicGridView.masonry({
    super.key,
    required this.items,
    required this.itemBuilder,
    required double Function(BuildContext context, T item, int index)
        itemExtentBuilder,
    this.onLoadMore,
    this.isLoadingMore = false,
    this.onRefresh,
    this.hasMore = true,
    this.columns = 2,
    this.mobileColumns,
    this.tabletColumns,
    this.desktopColumns,
    this.mainAxisSpacing = 8,
    this.crossAxisSpacing = 8,
    this.controller,
    this.padding,
    this.loadingBuilder,
    this.isLoading = false,
    this.emptyWidget,
    this.emptyTitle = 'Belum ada data',
    this.physics,
    this.shrinkWrap = false,
    this.loadMoreThreshold = 200,
  })  : gridType = MagicGridType.masonry,
        childAspectRatio = 1.0,
        itemExtentBuilder = itemExtentBuilder;

  int _resolveColumns(BuildContext context) {
    return MagicBreakpoints.responsive<int>(
      context,
      mobile: mobileColumns ?? columns,
      tablet: tabletColumns ?? columns + 1,
      desktop: desktopColumns ?? columns + 2,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = MagicTheme.of(context);
    final resolvedColumns = _resolveColumns(context);

    // Loading state
    if (isLoading && loadingBuilder != null) {
      return loadingBuilder!(context);
    }

    // Empty state
    if (!isLoading && items.isEmpty) {
      if (emptyWidget != null) {
        return emptyWidget!;
      }
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.6,
          child: Center(
            child: MagicEmptyState.noData(customTitle: emptyTitle),
          ),
        ),
      );
    }

    // Build grid based on type
    Widget gridWidget;

    if (gridType == MagicGridType.masonry) {
      gridWidget = _buildMasonryGrid(context, resolvedColumns);
    } else {
      gridWidget = _buildFixedGrid(context, resolvedColumns);
    }

    // Add scroll listener for load more
    if (onLoadMore != null) {
      gridWidget = NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollUpdateNotification) {
            final maxScroll = notification.metrics.maxScrollExtent;
            final currentScroll = notification.metrics.pixels;
            if (maxScroll - currentScroll <= loadMoreThreshold &&
                !isLoadingMore &&
                hasMore) {
              onLoadMore!();
            }
          }
          return false;
        },
        child: gridWidget,
      );
    }

    // Wrap with refresh
    if (onRefresh != null) {
      return RefreshIndicator(
        onRefresh: onRefresh!,
        color: theme.colors.primary,
        child: gridWidget,
      );
    }

    return gridWidget;
  }

  Widget _buildFixedGrid(BuildContext context, int resolvedColumns) {
    return GridView.builder(
      controller: controller,
      padding: padding,
      physics: physics,
      shrinkWrap: shrinkWrap,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: resolvedColumns,
        mainAxisSpacing: mainAxisSpacing,
        crossAxisSpacing: crossAxisSpacing,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: items.length + (hasMore || isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= items.length) {
          return _buildLoadMoreIndicator(context);
        }
        return itemBuilder(context, items[index], index);
      },
    );
  }

  Widget _buildMasonryGrid(BuildContext context, int resolvedColumns) {
    // Split items into columns and build
    final columnWidgets = List.generate(resolvedColumns, (_) => <Widget>[]);
    final columnHeights = List.filled(resolvedColumns, 0.0);

    for (var i = 0; i < items.length; i++) {
      // Find shortest column
      var minIndex = 0;
      for (var j = 1; j < resolvedColumns; j++) {
        if (columnHeights[j] < columnHeights[minIndex]) {
          minIndex = j;
        }
      }

      final itemHeight = itemExtentBuilder?.call(context, items[i], i) ?? 200.0;

      columnWidgets[minIndex].add(
        Padding(
          padding: EdgeInsets.only(bottom: mainAxisSpacing),
          child: itemBuilder(context, items[i], i),
        ),
      );
      columnHeights[minIndex] += itemHeight + mainAxisSpacing;
    }

    // Add load more indicator
    if (hasMore || isLoadingMore) {
      final minIndex = columnHeights.indexOf(
        columnHeights.reduce((a, b) => a < b ? a : b),
      );
      columnWidgets[minIndex].add(_buildLoadMoreIndicator(context));
    }

    return SingleChildScrollView(
      controller: controller,
      physics: physics,
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(resolvedColumns, (colIndex) {
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                left: colIndex > 0 ? crossAxisSpacing / 2 : 0,
                right:
                    colIndex < resolvedColumns - 1 ? crossAxisSpacing / 2 : 0,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: columnWidgets[colIndex],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildLoadMoreIndicator(BuildContext context) {
    final theme = MagicTheme.of(context);

    if (!isLoadingMore && !hasMore) {
      return const SizedBox.shrink();
    }

    return Center(
      child: Padding(
        padding: EdgeInsets.all(theme.spacing.md),
        child: isLoadingMore
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: theme.colors.primary,
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}
