import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/category_provider.dart';

class FilterBottomSheetWidget extends StatefulWidget {
  final List<String> selectedCategories;
  final RangeValues priceRange;
  final double minRating;
  final String sortBy;
  final Function(List<String>, RangeValues, double, String)? onApply;

  const FilterBottomSheetWidget({
    super.key,
    this.selectedCategories = const [],
    this.priceRange = const RangeValues(0, 20000),
    this.minRating = 0.0,
    this.sortBy = 'Relevance',
    this.onApply,
  });

  @override
  State<FilterBottomSheetWidget> createState() =>
      _FilterBottomSheetWidgetState();
}

class _FilterBottomSheetWidgetState extends State<FilterBottomSheetWidget> {
  late List<String> _selectedCategories;
  late RangeValues _priceRange;
  late double _minRating;
  late String _sortBy;

  final List<String> _sortOptions = [
    'Relevance',
    'Price Low-High',
    'Price High-Low',
    'Rating'
  ];

  @override
  void initState() {
    super.initState();
    _selectedCategories = List.from(widget.selectedCategories);
    _priceRange = widget.priceRange;
    _minRating = widget.minRating;
    _sortBy = widget.sortBy;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoryProvider = context.watch<CategoryProvider>();

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Filters',
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w600)),
                TextButton(
                  onPressed: () => setState(() {
                    _selectedCategories.clear();
                    _priceRange = const RangeValues(0, 20000);
                    _minRating = 0.0;
                    _sortBy = 'Relevance';
                  }),
                  child: const Text('Reset'),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle(theme, 'Sort By'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _sortOptions.map((option) {
                      return FilterChip(
                        label: Text(option),
                        selected: _sortBy == option,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _sortBy = option);
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle(theme, 'Categories'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: categoryProvider.categoryNames.map((category) {
                      return FilterChip(
                        label: Text(category),
                        selected: _selectedCategories.contains(category),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedCategories.add(category);
                            } else {
                              _selectedCategories.remove(category);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle(theme, 'Price Range'),
                  RangeSlider(
                    values: _priceRange,
                    min: 0,
                    max: 20000,
                    divisions: 100,
                    labels: RangeLabels(
                      'ج.م ${_priceRange.start.toInt()}',
                      'ج.م ${_priceRange.end.toInt()}',
                    ),
                    onChanged: (values) {
                      setState(() => _priceRange = values);
                    },
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle(theme, 'Minimum Rating'),
                  Slider(
                    value: _minRating,
                    min: 0,
                    max: 5,
                    divisions: 10,
                    label: '$_minRating',
                    onChanged: (value) {
                      setState(() => _minRating = value);
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        widget.onApply?.call(
                          _selectedCategories,
                          _priceRange,
                          _minRating,
                          _sortBy,
                        );
                        Navigator.pop(context);
                      },
                      child: const Text('Apply Filters'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
