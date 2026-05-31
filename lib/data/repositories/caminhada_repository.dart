import 'package:supabase_flutter/supabase_flutter.dart';

class CaminhadaRepository {
  final _supabase = Supabase.instance.client;

  // Salva a caminhada no banco
  Future<void> salvarCaminhada({
    required String alunoId,
    required double distanciaKm,
    required int passos,
    required double calorias,
    required int duracaoMinutos,
    required List<Map<String, double>> trajeto,
    required double velocidadeMedia,
  }) async {
    await _supabase.from('caminhadas').insert({
      'aluno_id': alunoId,
      'distancia_km': distanciaKm,
      'passos': passos,
      'calorias': calorias,
      'duracao_minutos': duracaoMinutos,
      'trajeto': trajeto,
      'velocidade_media': velocidadeMedia,
    });
  }

  // Busca histórico de caminhadas do aluno
  Future<List<Map<String, dynamic>>> buscarHistorico(String alunoId) async {
    final response = await _supabase
        .from('caminhadas')
        .select()
        .eq('aluno_id', alunoId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }
}
