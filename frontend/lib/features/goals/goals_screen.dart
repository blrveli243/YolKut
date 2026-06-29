import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../profile/profile_provider.dart';
import 'goals_provider.dart';
import 'create_goal_screen.dart';
import 'wishlist_sheet.dart';

class GoalsScreen extends ConsumerStatefulWidget {
  const GoalsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends ConsumerState<GoalsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedGoal = 'Formu Koru'; // 'Kilo Ver', 'Formu Koru', 'Kas Yap'
  double _activityLevel = 1.2;
  double _targetWeight = 70.0;
  int _targetDays = 30;
  double _currentWeight = 70.0;

  final _targetWeightController = TextEditingController();
  final _targetDaysController = TextEditingController();

  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _targetWeightController.dispose();
    _targetDaysController.dispose();
    super.dispose();
  }

  void _initFields(Map<String, dynamic> data) {
    if (_isInitialized) return;
    _currentWeight = (data['weight'] ?? 70.0).toDouble();
    _activityLevel = (data['activityLevel'] ?? 1.2).toDouble();
    _targetWeight = (data['targetWeight'] ?? _currentWeight).toDouble();
    _targetDays = data['targetDays'] ?? 30;
    
    if (_targetWeight < _currentWeight) {
      _selectedGoal = 'Kilo Ver';
    } else if (_targetWeight > _currentWeight) {
      _selectedGoal = 'Kas Yap';
    } else {
      _selectedGoal = 'Formu Koru';
    }
    
    _targetWeightController.text = _targetWeight.toStringAsFixed(1);
    _targetDaysController.text = _targetDays.toString();
    _isInitialized = true;
  }

  Future<void> _saveGoals() async {
    final data = {
      'dailyGoal': _selectedGoal,
      'activityLevel': _activityLevel,
      'targetWeight': _selectedGoal == 'Formu Koru' ? _currentWeight : _targetWeight,
      'targetDays': _targetDays,
    };
    
    await ref.read(profileProvider.notifier).updateProfile(data);
    
    if (mounted && ref.read(profileProvider).hasError == false) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Hedefler ve Plan Başarıyla Güncellendi! 🚀', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFF32D74B),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Widget _buildGoalSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _goalCard('Kilo Ver', Icons.trending_down, const Color(0xFFFF375F)),
        const SizedBox(width: 12),
        _goalCard('Formu Koru', Icons.monitor_weight_outlined, const Color(0xFF0A84FF)),
        const SizedBox(width: 12),
        _goalCard('Kas Yap', Icons.trending_up, const Color(0xFF5E5CE6)),
      ],
    );
  }

  Widget _goalCard(String title, IconData icon, Color color) {
    final isSelected = _selectedGoal == title;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedGoal = title;
            if (title == 'Kilo Ver' && _targetWeight >= _currentWeight) {
              _targetWeight = _currentWeight - 2.0; // Default deficit
            } else if (title == 'Kas Yap' && _targetWeight <= _currentWeight) {
              _targetWeight = _currentWeight + 2.0; // Default surplus
            } else if (title == 'Formu Koru') {
              _targetWeight = _currentWeight;
            }
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.15) : Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? color : Theme.of(context).dividerColor,
              width: 2,
            ),
            boxShadow: isSelected ? [
              BoxShadow(color: color.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))
            ] : [],
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? color : Theme.of(context).colorScheme.onSurface.withOpacity(0.5), size: 32),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityLevelSegmented() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Aktivite Seviyesi', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Row(
            children: [
              _buildActivityOption(1.2, Icons.chair_alt, 'Hareketsiz'),
              _buildActivityOption(1.375, Icons.directions_walk, 'Az'),
              _buildActivityOption(1.55, Icons.directions_run, 'Orta'),
              _buildActivityOption(1.725, Icons.fitness_center, 'Çok'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivityOption(double level, IconData icon, String label) {
    final isSelected = _activityLevel == level;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() { _activityLevel = level; });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0A84FF) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface.withOpacity(0.5), size: 24),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumberInput(String label, TextEditingController controller, String suffix, Color themeColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), fontSize: 16)),
          Row(
            children: [
              SizedBox(
                width: 80,
                child: TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  textAlign: TextAlign.right,
                  style: TextStyle(color: themeColor, fontSize: 24, fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
                  onChanged: (val) {
                    final parsed = double.tryParse(val.replaceAll(',', '.'));
                    if (parsed != null) {
                      setState(() {
                        if (label == 'Hedef Kilo') _targetWeight = parsed;
                        if (label == 'Hedef Süre') _targetDays = parsed.toInt();
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Text(suffix, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildSimulationCard(Map<String, dynamic> profile) {
    final height = (profile['height'] ?? 170.0).toDouble();
    final age = profile['age'] ?? 25;
    final gender = profile['gender'] ?? 'erkek';

    double bmr = 2000.0;
    if (gender.toString().toLowerCase() == 'erkek') {
      bmr = 88.362 + (13.397 * _currentWeight) + (4.799 * height) - (5.677 * age);
    } else {
      bmr = 447.593 + (9.247 * _currentWeight) + (3.098 * height) - (4.330 * age);
    }

    final tdee = bmr * _activityLevel;
    final weightDiff = _currentWeight - (_selectedGoal == 'Formu Koru' ? _currentWeight : _targetWeight);
    final totalCalorieDiff = weightDiff * 7700;
    final dailyDeficit = totalCalorieDiff / _targetDays;
    final targetCalories = (tdee - dailyDeficit).round();

    final isMale = gender.toString().toLowerCase() == 'erkek';
    final safeMin = isMale ? 1500 : 1200;
    final isUnsafe = targetCalories < safeMin;

    Color themeColor = const Color(0xFF0A84FF);
    String title = 'Mevcut Kiloyu Koru';
    String message = 'Bu hızla sağlığınızı riske atmadan planınızı uygulayabilirsiniz.';
    IconData icon = Icons.check_circle_outline;

    if (_selectedGoal != 'Formu Koru') {
      if (isUnsafe && weightDiff > 0) {
        themeColor = const Color(0xFFFF375F);
        title = 'Uyarı: Fazla Hızlı!';
        message = 'Hedefinize bu sürede ulaşmak için güvenli sınır ($safeMin kcal) altına düşmeniz gerekiyor. Lütfen hedefinizi veya süreyi uzatın.';
        icon = Icons.warning_amber_rounded;
      } else if (weightDiff > 0) {
        themeColor = const Color(0xFF32D74B);
        title = 'Sağlıklı Deficit (Açık)';
      } else {
        themeColor = const Color(0xFF5E5CE6);
        title = 'Sağlıklı Surplus (Fazla)';
      }
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                themeColor.withOpacity(0.2),
                Theme.of(context).brightness == Brightness.dark ? Colors.black.withOpacity(0.5) : Colors.white.withOpacity(0.5),
              ],
            ),
            border: Border.all(color: themeColor.withOpacity(0.3), width: 1.5),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(icon, color: themeColor, size: 28),
                  const SizedBox(width: 12),
                  Expanded(child: Text(title, style: TextStyle(color: themeColor, fontSize: 18, fontWeight: FontWeight.bold))),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Günlük Kalori Hedefi', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), fontSize: 14)),
                  Text(
                    isUnsafe && weightDiff > 0 ? 'Riskli' : '$targetCalories kcal',
                    style: TextStyle(color: isUnsafe && weightDiff > 0 ? const Color(0xFFFF375F) : Theme.of(context).colorScheme.onSurface, fontSize: 28, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
              if (isUnsafe && weightDiff > 0) ...[
                const SizedBox(height: 12),
                Text(message, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 13, height: 1.5)),
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomGoalsList() {
    final customGoalsState = ref.watch(customGoalsProvider);
    
    return customGoalsState.goals.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('Hata: $e', style: const TextStyle(color: Colors.red)),
      data: (goals) {
        if (goals.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Center(
              child: Text(
                'Henüz özel bir hedefiniz yok.\nSağ alt köşeden yeni bir hedef ekleyin!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), height: 1.5),
              ),
            ),
          );
        }

        return Column(
          children: goals.map((g) {
            final tasks = g['tasks'] as List<dynamic>? ?? [];
            final total = tasks.length;
            final completed = tasks.where((t) => t['isCompleted'] == true).length;
            final progress = total > 0 ? completed / total : 0.0;

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(g['title'], style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 18, fontWeight: FontWeight.bold)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0A84FF).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(g['category'], style: const TextStyle(color: Color(0xFF0A84FF), fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('İlerleme ($completed / $total görev)', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), fontSize: 14)),
                      Text('${(progress * 100).toInt()}%', style: const TextStyle(color: Color(0xFF32D74B), fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: const Color(0xFF2C2C2E),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF32D74B)),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildPhysicalTab(dynamic profile, AsyncValue profileState) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildGoalSelector(),
          
          const SizedBox(height: 32),
          
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return SizeTransition(sizeFactor: animation, child: FadeTransition(opacity: animation, child: child));
            },
            child: _selectedGoal == 'Formu Koru'
                ? const SizedBox.shrink()
                : Column(
                    key: const ValueKey('sliders'),
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildNumberInput('Hedef Kilo', _targetWeightController, 'kg', const Color(0xFF0A84FF)),
                      _buildNumberInput('Hedef Süre', _targetDaysController, 'gün', const Color(0xFF64D2FF)),
                      const SizedBox(height: 24),
                    ],
                  ),
          ),
          
          _buildActivityLevelSegmented(),
          
          const SizedBox(height: 40),
          _buildSimulationCard(profile),
          const SizedBox(height: 32),

          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: const Color(0xFF0A84FF),
            ),
            child: ElevatedButton(
              onPressed: profileState.isLoading ? null : _saveGoals,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 20),
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: profileState.isLoading 
                  ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Fiziksel Planı Güncelle', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildCustomTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildCustomGoalsList(),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Hedeflerim', style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_bag_outlined, color: Color(0xFF0A84FF)),
            tooltip: 'Alacaklarım & İsteklerim',
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const WishlistSheet(),
              );
            },
          ),
        ],
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.onSurface),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF32D74B),
          labelColor: Theme.of(context).colorScheme.onSurface,
          unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          tabs: const [
            Tab(text: 'Fiziksel Hedef'),
            Tab(text: 'Kişisel Hedefler'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          profileState.when(
            loading: () => const Center(child: CircularProgressIndicator(color: Colors.blueAccent)),
            error: (err, stack) => Center(child: Text('Hata: $err', style: const TextStyle(color: Colors.redAccent))),
            data: (profile) {
              _initFields(profile);
              return _buildPhysicalTab(profile, profileState);
            },
          ),
          _buildCustomTab(),
        ],
      ),
      floatingActionButton: _tabController.index == 1 ? FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateGoalScreen()));
        },
        backgroundColor: const Color(0xFF32D74B),
        icon: const Icon(Icons.add, color: Colors.black),
        label: const Text('Hedef Ekle', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ) : null,
    );
  }
}
