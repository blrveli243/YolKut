import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'profile_provider.dart';
import '../../core/theme/app_theme_provider.dart';
import '../../core/api_client.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  double _height = 170.0;
  double _weight = 70.0;
  int _age = 25;
  String? _gender;
  String? _photoUrl;

  double? _targetWeight;
  int? _targetDays;
  String? _dailyGoal;
  double _activityLevel = 1.2;

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();

  bool _isInitialized = false;
  static const Color _themeColor = Color(0xFF0A84FF); // Elegant iOS Blue

  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _ageController = TextEditingController();
  final _targetWeightController = TextEditingController();
  final _targetDaysController = TextEditingController();

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _ageController.dispose();
    _targetWeightController.dispose();
    _targetDaysController.dispose();
    super.dispose();
  }

  void _initFields(Map<String, dynamic> data) {
    if (_isInitialized) return;
    _height = (data['height'] ?? 170.0).toDouble();
    _weight = (data['weight'] ?? 70.0).toDouble();
    _age = data['age'] ?? 25;
    _gender = data['gender'];
    _photoUrl = data['photoUrl'];
    _firstNameController.text = data['firstName'] ?? '';
    _lastNameController.text = data['lastName'] ?? '';
    _heightController.text = _height.toStringAsFixed(1);
    _weightController.text = _weight.toStringAsFixed(1);
    _ageController.text = _age.toString();

    _targetWeight = data['targetWeight']?.toDouble();
    _targetDays = data['targetDays'];
    _dailyGoal = data['dailyGoal'];
    _activityLevel = (data['activityLevel'] ?? 1.2).toDouble();

    if (_targetWeight != null) _targetWeightController.text = _targetWeight!.toStringAsFixed(1);
    if (_targetDays != null) _targetDaysController.text = _targetDays.toString();
    _isInitialized = true;
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      // Optimizm (kullanıcıya hemen göstermek için yerel pathi kullan)
      setState(() {
        _photoUrl = image.path;
      });

      try {
        await ref.read(profileProvider.notifier).uploadPhoto(image.path);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Fotoğraf sunucuya yüklenemedi ancak yerel olarak eklendi.',
              ),
              backgroundColor: _themeColor,
            ),
          );
        }
      }
    }
  }

  double _calculateBMR() {
    if (_gender == null || _gender!.isEmpty) return 2000.0;
    if (_gender!.toLowerCase() == 'erkek') {
      return 88.362 + (13.397 * _weight) + (4.799 * _height) - (5.677 * _age);
    } else {
      return 447.593 + (9.247 * _weight) + (3.098 * _height) - (4.330 * _age);
    }
  }

  Future<void> _saveProfile() async {
    final data = {
      'height': _height,
      'weight': _weight,
      'age': _age,
      if (_gender != null) 'gender': _gender,
      if (_firstNameController.text.isNotEmpty)
        'firstName': _firstNameController.text,
      if (_lastNameController.text.isNotEmpty)
        'lastName': _lastNameController.text,
      if (_targetWeight != null) 'targetWeight': _targetWeight,
      if (_targetDays != null) 'targetDays': _targetDays,
      if (_dailyGoal != null) 'dailyGoal': _dailyGoal,
      'activityLevel': _activityLevel,
    };

    await ref.read(profileProvider.notifier).updateProfile(data);

    if (mounted && ref.read(profileProvider).hasError == false) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Profil Başarıyla Güncellendi! ✨',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: _themeColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: TextField(
        controller: controller,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontSize: 16,
        ),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: _themeColor),
          labelText: label,
          labelStyle: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildNumberInput(
    String label,
    TextEditingController controller,
    String suffix,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              fontSize: 16,
            ),
          ),
          Row(
            children: [
              SizedBox(
                width: 80,
                child: TextField(
                  controller: controller,
                  textInputAction: TextInputAction.done,
                  onEditingComplete: () => FocusScope.of(context).unfocus(),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: _themeColor,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (val) {
                    final parsed = double.tryParse(val.replaceAll(',', '.'));
                    if (parsed != null) {
                      setState(() {
                        if (label == 'Boy') _height = parsed;
                        if (label == 'Kilo') _weight = parsed;
                        if (label == 'Yaş') _age = parsed.toInt();
                        if (label == 'Hedef Kilo') _targetWeight = parsed;
                        if (label == 'Hedef Süre') _targetDays = parsed.toInt();
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Text(
                suffix,
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.5),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileProvider);
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Profilim',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(
          color: Theme.of(context).colorScheme.onSurface,
        ),
        actions: [
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode : Icons.dark_mode,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            onPressed: () {
              ref.read(themeProvider.notifier).toggleTheme();
            },
          ),
        ],
      ),
      body: profileState.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Colors.blueAccent),
        ),
        error: (err, stack) => Center(
          child: Text(
            'Hata oluştu: $err',
            style: const TextStyle(color: Colors.redAccent),
          ),
        ),
        skipLoadingOnReload: true,
        data: (profile) {
          _initFields(profile);

          return GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: GestureDetector(
                    onTap: profileState.isLoading ? null : _pickImage,
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 70,
                          backgroundColor: Theme.of(
                            context,
                          ).dividerColor.withOpacity(0.2),
                          backgroundImage:
                              _photoUrl != null && _photoUrl!.isNotEmpty
                              ? (_photoUrl!.startsWith('http')
                                    ? NetworkImage(_photoUrl!) as ImageProvider
                                    : (_photoUrl!.startsWith('/uploads')
                                          ? NetworkImage(
                                                  '${apiClient.dio.options.baseUrl}$_photoUrl',
                                                )
                                                as ImageProvider
                                          : FileImage(File(_photoUrl!))
                                                as ImageProvider))
                              : null,
                          child: _photoUrl == null || _photoUrl!.isEmpty
                              ? Icon(
                                  Icons.person,
                                  size: 80,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.5),
                                )
                              : null,
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _themeColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Theme.of(context).scaffoldBackgroundColor,
                              width: 3,
                            ),
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  _firstNameController.text.isNotEmpty
                      ? '${_firstNameController.text} ${_lastNameController.text}'
                            .trim()
                      : (profile['email'] ?? 'Kullanıcı'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Theme.of(context).colorScheme.onSurface,
                    letterSpacing: 0.5,
                  ),
                ),
                if (_firstNameController.text.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      profile['email'] ?? '',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ),

                const SizedBox(height: 40),

                Text(
                  'Kişisel Bilgiler',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        _firstNameController,
                        'Ad',
                        Icons.person_outline,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        _lastNameController,
                        'Soyad',
                        Icons.badge_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                Text(
                  'Fiziksel Özellikler',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                _buildNumberInput('Boy', _heightController, 'cm'),
                _buildNumberInput('Kilo', _weightController, 'kg'),
                _buildNumberInput('Yaş', _ageController, 'yaş'),
                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Cinsiyet',
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: ['Erkek', 'Kadın'].map((g) {
                          final isSelected = _gender == g;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _gender = g;
                                });
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? _themeColor.withOpacity(0.15)
                                      : Theme.of(
                                          context,
                                        ).dividerColor.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? _themeColor
                                        : Colors.transparent,
                                    width: 1.5,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  g,
                                  style: TextStyle(
                                    color: isSelected
                                        ? _themeColor
                                        : Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withOpacity(0.5),
                                    fontSize: 16,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                ClipRRect(
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
                            Theme.of(context).cardColor,
                            Theme.of(context).cardColor.withOpacity(0.8),
                          ],
                        ),
                        border: Border.all(
                          color: Theme.of(context).dividerColor,
                          width: 1.0,
                        ),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Column(
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.local_fire_department_rounded,
                                color: _themeColor,
                                size: 28,
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Bazal Metabolizma (BMR)',
                                style: TextStyle(
                                  color: _themeColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Flexible(
                                child: Text(
                                  'Vücudunuzun dinlenirken yaktığı enerji',
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface.withOpacity(0.5),
                                    fontSize: 12,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                              Text(
                                '${_calculateBMR().round()} kcal',
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // YENİ HEDEFLERİM KARTI
                Text(
                  'Hedeflerim & Aktivite',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                _buildNumberInput('Hedef Kilo', _targetWeightController, 'kg'),
                _buildNumberInput('Hedef Süre', _targetDaysController, 'gün'),
                const SizedBox(height: 12),

                // Amacımız (dailyGoal)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Ana Hedefiniz',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: ['Zayıflamak', 'Kilo Almak', 'Kaslanmak'].map((g) {
                          final isSelected = _dailyGoal == g;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _dailyGoal = g;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected ? _themeColor.withOpacity(0.15) : Theme.of(context).dividerColor.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: isSelected ? _themeColor : Colors.transparent, width: 1.5),
                              ),
                              child: Text(
                                g,
                                style: TextStyle(
                                  color: isSelected ? _themeColor : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                  fontSize: 14,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Aktivite Seviyesi
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Günlük Aktivite Seviyesi',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonHideUnderline(
                        child: DropdownButton<double>(
                          value: [1.2, 1.375, 1.55, 1.725].contains(_activityLevel) ? _activityLevel : 1.2,
                          isExpanded: true,
                          dropdownColor: Theme.of(context).cardColor,
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 14, fontWeight: FontWeight.bold),
                          items: const [
                            DropdownMenuItem(value: 1.2, child: Text('Masa Başı / Sedanter (Çok Az)')),
                            DropdownMenuItem(value: 1.375, child: Text('Az Hareketli (Hafif Egzersiz)')),
                            DropdownMenuItem(value: 1.55, child: Text('Orta Hareketli (3-5 gün spor)')),
                            DropdownMenuItem(value: 1.725, child: Text('Çok Hareketli (Ağır spor)')),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _activityLevel = val;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: _themeColor,
                    boxShadow: [
                      BoxShadow(
                        color: _themeColor.withOpacity(0.4),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: profileState.isLoading ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: profileState.isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Değişiklikleri Kaydet',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ));
        },
      ),
    );
  }
}
