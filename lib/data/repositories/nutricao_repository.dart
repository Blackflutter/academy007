import 'package:supabase_flutter/supabase_flutter.dart';

class NutricaoRepository {
  final _supabase = Supabase.instance.client;

  // Busca as refeições do aluno logado
  Future<List<Map<String, dynamic>>> buscarPlano() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    return await _supabase
        .from('plano_alimentar')
        .select()
        .eq('aluno_id', user.id)
        .order('horario', ascending: true);
  }

  // Marca como concluído/não concluído
  Future<void> alternarConcluido(int id, bool status) async {
    await _supabase
        .from('plano_alimentar')
        .update({'concluido': status})
        .eq('id', id);
  }
}
