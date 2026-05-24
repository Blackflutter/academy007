import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificacoesService {
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Inicializa o serviço e configura as permissões
  Future<void> inicializar() async {
    // Inicializa os dados de fuso horário (obrigatório para agendamentos)
    tz.initializeTimeZones();

    // Configuração para Android
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    // Configuração para iOS
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

  // Configura e agenda o disparo do alarme/beep local
  Future<void> agendarBeepLocal({
    required int id,
    required String titulo,
    required String corpo,
    required DateTime horarioAgendado,
  }) async {
    // Configura o canal de notificação do Android (som, importância e vibração)
    const androidDetails = AndroidNotificationDetails(
      'academy007_alarmes', // ID do canal
      'Alarmes do App', // Nome do canal visível ao usuário
      channelDescription: 'Canal para alertas de treinos e refeições',
      importance: Importance.max,
      priority: Priority.high,
      sound: RawResourceAndroidNotificationSound(
        'notification_sound',
      ), // Nome do arquivo de som (opcional)
      playSound: true,
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

    // Converte o DateTime local para o formato de fuso horário do Timezone
    final tz.TZDateTime tempoConvertido = tz.TZDateTime.from(
      horarioAgendado,
      tz.local,
    );

    // Agenda a notificação baseada no horário exato
    await _localNotifications.zonedSchedule(
      id,
      titulo,
      corpo,
      tempoConvertido,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode
          .exactAllowWhileIdle, // Garante disparo mesmo com o celular em repouso
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // Cancela um alarme específico se necessário
  Future<void> cancelarAlarme(int id) async {
    await _localNotifications.cancel(id);
  }

  // Limpa todos os alarmes agendados
  Future<void> cancelarTodosOsAlarmes() async {
    await _localNotifications.cancelAll();
  }
}
