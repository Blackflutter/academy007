import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificacoesService {
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// Inicializa o serviço e configura permissões
  Future<void> inicializar() async {
    // Inicializa dados de fuso horário (obrigatório para agendamento)
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(initSettings);
  }

  /// Agenda um alarme/notificação local
  Future<void> agendarBeepLocal({
    required int id,
    required String titulo,
    required String corpo,
    required DateTime horarioAgendado,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'academy007_alarmes',
      'Alarmes do App',
      channelDescription: 'Canal para alertas de treinos e refeições',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentSound: true,
      presentAlert: true,
      presentBadge: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final tz.TZDateTime tempoConvertido = tz.TZDateTime.from(
      horarioAgendado,
      tz.local,
    );

    await _localNotifications.zonedSchedule(
      id,
      titulo,
      corpo,
      tempoConvertido,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents:
          DateTimeComponents.time, // Repete diariamente no mesmo horário
    );
  }

  /// Cancela um alarme específico
  Future<void> cancelarAlarme(int id) async {
    await _localNotifications.cancel(id);
  }

  /// Cancela todos os alarmes
  Future<void> cancelarTodosOsAlarmes() async {
    await _localNotifications.cancelAll();
  }
}
