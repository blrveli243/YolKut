import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/foundation.dart';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) async {
  if (notificationResponse.actionId != null) {
    final action = notificationResponse.actionId!;
    final payload = notificationResponse.payload ?? '';
    final prefs = await SharedPreferences.getInstance();

    if (action == 'pause_task') {
      if (payload == 'sunbathing') {
        final startTimeMs = prefs.getInt('sunbathing_start_time') ?? 0;
        final totalDuration = prefs.getInt('sunbathing_total_duration') ?? 15 * 60;
        if (startTimeMs > 0) {
          final startTime = DateTime.fromMillisecondsSinceEpoch(startTimeMs);
          final elapsed = DateTime.now().difference(startTime).inSeconds;
          final remaining = totalDuration - elapsed;
          await prefs.setInt('sunbathing_paused_remaining', remaining > 0 ? remaining : 0);
          await prefs.setBool('sunbathing_is_running', false);
          await prefs.remove('sunbathing_start_time');
        }
      } else if (payload == 'study') {
        final startTimeMs = prefs.getInt('study_start_time') ?? 0;
        final savedSeconds = prefs.getInt('study_seconds_remaining') ?? 25 * 60;
        if (startTimeMs > 0) {
          final startTime = DateTime.fromMillisecondsSinceEpoch(startTimeMs);
          final elapsed = DateTime.now().difference(startTime).inSeconds;
          final remaining = savedSeconds - elapsed;
          await prefs.setInt('study_seconds_remaining', remaining > 0 ? remaining : 0);
          await prefs.setBool('study_is_running', false);
          await prefs.remove('study_start_time');
        }
      } else if (payload == 'workout') {
        final startTimeMs = prefs.getInt('workout_start_time') ?? 0;
        final savedSeconds = prefs.getInt('workout_seconds_elapsed') ?? 0;
        if (startTimeMs > 0) {
          final startTime = DateTime.fromMillisecondsSinceEpoch(startTimeMs);
          final elapsed = DateTime.now().difference(startTime).inSeconds;
          final total = savedSeconds + elapsed;
          await prefs.setInt('workout_seconds_elapsed', total);
          await prefs.setBool('workout_is_running', false);
          await prefs.remove('workout_start_time');
        }
      } else if (payload == 'pacer') {
        await prefs.setBool('pacer_is_paused', true);
      }
    } else if (action == 'resume_task') {
      if (payload == 'sunbathing') {
        final pausedRemaining = prefs.getInt('sunbathing_paused_remaining') ?? 15 * 60;
        await prefs.setInt('sunbathing_total_duration', pausedRemaining);
        await prefs.setInt('sunbathing_start_time', DateTime.now().millisecondsSinceEpoch);
        await prefs.setBool('sunbathing_is_running', true);
        await prefs.remove('sunbathing_paused_remaining');
      } else if (payload == 'study') {
        await prefs.setInt('study_start_time', DateTime.now().millisecondsSinceEpoch);
        await prefs.setBool('study_is_running', true);
      } else if (payload == 'workout') {
        await prefs.setInt('workout_start_time', DateTime.now().millisecondsSinceEpoch);
        await prefs.setBool('workout_is_running', true);
      } else if (payload == 'pacer') {
        await prefs.setBool('pacer_is_paused', false);
      }
    } else if (action == 'stop_task') {
      if (payload == 'sunbathing') {
        await prefs.setBool('sunbathing_is_running', false);
        await prefs.remove('sunbathing_start_time');
        await prefs.remove('sunbathing_paused_remaining');
      } else if (payload == 'study') {
        await prefs.setBool('study_is_running', false);
        await prefs.remove('study_start_time');
        final plugin = FlutterLocalNotificationsPlugin();
        await plugin.cancel(id: 9997);
      } else if (payload == 'workout') {
        await prefs.setBool('workout_is_running', false);
        await prefs.remove('workout_start_time');
        await prefs.remove('workout_seconds_elapsed');
        final plugin = FlutterLocalNotificationsPlugin();
        await plugin.cancel(id: 9996);
      } else if (payload == 'pacer') {
        await prefs.setBool('pacer_is_running', false);
        final plugin = FlutterLocalNotificationsPlugin();
        await plugin.cancel(id: 9995);
      }
    }
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Curated motivational quotes (Atatürk, Stoics, Science, Turkish proverbs, no emojis)
  final List<Map<String, String>> _morningQuotes = [
    {
      'author': 'Mustafa Kemal Atatürk',
      'quote': 'Tek bir şeye ihtiyacımız vardır: Çalışkan olmak.',
    },
    {
      'author': 'Marcus Aurelius',
      'quote':
          'Güne başlarken kendinize söyleyin: Bugün bilgelik ve sabırla hareket edeceğim.',
    },
    {
      'author': 'Albert Einstein',
      'quote':
          'Öğrenmeyi bıraktığın an ölmeye başlarsın. Her sabah yeni bir şeyle başla.',
    },
    {
      'author': 'Türk Atasözü',
      'quote': 'İşleyen demir ışıldar. Çalışmak zihni ve bedeni dinç tutar.',
    },
    {
      'author': 'Seneca',
      'quote':
          'Hayat bir oyun gibidir, önemli olan ne kadar uzun oynandığı değil, ne kadar iyi oynandığıdır.',
    },
    {
      'author': 'Steve Jobs',
      'quote':
          'Zamanınız kısıtlı, bu yüzden onu başkasının hayatını yaşayarak harcamayın.',
    },
    {
      'author': 'Mustafa Kemal Atatürk',
      'quote': 'Vatanını en çok seven, görevini en iyi yapandır.',
    },
    {
      'author': 'Aristotle',
      'quote':
          'Mükemmellik bir eylem değil, bir alışkanlıktır. Günlük rutininizi koruyun.',
    },
  ];

  final List<Map<String, String>> _eveningQuotes = [
    {
      'author': 'Mustafa Kemal Atatürk',
      'quote': 'Hayatta en hakiki mürşit ilimdir, fendir.',
    },
    {
      'author': 'Seneca',
      'quote':
          'Zorluklar zihni güçlendirir, tıpkı çalışmanın bedeni güçlendirdiği gibi.',
    },
    {
      'author': 'Türk Atasözü',
      'quote':
          'Damlaya damlaya göl olur. Küçük adımlar büyük sonuçlar doğurur.',
    },
    {
      'author': 'Nikola Tesla',
      'quote':
          'Yaşadığım sürece çalışmaya devam edeceğim, zira beni hayatta tutan şey budur.',
    },
    {
      'author': 'Benjamin Franklin',
      'quote': 'Bilgiye yapılan yatırım en yüksek faizi getirir.',
    },
    {
      'author': 'Leonardo da Vinci',
      'quote': 'Öğrenmek zihni asla yormaz, onu besler ve canlandırır.',
    },
    {
      'author': 'Türk Atasözü',
      'quote': 'Emek olmadan yemek olmaz. Başarı gayret gerektirir.',
    },
    {
      'author': 'Thomas Edison',
      'quote': 'Ben hiç hata yapmadım. Sadece çalışmayan 10.000 yol buldum.',
    },
  ];

  final List<Map<String, String>> _nightQuotes = [
    {
      'author': 'Mustafa Kemal Atatürk',
      'quote': 'Gençliği yetiştiriniz. Onlara bilim ve kültür veriniz.',
    },
    {
      'author': 'Marcus Aurelius',
      'quote':
          'Günün sonunda zihninizi huzura kavuşturun. Yaptığınız iyi şeyleri düşünün.',
    },
    {
      'author': 'Türk Atasözü',
      'quote':
          'Ağaç yaşken eğilir. Öğrenmeye ve gelişmeye her yaşta devam edin.',
    },
    {
      'author': 'Socrates',
      'quote': 'Sorgulanmamış bir hayat yaşanmaya değmez. Bugün ne öğrendiniz?',
    },
    {
      'author': 'Seneca',
      'quote':
          'Yarının neler getireceğini bilmeden yaşa, ama bu günü en verimli şekilde bitir.',
    },
    {
      'author': 'Albert Einstein',
      'quote':
          'Karmaşıklığın ortasında sadeliği bulun. Zorlukların içinde fırsat yatar.',
    },
    {
      'author': 'Steve Jobs',
      'quote': 'Harika işler yapmanın tek yolu, yaptığınız işi sevmektir.',
    },
    {
      'author': 'Nikola Tesla',
      'quote':
          'Bizi biz yapan şey, fikirlerimize olan bağlılığımız ve harcadığımız emektir.',
    },
  ];

  // Default words for spaced repetition fallback across various languages (No emojis)
  final List<Map<String, String>> _defaultVocab = [
    {
      'word': 'Consistency (İngilizce: Tutarlılık)',
      'meaning': 'Başarının anahtarı her gün adım atmaktır.',
    },
    {
      'word': 'Persistencia (İspanyolca: Kararlılık)',
      'meaning': 'Amaçlarınıza ulaşmak için yılmadan çalışmaktır.',
    },
    {
      'word': 'Disziplin (Almanca: Disiplin)',
      'meaning': 'Hedefleriniz ile başarınız arasındaki bağdır.',
    },
    {
      'word': 'Apprentissage (Fransızca: Öğrenme)',
      'meaning': 'Zihni her zaman dinamik tutar.',
    },
    {
      'word': 'Pazienza (İtalyanca: Sabır)',
      'meaning': 'Her başarılı sürecin temelidir.',
    },
    {
      'word': 'Kaizen (Japonca: Sürekli Gelişim)',
      'meaning': 'Her gün küçük adımlarla kendinizi geliştirmektir.',
    },
    {
      'word': 'Al-Azima (Arapça: Azim)',
      'meaning': 'Zorluklar karşısında direnmek ve başarıya ulaşmaktır.',
    },
    {
      'word': 'Trud (Rusça: Emek)',
      'meaning': 'Gelişimin ve başarının temel taşıdır.',
    },
  ];

  Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotificationsPlugin.initialize(
      settings: initSettings,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
      onDidReceiveNotificationResponse: (response) {
        // Foreground tap handling (optional navigation)
        notificationTapBackground(response);
      },
    );

    // Request permissions for Android 13+
    final androidImplementation = _localNotificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidImplementation?.requestNotificationsPermission();
    await androidImplementation?.requestExactAlarmsPermission();

    // Schedule the 28 rotating weekly notifications (quotes + spaced repetition)
    await scheduleDailyReminders();
  }

  // Schedule a task reminder with custom duration before the task starts
  Future<void> scheduleTaskReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    int minutesBefore = 15,
  }) async {
    final reminderTime = scheduledTime.subtract(
      Duration(minutes: minutesBefore),
    );

    if (reminderTime.isBefore(DateTime.now())) {
      return;
    }

    final androidDetails = const AndroidNotificationDetails(
      'task_reminders',
      'Gorev Hatirlaticilari',
      channelDescription: 'Planlanmis gorevler icin hatirlatmalar',
      importance: Importance.max,
      priority: Priority.high,
    );

    final iosDetails = const DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotificationsPlugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(reminderTime, tz.local),
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  // Schedule weekly repeating notifications for learning retention (4 times a day, 7 days a week)
  // According to Ebbinghaus forgetting curve, spaced repetition at 1h, 4h, 8h is optimal.
  // 4 times a day (09:00, 13:00, 18:00, 21:30) is the optimal frequency.
  Future<void> scheduleDailyReminders() async {
    // Load vocabulary for spaced repetition
    final prefs = await SharedPreferences.getInstance();
    final vocabRaw = prefs.getString('lang_vocab_list') ?? '[]';
    List<Map<String, dynamic>> vocabList = [];
    try {
      vocabList = List<Map<String, dynamic>>.from(json.decode(vocabRaw));
    } catch (_) {}

    final androidDetails = const AndroidNotificationDetails(
      'daily_retention_channel',
      'Kisisel Gelisim ve Hatirlaticilar',
      channelDescription: 'Gunluk ogrenme, motivasyon ve zihin hatirlaticilari',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    final iosDetails = const DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final now = DateTime.now();

    // Loop through 7 days of the week to create a distinct schedule for each day
    for (int day = 1; day <= 7; day++) {
      // Find the next occurrence of this weekday (1 = Monday, 7 = Sunday)
      int daysUntil = day - now.weekday;
      if (daysUntil <= 0) daysUntil += 7;
      final targetDate = now.add(Duration(days: daysUntil));

      // 1. Morning Motivation Quote (09:00)
      final morningQuote = _morningQuotes[(day - 1) % _morningQuotes.length];
      final morningTime = tz.TZDateTime(
        tz.local,
        targetDate.year,
        targetDate.month,
        targetDate.day,
        9, // 09:00 AM
        0,
      );
      await _localNotificationsPlugin.zonedSchedule(
        id: 9000 + day, // Unique IDs 9001 - 9007
        title: 'Gunun Motivasyonu',
        body: '${morningQuote['quote']} - ${morningQuote['author']}',
        scheduledDate: morningTime,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );

      // 2. Midday Spaced Repetition (13:00)
      // Pick a vocabulary word from user list or fallback
      String vocabTitle = 'Kelimemi Hatirla';
      String vocabBody = '';

      if (vocabList.isNotEmpty) {
        final item = vocabList[(day - 1) % vocabList.length];
        vocabTitle = 'Kelime Hatirlatici: ${item['word'] ?? ''}';
        vocabBody =
            'Anlami: ${item['meaning'] ?? ''}. Cumle: ${item['sentence'] ?? ''}';
      } else {
        final item = _defaultVocab[(day - 1) % _defaultVocab.length];
        vocabTitle = 'Kelimeni Ogren: ${item['word']}';
        vocabBody = item['meaning']!;
      }

      final noonTime = tz.TZDateTime(
        tz.local,
        targetDate.year,
        targetDate.month,
        targetDate.day,
        13, // 01:00 PM
        0,
      );
      await _localNotificationsPlugin.zonedSchedule(
        id: 9100 + day, // Unique IDs 9101 - 9107
        title: vocabTitle,
        body: vocabBody,
        scheduledDate: noonTime,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );

      // 3. Evening Study Reminder (18:00)
      final eveningQuote = _eveningQuotes[(day - 1) % _eveningQuotes.length];
      final eveningTime = tz.TZDateTime(
        tz.local,
        targetDate.year,
        targetDate.month,
        targetDate.day,
        18, // 06:00 PM
        0,
      );
      await _localNotificationsPlugin.zonedSchedule(
        id: 9200 + day, // Unique IDs 9201 - 9207
        title: 'Calisma Zamani',
        body: '${eveningQuote['quote']} - ${eveningQuote['author']}',
        scheduledDate: eveningTime,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );

      // 4. Night Reflection Quote (21:30)
      final nightQuote = _nightQuotes[(day - 1) % _nightQuotes.length];
      final nightTime = tz.TZDateTime(
        tz.local,
        targetDate.year,
        targetDate.month,
        targetDate.day,
        21, // 09:30 PM
        30,
      );
      await _localNotificationsPlugin.zonedSchedule(
        id: 9300 + day, // Unique IDs 9301 - 9307
        title: 'Gunun Ozeti',
        body: '${nightQuote['quote']} - ${nightQuote['author']}',
        scheduledDate: nightTime,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    }
  }

  Future<void> cancelReminder(int id) async {
    await _localNotificationsPlugin.cancel(id: id);
  }

  // Sunbathing specific notifications
  Future<void> scheduleSunbathingAlarm({
    required int durationSeconds,
    required String title,
    required String body,
  }) async {
    final scheduledTime = DateTime.now().add(Duration(seconds: durationSeconds));

    final androidDetails = const AndroidNotificationDetails(
      'sunbathing_alarm',
      'Güneşlenme Alarmları',
      channelDescription: 'Güneşlenme süresi dolduğunda çalan alarmlar',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    final iosDetails = const DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotificationsPlugin.zonedSchedule(
      id: 9999, // Unique ID for sunbathing
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(scheduledTime, tz.local),
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> cancelSunbathingAlarm() async {
    await _localNotificationsPlugin.cancel(id: 9999);
  }

  Future<void> showOngoingNotification({
    required int id,
    required String title,
    required String body,
    required int durationSeconds,
    required String taskType,
    bool isPaused = false,
  }) async {
    final actions = <AndroidNotificationAction>[];
    
    if (isPaused) {
      actions.add(const AndroidNotificationAction(
        'resume_task',
        '▶️ Devam Et',
        showsUserInterface: true,
      ));
    } else {
      actions.add(const AndroidNotificationAction(
        'pause_task',
        '⏸️ Durdur',
        showsUserInterface: true,
      ));
    }
    
    actions.add(const AndroidNotificationAction(
      'stop_task',
      '⏹️ Bitir',
      showsUserInterface: true,
      cancelNotification: true,
    ));

    final androidDetails = AndroidNotificationDetails(
      'ongoing_tasks_channel',
      'Aktif İşlemler',
      channelDescription: 'Devam eden işlemlerin gösterildiği bildirimler',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: !isPaused,
      autoCancel: false,
      showWhen: true,
      usesChronometer: !isPaused, // Sadece devam ederken sayaç akar
      chronometerCountDown: true,
      when: isPaused ? 0 : DateTime.now().millisecondsSinceEpoch + (durationSeconds * 1000),
      playSound: false,
      enableVibration: false,
      actions: actions,
    );

    final iosDetails = const DarwinNotificationDetails(
      presentAlert: false,
      presentBadge: false,
      presentSound: false,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      payload: taskType,
      notificationDetails: details,
    );
  }

  Future<void> cancelOngoingNotification(int id) async {
    await _localNotificationsPlugin.cancel(id: id);
  }
}
