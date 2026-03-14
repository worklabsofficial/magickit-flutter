import 'package:flutter/material.dart';
import 'package:magickit/magickit.dart';

class MagicKitDropdownExample extends StatefulWidget {
  const MagicKitDropdownExample({super.key});

  @override
  State<MagicKitDropdownExample> createState() => _MagicKitDropdownExampleState();
}

class _MagicKitDropdownExampleState extends State<MagicKitDropdownExample> {
  String? _value = 'ui';

  @override
  Widget build(BuildContext context) {
    return MagicDropdown<String>(
      value: _value,
      hint: 'Choose team',
      items: const [
        MagicDropdownItem(value: 'ui', label: 'UI/UX', icon: Icons.palette_outlined),
        MagicDropdownItem(value: 'fe', label: 'Frontend', icon: Icons.web_outlined),
        MagicDropdownItem(value: 'be', label: 'Backend', icon: Icons.storage_outlined),
      ],
      onChanged: (value) => setState(() => _value = value),
    );
  }
}
