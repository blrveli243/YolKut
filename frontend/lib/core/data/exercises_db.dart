import 'package:flutter/material.dart';

class Exercise {
  final String id;
  final String name;
  final String category;
  final IconData icon;

  const Exercise({
    required this.id,
    required this.name,
    required this.category,
    required this.icon,
  });
}

class ExercisesDB {
  static const List<Exercise> allExercises = [
    // Göğüs (Chest)
    Exercise(id: 'bench_press', name: 'Bench Press', category: 'Göğüs', icon: Icons.fitness_center),
    Exercise(id: 'incline_bench_press', name: 'Incline Bench Press', category: 'Göğüs', icon: Icons.fitness_center),
    Exercise(id: 'dumbbell_fly', name: 'Dumbbell Fly', category: 'Göğüs', icon: Icons.fitness_center),
    Exercise(id: 'push_up', name: 'Şınav', category: 'Göğüs', icon: Icons.accessibility_new),
    Exercise(id: 'chest_dip', name: 'Göğüs Dips', category: 'Göğüs', icon: Icons.fitness_center),
    Exercise(id: 'cable_crossover', name: 'Cable Crossover', category: 'Göğüs', icon: Icons.fitness_center),
    Exercise(id: 'pec_deck', name: 'Pec Deck (Machine Fly)', category: 'Göğüs', icon: Icons.fitness_center),
    
    // Sırt (Back)
    Exercise(id: 'pull_up', name: 'Barfiks', category: 'Sırt', icon: Icons.accessibility_new),
    Exercise(id: 'lat_pulldown', name: 'Lat Pulldown', category: 'Sırt', icon: Icons.fitness_center),
    Exercise(id: 'barbell_row', name: 'Barbell Row', category: 'Sırt', icon: Icons.fitness_center),
    Exercise(id: 'deadlift', name: 'Deadlift', category: 'Sırt', icon: Icons.fitness_center),
    Exercise(id: 'seated_cable_row', name: 'Seated Cable Row', category: 'Sırt', icon: Icons.fitness_center),
    Exercise(id: 't_bar_row', name: 'T-Bar Row', category: 'Sırt', icon: Icons.fitness_center),
    Exercise(id: 'face_pull', name: 'Face Pull', category: 'Sırt', icon: Icons.fitness_center),

    // Bacak (Legs)
    Exercise(id: 'squat', name: 'Squat', category: 'Bacak', icon: Icons.fitness_center),
    Exercise(id: 'leg_press', name: 'Leg Press', category: 'Bacak', icon: Icons.fitness_center),
    Exercise(id: 'lunge', name: 'Lunge', category: 'Bacak', icon: Icons.accessibility_new),
    Exercise(id: 'leg_extension', name: 'Leg Extension', category: 'Bacak', icon: Icons.fitness_center),
    Exercise(id: 'leg_curl', name: 'Leg Curl', category: 'Bacak', icon: Icons.fitness_center),
    Exercise(id: 'calf_raise', name: 'Calf Raise', category: 'Bacak', icon: Icons.fitness_center),
    Exercise(id: 'bulgarian_split_squat', name: 'Bulgarian Split Squat', category: 'Bacak', icon: Icons.fitness_center),
    Exercise(id: 'romanian_deadlift', name: 'Romanian Deadlift (RDL)', category: 'Bacak', icon: Icons.fitness_center),
    
    // Omuz (Shoulders)
    Exercise(id: 'overhead_press', name: 'Overhead Press', category: 'Omuz', icon: Icons.fitness_center),
    Exercise(id: 'lateral_raise', name: 'Lateral Raise', category: 'Omuz', icon: Icons.fitness_center),
    Exercise(id: 'front_raise', name: 'Front Raise', category: 'Omuz', icon: Icons.fitness_center),
    Exercise(id: 'arnold_press', name: 'Arnold Press', category: 'Omuz', icon: Icons.fitness_center),
    Exercise(id: 'upright_row', name: 'Upright Row', category: 'Omuz', icon: Icons.fitness_center),

    // Kollar (Arms)
    Exercise(id: 'bicep_curl', name: 'Bicep Curl', category: 'Kol', icon: Icons.fitness_center),
    Exercise(id: 'tricep_extension', name: 'Tricep Extension', category: 'Kol', icon: Icons.fitness_center),
    Exercise(id: 'hammer_curl', name: 'Hammer Curl', category: 'Kol', icon: Icons.fitness_center),
    Exercise(id: 'tricep_pushdown', name: 'Tricep Pushdown', category: 'Kol', icon: Icons.fitness_center),
    Exercise(id: 'preacher_curl', name: 'Preacher Curl', category: 'Kol', icon: Icons.fitness_center),
    Exercise(id: 'skull_crusher', name: 'Skull Crusher', category: 'Kol', icon: Icons.fitness_center),

    // Karın (Core)
    Exercise(id: 'crunch', name: 'Crunch', category: 'Karın', icon: Icons.accessibility_new),
    Exercise(id: 'plank', name: 'Plank', category: 'Karın', icon: Icons.accessibility_new),
    Exercise(id: 'leg_raise', name: 'Hanging Leg Raise', category: 'Karın', icon: Icons.accessibility_new),
    Exercise(id: 'russian_twist', name: 'Russian Twist', category: 'Karın', icon: Icons.accessibility_new),
    Exercise(id: 'ab_wheel', name: 'Ab Wheel Rollout', category: 'Karın', icon: Icons.accessibility_new),

    // Kardiyo & Diğer (Cardio)
    Exercise(id: 'running', name: 'Koşu', category: 'Kardiyo', icon: Icons.directions_run),
    Exercise(id: 'cycling', name: 'Bisiklet', category: 'Kardiyo', icon: Icons.directions_bike),
    Exercise(id: 'swimming', name: 'Yüzme', category: 'Kardiyo', icon: Icons.pool),
    Exercise(id: 'jump_rope', name: 'İp Atlama', category: 'Kardiyo', icon: Icons.accessibility_new),
    Exercise(id: 'rowing_machine', name: 'Kürek Makinesi', category: 'Kardiyo', icon: Icons.rowing),
    Exercise(id: 'burpees', name: 'Burpee', category: 'Kardiyo', icon: Icons.accessibility_new),
  ];

  static List<String> get categories => 
    allExercises.map((e) => e.category).toSet().toList();

  static IconData getIconForCategory(String category) {
    if (category == 'Göğüs' || category == 'Sırt' || category == 'Bacak' || category == 'Omuz' || category == 'Kol') {
      return Icons.fitness_center;
    } else if (category == 'Kardiyo') {
      return Icons.directions_run;
    } else {
      return Icons.accessibility_new;
    }
  }

  static List<Exercise> getByCategory(String category) =>
    allExercises.where((e) => e.category == category).toList();

  static Exercise? getById(String id) {
    try {
      return allExercises.firstWhere((e) => e.id == id);
    } catch (e) {
      return null;
    }
  }
}
