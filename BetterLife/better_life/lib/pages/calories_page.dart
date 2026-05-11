import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/calorie_entry.dart';
import '../models/usda_food_search_result.dart';
import '../services/calorie_service.dart';
import '../services/usda_food_service.dart';
import '../theme/app_palette.dart';
import 'widgets/add_calorie_sheet.dart';
import 'widgets/profile_action_button.dart';

class CaloriesPage extends StatefulWidget {
  const CaloriesPage({super.key});

  @override
  State<CaloriesPage> createState() => _CaloriesPageState();
}

class _CaloriesPageState extends State<CaloriesPage> {
  final CalorieService _calorieService = CalorieService();
  final UsdaFoodService _usdaFoodService = UsdaFoodService();
  final TextEditingController _searchController = TextEditingController();
  DateTime _selectedDay = DateTime.now();
  UsdaFoodSearchPage? _foodSearchPage;
  String _lastSearchQuery = '';
  int _foodSearchPageNumber = 1;
  bool _isSearchingFoods = false;
  bool _hasSearchedFoods = false;
  String? _foodSearchError;

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  DateTime _normalize(DateTime d) => DateTime(d.year, d.month, d.day);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openAddSheet() async {
    CalorieEntry? savedEntry;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddCalorieSheet(
        initialDate: _selectedDay,
        onSave: (entry) async {
          await _calorieService.addEntry(_uid, entry);
          savedEntry = entry;
        },
      ),
    );

    if (!mounted || savedEntry == null) return;

