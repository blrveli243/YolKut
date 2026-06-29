import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'goals_provider.dart';
import '../tasks/tasks_provider.dart';

class CreateGoalScreen extends ConsumerStatefulWidget {
  const CreateGoalScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CreateGoalScreen> createState() => _CreateGoalScreenState();
}

class _CreateGoalScreenState extends ConsumerState<CreateGoalScreen> {
  final _titleController = TextEditingController();
  final _taskTitleController = TextEditingController();
  final _targetDaysController = TextEditingController(text: '30');

  String _selectedCategory = 'Kişisel Gelişim';
  final List<String> _categories = ['Kişisel Gelişim', 'Eğitim', 'Spor', 'Hobi', 'Sağlık'];
  
  // 1=Mon, 2=Tue, 3=Wed, 4=Thu, 5=Fri, 6=Sat, 7=Sun
  final Set<int> _selectedDays = {1, 2, 3, 4, 5, 6, 7}; // Default all days
  final Map<int, String> _dayNames = {
    1: 'Pzt', 2: 'Sal', 3: 'Çar', 4: 'Per', 5: 'Cum', 6: 'Cts', 7: 'Paz'
  };

  @override
  void dispose() {
    _titleController.dispose();
    _taskTitleController.dispose();
    _targetDaysController.dispose();
    super.dispose();
  }

  void _saveGoal() async {
    if (_titleController.text.trim().isEmpty || _taskTitleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lütfen hedef ve görev adını girin.')));
      return;
    }

    if (_selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lütfen en az bir gün seçin.')));
      return;
    }

    final data = {
      'title': _titleController.text.trim(),
      'category': _selectedCategory,
      'targetDays': int.tryParse(_targetDaysController.text) ?? 30,
      'daysOfWeek': _selectedDays.toList(),
      'taskTitle': _taskTitleController.text.trim(),
    };

    try {
      await ref.read(customGoalsProvider.notifier).createGoal(data);
      
      // Refresh the tasks screen to show the newly generated tasks
      ref.read(tasksProvider.notifier).fetchTasksForDate(ref.read(tasksProvider).selectedDate);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Hedef başarıyla oluşturuldu!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildDaySelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _dayNames.entries.map((entry) {
        final isSelected = _selectedDays.contains(entry.key);
        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedDays.remove(entry.key);
              } else {
                _selectedDays.add(entry.key);
              }
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF0A84FF) : const Color(0xFF1C1C1E),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isSelected ? const Color(0xFF0A84FF) : Colors.white12),
            ),
            child: Text(entry.value, style: TextStyle(color: isSelected ? Colors.white : Colors.white54, fontWeight: FontWeight.bold)),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(customGoalsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F13),
      appBar: AppBar(
        title: const Text('Yeni Hedef Oluştur', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Hedef Detayları', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            // Title
            TextField(
              controller: _titleController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Hedef Adı (Örn: YÖKDİL Hazırlık)',
                labelStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: const Color(0xFF1C1C1E),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),

            // Category
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              dropdownColor: const Color(0xFF2C2C2E),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Kategori',
                labelStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: const Color(0xFF1C1C1E),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
              items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedCategory = val);
              },
            ),
            const SizedBox(height: 32),

            const Text('Görev Takvimi', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            // Task Title
            TextField(
              controller: _taskTitleController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Günlük Görev Adı (Örn: 50 Kelime Ezberle)',
                labelStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: const Color(0xFF1C1C1E),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 16),

            // Duration
            TextField(
              controller: _targetDaysController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Hedef Süresi (Gün)',
                labelStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: const Color(0xFF1C1C1E),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 24),

            const Text('Hangi Günler Tekrarlansın?', style: TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 12),
            _buildDaySelector(),

            const SizedBox(height: 48),

            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: const Color(0xFF32D74B),
              ),
              child: ElevatedButton(
                onPressed: state.isCreating ? null : _saveGoal,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: state.isCreating 
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Programı Başlat', style: TextStyle(fontSize: 18, color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
