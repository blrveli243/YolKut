import 'package:live_activities/live_activities.dart';

class LiveActivityService {
  static final LiveActivityService _instance = LiveActivityService._();
  factory LiveActivityService() => _instance;
  LiveActivityService._();

  final _liveActivitiesPlugin = LiveActivities();
  String? _currentActivityId;

  Future<void> init() async {
    await _liveActivitiesPlugin.init(
      appGroupId: 'group.com.velibilir.yolkut',
    );
  }

  Future<void> startActivity({
    required String title,
    required String subtitle,
    required String timeValue,
    required String iconName,
    required String taskType,
    required bool isRunning,
    int? endTime,
  }) async {
    if (_currentActivityId != null) {
      await stopActivity();
    }
    
    _currentActivityId = await _liveActivitiesPlugin.createActivity(
      taskType, // Use taskType as the activityId
      {
        'title': title,
        'subtitle': subtitle,
        'timeValue': timeValue,
        'iconName': iconName,
        'isRunning': isRunning,
        'taskType': taskType,
        'endTime': endTime ?? 0,
      },
    );
  }

  Future<void> updateActivity({
    required String title,
    required String subtitle,
    required String timeValue,
    required String iconName,
    required String taskType,
    required bool isRunning,
    int? endTime,
  }) async {
    if (_currentActivityId != null) {
      await _liveActivitiesPlugin.updateActivity(
        _currentActivityId!,
        {
          'title': title,
          'subtitle': subtitle,
          'timeValue': timeValue,
          'iconName': iconName,
          'isRunning': isRunning,
          'taskType': taskType,
          'endTime': endTime ?? 0,
        },
      );
    }
  }

  Future<void> stopActivity() async {
    if (_currentActivityId != null) {
      await _liveActivitiesPlugin.endActivity(_currentActivityId!);
      _currentActivityId = null;
    }
  }
}
