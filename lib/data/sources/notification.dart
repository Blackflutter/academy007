import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificacoesService {
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  Future<void> inicializar() async {
    const androidConfig = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosConfig = DarwinInitializationSettings();
    
    await _plugin.initialize(
      const InitializationSettings(android: androidConfig, iOS: iosConfig)
    );
  }

  Future<void> agendarBeepLocal({
    required int id,
    required String titulo,
    required String corpo,
    required DateTime horarioAgendado,
  }) async {
    // Configura o canal para forçar o som e o uso de beep padrão do sistema
    const androidDetalhes = AndroidNotificationDetails(
      'canal_alimentacao_007',
      'Alertas de Alimentação',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true, // Garante a execução do som
      enableVibration: true,
    );

    const iosDetalhes = DarwinNotificationDetails(presentSound: true);

    await _plugin.zonedSchedule(
      id,
      titulo,
      corpo,
      tz.TZDateTime.from(horarioAgendado, tz.local),
      const NotificationDetails(android: androidDetalhes, iOS: iosDetalhes),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle, // Toca mesmo com o app fechado
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // Repete todo dia nesse horário
    );
  }
}
