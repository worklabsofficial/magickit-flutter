import 'package:flutter/material.dart';
import '../molecules/magic_empty_state.dart';
import '../tokens/magic_theme.dart';

/// {@magickit}
/// name: MagicListView
/// category: organism
/// use_case: List dengan infinite scroll, pull-to-refresh, loading & empty state
/// visual_keywords: list, infinite scroll, pagination, lazy load, pull refresh, daftar
/// {@end}
class MagicListView<T> extends StatelessWidget {
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

  /// Separator widget antar item.
  final Widget Function(BuildContext context, int index)? separatorBuilder;

  /// Controller opsional.
  final ScrollController? controller;

  /// Padding list.
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

  /// Reverse scroll.
  final bool reverse;

  /// Shrinkwrap.
  final bool shrinkWrap;

  /// Threshold untuk trigger load more (dalam pixel dari bawah).
  final double loadMoreThreshold;

  /// Loading indicator widget untuk load more.
  final Widget? loadMoreIndicator;

  /// Axis untuk scroll direction.
  final Axis scrollDirection;

  const MagicListView({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.onLoadMore,
    this.isLoadingMore = false,
    this.onRefresh,
    this.hasMore = true,
    this.separatorBuilder,
    this.controller,
    this.padding,
    this.loadingBuilder,
    this.isLoading = false,
    this.emptyWidget,
    this.emptyTitle = 'Belum ada data',
    this.physics,
    this.reverse = false,
    this.shrinkWrap = false,
    this.loadMoreThreshold = 200,
    this.loadMoreIndicator,
    this.scrollDirection = Axis.vertical,
  });

  @override
  Widget build(BuildContext context) {
    final theme = MagicTheme.of(context);

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
            child: MagicEmptyState.noData(
              customTitle: emptyTitle,
            ),
          ),
        ),
      );
    }

    // Build list
    Widget listWidget;

    if (separatorBuilder != null) {
      listWidget = ListView.separated(
        controller: controller,
        padding: padding,
        physics: physics,
        reverse: reverse,
        shrinkWrap: shrinkWrap,
        scrollDirection: scrollDirection,
        itemCount: items.length + (hasMore || isLoadingMore ? 1 : 0),
        separatorBuilder: (context, index) => separatorBuilder!(context, index),
        itemBuilder: (context, index) {
          if (index >= items.length) {
            return _buildLoadMoreIndicator(theme);
          }
          return itemBuilder(context, items[index], index);
        },
      );
    } else {
      listWidget = ListView.builder(
        controller: controller,
        padding: padding,
        physics: physics,
        reverse: reverse,
        shrinkWrap: shrinkWrap,
        scrollDirection: scrollDirection,
        itemCount: items.length + (hasMore || isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= items.length) {
            return _buildLoadMoreIndicator(theme);
          }
          return itemBuilder(context, items[index], index);
        },
      );
    }

    // Add scroll listener for load more
    if (onLoadMore != null) {
      listWidget = NotificationListener<ScrollNotification>(
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
        child: listWidget,
      );
    }

    // Wrap with refresh
    if (onRefresh != null) {
      return RefreshIndicator(
        onRefresh: onRefresh!,
        color: theme.colors.primary,
        child: listWidget,
      );
    }

    return listWidget;
  }

  Widget _buildLoadMoreIndicator(MagicTheme theme) {
    if (loadMoreIndicator != null) return loadMoreIndicator!;

    if (!isLoadingMore && !hasMore) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.all(theme.spacing.md),
      child: Center(
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
