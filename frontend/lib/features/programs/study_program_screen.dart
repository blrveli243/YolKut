import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class StudyProgramScreen extends StatefulWidget {
  const StudyProgramScreen({Key? key}) : super(key: key);

  @override
  State<StudyProgramScreen> createState() => _StudyProgramScreenState();
}

class _StudyProgramScreenState extends State<StudyProgramScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Study Goals Status
  bool _goalHours = false;
  bool _goalQuestions = false;
  bool _goalReview = false;
  bool _goalReading = false;

  // Pomodoro State
  Timer? _timer;
  int _secondsRemaining = 25 * 60;
  bool _isRunning = false;
  bool _isBreak = false;
  int _completedPomodoros = 0;

  // Study Session Logs
  List<Map<String, dynamic>> _studyLogs = [];

  // Controllers
  final _subjectController = TextEditingController();
  final _durationController = TextEditingController();
  final _questionsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tabController.dispose();
    _subjectController.dispose();
    _durationController.dispose();
    _questionsController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final lastDate = prefs.getString('study_last_date') ?? '';

      if (lastDate != todayStr) {
        _goalHours = false;
        _goalQuestions = false;
        _goalReview = false;
        _goalReading = false;
      } else {
        _goalHours = prefs.getBool('study_goal_hours') ?? false;
        _goalQuestions = prefs.getBool('study_goal_questions') ?? false;
        _goalReview = prefs.getBool('study_goal_review') ?? false;
        _goalReading = prefs.getBool('study_goal_reading') ?? false;
      }

      _completedPomodoros = prefs.getInt('study_completed_pomodoros') ?? 0;

      final logsRaw = prefs.getString('study_logs') ?? '[]';
      _studyLogs = List<Map<String, dynamic>>.from(json.decode(logsRaw));
    });
  }

  Future<void> _saveGoals() async {
    final prefs = await SharedPreferences.getInstance();
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    await prefs.setString('study_last_date', todayStr);
    await prefs.setBool('study_goal_hours', _goalHours);
    await prefs.setBool('study_goal_questions', _goalQuestions);
    await prefs.setBool('study_goal_review', _goalReview);
    await prefs.setBool('study_goal_reading', _goalReading);
  }

  Future<void> _saveLogs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('study_logs', json.encode(_studyLogs));
  }

  Future<void> _savePomodoroCount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('study_completed_pomodoros', _completedPomodoros);
  }

  // --- Pomodoro Logic ---
  void _toggleTimer() {
    if (_isRunning) {
      _timer?.cancel();
      setState(() {
        _isRunning = false;
      });
    } else {
      setState(() {
        _isRunning = true;
      });
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_secondsRemaining > 0) {
          setState(() {
            _secondsRemaining--;
          });
        } else {
          _timer?.cancel();
          _handleTimerCompletion();
        }
      });
    }
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _secondsRemaining = _isBreak ? 5 * 60 : 25 * 60;
    });
  }

  void _handleTimerCompletion() {
    setState(() {
      _isRunning = false;
      if (!_isBreak) {
        // Pomodoro Work Completed
        _completedPomodoros++;
        _savePomodoroCount();
        _isBreak = true;
        _secondsRemaining = 5 * 60; // 5 min break
        // Add to study logs automatically
        _studyLogs.insert(0, {
          'date': DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now()),
          'subject': 'Pomodoro Oturumu',
          'duration': 25,
          'questions': 0,
        });
        _saveLogs();
      } else {
        // Break Completed
        _isBreak = false;
        _secondsRemaining = 25 * 60; // 25 min work
      }
    });
    
    // Play sound / Show dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_isBreak ? 'Tebrikler!' : 'Mola Bitti!'),
        content: Text(_isBreak 
            ? 'Bir Pomodoro seansını tamamladınız. Şimdi 5 dakikalık mola zamanı!' 
            : 'Molanız bitti. Yeni odaklanma seansına başlamaya hazır mısınız?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  String _formatTime(int totalSeconds) {
    final minutes = (totalSeconds / 60).floor().toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Ders / Çalışma Asistanı', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.onSurface),
      ),
      body: Column(
        children: [
          // Stat Bar Card
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  )
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildHeaderStat(
                    icon: Icons.timer,
                    label: 'Toplam Süre',
                    value: '${_getTotalStudyMinutes()} dk',
                  ),
                  _buildHeaderStat(
                    icon: Icons.task_alt,
                    label: 'Çözülen Soru',
                    value: '${_getTotalQuestions()}',
                  ),
                  _buildHeaderStat(
                    icon: Icons.hourglass_empty,
                    label: 'Pomodoro',
                    value: '$_completedPomodoros adet',
                  ),
                ],
              ),
            ),
          ),

          // Tab Bar
          TabBar(
            controller: _tabController,
            labelColor: const Color(0xFF3B82F6),
            unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            indicatorColor: const Color(0xFF3B82F6),
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            tabs: const [
              Tab(text: 'Hedefler'),
              Tab(text: 'Pomodoro'),
              Tab(text: 'Çalışma Günlüğü'),
            ],
          ),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildGoalsTab(),
                _buildPomodoroTab(),
                _buildLogsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStat({required IconData icon, required String label, required String value}) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11),
        ),
      ],
    );
  }

  int _getTotalStudyMinutes() {
    int total = 0;
    for (var log in _studyLogs) {
      total += (log['duration'] as int? ?? 0);
    }
    return total;
  }

  int _getTotalQuestions() {
    int total = 0;
    for (var log in _studyLogs) {
      total += (log['questions'] as int? ?? 0);
    }
    return total;
  }

  // --- GOALS TAB ---
  Widget _buildGoalsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Günlük Ders Çalışma Hedefleri', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text(
          'Günü verimli geçirmek için çalışma programınızı kontrol edin.',
          style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
        ),
        const SizedBox(height: 20),
        _buildGoalTile(
          title: '3 Saat Ders Çalış',
          subtitle: 'Günde en az 3 saat (180 dakika) aktif çalışmayı hedefleyin.',
          icon: Icons.schedule,
          color: Colors.blue,
          value: _goalHours,
          onChanged: (val) {
            setState(() => _goalHours = val ?? false);
            _saveGoals();
          },
        ),
        _buildGoalTile(
          title: 'Soru Çözümü',
          subtitle: 'Günde en az 50 yeni test veya pratik sorusu çözün.',
          icon: Icons.quiz,
          color: Colors.amber,
          value: _goalQuestions,
          onChanged: (val) {
            setState(() => _goalQuestions = val ?? false);
            _saveGoals();
          },
        ),
        _buildGoalTile(
          title: 'Konu Tekrarı',
          subtitle: 'Bugün çalıştığın önemli konuları 15 dakika gözden geçir.',
          icon: Icons.auto_stories,
          color: Colors.purple,
          value: _goalReview,
          onChanged: (val) {
            setState(() => _goalReview = val ?? false);
            _saveGoals();
          },
        ),
        _buildGoalTile(
          title: 'Akademik Okuma',
          subtitle: 'Ders kitaplarından veya makalelerden 10 sayfa oku.',
          icon: Icons.menu_book,
          color: Colors.redAccent,
          value: _goalReading,
          onChanged: (val) {
            setState(() => _goalReading = val ?? false);
            _saveGoals();
          },
        ),
      ],
    );
  }

  Widget _buildGoalTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: CheckboxListTile(
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF3B82F6),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(subtitle, style: const TextStyle(fontSize: 13)),
        ),
        secondary: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        controlAffinity: ListTileControlAffinity.trailing,
      ),
    );
  }

  // --- POMODORO TAB ---
  Widget _buildPomodoroTab() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Timer Face Circle
            Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).cardColor,
                border: Border.all(
                  color: _isBreak ? const Color(0xFF10B981) : const Color(0xFF3B82F6),
                  width: 8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (_isBreak ? const Color(0xFF10B981) : const Color(0xFF3B82F6)).withOpacity(0.15),
                    blurRadius: 20,
                  )
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _isBreak ? 'Mola' : 'Odaklanma',
                    style: TextStyle(
                      fontSize: 16, 
                      fontWeight: FontWeight.w600,
                      color: _isBreak ? const Color(0xFF10B981) : const Color(0xFF3B82F6),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _formatTime(_secondsRemaining),
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _toggleTimer,
                  icon: Icon(_isRunning ? Icons.pause : Icons.play_arrow, color: Colors.white),
                  label: Text(_isRunning ? 'Duraklat' : 'Başlat', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isBreak ? const Color(0xFF10B981) : const Color(0xFF3B82F6),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  onPressed: _resetTimer,
                  icon: const Icon(Icons.refresh),
                  iconSize: 32,
                  color: Colors.grey,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- LOGS TAB ---
  Widget _buildLogsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Çalıştığım Konular', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(
            'Her çalışma seansını kaydederek gelişiminizi görün.',
            style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
          ),
          const SizedBox(height: 20),

          // Log creation form
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
                  controller: _subjectController,
                  decoration: const InputDecoration(
                    labelText: 'Ders / Konu Başlığı',
                    border: OutlineInputBorder(),
                    hintText: 'e.g. Matematik - Türev integral',
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _durationController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Süre (Dakika)',
                          border: OutlineInputBorder(),
                          hintText: 'e.g. 45',
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _questionsController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Çözülen Soru',
                          border: OutlineInputBorder(),
                          hintText: 'e.g. 20',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    if (_subjectController.text.isNotEmpty && _durationController.text.isNotEmpty) {
                      setState(() {
                        _studyLogs.insert(0, {
                          'date': DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now()),
                          'subject': _subjectController.text.trim(),
                          'duration': int.tryParse(_durationController.text) ?? 30,
                          'questions': int.tryParse(_questionsController.text) ?? 0,
                        });
                        _subjectController.clear();
                        _durationController.clear();
                        _questionsController.clear();
                      });
                      _saveLogs();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Çalışmayı Kaydet', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          const Text('Geçmiş Çalışmalarım', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          _studyLogs.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24.0),
                  child: Center(
                    child: Text(
                      'Henüz çalışma seansı kaydedilmedi.',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4)),
                    ),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _studyLogs.length,
                  itemBuilder: (context, index) {
                    final log = _studyLogs[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Theme.of(context).dividerColor),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3B82F6).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.bookmark, color: Color(0xFF3B82F6)),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  log['subject'] ?? '',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${log['duration']} Dakika | ${log['questions']} Soru',
                                  style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                log['date']?.toString().split(' ')[0] ?? '',
                                style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4)),
                              ),
                              const SizedBox(height: 6),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _studyLogs.removeAt(index);
                                  });
                                  _saveLogs();
                                },
                                child: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                              )
                            ],
                          ),
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
