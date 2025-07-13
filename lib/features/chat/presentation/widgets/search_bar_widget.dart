import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class SearchBarWidget extends StatefulWidget {
  final TextEditingController controller;
  final String? hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final VoidCallback? onSubmitted;
  final bool autofocus;
  final bool enabled;
  final Widget? leading;

  const SearchBarWidget({
    super.key,
    required this.controller,
    this.hintText,
    this.onChanged,
    this.onClear,
    this.onSubmitted,
    this.autofocus = false,
    this.enabled = true,
    this.leading,
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isFocused
              ? AppTheme.primaryColor
              : (isDark
                    ? AppTheme.darkDividerColor
                    : AppTheme.lightDividerColor),
          width: _isFocused ? 2 : 1,
        ),
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: _focusNode,
        autofocus: widget.autofocus,
        enabled: widget.enabled,
        onChanged: widget.onChanged,
        onSubmitted: widget.onSubmitted != null
            ? (_) => widget.onSubmitted!()
            : null,
        decoration: InputDecoration(
          hintText: widget.hintText ?? 'Search conver...',
          hintStyle: TextStyle(
            color: isDark
                ? AppTheme.darkTextSecondary
                : AppTheme.lightTextSecondary,
            fontSize: 16,
          ),
          prefixIcon:
              widget.leading ??
              Icon(
                Icons.search,
                color: _isFocused
                    ? AppTheme.primaryColor
                    : (isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.lightTextSecondary),
              ),
          suffixIcon: widget.controller.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
                  ),
                  onPressed: () {
                    widget.controller.clear();
                    widget.onClear?.call();
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        style: TextStyle(
          color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
          fontSize: 16,
        ),
      ),
    );
  }
}

// Advanced search bar with filters
class AdvancedSearchBar extends StatefulWidget {
  final TextEditingController controller;
  final String? hintText;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final VoidCallback? onSubmitted;
  final List<SearchFilter> filters;
  final ValueChanged<List<SearchFilter>>? onFiltersChanged;
  final bool autofocus;
  final bool enabled;

  const AdvancedSearchBar({
    super.key,
    required this.controller,
    this.hintText,
    this.onChanged,
    this.onClear,
    this.onSubmitted,
    this.filters = const [],
    this.onFiltersChanged,
    this.autofocus = false,
    this.enabled = true,
  });

  @override
  State<AdvancedSearchBar> createState() => _AdvancedSearchBarState();
}

class _AdvancedSearchBarState extends State<AdvancedSearchBar> {
  late FocusNode _focusNode;
  bool _isFocused = false;
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _isFocused
                  ? AppTheme.primaryColor
                  : (isDark
                        ? AppTheme.darkDividerColor
                        : AppTheme.lightDividerColor),
              width: _isFocused ? 2 : 1,
            ),
          ),
          child: TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            autofocus: widget.autofocus,
            enabled: widget.enabled,
            onChanged: widget.onChanged,
            onSubmitted: widget.onSubmitted != null
                ? (_) => widget.onSubmitted!()
                : null,
            decoration: InputDecoration(
              hintText:
                  widget.hintText ?? 'Search messages, files, and more...',
              hintStyle: TextStyle(
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.lightTextSecondary,
                fontSize: 16,
              ),
              prefixIcon: Icon(
                Icons.search,
                color: _isFocused
                    ? AppTheme.primaryColor
                    : (isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.lightTextSecondary),
              ),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.filters.isNotEmpty) ...[
                    IconButton(
                      icon: Icon(
                        _showFilters
                            ? Icons.filter_list
                            : Icons.filter_list_outlined,
                        color: _showFilters ? AppTheme.primaryColor : null,
                      ),
                      onPressed: () {
                        setState(() {
                          _showFilters = !_showFilters;
                        });
                      },
                    ),
                  ],
                  if (widget.controller.text.isNotEmpty) ...[
                    IconButton(
                      icon: Icon(
                        Icons.clear,
                        color: isDark
                            ? AppTheme.darkTextSecondary
                            : AppTheme.lightTextSecondary,
                      ),
                      onPressed: () {
                        widget.controller.clear();
                        widget.onClear?.call();
                      },
                    ),
                  ],
                ],
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            style: TextStyle(
              color: isDark
                  ? AppTheme.darkTextPrimary
                  : AppTheme.lightTextPrimary,
              fontSize: 16,
            ),
          ),
        ),

        // Filters section
        if (_showFilters && widget.filters.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildFiltersSection(isDark),
        ],
      ],
    );
  }

  Widget _buildFiltersSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? AppTheme.darkDividerColor
              : AppTheme.lightDividerColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filters',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.filters.map((filter) {
              return FilterChip(
                label: Text(filter.label),
                selected: filter.isSelected,
                onSelected: (selected) {
                  final updatedFilters = widget.filters.map((f) {
                    if (f.key == filter.key) {
                      return f.copyWith(isSelected: selected);
                    }
                    return f;
                  }).toList();
                  widget.onFiltersChanged?.call(updatedFilters);
                },
                selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                checkmarkColor: AppTheme.primaryColor,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// Search filter model
class SearchFilter {
  final String key;
  final String label;
  final bool isSelected;

  const SearchFilter({
    required this.key,
    required this.label,
    this.isSelected = false,
  });

  SearchFilter copyWith({String? key, String? label, bool? isSelected}) {
    return SearchFilter(
      key: key ?? this.key,
      label: label ?? this.label,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}

// Search suggestions widget
class SearchSuggestions extends StatelessWidget {
  final List<String> suggestions;
  final ValueChanged<String>? onSuggestionTap;

  const SearchSuggestions({
    super.key,
    required this.suggestions,
    this.onSuggestionTap,
  });

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: suggestions.map((suggestion) {
          return ListTile(
            leading: const Icon(Icons.history),
            title: Text(suggestion),
            onTap: () => onSuggestionTap?.call(suggestion),
          );
        }).toList(),
      ),
    );
  }
}
