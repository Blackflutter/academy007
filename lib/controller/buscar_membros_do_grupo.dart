import 'package:supabase_flutter/supabase_flutter.dart';

class GrupoRepositoryBuscarMembrosDoGrupo {
  final _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> buscarMembrosDoGrupo(
    String grupoId,
  ) async {
    try {
      final response = await _supabase
          .from('grupo_alunos')
          .select('aluno_id')
          .eq('grupo_id', grupoId.trim());

      if (response.isEmpty) {
        return [];
      }

      final alunoIds = (response as List)
          .map((item) => item['aluno_id'].toString())
          .toList();

      final perfis = await _supabase
          .from('perfis')
          .select('id, nome, peso_atual, altura, anamnese')
          .inFilter('id', alunoIds);

      return List<Map<String, dynamic>>.from(perfis);
    } catch (e) {
      throw 'Erro ao carregar membros: $e';
    }
  }
}
