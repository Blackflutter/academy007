import 'package:supabase_flutter/supabase_flutter.dart';

class TreinoRepository {
  final _supabase = Supabase.instance.client;

  /// Busca exercícios por categoria (Apenas os não concluídos para não voltarem como fantasma)
  Future<List<Map<String, dynamic>>> buscarExerciciosPorCategoria(
    int categoriaId,
  ) async {
    try {
      return await _supabase
          .from('exercicios')
          .select()
          .eq('categoria_id', categoriaId)
          .eq(
            'concluido',
            false,
          ) // 🟢 CORREÇÃO: Garante que os concluídos sumam da listagem geral
          .order('nome', ascending: true);
    } catch (e) {
      throw 'Erro ao buscar exercícios: $e';
    }
  }

  Future<List<Map<String, dynamic>>> buscarCategorias() async {
    try {
      final response = await _supabase
          .from('categorias')
          .select()
          .order('nome', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  /// Busca exercícios pendentes mapeando os tipos com segurança
  Future<List<Map<String, dynamic>>> buscarExerciciosNaoConcluidos(
    int categoriaId,
  ) async {
    try {
      final List<dynamic> response = await _supabase
          .from('exercicios')
          .select()
          .eq('categoria_id', categoriaId)
          .eq('concluido', false);

      return List<Map<String, dynamic>>.from(
        response.map((item) {
          return {
            'id': int.tryParse(item['id'].toString()) ?? 0,
            'categoria_id':
                int.tryParse(item['categoria_id'].toString()) ?? categoriaId,
            'nome': item['nome'] ?? 'Sem nome',
            'descricao': item['descricao'] ?? '',
            'concluido':
                item['concluido'] ??
                false, // 🟢 CORREÇÃO: Mantém o estado boolean explícito na memória
          };
        }),
      );
    } catch (e) {
      throw 'Erro ao filtrar exercícios: $e';
    }
  }

  /// Registra que o aluno completou o exercício alterando a flag na tabela
  Future<void> concluirExercicio(int exercicioId) async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw 'Você precisa estar logado para salvar o progresso.';
    }

    try {
      await _supabase
          .from('exercicios')
          .update({'concluido': true})
          .eq('id', exercicioId);
    } on PostgrestException catch (e) {
      throw 'Erro ao salvar conclusão: ${e.message}';
    } catch (e) {
      throw 'Erro inesperado: $e';
    }
  }

  /// Busca o histórico completo com o nome do exercício (Join)
  Future<List<Map<String, dynamic>>> buscarHistoricoCompleto() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    try {
      final response = await _supabase
          .from('treinos_concluidos')
          .select('*, exercicios(*)')
          .eq('aluno_id', user.id)
          .order('data_conclusao', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw 'Erro ao carregar histórico: $e';
    }
  }

  /// Busca o total de treinos realizados hoje (para a Dashboard)
  Future<int> buscarTotalTreinosHoje() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return 0;

    final hoje = DateTime.now().toIso8601String().substring(0, 10);

    try {
      final response = await _supabase
          .from('treinos_concluidos')
          .select()
          .eq('aluno_id', user.id)
          .gte('data_conclusao', hoje);

      return (response as List).length;
    } catch (e) {
      return 0;
    }
  }
}
