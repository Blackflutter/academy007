import 'package:academy007/data/sources/notification.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AlarmeController {
  final _supabase = Supabase.instance.client;
  final _notificacoes = NotificacoesService();

  Future<void> sincronizarAlarmesAluno() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    // 1. Busca os planos onde o "notificar" está ativado no banco
    final List<dynamic> dados = await _supabase
        .from('plano_alimentar')
        .select('id, titulo, descricao, horario')
        .eq('aluno_id', user.id)
        .eq('notificar', true);

    // 2. Inicializa o serviço de som/notificação do celular
    await _notificacoes.inicializar();

    // 3. Passa por cada refeição agendando o horário local no sistema operacional
    for (var item in dados) {
      final String stringHorario =
          item['horario']; // Formato vindo do banco "HH:mm:ss"
      final partesHora = stringHorario.split(':');

      final agora = DateTime.now();
      final horarioAlarme = DateTime(
        agora.year,
        agora.month,
        agora.day,
        int.parse(partesHora[0]), // Hora
        int.parse(partesHora[1]), // Minuto
      );

      // Agenda o disparo do som no celular do aluno
      await _notificacoes.agendarBeepLocal(
        id: item['id'], // Usa o próprio ID da tabela como ID do alarme
        titulo: 'Academy007: ${item['titulo']}',
        corpo: item['descricao'] ?? 'Hora de se alimentar!',
        horarioAgendado: horarioAlarme,
      );
    }
  }
}
