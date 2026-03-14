import 'package:flutter/material.dart';
import 'package:magickit/magickit.dart';

class MagicKitNavBarExample extends StatefulWidget {
  const MagicKitNavBarExample({super.key});

  @override
  State<MagicKitNavBarExample> createState() => _MagicKitNavBarExampleState();
}

class _MagicKitNavBarExampleState extends State<MagicKitNavBarExample> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return MagicNavBar(
      items: const [
        MagicNavBarItem(label: 'Home', icon: Icons.home_outlined),
        MagicNavBarItem(label: 'Explore', icon: Icons.explore_outlined),
        MagicNavBarItem(label: 'Profile', icon: Icons.person_outline),
      ],
      currentIndex: _index,
      onTap: (index) => setState(() => _index = index),
    );
  }
}
