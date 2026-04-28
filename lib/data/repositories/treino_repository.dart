import 'package:supabase_flutter/supabase_flutter.dart';

class TreinoRepository {
  final _supabase = Supabase.instance.client;

  /// Busca exercícios por categoria
  Future<List<Map<String, dynamic>>> buscarExerciciosPorCategoria(
    int categoriaId,
  ) async {
    try {
      return await _supabase
          .from('exercicios')
          .select()
          .eq('categoria_id', categoriaId)
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

  /// REPOSITÓRIO ATUALIZADO
  Future<List<Map<String, dynamic>>> buscarExerciciosNaoConcluidos(
    int categoriaId,
  ) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    final hoje = DateTime.now().toIso8601String().substring(0, 10);

    try {
      // 1. Primeiro, buscamos os IDs dos exercícios que o aluno JÁ FEZ hoje
      final concluidoshoje = await _supabase
          .from('treinos_concluidos')
          .select('exercicio_id')
          .eq('aluno_id', user.id)
          .gte('data_conclusao', hoje);

      // Criamos uma lista só com os IDs: [1, 5, 8...]
      final List<int> idsConcluidos = List<int>.from(
        concluidoshoje.map((item) => item['exercicio_id']),
      );

      // 2. Agora buscamos os exercícios da categoria que NÃO ESTÃO nessa lista de IDs
      var query = _supabase
          .from('exercicios')
          .select()
          .eq('categoria_id', categoriaId);

      if (idsConcluidos.isNotEmpty) {
        // O filtro 'not.in' exclui os IDs que já foram concluídos
        query = query.not('id', 'in', idsConcluidos);
      }

      return await query.order('nome', ascending: true);
    } catch (e) {
      throw 'Erro ao filtrar exercícios: $e';
    }
  }

  /// Registra que o aluno completou o exercício no histórico
  Future<void> concluirExercicio(int exercicioId) async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw 'Você precisa estar logado para salvar o progresso.';
    }

    try {
      await _supabase.from('treinos_concluidos').insert({
        'aluno_id': user.id,
        'exercicio_id': exercicioId,
        'data_conclusao': DateTime.now().toIso8601String(),
      });
    } on PostgrestException catch (e) {
      throw 'Erro ao salvar conclusão: ${e.message}';
    } catch (e) {
      throw 'Erro inesperado: $e';
    }
  }

  /// NOVO: Busca o histórico completo com o nome do exercício (Join)
  Future<List<Map<String, dynamic>>> buscarHistoricoCompleto() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    try {
      // O 'exercicios(*)' busca os dados da tabela relacionada
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

  /// NOVO: Busca o total de treinos realizados hoje (para a Dashboard)
  Future<int> buscarTotalTreinosHoje() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return 0;

    // Formato YYYY-MM-DD
    final hoje = DateTime.now().toIso8601String().substring(0, 10);

    try {
      // A forma mais estável de contar registros atualmente:
      final response = await _supabase
          .from('treinos_concluidos')
          .select() // Busca os registros
          .eq('aluno_id', user.id)
          .gte('data_conclusao', hoje);

      // Retornamos o tamanho da lista gerada
      return (response as List).length;
    } catch (e) {
      return 0;
    }
  }
}
