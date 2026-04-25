import 'package:flutter/material.dart';
import '../tokens/magic_theme.dart';

/// Tipe refresh indicator.
enum MagicRefreshType {
  /// Standard Material refresh indicator
  material,

  /// iOS-style refresh indicator (bounce)
  cupertino,

  /// Custom dengan widget builder
  custom,
}

/// State dari refresh indicator.
enum MagicRefreshState {
  /// Idle / tidak dalam proses
  idle,

  /// Pull down - belum cukup untuk trigger refresh
  pullToRefresh,

  /// Pull down cukup - release untuk refresh
  releaseToRefresh,

  /// Sedang refreshing
  refreshing,

  /// Refresh selesai
  completed,
}

/// {@magickit}
/// name: MagicRefreshLayout
/// category: organism
/// use_case: Pull-to-refresh wrapper untuk konten yang perlu di-refresh
/// visual_keywords: refresh, pull to refresh, reload, swipe down, refresh indicator
/// {@end}
class MagicRefreshLayout extends StatefulWidget {
  /// Child widget yang di-wrap.
  final Widget child;

  /// Callback saat refresh dipicu.
  final Future<void> Function() onRefresh;

  /// Tipe refresh indicator.
  final MagicRefreshType type;

  /// Warna refresh indicator.
  final Color? color;

  /// Background color refresh indicator.
  final Color? backgroundColor;

  /// Displacement (jarak dari atas untuk Material style).
  final double displacement;

  /// Stroke width untuk CircularProgressIndicator.
  final double strokeWidth;

  /// Custom builder untuk refresh indicator.
  /// Hanya digunakan jika type = custom.
  final Widget Function(
    BuildContext context,
    MagicRefreshState state,
    double progress,
  )? customBuilder;

  /// Edge offset trigger (berapa pixel dari atas untuk trigger).
  final double triggerOffset;

  /// Enable/disable refresh.
  final bool enabled;

  /// Semantics label untuk aksesbilitas.
  final String semanticsLabel;

  /// Semantics value untuk aksesbilitas.
  final String semanticsValue;

  const MagicRefreshLayout({
    super.key,
    required this.child,
    required this.onRefresh,
    this.type = MagicRefreshType.material,
    this.color,
    this.backgroundColor,
    this.displacement = 40.0,
    this.strokeWidth = 2.0,
    this.customBuilder,
    this.triggerOffset = 100.0,
    this.enabled = true,
    this.semanticsLabel = 'Pull to refresh',
    this.semanticsValue = '',
  });

  /// Refresh layout dengan iOS-style bounce effect.
  const MagicRefreshLayout.ios({
    super.key,
    required this.child,
    required this.onRefresh,
    this.color,
    this.backgroundColor,
    this.triggerOffset = 100.0,
    this.enabled = true,
  })  : type = MagicRefreshType.cupertino,
        displacement = 40.0,
        strokeWidth = 2.0,
        customBuilder = null,
        semanticsLabel = 'Pull to refresh',
        semanticsValue = '';

  /// Refresh layout dengan custom indicator builder.
  const MagicRefreshLayout.custom({
    super.key,
    required this.child,
    required this.onRefresh,
    required this.customBuilder,
    this.triggerOffset = 100.0,
    this.enabled = true,
  })  : type = MagicRefreshType.custom,
        color = null,
        backgroundColor = null,
        displacement = 40.0,
        strokeWidth = 2.0,
        semanticsLabel = 'Pull to refresh',
        semanticsValue = '';

  @override
  State<MagicRefreshLayout> createState() => _MagicRefreshLayoutState();
}

