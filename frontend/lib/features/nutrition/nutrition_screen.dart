import '../../core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'nutrition_provider.dart';
import '../../core/utils/date_formatter.dart';
import '../health/health_provider.dart';

class NutritionScreen extends ConsumerStatefulWidget {
  const NutritionScreen({super.key});

  @override
  ConsumerState<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends ConsumerState<NutritionScreen> {
  Widget _buildTimelineItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required int calories,
    required Color color,
    required bool isBurn,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.5),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${isBurn ? "-" : "+"}$calories kcal',
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddFoodSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: const _FoodSearchSheet(),
        );
      },
    );
  }

  Widget _buildRingChart(double netCalories, double consumed, double target) {
    final safeTarget = target > 0 ? target : 2000.0;
    double progress = consumed / safeTarget;
    if (progress > 1.0) progress = 1.0;

    final remaining = target - consumed;
    final isOver = remaining < 0;
    final color = isOver ? AppColors.error : AppColors.primary;

    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 220,
            height: 220,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 18,
              backgroundColor: Theme.of(context).dividerColor,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              strokeCap: StrokeCap.round,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${isOver ? "+" : ""}${remaining.abs().round()}',
                style: TextStyle(
                  color: color,
                  fontSize: 44,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                isOver ? 'Kcal Fazla' : 'Kcal Kaldı',
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.5),
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Hedef: ${target.round()}',
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.3),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMathSummary(double consumed, double totalBurned, double net) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor, width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _mathCol(
            'Alınan',
            consumed.round(),
            Icons.restaurant,
            AppColors.info,
          ),
          Text(
            '-',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              fontSize: 24,
            ),
          ),
          _mathCol(
            'Yakılan',
            totalBurned.round(),
            Icons.local_fire_department,
            AppColors.warning,
          ),
          Text(
            '=',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
              fontSize: 24,
            ),
          ),
          _mathCol(
            'Net',
            net.round(),
            Icons.balance,
            net > 0 ? AppColors.error : AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _mathCol(String label, int val, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          '$val',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildMacroBar(
    String title,
    double value,
    double target,
    Color color,
  ) {
    final safeTarget = target > 0 ? target : 100.0;
    double progress = value / safeTarget;
    if (progress > 1.0) progress = 1.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
              ),
              Text(
                '${value.round()}g / ${safeTarget.round()}g',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Theme.of(context).dividerColor,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalDatePicker(DateTime selectedDate) {
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 30, // 30 days window roughly
        itemBuilder: (context, index) {
          final date = DateTime.now()
              .subtract(const Duration(days: 15))
              .add(Duration(days: index));
          final isSelected =
              date.year == selectedDate.year &&
              date.month == selectedDate.month &&
              date.day == selectedDate.day;

          final weekdays = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
          final weekdayStr = weekdays[date.weekday - 1];

          return GestureDetector(
            onTap: () {
              ref.read(nutritionProvider.notifier).changeDate(date);
            },
            child: Container(
              width: 60,
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    weekdayStr,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.black54
                          : Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${date.day}',
                    style: TextStyle(
                      color: isSelected
                          ? Colors.black
                          : Theme.of(context).colorScheme.onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(nutritionProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Enerji Dengesi\n${DateFormatter.toTurkishDate(state.selectedDate)}',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        iconTheme: IconThemeData(
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      body: Column(
        children: [
          _buildHorizontalDatePicker(state.selectedDate),
          Expanded(
            child: state.summary.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (err, stack) => Center(
                child: Text(
                  'Hata: $err',
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
              skipLoadingOnReload: true,
              data: (summary) {
                final consumed = (summary['consumedCalories'] ?? 0).toDouble();
                final tdee = (summary['tdee'] ?? 2400).toDouble();
                final targetCalories = (summary['targetCalories'] ?? tdee)
                    .toDouble();
                final bmr = (summary['bmr'] ?? 2000).toDouble();

                // Get active calories directly from healthProvider if viewing today
                final healthState = ref.watch(healthSyncProvider);
                final isToday =
                    state.selectedDate.year == DateTime.now().year &&
                    state.selectedDate.month == DateTime.now().month &&
                    state.selectedDate.day == DateTime.now().day;
                final active = isToday
                    ? healthState.activeCalories
                    : (summary['activeCalories'] ?? 0).toDouble();

                // Çift saymayı önleme algoritması (MyFitnessPal mantığı)
                // Eğer kullanıcının aktivite seviyesinden kaynaklı beklenen bir kalori yakımı varsa,
                // sadece bu beklentiyi aşan (ekstra) adım/sporları totalBurned'e ekleriz.
                final expectedActive = tdee > bmr ? tdee - bmr : 0.0;
                final extraActive = active > expectedActive
                    ? active - expectedActive
                    : 0.0;

                final totalBurned = tdee + extraActive;
                final net = consumed - totalBurned;

                final macros = summary['macros'] ?? {};
                final protein = (macros['protein'] ?? 0).toDouble();
                final carbs = (macros['carbs'] ?? 0).toDouble();
                final fat = (macros['fat'] ?? 0).toDouble();
                final sugar = (macros['sugar'] ?? 0).toDouble();

                final targets = summary['targets'] ?? {};
                final targetProtein = (targets['protein'] ?? 150).toDouble();
                final targetCarbs = (targets['carbs'] ?? 200).toDouble();
                final targetFat = (targets['fat'] ?? 70).toDouble();
                final targetSugar = (targets['sugar'] ?? 50).toDouble();

                final foodLogs = summary['foodLogs'] as List<dynamic>? ?? [];

                final String goalType = summary['goalType'] ?? 'maintain';
                final bool isLoseWeight = goalType == 'lose';

                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 24),
                      _buildRingChart(net, consumed, targetCalories),
                      _buildMathSummary(consumed, totalBurned, net),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(
                          children: [
                            _buildMacroBar(
                              'Protein',
                              protein,
                              targetProtein,
                              AppColors.error,
                            ),
                            _buildMacroBar(
                              'Karb',
                              carbs,
                              targetCarbs,
                              AppColors.warning,
                            ),
                            _buildMacroBar(
                              'Yağ',
                              fat,
                              targetFat,
                              AppColors.fat,
                            ),
                            _buildMacroBar(
                              'Şeker',
                              sugar,
                              targetSugar,
                              AppColors.sugar,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Text(
                          'Enerji Akışı (Günlük Özet)',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(
                          children: [
                            _buildTimelineItem(
                              icon: Icons.bedtime,
                              title: 'Bazal Metabolizma',
                              subtitle: 'Dinlenirken harcanan enerji',
                              calories: summary['bmr'].round(),
                              color: isLoseWeight
                                  ? AppColors.primary
                                  : AppColors.error,
                              isBurn: true,
                            ),

                            if (summary['tdee'] - summary['bmr'] > 0)
                              _buildTimelineItem(
                                icon: Icons.directions_walk,
                                title: 'Günlük Hareket',
                                subtitle: 'Rutin aktiviteler (TDEE)',
                                calories: (summary['tdee'] - summary['bmr'])
                                    .round(),
                                color: isLoseWeight
                                    ? AppColors.primary
                                    : AppColors.error,
                                isBurn: true,
                              ),

                            if (active > 0)
                              _buildTimelineItem(
                                icon: Icons.fitness_center,
                                title: 'Antrenman',
                                subtitle: 'Apple Health verisi',
                                calories: active.round(),
                                color: isLoseWeight
                                    ? AppColors.primary
                                    : AppColors.error,
                                isBurn: true,
                              ),

                            if (foodLogs.isEmpty)
                              Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Text(
                                  'Bugün henüz yemek girmediniz.',
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface.withValues(alpha: 0.5),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              )
                            else
                              ...foodLogs
                                  .map(
                                    (food) => _buildTimelineItem(
                                      icon: Icons.restaurant,
                                      title: food['name'],
                                      subtitle:
                                          'P: ${food['protein']}g • K: ${food['carbs']}g • Y: ${food['fat']}g',
                                      calories: food['calories'].round(),
                                      color: isLoseWeight
                                          ? AppColors.error
                                          : AppColors.primary,
                                      isBurn: false,
                                    ),
                                  )
                                  ,
                          ],
                        ),
                      ),

                      const SizedBox(height: 80),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddFoodSheet,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.black),
        label: const Text(
          'Yemek Ekle',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _FoodSearchSheet extends ConsumerStatefulWidget {
  final Function(Map<String, dynamic>)? onFoodSelected;
  const _FoodSearchSheet({this.onFoodSelected});

  @override
  ConsumerState<_FoodSearchSheet> createState() => _FoodSearchSheetState();
}

class _FoodSearchSheetState extends ConsumerState<_FoodSearchSheet> {
  final _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    // Initially fetch custom foods by searching with empty string
    _onSearchChanged('');
  }

  void _onSearchChanged(String query) async {
    setState(() {
      _isSearching = true;
    });

    try {
      final results = await ref
          .read(nutritionProvider.notifier)
          .searchFood(query);
      if (mounted) {
        setState(() {
          _searchResults = results;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.onFoodSelected != null
                    ? 'Malzeme Ara'
                    : 'Yemek Ara ve Ekle',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (widget.onFoodSelected == null)
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(context); // Close search
                    _showRecipeBuilder(context); // Open recipe builder
                  },
                  icon: const Icon(
                    Icons.auto_awesome,
                    color: AppColors.primary,
                  ),
                  label: const Text(
                    'Tarif Oluştur',
                    style: TextStyle(color: AppColors.primary),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            autofocus: true,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Yemek Ara (Örn: Yulaf, Tavuk)',
              hintStyle: const TextStyle(color: Colors.white54),
              filled: true,
              fillColor: Theme.of(context).cardColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              prefixIcon: const Icon(Icons.search, color: Colors.white54),
            ),
            onChanged: _onSearchChanged,
          ),
          const SizedBox(height: 16),
          if (_isSearching)
            const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          else if (_searchResults.isEmpty && _searchController.text.isNotEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Sonuç bulunamadı.',
                style: TextStyle(color: Colors.white54),
                textAlign: TextAlign.center,
              ),
            )
          else
            SizedBox(
              height: 300,
              child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final food = _searchResults[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).dividerColor,
                      child: Icon(
                        food['isCustom'] == true ? Icons.star : Icons.fastfood,
                        color: food['isCustom'] == true
                            ? Colors.amber
                            : AppColors.primary,
                      ),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            food['name'],
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        if (food['isCustom'] == true)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'ÖZEL TARİF',
                              style: TextStyle(
                                color: Colors.amber,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    subtitle: Text(
                      '${food['calories']} kcal • P: ${food['protein']}g',
                      style: const TextStyle(color: Colors.white54),
                    ),
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.add_circle,
                        color: AppColors.primary,
                      ),
                      onPressed: () {
                        _showQuantityDialog(context, food);
                      },
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Map<String, dynamic> _parseFoodUnit(String name) {
    double baseAmount = 1.0;
    String unitType = "porsiyon";

    // Grams check e.g. (100g)
    final gramMatch = RegExp(
      r'\((\d+)(?:g| gr)\)',
      caseSensitive: false,
    ).firstMatch(name);
    if (gramMatch != null) {
      baseAmount = double.tryParse(gramMatch.group(1) ?? '100') ?? 100.0;
      return {"base": baseAmount, "unit": "gram", "label": "Miktar (gram)"};
    }

    // Adet, Dilim, Kaşık etc. check
    final customMatch = RegExp(
      r'\((\d+)\s+(Adet|Porsiyon|Dilim|Bardak|Kaşık|Kare|Ölçek|Avuç)',
      caseSensitive: false,
    ).firstMatch(name);
    if (customMatch != null) {
      baseAmount = double.tryParse(customMatch.group(1) ?? '1') ?? 1.0;
      unitType = customMatch.group(2)?.toLowerCase() ?? "adet";
      return {
        "base": baseAmount,
        "unit": unitType,
        "label": "Miktar ($unitType)",
      };
    }

    // Yemek kaşığı check
    final kasikMatch = RegExp(
      r'\((\d+)\s+(Yemek Kaşığı|Tatlı Kaşığı)\)',
      caseSensitive: false,
    ).firstMatch(name);
    if (kasikMatch != null) {
      baseAmount = double.tryParse(kasikMatch.group(1) ?? '1') ?? 1.0;
      return {"base": baseAmount, "unit": "kaşık", "label": "Miktar (kaşık)"};
    }

    return {"base": 1.0, "unit": "porsiyon", "label": "Miktar (Porsiyon/Adet)"};
  }

  void _showQuantityDialog(BuildContext context, dynamic food) {
    final parsed = _parseFoodUnit(food['name']);
    final double baseAmount = parsed['base'];
    final String unitLabel = parsed['label'];
    final String unitType = parsed['unit'];

    final initialText = baseAmount.truncateToDouble() == baseAmount
        ? baseAmount.toInt().toString()
        : baseAmount.toString();

    final quantityController = TextEditingController(text: initialText);

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            food['name'],
            style: const TextStyle(color: Colors.white, fontSize: 18),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Kaç $unitType tüketildi? ($unitLabel olarak girin)',
                style: const TextStyle(color: Colors.white54, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: quantityController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  suffixText: unitType,
                  suffixStyle: const TextStyle(
                    color: Colors.white54,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'İptal',
                style: TextStyle(color: Colors.white54),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              onPressed: () {
                final inputVal =
                    double.tryParse(
                      quantityController.text.replaceAll(',', '.'),
                    ) ??
                    baseAmount;
                final multiplier = inputVal / baseAmount;

                String newName = food['name'];
                final baseName = food['name'].split('(')[0].trim();

                if (unitType == 'gram') {
                  newName = '$baseName (${inputVal.toInt()}g)';
                } else {
                  final formattedVal = inputVal.truncateToDouble() == inputVal
                      ? inputVal.toInt().toString()
                      : inputVal.toStringAsFixed(1);
                  newName = '$baseName ($formattedVal $unitType)';
                }

                final foodData = {
                  'name': newName,
                  'calories': (food['calories'] * multiplier).round(),
                  'protein': (food['protein'] * multiplier).round(),
                  'carbs': (food['carbs'] * multiplier).round(),
                  'fat': (food['fat'] * multiplier).round(),
                  'sugar': (food['sugar'] * multiplier).round(),
                };

                if (widget.onFoodSelected != null) {
                  widget.onFoodSelected!(foodData);
                  Navigator.pop(ctx);
                  Navigator.pop(
                    context,
                  ); // Close the search sheet to go back to RecipeBuilder
                } else {
                  ref.read(nutritionProvider.notifier).addFood(foodData);
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                }
              },
              child: const Text(
                'Ekle',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

void _showRecipeBuilder(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).cardColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => const Padding(
      padding: EdgeInsets.all(24.0),
      child: _RecipeBuilderSheet(),
    ),
  );
}

class _RecipeBuilderSheet extends ConsumerStatefulWidget {
  const _RecipeBuilderSheet();

  @override
  ConsumerState<_RecipeBuilderSheet> createState() =>
      _RecipeBuilderSheetState();
}

class _RecipeBuilderSheetState extends ConsumerState<_RecipeBuilderSheet> {
  final _nameController = TextEditingController();
  final List<Map<String, dynamic>> _ingredients = [];

  void _addIngredient() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: _FoodSearchSheet(
          onFoodSelected: (food) {
            setState(() {
              _ingredients.add(food);
            });
          },
        ),
      ),
    );
  }

  void _saveRecipe() {
    if (_nameController.text.trim().isEmpty || _ingredients.isEmpty) return;

    double totalCals = 0;
    double totalP = 0, totalC = 0, totalF = 0, totalS = 0;
    List<String> names = [];

    for (final ing in _ingredients) {
      totalCals += (ing['calories'] as num).toDouble();
      totalP += (ing['protein'] as num).toDouble();
      totalC += (ing['carbs'] as num).toDouble();
      totalF += (ing['fat'] as num).toDouble();
      totalS += (ing['sugar'] as num).toDouble();
      names.add(ing['name'].split('(')[0].trim());
    }

    final data = {
      'name': _nameController.text.trim(),
      'ingredients': names.join(', '),
      'calories': totalCals.round(),
      'protein': totalP.round(),
      'carbs': totalC.round(),
      'fat': totalF.round(),
      'sugar': totalS.round(),
    };

    ref.read(nutritionProvider.notifier).createCustomFood(data);

    // Yemeği günlüğe de ekleyelim
    ref.read(nutritionProvider.notifier).addFood({
      ...data,
      'name': _nameController.text.trim(), // Loglara isim olarak kaydet
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    double totalCals = 0, totalP = 0, totalC = 0, totalF = 0;
    for (final ing in _ingredients) {
      totalCals += (ing['calories'] as num).toDouble();
      totalP += (ing['protein'] as num).toDouble();
      totalC += (ing['carbs'] as num).toDouble();
      totalF += (ing['fat'] as num).toDouble();
    }

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Akıllı Tarif Oluştur',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white54),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Tarif Adı (Örn: Benim Yulafım)',
              hintStyle: const TextStyle(color: Colors.white54),
              filled: true,
              fillColor: Theme.of(context).cardColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Malzemeler',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton.icon(
                onPressed: _addIngredient,
                icon: const Icon(Icons.add, color: AppColors.primary),
                label: const Text(
                  'Malzeme Ekle',
                  style: TextStyle(color: AppColors.primary),
                ),
              ),
            ],
          ),
          if (_ingredients.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Henüz malzeme eklenmedi. Arama yaparak malzeme seçin.',
                style: TextStyle(color: Colors.white54),
                textAlign: TextAlign.center,
              ),
            )
          else
            SizedBox(
              height: 150,
              child: ListView.builder(
                itemCount: _ingredients.length,
                itemBuilder: (ctx, i) {
                  final ing = _ingredients[i];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      ing['name'],
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      '${ing['calories']} kcal • P: ${ing['protein']}g',
                      style: const TextStyle(color: Colors.white54),
                    ),
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.remove_circle,
                        color: Colors.redAccent,
                      ),
                      onPressed: () {
                        setState(() {
                          _ingredients.removeAt(i);
                        });
                      },
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMacroSummary(
                  'Kcal',
                  totalCals.round(),
                  AppColors.primary,
                ),
                _buildMacroSummary('Pro', totalP.round(), AppColors.error),
                _buildMacroSummary('Karb', totalC.round(), AppColors.warning),
                _buildMacroSummary('Yağ', totalF.round(), AppColors.fat),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed:
                _ingredients.isEmpty || _nameController.text.trim().isEmpty
                ? null
                : _saveRecipe,
            child: const Text(
              'Kaydet ve Tüket',
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildMacroSummary(String label, int val, Color color) {
    return Column(
      children: [
        Text(
          '$val',
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 12),
        ),
      ],
    );
  }
}
