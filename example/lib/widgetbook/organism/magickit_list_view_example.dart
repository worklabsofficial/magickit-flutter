import 'package:flutter/material.dart';
import 'package:magickit/magickit.dart';

class MagicKitListViewExample extends StatefulWidget {
  const MagicKitListViewExample({super.key});

  @override
  State<MagicKitListViewExample> createState() =>
      _MagicKitListViewExampleState();
}

class _MagicKitListViewExampleState extends State<MagicKitListViewExample> {
  late List<_ListItem> _items;
  bool _isLoading = false;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _items = List.generate(
      8,
      (index) => _ListItem(
        title: 'Contact ${index + 1}',
        subtitle: 'contact${index + 1}@example.com',
        icon: Icons.person_rounded,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = MagicTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MagicSwitch(
          value: _isLoading,
          onChanged: (value) => setState(() => _isLoading = value),
          label: 'Loading state',
        ),
        SizedBox(height: theme.spacing.md),
        const MagicText('Basic List', style: MagicTextStyle.label),
        SizedBox(height: theme.spacing.sm),
        SizedBox(
          height: 250,
          child: MagicListView<_ListItem>(
            items: _items,
            isLoading: _isLoading,
            itemBuilder: (context, item, index) {
              return MagicListTile(
                leading: MagicAvatar(
                  fallbackInitial: item.title.substring(0, 2),
                  size: MagicAvatarSize.md,
                ),
                title: item.title,
                subtitle: item.subtitle,
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {},
              );
            },
          ),
        ),
        SizedBox(height: theme.spacing.md),
        const MagicText('With Separator', style: MagicTextStyle.label),
        SizedBox(height: theme.spacing.sm),
        SizedBox(
          height: 250,
          child: MagicListView<_ListItem>(
            items: _items,
            separatorBuilder: (context, index) =>
                Divider(height: 1, color: theme.colors.outline),
            itemBuilder: (context, item, index) {
              return MagicListTile(
                leading: CircleAvatar(
                  backgroundColor: theme.colors.primary.withValues(alpha: 0.1),
                  child: Icon(item.icon, color: theme.colors.primary, size: 20),
                ),
                title: item.title,
                subtitle: item.subtitle,
              );
            },
          ),
        ),
        SizedBox(height: theme.spacing.md),
        const MagicText('With Load More', style: MagicTextStyle.label),
        SizedBox(height: theme.spacing.sm),
        SizedBox(
          height: 250,
          child: MagicListView<_ListItem>(
            items: _items,
            isLoadingMore: _isLoadingMore,
            hasMore: true,
            onLoadMore: () {
              setState(() => _isLoadingMore = true);
              Future.delayed(const Duration(seconds: 2), () {
                if (mounted) setState(() => _isLoadingMore = false);
              });
            },
            itemBuilder: (context, item, index) {
              return MagicListTile(
                leading: Icon(item.icon, color: theme.colors.primary),
                title: item.title,
                subtitle: item.subtitle,
                trailing: MagicBadge(
                  label: '#${index + 1}',
                  variant: MagicBadgeVariant.soft,
                ),
              );
            },
          ),
        ),
        SizedBox(height: theme.spacing.md),
        const MagicText('Empty State', style: MagicTextStyle.label),
        SizedBox(height: theme.spacing.sm),
        SizedBox(
          height: 200,
          child: MagicListView<_ListItem>(
            items: const [],
            itemBuilder: (context, item, index) => const SizedBox(),
          ),
        ),
      ],
    );
  }
}

class _ListItem {
  final String title;
  final String subtitle;
  final IconData icon;

  const _ListItem({
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}
