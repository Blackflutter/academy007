import 'package:supabase_flutter/supabase_flutter.dart';

class GrupoRepositoryListarTodosAlunos {
  final _supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> listarTodosAlunos() async {
    try {
      final response = await _supabase
          .from('perfis')
          .select('id, nome, peso_atual, anamnese')
          .order('nome');

      if (response == null) return [];

      // CORREÇÃO: Mapeamento manual tratando cada valor individualmente
      // Evita o erro de tipo se id for UUID string e peso for int/double
      return (response as List).map((item) {
        final map = item as Map<String, dynamic>;
        return {
          'id':
              map['id']?.toString() ??
              '', // Garante que o ID do aluno seja String
          'nome': map['nome']?.toString() ?? 'Sem Nome',
          'peso_atual':
              map['peso_atual']?.toString() ??
              '0', // Converte peso para String seguro
          'anamnese': map['anamnese']?.toString() ?? 'Não preenchida',
        };
      }).toList();
    } catch (e) {
      throw 'Erro ao listar alunos: $e';
    }
  }
}
