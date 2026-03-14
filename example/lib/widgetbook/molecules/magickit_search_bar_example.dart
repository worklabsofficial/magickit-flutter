import 'package:flutter/material.dart';
import 'package:magickit/magickit.dart';

class MagicKitSearchBarExample extends StatefulWidget {
  const MagicKitSearchBarExample({super.key});

  @override
  State<MagicKitSearchBarExample> createState() => _MagicKitSearchBarExampleState();
}

class _MagicKitSearchBarExampleState extends State<MagicKitSearchBarExample> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MagicSearchBar(
      controller: _controller,
      hint: 'Search components',
      onSearch: (_) {},
    );
  }
}
