import 'package:flutter/foundation.dart'; // Necessário para kIsWeb
import 'package:academy007/data/sources/notification.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AlarmeController {
  final _supabase = Supabase.instance.client;
  final _notificacoes = NotificacoesService();

  Future<void> sincronizarAlarmesAluno() async {
    // 🟢 PROTEÇÃO PARA WEB: O plugin de alarme local não funciona no Chrome/Navegador.
    // Isso evita o erro de "LateInitializationError" durante seus testes no PC.
    if (kIsWeb) {
      debugPrint("Sincronização de alarmes ignorada: Ambiente Web detectado.");
      return;
    }

    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      await _notificacoes.inicializar();
      await _notificacoes.cancelarTodosOsAlarmes();

      await _sincronizarAlimentacao(user.id);
      await _sincronizarTreinos();
    } catch (e) {
      debugPrint("Erro ao sincronizar alarmes locais: $e");
    }
  }

  Future<void> _sincronizarAlimentacao(String userId) async {
    final List<dynamic> dadosAlimentacao = await _supabase
        .from('plano_alimentar')
        .select('id, titulo, descricao, horario')
        .eq('aluno_id', userId)
        .eq('notificar', true);

    for (var item in dadosAlimentacao) {
      if (item['horario'] == null) continue;
      final horarioAlarme = _converterStringParaDateTime(item['horario']);

      await _notificacoes.agendarBeepLocal(
        id: item['id'],
        titulo: 'Alimentação: ${item['titulo']}',
        corpo: item['descricao'] ?? 'Hora de se alimentar!',
        horarioAgendado: horarioAlarme,
      );
    }
  }

  Future<void> _sincronizarTreinos() async {
    // 🟢 CORREÇÃO: Removemos o .eq('aluno_id') porque treinos coletivos filtram apenas por notificações ativas
    final List<dynamic> dadosTreino = await _supabase
        .from('treinos_coletivos')
        .select('id, titulo, descricao_treino, horario')
        .eq('notificar', true);

    for (var item in dadosTreino) {
      if (item['horario'] == null) continue;
      final horarioAlarme = _converterStringParaDateTime(item['horario']);

      await _notificacoes.agendarBeepLocal(
        id: item['horario'].hashCode,
        titulo: 'Treino: ${item['titulo'] ?? 'Hora de Treinar'}',
        corpo: item['descricao_treino'] ?? 'Prepare o foco e bora treinar!',
        horarioAgendado: horarioAlarme,
      );
    }
  }

  DateTime _converterStringParaDateTime(String stringHorario) {
    final partesHora = stringHorario.split(':');
    final agora = DateTime.now();

    var horarioAlarme = DateTime(
      agora.year,
      agora.month,
      agora.day,
      int.parse(partesHora[0]),
      int.parse(partesHora[1]),
    );

    if (horarioAlarme.isBefore(agora)) {
      horarioAlarme = horarioAlarme.add(const Duration(days: 1));
    }

    return horarioAlarme;
  }
}
