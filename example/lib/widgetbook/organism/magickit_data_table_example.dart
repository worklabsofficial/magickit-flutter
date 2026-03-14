import 'package:flutter/material.dart';
import 'package:magickit/magickit.dart';

class MagicKitDataTableExample extends StatefulWidget {
  const MagicKitDataTableExample({super.key});

  @override
  State<MagicKitDataTableExample> createState() => _MagicKitDataTableExampleState();
}

class _MagicKitDataTableExampleState extends State<MagicKitDataTableExample> {
  bool _isLoading = false;
  int? _sortColumnIndex;
  bool _sortAscending = true;
  late List<MagicKitUserRow> _rows;

  @override
  void initState() {
    super.initState();
    _rows = [
      const MagicKitUserRow(name: 'Alya', role: 'Designer', status: 'Active'),
      const MagicKitUserRow(name: 'Bima', role: 'Engineer', status: 'Active'),
      const MagicKitUserRow(name: 'Citra', role: 'Product', status: 'Pending'),
      const MagicKitUserRow(name: 'Dio', role: 'QA', status: 'Inactive'),
    ];
  }

  void _sortTable(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;

      int compareStrings(String a, String b) =>
          a.toLowerCase().compareTo(b.toLowerCase());

      _rows.sort((a, b) {
        int result;
        switch (columnIndex) {
          case 0:
            result = compareStrings(a.name, b.name);
            break;
          case 1:
            result = compareStrings(a.role, b.role);
            break;
          case 2:
          default:
            result = compareStrings(a.status, b.status);
            break;
        }
        return ascending ? result : -result;
      });
    });
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
        MagicDataTable(
          columns: const [
            MagicDataColumn(label: 'Name', sortable: true, width: 140),
            MagicDataColumn(label: 'Role', sortable: true),
            MagicDataColumn(label: 'Status', sortable: true, width: 120),
          ],
          rows: _rows
              .map(
                (row) => MagicDataRow(
                  selected: row.status == 'Active',
                  onTap: () {},
                  cells: [
                    Text(row.name),
                    Text(row.role),
                    MagicBadge(
                      label: row.status,
                      variant: row.status == 'Active'
                          ? MagicBadgeVariant.solid
                          : MagicBadgeVariant.soft,
                      color: row.status == 'Active'
                          ? const Color(0xFF1B7A3E)
                          : theme.colors.secondary,
                    ),
                  ],
                ),
              )
              .toList(),
          isLoading: _isLoading,
          sortColumnIndex: _sortColumnIndex,
          sortAscending: _sortAscending,
          onSort: _sortTable,
        ),
      ],
    );
  }
}

class MagicKitUserRow {
  final String name;
  final String role;
  final String status;

  const MagicKitUserRow({
    required this.name,
    required this.role,
    required this.status,
  });
}
