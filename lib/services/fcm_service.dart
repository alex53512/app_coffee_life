import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'api_service.dart';
import 'app_state.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  final data = message.data;
  debugPrint('FCM background: ${message.notification?.title} / $data');
}

class FcmService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static final ValueNotifier<RemoteMessage?> pendingNotification =
      ValueNotifier(null);

  static String? _currentToken;
  static String? get currentToken => _currentToken;

  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized || kIsWeb) return;
    _initialized = true;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _localNotifications.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    final messaging = FirebaseMessaging.instance;

    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    debugPrint('FCM permission: ${settings.authorizationStatus}');

    _currentToken = await messaging.getToken();
    debugPrint('FCM token: $_currentToken');

    messaging.onTokenRefresh.listen((token) {
      _currentToken = token;
      _registerToken(token);
    });

    await _registerToken(_currentToken);

    RemoteMessage? initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      pendingNotification.value = initialMessage;
    }

    FirebaseMessaging.onMessage.listen(_onForegroundMessage);

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      pendingNotification.value = message;
    });

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  static Future<void> registerToken() {
    if (!_initialized) return Future.value();
    return _registerToken(_currentToken);
  }

  static Future<void> _registerToken(String? token) async {
    if (token == null || token.isEmpty) return;
    try {
      await ApiService.post('/usuarios/fcm-token', {'token': token});
      // ignore: avoid_print
      debugPrint('FCM TOKEN REGISTRADO: $token');
    } catch (_) {}
  }

  static Future<void> _onForegroundMessage(RemoteMessage message) async {
    final data = message.data;
    final esExperto = (data['tipoRecomendacion'] ?? data['tipo'] ?? '')
        .toString()
        .toLowerCase()
        .contains('diagnostico');
    AppState.instance.agregarNotificacion({
      'titulo': message.notification?.title ?? 'Notificación',
      'mensaje': message.notification?.body ?? '',
      'tipoRecomendacion': esExperto ? 'diagnostico_experto' : (data['tipo'] ?? 'notificacion'),
      'idMonitoreo': data['idMonitoreo'] ?? data['id_monitoreo'],
      'id_monitoreo': data['idMonitoreo'] ?? data['id_monitoreo'],
      'leida': false,
    });
    final notification = message.notification;
    if (notification == null) return;

    const androidDetails = AndroidNotificationDetails(
      'coffee_life_channel',
      'Coffee Life',
      channelDescription: 'Notificaciones de Coffee Life',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const iosDetails = DarwinNotificationDetails();

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      const NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      ),
      payload: data['idMonitoreo']?.toString() ??
          data['id_monitoreo']?.toString(),
    );
  }

  static void _onNotificationTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null && payload.isNotEmpty) {
      pendingNotification.value = RemoteMessage(
        senderId: '',
        data: {'idMonitoreo': payload, 'id_monitoreo': payload},
        messageId: payload,
      );
    }
  }

  static void consumePendingNotification() {
    pendingNotification.value = null;
  }
}
