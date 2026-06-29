import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class PersonalDevProgramScreen extends StatefulWidget {
  const PersonalDevProgramScreen({Key? key}) : super(key: key);

  @override
  State<PersonalDevProgramScreen> createState() => _PersonalDevProgramScreenState();
}

class _PersonalDevProgramScreenState extends State<PersonalDevProgramScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Habits State
  List<Map<String, dynamic>> _habitsList = [];
  
  // Reading Tracker State
  List<Map<String, dynamic>> _booksList = [];

  // Controllers
  final _habitNameController = TextEditingController();
  final _bookTitleController = TextEditingController();
  final _bookAuthorController = TextEditingController();
  final _bookTotalPagesController = TextEditingController();
  final _bookCurrentPageController = TextEditingController();

  // Weekly tracker dates (Monday to Sunday of the current week)
  late List<DateTime> _weekDays;
  final List<String> _weekDayLabels = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _calculateWeekDates();
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _habitNameController.dispose();
    _bookTitleController.dispose();
    _bookAuthorController.dispose();
    _bookTotalPagesController.dispose();
    _bookCurrentPageController.dispose();
    super.dispose();
  }

  void _calculateWeekDates() {
    final now = DateTime.now();
    final currentWeekday = now.weekday; // 1 = Monday ... 7 = Sunday
    final startOfWeek = now.subtract(Duration(days: currentWeekday - 1));
    _weekDays = List.generate(7, (index) => startOfWeek.add(Duration(days: index)));
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      // Habits list
      final habitsRaw = prefs.getString('personal_habits') ?? '[]';
      _habitsList = List<Map<String, dynamic>>.from(json.decode(habitsRaw));
      
      // If list is empty, put some default ones to guide the user
      if (_habitsList.isEmpty) {
        _habitsList = [
          {'id': '1', 'name': 'Kitap Okuma', 'history': []},
          {'id': '2', 'name': 'Meditasyon', 'history': []},
          {'id': '3', 'name': 'Erken Kalkma', 'history': []},
          {'id': '4', 'name': 'Günlük Tutma', 'history': []},
        ];
      }

      // Books list
      final booksRaw = prefs.getString('personal_books') ?? '[]';
      _booksList = List<Map<String, dynamic>>.from(json.decode(booksRaw));
      if (_booksList.isEmpty) {
        _booksList = [
          {
            'id': '1',
            'title': 'Atomik Alışkanlıklar',
            'author': 'James Clear',
            'totalPages': 320,
            'currentPage': 140,
          }
        ];
      }
    });
  }

  Future<void> _saveHabits() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('personal_habits', json.encode(_habitsList));
  }

  Future<void> _saveBooks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('personal_books', json.encode(_booksList));
  }

  // --- Habit Actions ---
  void _addHabit(String name) {
    if (name.trim().isEmpty) return;
    setState(() {
      _habitsList.add({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'name': name.trim(),
        'history': [],
      });
      _habitNameController.clear();
    });
    _saveHabits();
  }

  void _toggleHabitDate(int habitIndex, DateTime date) {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final history = List<String>.from(_habitsList[habitIndex]['history'] ?? []);

    setState(() {
      if (history.contains(dateStr)) {
        history.remove(dateStr);
      } else {
        history.add(dateStr);
      }
      _habitsList[habitIndex]['history'] = history;
    });
    _saveHabits();
  }

  void _deleteHabit(int index) {
    setState(() {
      _habitsList.removeAt(index);
    });
    _saveHabits();
  }

  // --- Book Actions ---
  void _addBook() {
    final title = _bookTitleController.text.trim();
    final author = _bookAuthorController.text.trim();
    final total = int.tryParse(_bookTotalPagesController.text) ?? 200;
    final current = int.tryParse(_bookCurrentPageController.text) ?? 0;

    if (title.isEmpty) return;

    setState(() {
      _booksList.add({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'title': title,
        'author': author.isEmpty ? 'Bilinmeyen Yazar' : author,
        'totalPages': total,
        'currentPage': current > total ? total : current,
      });
      _bookTitleController.clear();
      _bookAuthorController.clear();
      _bookTotalPagesController.clear();
      _bookCurrentPageController.clear();
    });
    _saveBooks();
    Navigator.pop(context);
  }

  void _updateBookPage(int index, int newPage) {
    final total = _booksList[index]['totalPages'] as int;
    setState(() {
      _booksList[index]['currentPage'] = newPage > total ? total : (newPage < 0 ? 0 : newPage);
    });
    _saveBooks();
  }

  void _deleteBook(int index) {
    setState(() {
      _booksList.removeAt(index);
    });
    _saveBooks();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Kişisel Gelişim Asistanı', style: TextStyle(fontWeight: FontWeight.bold)),
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
                  colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8B5CF6).withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  )
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildHeaderStat(
                    icon: Icons.check_circle,
                    label: 'Alışkanlıklar',
                    value: '${_habitsList.length}',
                  ),
                  _buildHeaderStat(
                    icon: Icons.book,
                    label: 'Okunan Kitap',
                    value: '${_booksList.length}',
                  ),
                  _buildHeaderStat(
                    icon: Icons.emoji_events,
                    label: 'Aktif Gelişim',
                    value: 'A+',
                  ),
                ],
              ),
            ),
          ),

          // Tab Bar
          TabBar(
            controller: _tabController,
            labelColor: const Color(0xFF8B5CF6),
            unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            indicatorColor: const Color(0xFF8B5CF6),
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            tabs: const [
              Tab(text: 'Alışkanlık Takibi'),
              Tab(text: 'Kitap Okuma'),
            ],
          ),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildHabitsTab(),
                _buildBooksTab(),
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

  // --- HABITS TAB ---
  Widget _buildHabitsTab() {
    return Column(
      children: [
        // Quick add habit
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _habitNameController,
                  decoration: const InputDecoration(
                    hintText: 'e.g. 10 sayfa kitap oku, Meditasyon yap',
                    border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () => _addHabit(_habitNameController.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Icon(Icons.add, color: Colors.white),
              )
            ],
          ),
        ),

        // Grid / List header for week days
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              const Expanded(flex: 3, child: Text('Alışkanlık', style: TextStyle(fontWeight: FontWeight.bold))),
              Expanded(
                flex: 5,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: _weekDays.map((d) {
                    final dayLabel = _weekDayLabels[d.weekday - 1];
                    final isToday = DateFormat('yyyy-MM-dd').format(d) == DateFormat('yyyy-MM-dd').format(DateTime.now());
                    return Text(
                      dayLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                        color: isToday ? const Color(0xFF8B5CF6) : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        const Divider(),

        // Habits rows
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _habitsList.length,
            itemBuilder: (context, habitIndex) {
              final habit = _habitsList[habitIndex];
              final history = List<String>.from(habit['history'] ?? []);

              return Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Row(
                  children: [
                    // Habit Title / Delete
                    Expanded(
                      flex: 3,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 12.0),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () => _deleteHabit(habitIndex),
                              child: const Icon(Icons.close, color: Colors.redAccent, size: 16),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                habit['name'] ?? '',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Checkboxes for week
                    Expanded(
                      flex: 5,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: _weekDays.map((day) {
                          final dateStr = DateFormat('yyyy-MM-dd').format(day);
                          final checked = history.contains(dateStr);
                          return GestureDetector(
                            onTap: () => _toggleHabitDate(habitIndex, day),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: checked ? const Color(0xFF8B5CF6) : Colors.transparent,
                                border: Border.all(
                                  color: checked ? const Color(0xFF8B5CF6) : Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: checked 
                                ? const Icon(Icons.check, size: 16, color: Colors.white) 
                                : null,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // --- BOOKS TAB ---
  Widget _buildBooksTab() {
    return Column(
      children: [
        // Add book button
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            onPressed: _showAddBookDialog,
            icon: const Icon(Icons.book_outlined, color: Colors.white),
            label: const Text('Yeni Kitap Ekle', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),

        // List of books
        Expanded(
          child: _booksList.isEmpty
              ? Center(
                  child: Text(
                    'Henüz okuma günlüğü kaydedilmedi.',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4)),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _booksList.length,
                  itemBuilder: (context, index) {
                    final book = _booksList[index];
                    final total = book['totalPages'] as int? ?? 100;
                    final current = book['currentPage'] as int? ?? 0;
                    final progress = total > 0 ? current / total : 0.0;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
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
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      book['title'] ?? '',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      book['author'] ?? '',
                                      style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5)),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                onPressed: () => _deleteBook(index),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Progress Bar
                          Row(
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: LinearProgressIndicator(
                                    value: progress,
                                    minHeight: 8,
                                    backgroundColor: const Color(0xFF8B5CF6).withOpacity(0.1),
                                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF8B5CF6)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Text(
                                '${(progress * 100).toInt()}%',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF8B5CF6)),
                              )
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Page selectors
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Sayfa: $current / $total',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline, color: Color(0xFF8B5CF6)),
                                    onPressed: () => _updateBookPage(index, current - 5),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline, color: Color(0xFF8B5CF6)),
                                    onPressed: () => _updateBookPage(index, current + 5),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showAddBookDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Yeni Kitap Ekle', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _bookTitleController,
                  decoration: const InputDecoration(labelText: 'Kitap Adı', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _bookAuthorController,
                  decoration: const InputDecoration(labelText: 'Yazar', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _bookTotalPagesController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Toplam Sayfa', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _bookCurrentPageController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Kaldığım Sayfa', border: OutlineInputBorder()),
                      ),
                    ),
                  ],
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
              onPressed: _addBook,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6)),
              child: const Text('Ekle', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}
