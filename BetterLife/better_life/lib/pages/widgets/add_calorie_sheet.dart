import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../models/calorie_entry.dart';
import '../../models/usda_food_search_result.dart';
import '../../services/usda_food_service.dart';
import '../../theme/app_palette.dart';

class AddCalorieSheet extends StatefulWidget {
  final DateTime initialDate;
  final Future<void> Function(CalorieEntry entry) onSave;

  const AddCalorieSheet({
    super.key,
    required this.initialDate,
    required this.onSave,
  });

  @override
  State<AddCalorieSheet> createState() => _AddCalorieSheetState();
}

class _AddCalorieSheetState extends State<AddCalorieSheet> {
  final _formKey = GlobalKey<FormState>();
  final _searchController = TextEditingController();
  final _mealNameController = TextEditingController();
  final _noteController = TextEditingController();
  final _foodService = UsdaFoodService();
  final List<_SelectedIngredient> _ingredients = [];
  late DateTime _selectedDate;
  UsdaFoodSearchPage? _searchPage;
  String _lastSearchQuery = '';
  int _searchPageNumber = 1;
  bool _isSearching = false;
  bool _hasSearched = false;
  bool _saving = false;
  String? _searchError;

  double get _totalCalories {
    return _ingredients.fold<double>(
      0,
      (sum, ingredient) => sum + ingredient.calories,
    );
  }

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(
      widget.initialDate.year,
      widget.initialDate.month,
      widget.initialDate.day,
      now.hour,
      now.minute,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mealNameController.dispose();
    _noteController.dispose();
    for (final ingredient in _ingredients) {
      ingredient.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked == null || !mounted) return;

    setState(() {
      _selectedDate = DateTime(
        picked.year,
        picked.month,
        picked.day,
        _selectedDate.hour,
        _selectedDate.minute,
      );
    });
  }

