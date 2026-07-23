import '../../core/theme/app_colors.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'workout_logs_provider.dart';

class YolKutAnalyticsScreen extends ConsumerStatefulWidget {
  const YolKutAnalyticsScreen({super.key});

  @override
  ConsumerState<YolKutAnalyticsScreen> createState() =>
      _YolKutAnalyticsScreenState();
}

class _ProgramDataStore {
  List<Map<String, dynamic>> langLogs = [];
  List<Map<String, dynamic>> langVocab = [];
  List<Map<String, dynamic>> studyLogs = [];
  List<Map<String, dynamic>> habits = [];
  List<Map<String, dynamic>> books = [];
  List<Map<String, dynamic>> otherLogs = [];
}

class _YolKutAnalyticsScreenState extends ConsumerState<YolKutAnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _ProgramDataStore _dataStore = _ProgramDataStore();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _initializeDataStore();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeDataStore() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _dataStore.langLogs = _parseJsonList(
        prefs.getString('lang_journal_logs'),
      );
      _dataStore.langVocab = _parseJsonList(prefs.getString('lang_vocab_list'));
      _dataStore.studyLogs = _parseJsonList(prefs.getString('study_logs'));
      _dataStore.habits = _parseJsonList(prefs.getString('personal_habits'));
      _dataStore.books = _parseJsonList(prefs.getString('personal_books'));
      _dataStore.otherLogs = _parseJsonList(prefs.getString('other_logs'));
      _isLoading = false;
    });
  }

  List<Map<String, dynamic>> _parseJsonList(String? raw) {
    if (raw == null) return [];
    try {
      return List<Map<String, dynamic>>.from(json.decode(raw));
    } catch (_) {
      return [];
    }
  }

  DateTime? _parseDate(dynamic value) {
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateFormat('dd.MM.yyyy HH:mm').parse(value);
      } catch (_) {
        try {
          return DateFormat('yyyy-MM-dd').parse(value);
        } catch (_) {}
      }
    }
    return null;
  }

  bool _isThisWeek(DateTime date) {
    final now = DateTime.now();
    final startOfThisWeek = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    return date.isAfter(startOfThisWeek) ||
        date.isAtSameMomentAs(startOfThisWeek);
  }

  bool _isLastWeek(DateTime date) {
    final now = DateTime.now();
    final startOfThisWeek = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    final startOfLastWeek = startOfThisWeek.subtract(const Duration(days: 7));
    return (date.isAfter(startOfLastWeek) ||
            date.isAtSameMomentAs(startOfLastWeek)) &&
        date.isBefore(startOfThisWeek);
  }

  Map<String, double> _computeWorkoutStats() {
    final logs = ref.watch(workoutLogsProvider);
    double thisWeekVolume = 0;
    double lastWeekVolume = 0;
    int thisWeekCount = 0;
    int lastWeekCount = 0;

    for (var log in logs) {
      final date = _parseDate(log.date);
      if (date == null) continue;

      double volume = 0;
      for (var exLog in log.exercises) {
        for (var set in exLog.sets) {
          volume += set.actualReps * set.weightKg;
        }
      }

      if (_isThisWeek(date)) {
        thisWeekVolume += volume;
        thisWeekCount++;
      } else if (_isLastWeek(date)) {
        lastWeekVolume += volume;
        lastWeekCount++;
      }
    }

    return {
      'thisWeekVolume': thisWeekVolume,
      'lastWeekVolume': lastWeekVolume,
      'thisWeekCount': thisWeekCount.toDouble(),
      'lastWeekCount': lastWeekCount.toDouble(),
    };
  }

  Map<String, double> _computeLanguageStats() {
    double thisWeekMinutes = 0;
    double lastWeekMinutes = 0;

    for (var log in _dataStore.langLogs) {
      final date = _parseDate(log['date']);
      if (date == null) continue;
      final mins = (log['duration'] as num? ?? 0).toDouble();

      if (_isThisWeek(date)) {
        thisWeekMinutes += mins;
      } else if (_isLastWeek(date)) {
        lastWeekMinutes += mins;
      }
    }

    return {
      'thisWeekMinutes': thisWeekMinutes,
      'lastWeekMinutes': lastWeekMinutes,
      'totalVocab': _dataStore.langVocab.length.toDouble(),
    };
  }

  Map<String, double> _computeStudyStats() {
    double thisWeekMinutes = 0;
    double lastWeekMinutes = 0;
    double thisWeekQuestions = 0;
    double lastWeekQuestions = 0;

    for (var log in _dataStore.studyLogs) {
      final date = _parseDate(log['date']);
      if (date == null) continue;
      final mins = (log['duration'] as num? ?? 0).toDouble();
      final qCount = (log['questions'] as num? ?? 0).toDouble();

      if (_isThisWeek(date)) {
        thisWeekMinutes += mins;
        thisWeekQuestions += qCount;
      } else if (_isLastWeek(date)) {
        lastWeekMinutes += mins;
        lastWeekQuestions += qCount;
      }
    }

    return {
      'thisWeekMinutes': thisWeekMinutes,
      'lastWeekMinutes': lastWeekMinutes,
      'thisWeekQuestions': thisWeekQuestions,
      'lastWeekQuestions': lastWeekQuestions,
    };
  }

  Map<String, double> _computeHabitsStats() {
    double thisWeekChecks = 0;
    double lastWeekChecks = 0;

    for (var habit in _dataStore.habits) {
      final history = List<String>.from(habit['history'] ?? []);
      for (var dateStr in history) {
        final date = _parseDate(dateStr);
        if (date == null) continue;
        if (_isThisWeek(date)) {
          thisWeekChecks++;
        } else if (_isLastWeek(date)) {
          lastWeekChecks++;
        }
      }
    }

    return {'thisWeekChecks': thisWeekChecks, 'lastWeekChecks': lastWeekChecks};
  }

  Map<String, double> _computeOtherStats() {
    double thisWeekMinutes = 0;
    double lastWeekMinutes = 0;

    for (var log in _dataStore.otherLogs) {
      final date = _parseDate(log['date']);
      if (date == null) continue;
      final mins = (log['duration'] as num? ?? 0).toDouble();

      if (_isThisWeek(date)) {
        thisWeekMinutes += mins;
      } else if (_isLastWeek(date)) {
        lastWeekMinutes += mins;
      }
    }

    return {
      'thisWeekMinutes': thisWeekMinutes,
      'lastWeekMinutes': lastWeekMinutes,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.info)),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Gelisim ve Istatistikler',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: AppColors.info,
            unselectedLabelColor: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.5),
            indicatorColor: AppColors.info,
            indicatorWeight: 3,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            tabs: const [
              Tab(text: 'Spor'),
              Tab(text: 'Dil Ogrenimi'),
              Tab(text: 'Ders/Egitim'),
              Tab(text: 'Aliskanlik'),
              Tab(text: 'Diger'),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSportsAnalytics(),
                _buildLanguageAnalytics(),
                _buildStudyAnalytics(),
                _buildHabitsAnalytics(),
                _buildOtherAnalytics(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCard({
    required String title,
    required String thisWeekVal,
    required String lastWeekVal,
    required double thisWeekRaw,
    required double lastWeekRaw,
    required Color color,
    required String changeLabel,
  }) {
    double percentageChange = 0;
    if (lastWeekRaw > 0) {
      percentageChange = ((thisWeekRaw - lastWeekRaw) / lastWeekRaw) * 100;
    } else if (thisWeekRaw > 0) {
      percentageChange = 100;
    }
    final isIncrease = percentageChange >= 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bu Hafta',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    thisWeekVal,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                height: 40,
                width: 1,
                color: Theme.of(context).dividerColor,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Gecen Hafta',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lastWeekVal,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: (isIncrease ? Colors.green : Colors.red).withValues(alpha: 
                    0.12,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      isIncrease ? Icons.arrow_upward : Icons.arrow_downward,
                      color: isIncrease ? Colors.green : Colors.red,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${percentageChange.abs().toStringAsFixed(0)}%',
                      style: TextStyle(
                        color: isIncrease ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            isIncrease
                ? 'Gecen haftaya gore gelisim gosterdiniz, tebrikler!'
                : 'Ilerlemeyi korumak icin hedeflerinizi gozden gecirin.',
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonChart({
    required String label1,
    required double value1,
    required String label2,
    required double value2,
    required Color color,
    required String unit,
  }) {
    final maxValue = value1 > value2 ? value1 : value2;
    final height1 = maxValue == 0 ? 10.0 : (value1 / maxValue) * 120.0;
    final height2 = maxValue == 0 ? 10.0 : (value2 / maxValue) * 120.0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          const Text(
            'Haftalik Karsilastirma Grafigi',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                children: [
                  Text(
                    '${value2.toStringAsFixed(0)} $unit',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    width: 48,
                    height: height2 < 10 ? 10 : height2,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.4),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label2,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  Text(
                    '${value1.toStringAsFixed(0)} $unit',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    width: 48,
                    height: height1 < 10 ? 10 : height1,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label1,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSportsAnalytics() {
    final stats = _computeWorkoutStats();
    return ListView(
      children: [
        _buildOverviewCard(
          title: 'Toplam Antrenman Hacmi',
          thisWeekVal: '${stats['thisWeekVolume']!.toStringAsFixed(0)} kg',
          lastWeekVal: '${stats['lastWeekVolume']!.toStringAsFixed(0)} kg',
          thisWeekRaw: stats['thisWeekVolume']!,
          lastWeekRaw: stats['lastWeekVolume']!,
          color: AppColors.info,
          changeLabel: 'hacim artisi',
        ),
        _buildComparisonChart(
          label1: 'Bu Hafta',
          value1: stats['thisWeekVolume']!,
          label2: 'Gecen Hafta',
          value2: stats['lastWeekVolume']!,
          color: AppColors.info,
          unit: 'kg',
        ),
        _buildOverviewCard(
          title: 'Antrenman Sayisi',
          thisWeekVal: '${stats['thisWeekCount']!.toInt()} Seans',
          lastWeekVal: '${stats['lastWeekCount']!.toInt()} Seans',
          thisWeekRaw: stats['thisWeekCount']!,
          lastWeekRaw: stats['lastWeekCount']!,
          color: AppColors.info,
          changeLabel: 'seans',
        ),
      ],
    );
  }

  Widget _buildLanguageAnalytics() {
    final stats = _computeLanguageStats();
    return ListView(
      children: [
        _buildOverviewCard(
          title: 'Dil Pratigi Suresi',
          thisWeekVal: '${stats['thisWeekMinutes']!.toInt()} dk',
          lastWeekVal: '${stats['lastWeekMinutes']!.toInt()} dk',
          thisWeekRaw: stats['thisWeekMinutes']!,
          lastWeekRaw: stats['lastWeekMinutes']!,
          color: AppColors.primary,
          changeLabel: 'sure',
        ),
        _buildComparisonChart(
          label1: 'Bu Hafta',
          value1: stats['thisWeekMinutes']!,
          label2: 'Gecen Hafta',
          value2: stats['lastWeekMinutes']!,
          color: AppColors.primary,
          unit: 'dk',
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Row(
            children: [
              const Icon(Icons.style, color: AppColors.primary, size: 36),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Kelime Haznem',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${stats['totalVocab']!.toInt()} Kelime Aktif',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStudyAnalytics() {
    final stats = _computeStudyStats();
    return ListView(
      children: [
        _buildOverviewCard(
          title: 'Ders Calisma Suresi',
          thisWeekVal: '${stats['thisWeekMinutes']!.toInt()} dk',
          lastWeekVal: '${stats['lastWeekMinutes']!.toInt()} dk',
          thisWeekRaw: stats['thisWeekMinutes']!,
          lastWeekRaw: stats['lastWeekMinutes']!,
          color: AppColors.info,
          changeLabel: 'sure',
        ),
        _buildComparisonChart(
          label1: 'Bu Hafta',
          value1: stats['thisWeekMinutes']!,
          label2: 'Gecen Hafta',
          value2: stats['lastWeekMinutes']!,
          color: AppColors.info,
          unit: 'dk',
        ),
        _buildOverviewCard(
          title: 'Cozulen Soru Sayisi',
          thisWeekVal: '${stats['thisWeekQuestions']!.toInt()} Soru',
          lastWeekVal: '${stats['lastWeekQuestions']!.toInt()} Soru',
          thisWeekRaw: stats['thisWeekQuestions']!,
          lastWeekRaw: stats['lastWeekQuestions']!,
          color: AppColors.info,
          changeLabel: 'soru',
        ),
      ],
    );
  }

  Widget _buildHabitsAnalytics() {
    final stats = _computeHabitsStats();
    return ListView(
      children: [
        _buildOverviewCard(
          title: 'Aliskanlik Tamamlama Sayisi',
          thisWeekVal: '${stats['thisWeekChecks']!.toInt()} Kez',
          lastWeekVal: '${stats['lastWeekChecks']!.toInt()} Kez',
          thisWeekRaw: stats['thisWeekChecks']!,
          lastWeekRaw: stats['lastWeekChecks']!,
          color: const Color(0xFF8B5CF6),
          changeLabel: 'tekrar',
        ),
        _buildComparisonChart(
          label1: 'Bu Hafta',
          value1: stats['thisWeekChecks']!,
          label2: 'Gecen Hafta',
          value2: stats['lastWeekChecks']!,
          color: const Color(0xFF8B5CF6),
          unit: 'kez',
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Row(
            children: [
              const Icon(Icons.book, color: Color(0xFF8B5CF6), size: 36),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Okuma Listesi',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_dataStore.books.length} Aktif Kitap Okunuyor',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOtherAnalytics() {
    final stats = _computeOtherStats();
    return ListView(
      children: [
        _buildOverviewCard(
          title: 'Ozel Program Calisma Suresi',
          thisWeekVal: '${stats['thisWeekMinutes']!.toInt()} dk',
          lastWeekVal: '${stats['lastWeekMinutes']!.toInt()} dk',
          thisWeekRaw: stats['thisWeekMinutes']!,
          lastWeekRaw: stats['lastWeekMinutes']!,
          color: const Color(0xFFEC4899),
          changeLabel: 'sure',
        ),
        _buildComparisonChart(
          label1: 'Bu Hafta',
          value1: stats['thisWeekMinutes']!,
          label2: 'Gecen Hafta',
          value2: stats['lastWeekMinutes']!,
          color: const Color(0xFFEC4899),
          unit: 'dk',
        ),
      ],
    );
  }
}
