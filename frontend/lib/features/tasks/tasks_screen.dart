import '../../core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'tasks_provider.dart';
import 'package:intl/intl.dart';
import '../../core/utils/date_formatter.dart';
import '../programs/active_workout_screen.dart';
import '../goals/wishlist_sheet.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  void _showAddTaskSheet() {
    final titleController = TextEditingController();
    final locationController = TextEditingController();
    TimeOfDay? selectedTime;
    int reminderOffset = 15;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Yeni Görev',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Görev Adı
                  TextField(
                    controller: titleController,
                    autofocus: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Örn: CrossFit Antrenmanı',
                      hintStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: Theme.of(context).cardColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(
                        Icons.task_alt,
                        color: AppColors.info,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Saat Seçici
                  GestureDetector(
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                        builder: (context, child) {
                          return Theme(
                            data: ThemeData.dark().copyWith(
                              colorScheme: const ColorScheme.dark(
                                primary: AppColors.info,
                                surface: Color(0xFF1E1E1E),
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (time != null) {
                        setModalState(() {
                          selectedTime = time;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).dividerColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            color: AppColors.warning,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            selectedTime != null
                                ? selectedTime!.format(context)
                                : 'Saat Seç (İsteğe Bağlı)',
                            style: TextStyle(
                              color: selectedTime != null
                                  ? Colors.white
                                  : Colors.white54,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Konum
                  TextField(
                    controller: locationController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Konum (Örn: MacFit)',
                      hintStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: Theme.of(context).cardColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(
                        Icons.location_on,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                  // Hatırlatıcı Süresi
                  if (selectedTime != null) ...[
                    DropdownButtonFormField<int>(
                      initialValue: reminderOffset,
                      dropdownColor: Theme.of(context).cardColor,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Theme.of(context).cardColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: const Icon(
                          Icons.notifications_active,
                          color: Color(0xFF30D158),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 15,
                          child: Text(
                            '15 dakika önce hatırlat',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 30,
                          child: Text(
                            '30 dakika önce hatırlat',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 60,
                          child: Text(
                            '1 saat önce hatırlat',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                      onChanged: (val) {
                        setModalState(() {
                          reminderOffset = val ?? 15;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                  ],

                  const SizedBox(height: 8),

                  // Kaydet
                  ElevatedButton(
                    onPressed: () {
                      if (titleController.text.trim().isNotEmpty) {
                        DateTime? scheduledDateTime;
                        if (selectedTime != null) {
                          final selectedDate = ref
                              .read(tasksProvider)
                              .selectedDate;
                          scheduledDateTime = DateTime(
                            selectedDate.year,
                            selectedDate.month,
                            selectedDate.day,
                            selectedTime!.hour,
                            selectedTime!.minute,
                          );
                        }

                        ref
                            .read(tasksProvider.notifier)
                            .createTask(
                              titleController.text.trim(),
                              scheduledTime: scheduledDateTime,
                              location:
                                  locationController.text.trim().isNotEmpty
                                  ? locationController.text.trim()
                                  : null,
                              reminderOffsetMinutes: reminderOffset,
                            );
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      backgroundColor: AppColors.info,
                    ),
                    child: const Text(
                      'Görevi Oluştur',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showRescheduleSheet(int taskId) async {
    final initialDate = ref.read(tasksProvider).selectedDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.warning,
              surface: Color(0xFF1E1E1E),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      ref.read(tasksProvider.notifier).rescheduleTask(taskId, picked);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Görev başka güne taşındı'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Widget _buildHorizontalDatePicker(DateTime selectedDate) {
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 365, // 1 year window into the future
        itemBuilder: (context, index) {
          final date = DateTime.now().add(Duration(days: index));
          final isSelected =
              date.year == selectedDate.year &&
              date.month == selectedDate.month &&
              date.day == selectedDate.day;

          final weekdays = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
          final weekdayStr = weekdays[date.weekday - 1];

          return GestureDetector(
            onTap: () {
              ref.read(tasksProvider.notifier).changeDate(date);
            },
            child: Container(
              width: 60,
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.info
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
                          ? Colors.white
                          : Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.5),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${date.day}',
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
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
    final state = ref.watch(tasksProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Görevler - ${DateFormatter.toTurkishDate(state.selectedDate)}',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 16,
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
            icon: const Icon(
              Icons.shopping_bag_outlined,
              color: AppColors.info,
            ),
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
      ),
      body: Column(
        children: [
          _buildHorizontalDatePicker(state.selectedDate),
          Expanded(
            child: state.tasks.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.info),
              ),
              error: (err, stack) => Center(
                child: Text(
                  'Hata: $err',
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
              skipLoadingOnReload: true,
              data: (tasks) {
                if (tasks.isEmpty) {
                  return Center(
                    child: Text(
                      'Bu güne ait görev yok. Hemen planla!',
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.5),
                        fontSize: 16,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    final isCompleted = task['isCompleted'] ?? false;
                    final scheduledTimeStr = task['scheduledTime'];
                    final location = task['location'];

                    String? timeDisplay;
                    if (scheduledTimeStr != null) {
                      final dt = DateTime.parse(scheduledTimeStr).toLocal();
                      timeDisplay = DateFormat('HH:mm').format(dt);
                    }

                    return Dismissible(
                      key: Key(task['id'].toString()),
                      direction: DismissDirection.horizontal,
                      background: Container(
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: const Icon(
                          Icons.check,
                          color: Colors.black,
                          size: 32,
                        ),
                      ),
                      secondaryBackground: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF453A),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: const Icon(
                          Icons.delete,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      onDismissed: (direction) {
                        if (direction == DismissDirection.endToStart) {
                          ref
                              .read(tasksProvider.notifier)
                              .deleteTask(task['id']);
                        } else {
                          if (!isCompleted) {
                            ref
                                .read(tasksProvider.notifier)
                                .toggleTaskCompletion(task['id'], isCompleted);
                          }
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isCompleted
                                ? AppColors.primary.withOpacity(0.3)
                                : Theme.of(context).dividerColor,
                          ),
                        ),
                        child: ListTile(
                          onTap: task['isWorkout'] == true && !isCompleted
                              ? () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ActiveWorkoutScreen(
                                        date: state.selectedDate,
                                      ),
                                    ),
                                  );
                                }
                              : null,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: task['isWorkout'] == true
                              ? Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isCompleted
                                        ? AppColors.primary.withOpacity(0.1)
                                        : AppColors.info.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isCompleted
                                        ? Icons.check
                                        : Icons.fitness_center,
                                    color: isCompleted
                                        ? AppColors.primary
                                        : AppColors.info,
                                    size: 24,
                                  ),
                                )
                              : Checkbox(
                                  value: isCompleted,
                                  activeColor: AppColors.primary,
                                  checkColor: Colors.white,
                                  side: BorderSide(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface.withOpacity(0.5),
                                    width: 2,
                                  ),
                                  shape: const CircleBorder(),
                                  onChanged: (val) {
                                    ref
                                        .read(tasksProvider.notifier)
                                        .toggleTaskCompletion(
                                          task['id'],
                                          isCompleted,
                                        );
                                  },
                                ),
                          title: Text(
                            task['title'],
                            style: TextStyle(
                              decoration: isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: isCompleted
                                  ? Theme.of(
                                      context,
                                    ).colorScheme.onSurface.withOpacity(0.5)
                                  : Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          subtitle:
                              (timeDisplay != null ||
                                  location != null ||
                                  task['goal'] != null)
                              ? Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Row(
                                    children: [
                                      if (timeDisplay != null) ...[
                                        const Icon(
                                          Icons.access_time,
                                          size: 14,
                                          color: AppColors.warning,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          timeDisplay,
                                          style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withOpacity(0.7),
                                            fontSize: 13,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                      ],
                                      if (location != null) ...[
                                        const Icon(
                                          Icons.location_on,
                                          size: 14,
                                          color: AppColors.error,
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            location,
                                            style: TextStyle(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface
                                                  .withOpacity(0.7),
                                              fontSize: 13,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                      if (task['goal'] != null) ...[
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.info.withOpacity(
                                              0.2,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.track_changes,
                                                size: 12,
                                                color: AppColors.info,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                task['goal']['title'],
                                                style: const TextStyle(
                                                  color: AppColors.info,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                )
                              : null,
                          trailing: IconButton(
                            icon: Icon(
                              Icons.more_vert,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.5),
                            ),
                            onPressed: () {
                              showModalBottomSheet(
                                context: context,
                                backgroundColor: const Color(0xFF1E1E1E),
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(
                                    top: Radius.circular(24),
                                  ),
                                ),
                                builder: (context) {
                                  return SafeArea(
                                    child: Container(
                                      color: Theme.of(
                                        context,
                                      ).scaffoldBackgroundColor,
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const SizedBox(height: 16),
                                          ListTile(
                                            leading: const Icon(
                                              Icons.calendar_month,
                                              color: AppColors.warning,
                                            ),
                                            title: Text(
                                              'Başka Güne Taşı',
                                              style: TextStyle(
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.onSurface,
                                              ),
                                            ),
                                            onTap: () {
                                              Navigator.pop(context);
                                              _showRescheduleSheet(task['id']);
                                            },
                                          ),
                                          ListTile(
                                            leading: const Icon(
                                              Icons.delete,
                                              color: AppColors.error,
                                            ),
                                            title: Text(
                                              'Sil',
                                              style: TextStyle(
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.onSurface,
                                              ),
                                            ),
                                            onTap: () {
                                              Navigator.pop(context);
                                              ref
                                                  .read(tasksProvider.notifier)
                                                  .deleteTask(task['id']);
                                            },
                                          ),
                                          const SizedBox(height: 16),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddTaskSheet,
        backgroundColor: AppColors.info,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Görev Ekle',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
