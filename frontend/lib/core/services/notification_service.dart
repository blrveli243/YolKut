import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

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

    await _localNotificationsPlugin.initialize(settings: initSettings);

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
}
