import 'package:flutter/material.dart';
import 'package:magickit/magickit.dart';

class MagicKitGridViewExample extends StatefulWidget {
  const MagicKitGridViewExample({super.key});

  @override
  State<MagicKitGridViewExample> createState() =>
      _MagicKitGridViewExampleState();
}

class _MagicKitGridViewExampleState extends State<MagicKitGridViewExample> {
  late List<_GridItem> _items;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _items = List.generate(
      12,
      (index) => _GridItem(
        title: 'Item ${index + 1}',
        color: Colors.primaries[index % Colors.primaries.length].shade400,
        icon: Icons.widgets_rounded,
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
        const MagicText('Responsive Grid', style: MagicTextStyle.label),
        SizedBox(height: theme.spacing.sm),
        SizedBox(
          height: 300,
          child: MagicGridView<_GridItem>(
            items: _items,
            gridType: MagicGridType.responsive,
            columns: 2,
            childAspectRatio: 1.2,
            isLoading: _isLoading,
            itemBuilder: (context, item, index) {
              return Card(
                color: item.color.withValues(alpha: 0.15),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(item.icon, color: item.color, size: 32),
                      const SizedBox(height: 8),
                      Text(
                        item.title,
                        style: TextStyle(
                          color: item.color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(height: theme.spacing.md),
        const MagicText('Fixed Grid (3 columns)', style: MagicTextStyle.label),
        SizedBox(height: theme.spacing.sm),
        SizedBox(
          height: 200,
          child: MagicGridView<_GridItem>(
            items: _items.sublist(0, 6),
            gridType: MagicGridType.fixed,
            columns: 3,
            childAspectRatio: 1.0,
            itemBuilder: (context, item, index) {
              return Container(
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    item.title,
                    style: TextStyle(
                      color: item.color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
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
          child: MagicGridView<_GridItem>(
            items: const [],
            gridType: MagicGridType.fixed,
            itemBuilder: (context, item, index) => const SizedBox(),
          ),
        ),
      ],
    );
  }
}

class _GridItem {
  final String title;
  final Color color;
  final IconData icon;

  const _GridItem({
    required this.title,
    required this.color,
    required this.icon,
  });
}