    setState(() => _selectedDay = _normalize(savedEntry!.date));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Kalorijų įrašas išsaugotas')),
    );
  }

  Future<void> _searchFoods({int page = 1}) async {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _foodSearchPage = null;
        _lastSearchQuery = '';
        _foodSearchPageNumber = 1;
        _hasSearchedFoods = false;
        _foodSearchError = null;
      });
      return;
    }

    setState(() {
      _isSearchingFoods = true;
      _hasSearchedFoods = true;
      _foodSearchError = null;
      _foodSearchPageNumber = page;
      _lastSearchQuery = query;
    });

    try {
      final results = await _usdaFoodService.searchFoods(
        query: query,
        page: page,
      );
      if (!mounted) return;

      setState(() => _foodSearchPage = results);
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _foodSearchPage = null;
        _foodSearchError = 'Nepavyko gauti duomenų';
      });
    } finally {
      if (mounted) setState(() => _isSearchingFoods = false);
    }
  }

  Future<void> _changeFoodSearchPage(int page) async {
    _searchController.text = _lastSearchQuery;
    await _searchFoods(page: page);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Pirma prisijunk')),
      );
    }

    final background = AppPalette.background(context);
    final surface = AppPalette.surface(context);
    final border = AppPalette.border(context);
    final text = AppPalette.primaryText(context);
    final subtext = AppPalette.secondaryText(context);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        foregroundColor: text,
        elevation: 0,
        title: const Text('Kalorijos'),
        actions: const [ProfileActionButton()],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddSheet,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Pridėti'),
      ),
      body: StreamBuilder<List<CalorieEntry>>(
        stream: _calorieService.watchDayEntries(_uid, _selectedDay),
        builder: (context, snapshot) {
          final entries = snapshot.data ?? [];
          final total = entries.fold<int>(
            0,
            (sum, entry) => sum + entry.calories,
          );

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: AppPalette.heroGradient,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Dienos suvestinė',
                      style: TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$total kcal',
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      DateFormat('yyyy-MM-dd').format(_selectedDay),
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: border),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _selectedDay = _selectedDay.subtract(
                            const Duration(days: 1),
                          );
                        });
                      },
                      icon: const Icon(Icons.chevron_left_rounded),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            'Pasirinkta diena',
                            style: TextStyle(color: subtext),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('yyyy MMMM d').format(_selectedDay),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: text,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _selectedDay = _selectedDay.add(
                            const Duration(days: 1),
                          );
                        });
                      },
                      icon: const Icon(Icons.chevron_right_rounded),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _FoodSearchPanel(
                controller: _searchController,
                page: _foodSearchPage,
                currentPage: _foodSearchPageNumber,
                isLoading: _isSearchingFoods,
                hasSearched: _hasSearchedFoods,
                errorMessage: _foodSearchError,
                onSearch: () => _searchFoods(),
                onSubmitted: (_) => _searchFoods(),
                onPreviousPage:
                    _foodSearchPageNumber > 1 && !_isSearchingFoods
                    ? () => _changeFoodSearchPage(_foodSearchPageNumber - 1)
                    : null,
                onNextPage:
                    _foodSearchPage != null &&
                        _foodSearchPageNumber < _foodSearchPage!.totalPages &&
                        !_isSearchingFoods
                    ? () => _changeFoodSearchPage(_foodSearchPageNumber + 1)
                    : null,
              ),
              const SizedBox(height: 16),
              Text(
                'Dienos įrašai',
                style: TextStyle(
                  color: text,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              if (entries.isEmpty)
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: border),
                  ),
                  child: Text(
                    'Šiai dienai kalorijų įrašų dar nėra.',
                    style: TextStyle(color: subtext),
                  ),
                )
              else
                ...entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: border),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: AppPalette.accentOrange
                                .withOpacity(.16),
                            child: const Icon(
                              Icons.local_fire_department_rounded,
                              color: AppPalette.accentOrange,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  entry.effectiveName.isNotEmpty
                                      ? entry.effectiveName
                                      : '${entry.calories} kcal',
                                  style: TextStyle(
                                    color: text,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${entry.calories} kcal',
                                  style: TextStyle(
                                    color: AppPalette.accentOrange,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat(
                                    'yyyy-MM-dd HH:mm',
                                  ).format(entry.date),
                                  style: TextStyle(color: subtext),
                                ),
                                if (entry.ingredients.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  ...entry.ingredients.map(
                                    (ingredient) => Padding(
                                      padding: const EdgeInsets.only(bottom: 3),
                                      child: Text(
                                        '${ingredient.name} - ${ingredient.grams.toStringAsFixed(0)} g, ${ingredient.calories.round()} kcal',
                                        style: TextStyle(color: subtext),
                                      ),
                                    ),
                                  ),
                                ],
                                if (entry.note.trim().isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    entry.note.trim(),
                                    style: TextStyle(color: text),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _FoodSearchPanel extends StatelessWidget {
  final TextEditingController controller;
  final UsdaFoodSearchPage? page;
  final int currentPage;
  final bool isLoading;
  final bool hasSearched;
  final String? errorMessage;
  final VoidCallback onSearch;
  final ValueChanged<String> onSubmitted;
  final VoidCallback? onPreviousPage;
  final VoidCallback? onNextPage;

  const _FoodSearchPanel({
    required this.controller,
    required this.page,
    required this.currentPage,
    required this.isLoading,
    required this.hasSearched,
    required this.errorMessage,
    required this.onSearch,
    required this.onSubmitted,
    required this.onPreviousPage,
    required this.onNextPage,
  });

  @override
  Widget build(BuildContext context) {
    final surface = AppPalette.surface(context);
    final input = AppPalette.input(context);
    final border = AppPalette.border(context);
    final text = AppPalette.primaryText(context);
    final subtext = AppPalette.secondaryText(context);
    final results = page?.foods ?? const <UsdaFoodSearchResult>[];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'USDA maisto paieška',
            style: TextStyle(
              color: text,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            enabled: !isLoading,
            textInputAction: TextInputAction.search,
            onSubmitted: onSubmitted,
            style: TextStyle(color: text),
            decoration: InputDecoration(
              hintText: 'Pvz., cheddar cheese',
              hintStyle: TextStyle(color: subtext),
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: IconButton(
                tooltip: 'Ieškoti',
                onPressed: isLoading ? null : onSearch,
                icon: const Icon(Icons.arrow_forward_rounded),
              ),
              filled: true,
              fillColor: input,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: CircularProgressIndicator(),
              ),
            )
          else if (errorMessage != null)
            _SearchMessage(
              icon: Icons.error_outline_rounded,
              message: errorMessage!,
              color: AppPalette.accentOrange,
            )
          else if (hasSearched && results.isEmpty)
            _SearchMessage(
              icon: Icons.search_off_rounded,
              message: 'No results',
              color: subtext,
            )
          else ...[
            ...results.map(
              (food) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _FoodSearchResultTile(food: food),
              ),
            ),
            if (page != null && page!.totalHits > 0) ...[
              const SizedBox(height: 2),
              Row(
                children: [
                  Text(
                    'Puslapis $currentPage iš ${page!.totalPages}',
                    style: TextStyle(color: subtext),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Ankstesnis puslapis',
                    onPressed: onPreviousPage,
                    icon: const Icon(Icons.chevron_left_rounded),
                  ),
                  IconButton(
                    tooltip: 'Kitas puslapis',
                    onPressed: onNextPage,
                    icon: const Icon(Icons.chevron_right_rounded),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _FoodSearchResultTile extends StatelessWidget {
  final UsdaFoodSearchResult food;

  const _FoodSearchResultTile({required this.food});

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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 21,
            backgroundColor: AppPalette.accentGreen.withOpacity(.16),
            child: const Icon(
              Icons.restaurant_rounded,
              color: AppPalette.accentGreen,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  food.description,
                  style: TextStyle(
                    color: text,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 10,
                  runSpacing: 4,
                  children: [
                    Text(
                      '${food.caloriesText} ${food.calorieBasis}',
                      style: TextStyle(color: subtext),
                    ),
                    Text(
                      'FDC ID: ${food.fdcId}',
                      style: TextStyle(color: subtext),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchMessage extends StatelessWidget {
  final IconData icon;
  final String message;
  final Color color;

  const _SearchMessage({
    required this.icon,
    required this.message,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color),
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