  Future<void> _searchFoods({int page = 1}) async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _searchPage = null;
        _lastSearchQuery = '';
        _searchPageNumber = 1;
        _hasSearched = false;
        _searchError = null;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _hasSearched = true;
      _searchError = null;
      _searchPageNumber = page;
      _lastSearchQuery = query;
    });

    try {
      final results = await _foodService.searchFoods(query: query, page: page);
      if (!mounted) return;
      setState(() => _searchPage = results);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _searchPage = null;
        _searchError = 'Nepavyko gauti USDA duomenu';
      });
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _addFood(UsdaFoodSearchResult food) {
    if (food.calories == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Produktas neturi kaloriju duomenu')),
      );
      return;
    }

    setState(() {
      _ingredients.add(_SelectedIngredient(food));
    });
  }

  void _removeIngredient(_SelectedIngredient ingredient) {
    setState(() {
      _ingredients.remove(ingredient);
      ingredient.dispose();
    });
  }

  Future<void> _submit() async {
    if (_ingredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pasirinkite bent viena produkta')),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final name = _mealNameController.text.trim();
    final ingredientModels = _ingredients.map((ingredient) {
      return CalorieIngredient(
        fdcId: ingredient.food.fdcId,
        name: ingredient.food.description,
        grams: ingredient.grams,
        caloriesPerBasis: ingredient.food.calories ?? 0,
        gramsBasis: ingredient.food.gramsBasis,
      );
    }).toList();

    final effectiveName = name.isNotEmpty
        ? name
        : ingredientModels.length == 1
        ? ingredientModels.single.name
        : '';

    final entry = CalorieEntry(
      id: '',
      calories: _totalCalories.round(),
      date: _selectedDate,
      note: _noteController.text.trim(),
      name: effectiveName,
      ingredients: ingredientModels,
    );

    setState(() => _saving = true);
    try {
      await widget.onSave(entry);
      if (mounted) Navigator.pop(context, entry);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final surface = AppPalette.surface(context);
    final input = AppPalette.input(context);
    final text = AppPalette.primaryText(context);
    final subtext = AppPalette.secondaryText(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.55,
      maxChildSize: 0.96,
      builder: (context, scrollController) {
        return Container(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Form(
            key: _formKey,
            child: ListView(
              controller: scrollController,
              children: [
                Center(
                  child: Container(
                    width: 56,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(100),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Kaloriju irasas',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: text,
                  ),
                ),
                const SizedBox(height: 16),
                _buildSearch(input, text, subtext),
                const SizedBox(height: 16),
                _buildIngredients(input, text, subtext),
                const SizedBox(height: 12),
                if (_ingredients.length > 1)
                  TextFormField(
                    controller: _mealNameController,
                    style: TextStyle(color: text),
                    decoration: _fieldDecoration(
                      input: input,
                      subtext: subtext,
                      label: 'Patiekalo pavadinimas',
                      icon: Icons.restaurant_menu_rounded,
                    ),
                  ),
                if (_ingredients.length > 1) const SizedBox(height: 12),
                InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: _pickDate,
                  child: InputDecorator(
                    decoration: _fieldDecoration(
                      input: input,
                      subtext: subtext,
                      label: 'Data',
                      icon: Icons.calendar_today_rounded,
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        DateFormat('yyyy-MM-dd').format(_selectedDate),
                        style: TextStyle(color: text),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _noteController,
                  minLines: 1,
                  maxLines: 3,
                  style: TextStyle(color: text),
                  decoration: _fieldDecoration(
                    input: input,
                    subtext: subtext,
                    label: 'Pastaba',
                    icon: Icons.notes_rounded,
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: input,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.local_fire_department_rounded),
                      const SizedBox(width: 10),
                      Text(
                        'Is viso',
                        style: TextStyle(
                          color: subtext,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${_totalCalories.round()} kcal',
                        style: TextStyle(
                          color: text,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _saving ? null : _submit,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_rounded),
                    label: Text(_saving ? 'Saugoma...' : 'Issaugoti irasa'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearch(Color input, Color text, Color subtext) {
    final results = _searchPage?.foods ?? const <UsdaFoodSearchResult>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _searchController,
          enabled: !_isSearching,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _searchFoods(),
          style: TextStyle(color: text),
          decoration: _fieldDecoration(
            input: input,
            subtext: subtext,
            label: 'USDA produktu paieska',
            icon: Icons.search_rounded,
            suffixIcon: IconButton(
              tooltip: 'Ieskoti',
              onPressed: _isSearching ? null : () => _searchFoods(),
              icon: const Icon(Icons.arrow_forward_rounded),
            ),
          ),
        ),
        const SizedBox(height: 10),
        if (_isSearching)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_searchError != null)
          _MessageRow(message: _searchError!, color: AppPalette.accentOrange)
        else if (_hasSearched && results.isEmpty)
          _MessageRow(message: 'Rezultatu nerasta', color: subtext)
        else
          ...results.map(
            (food) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _SearchResultTile(food: food, onAdd: () => _addFood(food)),
            ),
          ),
        if (_searchPage != null && _searchPage!.totalHits > 0)
          Row(
            children: [
              Text(
                'Puslapis $_searchPageNumber is ${_searchPage!.totalPages}',
                style: TextStyle(color: subtext),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Ankstesnis puslapis',
                onPressed: _searchPageNumber > 1 && !_isSearching
                    ? () {
                        _searchController.text = _lastSearchQuery;
                        _searchFoods(page: _searchPageNumber - 1);
                      }
                    : null,
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              IconButton(
                tooltip: 'Kitas puslapis',
                onPressed:
                    _searchPageNumber < _searchPage!.totalPages && !_isSearching
                    ? () {
                        _searchController.text = _lastSearchQuery;
                        _searchFoods(page: _searchPageNumber + 1);
                      }
                    : null,
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildIngredients(Color input, Color text, Color subtext) {
    if (_ingredients.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: input,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          'Pasirinkti produktai bus rodomi cia.',
          style: TextStyle(color: subtext),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ingredientai',
          style: TextStyle(
            color: text,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        ..._ingredients.map(
          (ingredient) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _IngredientEditor(
              ingredient: ingredient,
              onChanged: () => setState(() {}),
              onRemove: () => _removeIngredient(ingredient),
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _fieldDecoration({
    required Color input,
    required Color subtext,
    required String label,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: subtext),
      prefixIcon: Icon(icon),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: input,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
    );
  }
}

class _SelectedIngredient {
  final UsdaFoodSearchResult food;
  final TextEditingController gramsController;

  _SelectedIngredient(this.food)
    : gramsController = TextEditingController(text: '100');

  double get grams => double.tryParse(gramsController.text.trim()) ?? 0;

  double get calories => food.caloriesForGrams(grams) ?? 0;

  void dispose() {
    gramsController.dispose();
  }
}

class _IngredientEditor extends StatelessWidget {
  final _SelectedIngredient ingredient;
  final VoidCallback onChanged;
  final VoidCallback onRemove;

  const _IngredientEditor({
    required this.ingredient,
    required this.onChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final input = AppPalette.input(context);
    final border = AppPalette.border(context);
    final text = AppPalette.primaryText(context);
    final subtext = AppPalette.secondaryText(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: input,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  ingredient.food.description,
                  style: TextStyle(color: text, fontWeight: FontWeight.w800),
                ),
              ),
              IconButton(
                tooltip: 'Pasalinti',
                onPressed: onRemove,
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: ingredient.gramsController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  onChanged: (_) => onChanged(),
                  style: TextStyle(color: text),
                  decoration: InputDecoration(
                    labelText: 'Gramai',
                    labelStyle: TextStyle(color: subtext),
                    suffixText: 'g',
                    filled: true,
                    fillColor: AppPalette.surface(context),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) {
                    final grams = double.tryParse((value ?? '').trim());
                    if (grams == null) return 'Iveskite gramus';
                    if (grams <= 0) return 'Turi buti > 0';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 96,
                child: Text(
                  '${ingredient.calories.round()} kcal',
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    color: text,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  final UsdaFoodSearchResult food;
  final VoidCallback onAdd;

  const _SearchResultTile({required this.food, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final input = AppPalette.input(context);
    final border = AppPalette.border(context);
    final text = AppPalette.primaryText(context);
    final subtext = AppPalette.secondaryText(context);
    final canAdd = food.calories != null;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: input,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  food.description,
                  style: TextStyle(color: text, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  '${food.caloriesText} ${food.calorieBasis}',
                  style: TextStyle(color: subtext),
                ),
              ],
            ),
          ),
          IconButton.filledTonal(
            tooltip: canAdd ? 'Prideti' : 'Nera kaloriju duomenu',
            onPressed: canAdd ? onAdd : null,
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
    );
  }
}

class _MessageRow extends StatelessWidget {
  final String message;
  final Color color;

  const _MessageRow({required this.message, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.info_outline_rounded, color: color),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              message,
              style: TextStyle(color: color, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
