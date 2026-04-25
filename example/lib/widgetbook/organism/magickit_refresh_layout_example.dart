import 'package:flutter/material.dart';
import 'package:magickit/magickit.dart';

class MagicKitRefreshLayoutExample extends StatefulWidget {
  const MagicKitRefreshLayoutExample({super.key});

  @override
  State<MagicKitRefreshLayoutExample> createState() =>
      _MagicKitRefreshLayoutExampleState();
}

class _MagicKitRefreshLayoutExampleState
    extends State<MagicKitRefreshLayoutExample> {
  int _refreshCount = 0;
  DateTime? _lastRefresh;

  Future<void> _handleRefresh() async {
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _refreshCount++;
      _lastRefresh = DateTime.now();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = MagicTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const MagicText('Material (Default)', style: MagicTextStyle.label),
        SizedBox(height: theme.spacing.sm),
        SizedBox(
          height: 200,
          child: MagicRefreshLayout(
            onRefresh: _handleRefresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                _buildInfoCard(theme, 'Refresh count: $_refreshCount'),
              ],
            ),
          ),
        ),
        SizedBox(height: theme.spacing.md),
        const MagicText('iOS Style', style: MagicTextStyle.label),
        SizedBox(height: theme.spacing.sm),
        SizedBox(
          height: 200,
          child: MagicRefreshLayout.ios(
            onRefresh: _handleRefresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                _buildInfoCard(
                  theme,
                  _lastRefresh != null
                      ? 'Last refresh: ${_lastRefresh!.hour}:${_lastRefresh!.minute.toString().padLeft(2, '0')}'
                      : 'Pull down to refresh',
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: theme.spacing.md),
        const MagicText('Custom Indicator', style: MagicTextStyle.label),
        SizedBox(height: theme.spacing.sm),
        SizedBox(
          height: 200,
          child: MagicRefreshLayout.custom(
            onRefresh: _handleRefresh,
            customBuilder: (context, state, progress) {
              return Center(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Transform.rotate(
                    angle: progress * 3.14159 * 4,
                    child: Icon(
                      Icons.refresh_rounded,
                      color: theme.colors.primary,
                    ),
                  ),
                ),
              );
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                _buildInfoCard(theme, 'Custom refresh indicator'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(MagicTheme theme, String text) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colors.outline),
      ),
      child: Center(
        child: MagicText(text, style: MagicTextStyle.bodyMedium),
      ),
    );
  }
}
