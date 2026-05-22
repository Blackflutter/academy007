import 'package:supabase_flutter/supabase_flutter.dart';

class GrupoRepositoryCriar {
  final _supabase = Supabase.instance.client;

  // --- MÉTODOS DE GESTÃO DE GRUPOS (PROFESSOR) ---

  Future<void> criarGrupo(String nome, String descricao) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw 'Professor não autenticado';
    try {
      await _supabase.from('grupos').insert({
        'nome': nome,
        'descricao': descricao,
        'professor_id': user.id,
      });
    } catch (e) {
      throw 'Erro ao criar grupo: $e';
    }
  }
}