class _MagicRefreshLayoutState extends State<MagicRefreshLayout>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  MagicRefreshState _refreshState = MagicRefreshState.idle;
  double _dragOffset = 0.0;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    if (_isRefreshing || !widget.enabled) return;

    setState(() {
      _isRefreshing = true;
      _refreshState = MagicRefreshState.refreshing;
    });

    try {
      await widget.onRefresh();
      setState(() {
        _refreshState = MagicRefreshState.completed;
      });
    } catch (e) {
      setState(() {
        _refreshState = MagicRefreshState.idle;
      });
      rethrow;
    } finally {
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) {
        setState(() {
          _isRefreshing = false;
          _refreshState = MagicRefreshState.idle;
          _dragOffset = 0;
        });
        _animationController.reset();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = MagicTheme.of(context);
    final resolvedColor = widget.color ?? theme.colors.primary;

    switch (widget.type) {
      case MagicRefreshType.material:
        return RefreshIndicator(
          onRefresh: _handleRefresh,
          color: resolvedColor,
          backgroundColor: widget.backgroundColor,
          displacement: widget.displacement,
          strokeWidth: widget.strokeWidth,
          semanticsLabel: widget.semanticsLabel,
          semanticsValue: widget.semanticsValue,
          child: widget.child,
        );

      case MagicRefreshType.cupertino:
        return _buildCupertinoRefresh(theme, resolvedColor);

      case MagicRefreshType.custom:
        return _buildCustomRefresh(theme, resolvedColor);
    }
  }

  Widget _buildCupertinoRefresh(MagicTheme theme, Color resolvedColor) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (!widget.enabled) return false;

        if (notification is ScrollStartNotification) {
          _dragOffset = 0;
        } else if (notification is ScrollUpdateNotification) {
          if (notification.metrics.extentBefore == 0 &&
              notification.scrollDelta! < 0) {
            setState(() {
              _dragOffset += (-notification.scrollDelta!);
              final progress =
                  (_dragOffset / widget.triggerOffset).clamp(0.0, 1.0);
              if (progress >= 1.0 && !_isRefreshing) {
                _refreshState = MagicRefreshState.releaseToRefresh;
              } else {
                _refreshState = MagicRefreshState.pullToRefresh;
              }
            });
          }
        } else if (notification is ScrollEndNotification) {
          if (_refreshState == MagicRefreshState.releaseToRefresh &&
              !_isRefreshing) {
            _handleRefresh();
          } else if (!_isRefreshing) {
            setState(() {
              _refreshState = MagicRefreshState.idle;
              _dragOffset = 0;
            });
          }
        }
        return false;
      },
      child: Stack(
        children: [
          widget.child,
          if (_dragOffset > 0 || _isRefreshing)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildCupertinoIndicator(theme, resolvedColor),
            ),
        ],
      ),
    );
  }

  Widget _buildCupertinoIndicator(MagicTheme theme, Color resolvedColor) {
    final progress = (_dragOffset / widget.triggerOffset).clamp(0.0, 1.0);
    final height = _isRefreshing ? 60.0 : (_dragOffset.clamp(0.0, 80.0));

    return SizedBox(
      height: height,
      child: Center(
        child: _isRefreshing
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: resolvedColor,
                ),
              )
            : Transform.rotate(
                angle: progress * 3.14159 * 2,
                child: Opacity(
                  opacity: progress,
                  child: Icon(
                    Icons.refresh_rounded,
                    color: resolvedColor,
                    size: 24,
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildCustomRefresh(MagicTheme theme, Color resolvedColor) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (!widget.enabled) return false;

        if (notification is ScrollStartNotification) {
          _dragOffset = 0;
        } else if (notification is ScrollUpdateNotification) {
          if (notification.metrics.extentBefore == 0 &&
              notification.scrollDelta! < 0) {
            setState(() {
              _dragOffset += (-notification.scrollDelta!);
              final progress =
                  (_dragOffset / widget.triggerOffset).clamp(0.0, 1.0);
              if (progress >= 1.0 && !_isRefreshing) {
                _refreshState = MagicRefreshState.releaseToRefresh;
              } else {
                _refreshState = MagicRefreshState.pullToRefresh;
              }
            });
          }
        } else if (notification is ScrollEndNotification) {
          if (_refreshState == MagicRefreshState.releaseToRefresh &&
              !_isRefreshing) {
            _handleRefresh();
          } else if (!_isRefreshing) {
            setState(() {
              _refreshState = MagicRefreshState.idle;
              _dragOffset = 0;
            });
          }
        }
        return false;
      },
      child: Stack(
        children: [
          widget.child,
          if (widget.customBuilder != null &&
              (_dragOffset > 0 || _isRefreshing))
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SizedBox(
                height: _isRefreshing ? 60.0 : _dragOffset.clamp(0.0, 80.0),
                child: widget.customBuilder!(
                  context,
                  _refreshState,
                  (_dragOffset / widget.triggerOffset).clamp(0.0, 1.0),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
