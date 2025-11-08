import 'dart:async';
import 'package:flutter/material.dart';

class SearchFilterBar extends StatefulWidget {
  final String query;
  final ValueChanged<String> onQuery;

  final List<String> groups;
  final String? selectedGroup;
  final ValueChanged<String?> onSelectGroup;

  final List<String> hosts;
  final String? selectedHost;
  final ValueChanged<String?> onSelectHost;

  final List<String> sortKeys;
  final String selectedSortKey;
  final ValueChanged<String?> onSelectSortKey;
  final bool sortAsc;
  final VoidCallback onToggleAsc;

  const SearchFilterBar({
    super.key,
    required this.query,
    required this.onQuery,
    required this.groups,
    required this.selectedGroup,
    required this.onSelectGroup,
    required this.hosts,
    required this.selectedHost,
    required this.onSelectHost,
    required this.sortKeys,
    required this.selectedSortKey,
    required this.onSelectSortKey,
    required this.sortAsc,
    required this.onToggleAsc,
  });

  @override
  State<SearchFilterBar> createState() => _SearchFilterBarState();
}

class _SearchFilterBarState extends State<SearchFilterBar> {
  late final TextEditingController _ctrl;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.query);
    _ctrl.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(covariant SearchFilterBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.query != _ctrl.text) {
      _ctrl.text = widget.query;
      _ctrl.selection = TextSelection.collapsed(offset: _ctrl.text.length);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.removeListener(_onControllerChanged);
    _ctrl.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 220), () {
      widget.onQuery(_ctrl.text.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final queryField = Flexible(
      flex: 2,
      child: SizedBox(
        height: 40,
        child: TextField(
          controller: _ctrl,
          textInputAction: TextInputAction.search,
          onSubmitted: (v) => widget.onQuery(v.trim()),
          autocorrect: false,
          enableSuggestions: false,
          smartDashesType: SmartDashesType.disabled,
          smartQuotesType: SmartQuotesType.disabled,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search),
            hintText: 'Search movies',
            border: const OutlineInputBorder(),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 8,
            ),
            suffixIcon: IconButton(
              tooltip: 'Clear',
              onPressed: () {
                if (_ctrl.text.isEmpty) return;
                _ctrl.clear();
                widget.onQuery('');
              },
              icon: const Icon(Icons.clear),
            ),
          ),
        ),
      ),
    );

    final groupField = Flexible(
      child: _DropdownTight(
        value: _normalizeChoice(widget.groups, widget.selectedGroup),
        items: widget.groups,
        labelWhenEmpty: 'All groups',
        hint: 'Group',
        onChanged: widget.onSelectGroup,
      ),
    );

    final hostField = Flexible(
      child: _DropdownTight(
        value: _normalizeChoice(widget.hosts, widget.selectedHost),
        items: widget.hosts,
        labelWhenEmpty: 'All hosts',
        hint: 'Host',
        onChanged: widget.onSelectHost,
      ),
    );

    final sortField = Flexible(
      child: _DropdownTight(
        value:
            _normalizeChoice(widget.sortKeys, widget.selectedSortKey) ??
            widget.sortKeys.first,
        items: widget.sortKeys,
        labelWhenEmpty: widget.sortKeys.first,
        hint: 'Sort by',
        onChanged: widget.onSelectSortKey,
      ),
    );

    final sortOrderBtn = Tooltip(
      message: widget.sortAsc ? 'Ascending' : 'Descending',
      child: InkWell(
        onTap: widget.onToggleAsc,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 40,
          width: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(color: cs.outline),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            widget.sortAsc ? Icons.arrow_upward : Icons.arrow_downward,
          ),
        ),
      ),
    );

    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: LayoutBuilder(
          builder: (c, bc) {
            final narrow = bc.maxWidth < 720;
            final comfy = bc.maxWidth >= 1000;

            if (narrow) {
              return Column(
                children: [
                  queryField,
                  const SizedBox(height: 8),
                  Row(
                    children: [groupField, const SizedBox(width: 8), hostField],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      sortField,
                      const SizedBox(width: 8),
                      sortOrderBtn,
                    ],
                  ),
                ],
              );
            }

            return Row(
              children: [
                queryField,
                SizedBox(width: comfy ? 12 : 8),
                groupField,
                const SizedBox(width: 8),
                hostField,
                const SizedBox(width: 8),
                sortField,
                const SizedBox(width: 8),
                sortOrderBtn,
              ],
            );
          },
        ),
      ),
    );
  }

  String? _normalizeChoice(List<String> options, String? value) {
    if (value == null) return '';
    if (!options.contains(value)) return '';
    return value; // '' = "All …"
  }
}

/// Compact dropdown qui évite les overflows et ellipsise le texte.
/// Utilise isExpanded: true + contentPadding réduit.
class _DropdownTight extends StatelessWidget {
  final String? value;
  final List<String> items;
  final String labelWhenEmpty;
  final String hint;
  final ValueChanged<String?> onChanged;

  const _DropdownTight({
    required this.value,
    required this.items,
    required this.labelWhenEmpty,
    required this.hint,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: DropdownButtonFormField<String>(
        value: value,
        isDense: true,
        isExpanded: true, // clé anti-overflow
        menuMaxHeight: 360,
        items: items
            .map(
              (v) => DropdownMenuItem(
                value: v,
                child: Text(
                  v.isEmpty ? labelWhenEmpty : v,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            )
            .toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          isDense: true,
          hintText: hint,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 8,
          ),
        ),
      ),
    );
  }
}
