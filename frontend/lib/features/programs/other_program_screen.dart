import '../../core/theme/app_colors.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class OtherProgramScreen extends StatefulWidget {
  const OtherProgramScreen({super.key});

  @override
  State<OtherProgramScreen> createState() => _OtherProgramScreenState();
}

class _OtherProgramScreenState extends State<OtherProgramScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Custom Program Settings
  String _programTitle = 'Özel Programım';
  IconData _programIcon = Icons.star;
  Color _programColor = const Color(0xFFEC4899);

  // Daily Tasks Checklist
  List<Map<String, dynamic>> _customTasks = [];

  // Progress Logs
  List<Map<String, dynamic>> _otherLogs = [];

  // Controllers
  final _titleEditingController = TextEditingController();
  final _taskNameController = TextEditingController();
  final _logActivityController = TextEditingController();
  final _logDurationController = TextEditingController();
  final _logNotesController = TextEditingController();

  final List<IconData> _availableIcons = [
    Icons.star,
    Icons.music_note,
    Icons.attach_money,
    Icons.code,
    Icons.brush,
    Icons.restaurant,
    Icons.business_center,
    Icons.home_repair_service,
    Icons.directions_car,
    Icons.flight,
  ];

  final List<Color> _availableColors = [
    const Color(0xFFEC4899), // Pink
    AppColors.info, // Blue
    AppColors.primary, // Green
    AppColors.warning, // Orange
    const Color(0xFF8B5CF6), // Purple
    const Color(0xFFEF4444), // Red
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleEditingController.dispose();
    _taskNameController.dispose();
    _logActivityController.dispose();
    _logDurationController.dispose();
    _logNotesController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _programTitle = prefs.getString('other_title') ?? 'Özel Programım';
      final iconCode = prefs.getInt('other_icon_code');
      if (iconCode != null) {
        _programIcon = IconData(iconCode, fontFamily: 'MaterialIcons');
      }
      final colorVal = prefs.getInt('other_color_val');
      if (colorVal != null) {
        _programColor = Color(colorVal);
      }

      // Load tasks
      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final lastCheckedDate = prefs.getString('other_last_date') ?? '';

      final tasksRaw = prefs.getString('other_tasks') ?? '[]';
      _customTasks = List<Map<String, dynamic>>.from(json.decode(tasksRaw));

      // Reset tasks checked state if date has changed
      if (lastCheckedDate != todayStr) {
        for (var task in _customTasks) {
          task['completed'] = false;
        }
      }

      if (_customTasks.isEmpty) {
        _customTasks = [
          {'id': '1', 'name': 'Günlük Rutin Başlangıcı', 'completed': false},
          {'id': '2', 'name': '1 Saat Pratik Yap', 'completed': false},
        ];
      }

      // Load logs
      final logsRaw = prefs.getString('other_logs') ?? '[]';
      _otherLogs = List<Map<String, dynamic>>.from(json.decode(logsRaw));
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('other_title', _programTitle);
    await prefs.setInt('other_icon_code', _programIcon.codePoint);
    await prefs.setInt('other_color_val', _programColor.value);
  }

  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    await prefs.setString('other_last_date', todayStr);
    await prefs.setString('other_tasks', json.encode(_customTasks));
  }

  Future<void> _saveLogs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('other_logs', json.encode(_otherLogs));
  }

  void _showConfigureDialog() {
    _titleEditingController.text = _programTitle;
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                'Programı Özelleştir',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _titleEditingController,
                      decoration: const InputDecoration(
                        labelText: 'Program Başlığı',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Simge Seçin',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _availableIcons.map((icon) {
                        final isSelected = _programIcon == icon;
                        return GestureDetector(
                          onTap: () {
                            setDialogState(() {
                              _programIcon = icon;
                            });
                            setState(() {});
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? _programColor.withValues(alpha: 0.2)
                                  : Colors.transparent,
                              border: Border.all(
                                color: isSelected
                                    ? _programColor
                                    : Colors.grey.shade300,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              icon,
                              color: isSelected ? _programColor : Colors.grey,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Tema Rengi Seçin',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _availableColors.map((color) {
                        final isSelected = _programColor == color;
                        return GestureDetector(
                          onTap: () {
                            setDialogState(() {
                              _programColor = color;
                            });
                            setState(() {});
                          },
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: isSelected
                                  ? Border.all(color: Colors.white, width: 3)
                                  : null,
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.3),
                                        blurRadius: 4,
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'İptal',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _programTitle = _titleEditingController.text.trim();
                    });
                    _saveSettings();
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _programColor,
                  ),
                  child: const Text(
                    'Kaydet',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _addTask(String name) {
    if (name.trim().isEmpty) return;
    setState(() {
      _customTasks.add({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'name': name.trim(),
        'completed': false,
      });
      _taskNameController.clear();
    });
    _saveTasks();
  }

  void _deleteTask(int index) {
    setState(() {
      _customTasks.removeAt(index);
    });
    _saveTasks();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          _programTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(
          color: Theme.of(context).colorScheme.onSurface,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            color: _programColor,
            onPressed: _showConfigureDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Stat Bar Card
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_programColor, _programColor.withValues(alpha: 0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: _programColor.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Colors.white24,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(_programIcon, size: 36, color: Colors.white),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _programTitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Kişisel hedeflerinize ve ilgi alanlarınıza özel esnek takip programı.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Tab Bar
          TabBar(
            controller: _tabController,
            labelColor: _programColor,
            unselectedLabelColor: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.5),
            indicatorColor: _programColor,
            indicatorWeight: 3,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
            tabs: const [
              Tab(text: 'Yapılacaklar'),
              Tab(text: 'İlerleme Günlüğü'),
            ],
          ),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildTasksTab(), _buildLogsTab()],
            ),
          ),
        ],
      ),
    );
  }

  // --- TASKS TAB ---
  Widget _buildTasksTab() {
    return Column(
      children: [
        // Quick add task
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _taskNameController,
                  decoration: const InputDecoration(
                    hintText: 'Yeni görev / hedef ekleyin...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () => _addTask(_taskNameController.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _programColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Icon(Icons.add, color: Colors.white),
              ),
            ],
          ),
        ),

        // List of tasks
        Expanded(
          child: _customTasks.isEmpty
              ? Center(
                  child: Text(
                    'Henüz görev eklenmedi.',
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _customTasks.length,
                  itemBuilder: (context, index) {
                    final task = _customTasks[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(context).dividerColor,
                        ),
                      ),
                      child: CheckboxListTile(
                        value: task['completed'] ?? false,
                        onChanged: (val) {
                          setState(() {
                            _customTasks[index]['completed'] = val ?? false;
                          });
                          _saveTasks();
                        },
                        activeColor: _programColor,
                        title: Text(
                          task['name'] ?? '',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            decoration: (task['completed'] ?? false)
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                            color: (task['completed'] ?? false)
                                ? Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withValues(alpha: 0.5)
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        secondary: GestureDetector(
                          onTap: () => _deleteTask(index),
                          child: const Icon(
                            Icons.close,
                            color: Colors.redAccent,
                            size: 20,
                          ),
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // --- LOGS TAB ---
  Widget _buildLogsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'İlerleme Notları',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Çalışmalarınızı, başarılarınızı ve diğer notlarınızı süreyle kaydedin.',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 20),

          // Log entry form
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Column(
              children: [
                TextField(
                  controller: _logActivityController,
                  decoration: const InputDecoration(
                    labelText: 'Yapılan Çalışma',
                    border: OutlineInputBorder(),
                    hintText: 'e.g. 2 saat gitar çalındı, 3 çizim yapıldı.',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _logDurationController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Süre (Dakika)',
                    border: OutlineInputBorder(),
                    hintText: 'e.g. 60',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _logNotesController,
                  decoration: const InputDecoration(
                    labelText: 'Detaylar / Notlar',
                    border: OutlineInputBorder(),
                    hintText: 'Bu seansa ait notlarınız...',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    if (_logActivityController.text.isNotEmpty &&
                        _logDurationController.text.isNotEmpty) {
                      setState(() {
                        _otherLogs.insert(0, {
                          'date': DateFormat(
                            'dd.MM.yyyy HH:mm',
                          ).format(DateTime.now()),
                          'activity': _logActivityController.text.trim(),
                          'duration':
                              int.tryParse(_logDurationController.text) ?? 30,
                          'note': _logNotesController.text.trim(),
                        });
                        _logActivityController.clear();
                        _logDurationController.clear();
                        _logNotesController.clear();
                      });
                      _saveLogs();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _programColor,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Günlüğe Kaydet',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          const Text(
            'Geçmiş Günlüklerim',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          _otherLogs.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24.0),
                  child: Center(
                    child: Text(
                      'Henüz günlük kaydedilmedi.',
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _otherLogs.length,
                  itemBuilder: (context, index) {
                    final log = _otherLogs[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(context).dividerColor,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                log['date'] ?? '',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withValues(alpha: 0.5),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _otherLogs.removeAt(index);
                                  });
                                  _saveLogs();
                                },
                                child: const Icon(
                                  Icons.close,
                                  size: 18,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            log['activity'] ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Süre: ${log['duration']} Dakika',
                            style: TextStyle(
                              color: _programColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          if (log['note'] != null &&
                              log['note'].toString().isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).scaffoldBackgroundColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                log['note'],
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }
}
