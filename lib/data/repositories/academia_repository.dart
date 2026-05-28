import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';

class AcademiaRepository {
  final _supabase = Supabase.instance.client;

  /// CORRIGIDO: Retorna a LISTA de todas as filiais do professor
  Future<List<Map<String, dynamic>>> listarMinhasFiliais() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw 'Usuário não autenticado';

    try {
      final response = await _supabase
          .from('academias')
          .select()
          .eq('responsavel_id', user.id)
          .order('nome', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw 'Erro ao listar filiais: $e';
    }
  }

  //* CORRIGIDO: Retorna a MÉDIA de evolução dos alunos da academia do professor
  Future<double> buscarEvolucaoMedia() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception("Usuário não autenticado");

    final academia = await _supabase
        .from('academias')
        .select('id')
        .eq('responsavel_id', user.id)
        .maybeSingle();

    if (academia == null) return 0.0;

    final dados = await _supabase
        .from('view_evolucao_media')
        .select()
        .eq('academia_id', academia['id'])
        .maybeSingle();

    return (dados?['media_variacao_30d'] as num?)?.toDouble() ?? 0.0;
  }

  //* CORRIGIDO: Retorna o RANKING dos 3 alunos com maior evolução dos últimos 30 dias
  Future<List<Map<String, dynamic>>> buscarRankingEvolucao() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception("Usuário não autenticado");

    final academia = await _supabase
        .from('academias')
        .select('id')
        .eq('responsavel_id', user.id)
        .maybeSingle();

    if (academia == null) return [];

    final academiaId = academia['id'];

    final dados = await _supabase
        .from('view_ranking_evolucao')
        .select()
        .eq('academia_id', academiaId)
        .limit(3);

    return List<Map<String, dynamic>>.from(dados);
  }

  //* CORRIGIDO: Retorna os dados para o gráfico de evolução da academia
  Future<List<Map<String, dynamic>>> buscarGraficoAcademia() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    final academia = await _supabase
        .from('academias')
        .select('id')
        .eq('responsavel_id', user.id)
        .maybeSingle();

    if (academia == null) return [];

    final academiaId = academia['id'];

    final dados = await _supabase
        .from('view_grafico_academia')
        .select()
        .eq('academia_id', academiaId)
        .order('data_registro', ascending: true);

    return List<Map<String, dynamic>>.from(dados);
  }

  //* NOVA FUNÇÃO: Cadastra uma nova filial gerando um código único de acesso
  Future<void> criarNovaFilial({
    required String nome,
    required String endereco,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw 'Usuário não autenticado';

    try {
      // Gera um código aleatório de 7 dígitos (ex: 6343498)
      final String novoCodigo = (1000000 + Random().nextInt(9000000))
          .toString();

      await _supabase.from('academias').insert({
        'nome': nome.trim(),
        'endereco': endereco.trim(),
        'responsavel_id': user.id,
        'codigo_acesso': novoCodigo,
      });
    } catch (e) {
      throw 'Erro ao criar nova filial: $e';
    }
  }

  /// Atualiza os dados cadastrais da academia específica
  Future<void> atualizarDadosFilial({
    required int id,
    required String nome,
    required String endereco,
  }) async {
    try {
      await _supabase
          .from('academias')
          .update({'nome': nome.trim(), 'endereco': endereco.trim()})
          .eq('id', id);
    } catch (e) {
      throw 'Erro ao atualizar dados: $e';
    }
  }

  /// Busca dados consolidados da view_consolidada
  Future<Map<String, dynamic>?> buscarDadosConsolidados() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('Usuário não autenticado');
    }

    try {
      // 1️⃣ Buscar a academia vinculada ao professor
      final academia = await _supabase
          .from('academias')
          .select('id, nome, codigo_acesso')
          .eq('responsavel_id', user.id)
          .maybeSingle();

      if (academia == null) return null;

      final academiaId = academia['id'];

      // 2️⃣ Buscar métricas consolidadas na view
      final consolidado = await _supabase
          .from('view_consolidada')
          .select()
          .eq('academia_id', academiaId)
          .maybeSingle();

      // 3️⃣ Unir dados da academia com dados consolidados
      return {
        'nome': academia['nome'],
        'codigo_acesso': academia['codigo_acesso'],
        'total_alunos': consolidado?['total_alunos'] ?? 0,
        'media_imc': consolidado?['media_imc'] ?? 0,
      };
    } catch (e) {
      throw Exception('Erro ao buscar dados consolidados: $e');
    }
  }
}
