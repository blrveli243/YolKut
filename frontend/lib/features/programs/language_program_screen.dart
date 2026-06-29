import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class LanguageProgramScreen extends StatefulWidget {
  const LanguageProgramScreen({Key? key}) : super(key: key);

  @override
  State<LanguageProgramScreen> createState() => _LanguageProgramScreenState();
}

class _LanguageProgramScreenState extends State<LanguageProgramScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // State Variables
  String _targetLanguage = 'İngilizce';
  String _targetLanguageFlag = '';
  int _streak = 0;
  String _lastStudiedDate = '';
  
  // Daily Goals Status
  bool _goalVocab = false;
  bool _goalImmersion = false;
  bool _goalSentence = false;
  bool _goalShadowing = false;

  // Lists
  List<Map<String, dynamic>> _vocabList = [];
  List<Map<String, dynamic>> _journalLogs = [];
  List<Map<String, dynamic>> _sentenceLogs = [];

  // Controllers
  final _wordController = TextEditingController();
  final _meaningController = TextEditingController();
  final _sentenceController = TextEditingController();
  
  final _activityController = TextEditingController();
  final _durationController = TextEditingController();
  final _notesController = TextEditingController();
  
  final _sentenceMiningController = TextEditingController();

  final List<Map<String, String>> _languages = [
    {'name': 'İngilizce', 'flag': ''},
    {'name': 'Almanca', 'flag': ''},
    {'name': 'İspanyolca', 'flag': ''},
    {'name': 'Fransızca', 'flag': ''},
    {'name': 'İtalyanca', 'flag': ''},
    {'name': 'Japonca', 'flag': ''},
    {'name': 'Rusça', 'flag': ''},
    {'name': 'Arapça', 'flag': ''},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _wordController.dispose();
    _meaningController.dispose();
    _sentenceController.dispose();
    _activityController.dispose();
    _durationController.dispose();
    _notesController.dispose();
    _sentenceMiningController.dispose();
    super.dispose();
  }

  // Load data from SharedPreferences
  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _targetLanguage = prefs.getString('lang_target') ?? 'İngilizce';
      _targetLanguageFlag = prefs.getString('lang_target_flag') ?? '';
      _streak = prefs.getInt('lang_streak') ?? 0;
      _lastStudiedDate = prefs.getString('lang_last_studied') ?? '';

      // Check if day has changed to reset daily goals
      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      if (_lastStudiedDate != todayStr) {
        _goalVocab = false;
        _goalImmersion = false;
        _goalSentence = false;
        _goalShadowing = false;
      } else {
        _goalVocab = prefs.getBool('lang_goal_vocab') ?? false;
        _goalImmersion = prefs.getBool('lang_goal_immersion') ?? false;
        _goalSentence = prefs.getBool('lang_goal_sentence') ?? false;
        _goalShadowing = prefs.getBool('lang_goal_shadowing') ?? false;
      }

      // Load vocab list
      final vocabRaw = prefs.getString('lang_vocab_list') ?? '[]';
      _vocabList = List<Map<String, dynamic>>.from(json.decode(vocabRaw));

      // Load journal logs
      final journalRaw = prefs.getString('lang_journal_logs') ?? '[]';
      _journalLogs = List<Map<String, dynamic>>.from(json.decode(journalRaw));

      // Load sentence logs
      final sentenceRaw = prefs.getString('lang_sentence_logs') ?? '[]';
      _sentenceLogs = List<Map<String, dynamic>>.from(json.decode(sentenceRaw));
    });
    _checkStreakValidity();
  }

  // Save current status of daily goals & last studied date
  Future<void> _saveGoals() async {
    final prefs = await SharedPreferences.getInstance();
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    
    // Update streak if a study goal is done today and last study wasn't today
    if ((_goalVocab || _goalImmersion || _goalSentence || _goalShadowing) && _lastStudiedDate != todayStr) {
      // Check if yesterday was studied to increment, else set to 1
      final yesterdayStr = DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(const Duration(days: 1)));
      if (_lastStudiedDate == yesterdayStr) {
        _streak += 1;
      } else if (_streak == 0 || _lastStudiedDate != todayStr) {
        _streak = 1;
      }
      _lastStudiedDate = todayStr;
      await prefs.setInt('lang_streak', _streak);
      await prefs.setString('lang_last_studied', _lastStudiedDate);
    }

    await prefs.setBool('lang_goal_vocab', _goalVocab);
    await prefs.setBool('lang_goal_immersion', _goalImmersion);
    await prefs.setBool('lang_goal_sentence', _goalSentence);
    await prefs.setBool('lang_goal_shadowing', _goalShadowing);
  }

  // Check if streak is broken (more than 1 day skipped)
  void _checkStreakValidity() {
    if (_lastStudiedDate.isNotEmpty) {
      final lastDate = DateFormat('yyyy-MM-dd').parse(_lastStudiedDate);
      final diff = DateTime.now().difference(lastDate).inDays;
      if (diff > 1) {
        setState(() {
          _streak = 0;
        });
        SharedPreferences.getInstance().then((prefs) => prefs.setInt('lang_streak', 0));
      }
    }
  }

  // Save full vocabulary list
  Future<void> _saveVocabList() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lang_vocab_list', json.encode(_vocabList));
  }

  // Save full journal logs
  Future<void> _saveJournalLogs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lang_journal_logs', json.encode(_journalLogs));
  }

  // Save sentence logs
  Future<void> _saveSentenceLogs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lang_sentence_logs', json.encode(_sentenceLogs));
  }

  // Calculate overall daily completion rate
  double _getDailyCompletionRate() {
    int completed = 0;
    if (_goalVocab) completed++;
    if (_goalImmersion) completed++;
    if (_goalSentence) completed++;
    if (_goalShadowing) completed++;
    return completed / 4.0;
  }

  @override
  Widget build(BuildContext context) {
    final completionRate = _getDailyCompletionRate();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Dil Öğrenim Asistanı', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).colorScheme.onSurface),
        actions: [
          // Target Language Selection Dropdown
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _targetLanguage,
                icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF10B981)),
                onChanged: (String? newValue) async {
                  if (newValue != null) {
                    final selectedLang = _languages.firstWhere((element) => element['name'] == newValue);
                    setState(() {
                      _targetLanguage = newValue;
                      _targetLanguageFlag = selectedLang['flag']!;
                    });
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString('lang_target', _targetLanguage);
                    await prefs.setString('lang_target_flag', _targetLanguageFlag);
                  }
                },
                items: _languages.map<DropdownMenuItem<String>>((Map<String, String> value) {
                  return DropdownMenuItem<String>(
                    value: value['name'],
                    child: Text(
                      '${value['flag']} ${value['name']}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  );
                }).toList(),
              ),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          // Top Stats Header Card
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  )
                ],
              ),
              child: Row(
                children: [
                  // Circular Progress Indicator
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 76,
                        height: 76,
                        child: CircularProgressIndicator(
                          value: completionRate,
                          strokeWidth: 8,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      Text(
                        '${(completionRate * 100).toInt()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 20),
                  // Streak & Status
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hedef Dil: $_targetLanguage $_targetLanguageFlag',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.local_fire_department, color: Colors.orangeAccent, size: 22),
                            const SizedBox(width: 4),
                            Text(
                              '$_streak Günlük Seri!',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          completionRate == 1.0 
                              ? 'Harika! Bugünün tüm hedeflerini tamamladın!'
                              : 'Bugünü kurtarmak için çalışmaya başla!',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 12,
                          ),
                        )
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
            isScrollable: true,
            labelColor: const Color(0xFF10B981),
            unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            indicatorColor: const Color(0xFF10B981),
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            tabs: const [
              Tab(text: 'Hedefler'),
              Tab(text: 'Kelime Kartları'),
              Tab(text: 'Dil Maruziyeti'),
              Tab(text: 'Cümle Pratiği'),
            ],
          ),

          // Tab Bar View
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildGoalsTab(),
                _buildVocabTab(),
                _buildImmersionTab(),
                _buildSentenceTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- GOALS TAB ---
  Widget _buildGoalsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Bilimsel Dil Öğrenme Rutini',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          'Günde sadece 4 basit adımı tamamlayarak dil öğreniminizi hızlandırın. Aktif maruziyet ve pratik en iyi taktiklerdir.',
          style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
        ),
        const SizedBox(height: 20),
        _buildGoalTile(
          title: 'Yeni Kelime Çalış',
          subtitle: 'En az 5 yeni kelime ekle veya kartlarını tekrar et.',
          icon: Icons.style,
          color: Colors.blue,
          value: _goalVocab,
          onChanged: (val) {
            setState(() => _goalVocab = val ?? false);
            _saveGoals();
          },
        ),
        _buildGoalTile(
          title: 'Dil Maruziyeti (Dinleme/Okuma)',
          subtitle: 'En az 15-20 dakika podcast, dizi, kitap veya makale incele.',
          icon: Icons.hearing,
          color: Colors.amber,
          value: _goalImmersion,
          onChanged: (val) {
            setState(() => _goalImmersion = val ?? false);
            _saveGoals();
          },
        ),
        _buildGoalTile(
          title: 'Aktif Cümle Üretimi (Sentence Mining)',
          subtitle: 'Yeni öğrendiğin kelimeleri kullanarak 3 adet cümle yaz.',
          icon: Icons.edit_note,
          color: Colors.purple,
          value: _goalSentence,
          onChanged: (val) {
            setState(() => _goalSentence = val ?? false);
            _saveGoals();
          },
        ),
        _buildGoalTile(
          title: 'Sesli Okuma / Gölgelendirme (Shadowing)',
          subtitle: 'Telaffuzunu geliştirmek için 10 dakika sesli tekrar yap.',
          icon: Icons.record_voice_over,
          color: Colors.redAccent,
          value: _goalShadowing,
          onChanged: (val) {
            setState(() => _goalShadowing = val ?? false);
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
        activeColor: const Color(0xFF10B981),
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

  // --- VOCABULARY TAB (Card flipping with 3D animation) ---
  Widget _buildVocabTab() {
    return Column(
      children: [
        // Add new vocab button
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            onPressed: _showAddVocabDialog,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('Yeni Kelime Ekle', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),

        // Vocab list / Flashcards
        Expanded(
          child: _vocabList.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.style_outlined, size: 64, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2)),
                      const SizedBox(height: 16),
                      Text(
                        'Henüz kelime eklenmedi.',
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Kelimeleri ekleyin ve dokunarak anlamlarını öğrenin.',
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4), fontSize: 12),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: _vocabList.length,
                  itemBuilder: (context, index) {
                    final item = _vocabList[index];
                    return FlipCard(
                      front: _buildCardHalf(
                        title: item['word'] ?? '',
                        subtitle: 'Dokun ve Çevir',
                        color: const Color(0xFF10B981).withOpacity(0.05),
                        isFront: true,
                        item: item,
                        index: index,
                      ),
                      back: _buildCardHalf(
                        title: item['meaning'] ?? '',
                        subtitle: item['sentence'] ?? 'Örnek cümle girilmedi.',
                        color: const Color(0xFF047857).withOpacity(0.1),
                        isFront: false,
                        item: item,
                        index: index,
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCardHalf({
    required String title,
    required String subtitle,
    required Color color,
    required bool isFront,
    required Map<String, dynamic> item,
    required int index,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isFront ? const Color(0xFF10B981).withOpacity(0.3) : const Color(0xFF10B981)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Row of actions (Delete, Mark Mastered)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (item['status'] == 'mastered' ? Colors.blue : Colors.orange).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item['status'] == 'mastered' ? 'Öğrenildi' : 'Öğreniliyor',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: item['status'] == 'mastered' ? Colors.blue : Colors.orange,
                  ),
                ),
              ),
              // Delete icon
              GestureDetector(
                onTap: () {
                  setState(() {
                    _vocabList.removeAt(index);
                  });
                  _saveVocabList();
                },
                child: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
              ),
            ],
          ),
          const Spacer(),
          // Main text
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          // Sub/Sentence text
          Text(
            subtitle,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontStyle: isFront ? FontStyle.italic : FontStyle.normal,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          const Spacer(),
          // Checkmark to toggle mastered
          if (!isFront)
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _vocabList[index]['status'] = 
                      _vocabList[index]['status'] == 'mastered' ? 'learning' : 'mastered';
                });
                _saveVocabList();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: item['status'] == 'mastered' ? Colors.orange : const Color(0xFF10B981),
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 32),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                item['status'] == 'mastered' ? 'Tekrar Al' : 'Öğrendim!',
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }

  void _showAddVocabDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Yeni Kelime Ekle', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _wordController,
                  decoration: const InputDecoration(
                    labelText: 'Kelime / İfade',
                    border: OutlineInputBorder(),
                    hintText: 'e.g. Ephemeral',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _meaningController,
                  decoration: const InputDecoration(
                    labelText: 'Türkçe Anlamı',
                    border: OutlineInputBorder(),
                    hintText: 'e.g. Geçici, kalıcı olmayan',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _sentenceController,
                  decoration: const InputDecoration(
                    labelText: 'Örnek Cümle (Önerilir)',
                    border: OutlineInputBorder(),
                    hintText: 'e.g. Life is ephemeral, enjoy it.',
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                if (_wordController.text.isNotEmpty && _meaningController.text.isNotEmpty) {
                  setState(() {
                    _vocabList.insert(0, {
                      'word': _wordController.text.trim(),
                      'meaning': _meaningController.text.trim(),
                      'sentence': _sentenceController.text.trim(),
                      'status': 'learning',
                    });
                    _wordController.clear();
                    _meaningController.clear();
                    _sentenceController.clear();
                  });
                  _saveVocabList();
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
              child: const Text('Ekle', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          ],
        );
      },
    );
  }

  // --- IMMERSION TAB (Journal Log) ---
  Widget _buildImmersionTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Maruz Kalma Günlüğü (Immersion Diary)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(
            'Bugün hedef dilde ne okudun veya ne dinledin? Bunu kaydetmek beynin dile alışmasını izlemenin en iyi yoludur.',
            style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
          ),
          const SizedBox(height: 20),
          
          // Log form card
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
                  controller: _activityController,
                  decoration: const InputDecoration(
                    labelText: 'Aktivite (Ne yaptınız?)',
                    border: OutlineInputBorder(),
                    hintText: 'e.g. Luke English Podcast dinledim, BBC makalesi okudum.',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _durationController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Süre (Dakika)',
                    border: OutlineInputBorder(),
                    hintText: 'e.g. 20',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notlar / Yeni İfadeler',
                    border: OutlineInputBorder(),
                    hintText: 'Bu çalışmada öğrendiğin ilginç kalıpları not et.',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    if (_activityController.text.isNotEmpty && _durationController.text.isNotEmpty) {
                      setState(() {
                        _journalLogs.insert(0, {
                          'date': DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now()),
                          'activity': _activityController.text.trim(),
                          'duration': int.tryParse(_durationController.text) ?? 15,
                          'note': _notesController.text.trim(),
                        });
                        _activityController.clear();
                        _durationController.clear();
                        _notesController.clear();
                      });
                      _saveJournalLogs();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Günlüğe Kaydet', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                )
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          const Text('Geçmiş Çalışmalarım', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          
          _journalLogs.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24.0),
                  child: Center(
                    child: Text(
                      'Henüz maruziyet günlüğü kaydedilmedi.',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4)),
                    ),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _journalLogs.length,
                  itemBuilder: (context, index) {
                    final log = _journalLogs[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Theme.of(context).dividerColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(log['date'] ?? '', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _journalLogs.removeAt(index);
                                  });
                                  _saveJournalLogs();
                                },
                                child: const Icon(Icons.close, size: 18, color: Colors.red),
                              )
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            log['activity'] ?? '',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          const SizedBox(height: 4),
                          Text('Süre: ${log['duration']} Dakika', style: const TextStyle(fontSize: 13, color: Color(0xFF10B981), fontWeight: FontWeight.w600)),
                          if (log['note'] != null && log['note'].toString().isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Theme.of(context).scaffoldBackgroundColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                log['note'],
                                style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
                              ),
                            )
                          ]
                        ],
                      ),
                    );
                  },
                )
        ],
      ),
    );
  }

  // --- SENTENCE TAB (Sentence builder / active recall) ---
  Widget _buildSentenceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Cümle Madenciliği (Sentence Mining)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(
            'Öğrendiğin kelimeleri aktif olarak kullanmak kalıcılığı artırır. Yeni kelimelerle kendi cümlelerini kur ve kaydet.',
            style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
          ),
          const SizedBox(height: 20),
          
          // Form
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
                  controller: _sentenceMiningController,
                  decoration: const InputDecoration(
                    labelText: 'Cümleniz',
                    border: OutlineInputBorder(),
                    hintText: 'Yeni öğrendiğiniz kelimeleri barındıran bir cümle yazın.',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    if (_sentenceMiningController.text.isNotEmpty) {
                      setState(() {
                        _sentenceLogs.insert(0, {
                          'date': DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now()),
                          'sentence': _sentenceMiningController.text.trim(),
                        });
                        _sentenceMiningController.clear();
                      });
                      _saveSentenceLogs();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Cümleyi Kaydet', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                )
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          const Text('Kurduğum Cümleler', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          
          _sentenceLogs.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24.0),
                  child: Center(
                    child: Text(
                      'Henüz cümle kaydedilmedi.',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4)),
                    ),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _sentenceLogs.length,
                  itemBuilder: (context, index) {
                    final log = _sentenceLogs[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Theme.of(context).dividerColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(log['date'] ?? '', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _sentenceLogs.removeAt(index);
                                  });
                                  _saveSentenceLogs();
                                },
                                child: const Icon(Icons.close, size: 18, color: Colors.red),
                              )
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            log['sentence'] ?? '',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, height: 1.4),
                          ),
                        ],
                      ),
                    );
                  },
                )
        ],
      ),
    );
  }
}

// Custom 3D Flip Card Widget
class FlipCard extends StatefulWidget {
  final Widget front;
  final Widget back;

  const FlipCard({Key? key, required this.front, required this.back}) : super(key: key);

  @override
  State<FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<FlipCard> {
  bool _showFront = true;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _showFront = !_showFront),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        transitionBuilder: (child, animation) {
          final rotate = Tween(begin: 3.1415, end: 0.0).animate(animation);
          return AnimatedBuilder(
            animation: rotate,
            child: child,
            builder: (context, child) {
              final isFront = child == widget.front;
              final angle = isFront ? rotate.value : rotate.value + 3.1415;
              return Transform(
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001) // 3D Perspective
                  ..rotateY(angle),
                alignment: Alignment.center,
                child: child,
              );
            },
          );
        },
        child: _showFront 
          ? SizedBox(key: const ValueKey('front'), child: widget.front) 
          : SizedBox(key: const ValueKey('back'), child: widget.back),
      ),
    );
  }
}
