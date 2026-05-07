import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/grupo_model.dart';

class GrupoRepository {
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

  Future<List<GrupoModel>> listarMeusGrupos() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];
    final response = await _supabase
        .from('grupos')
        .select()
        .eq('professor_id', user.id);
    return (response as List).map((map) => GrupoModel.fromMap(map)).toList();
  }

  Future<List<Map<String, dynamic>>> listarTodosAlunos() async {
    try {
      final response = await _supabase
          .from('perfis')
          .select('id, nome, peso_atual, anamnese')
          .order('nome');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw 'Erro ao listar alunos: $e';
    }
  }

  Future<void> adicionarAlunoAoGrupo(String grupoId, String alunoId) async {
    try {
      await _supabase.from('grupo_alunos').insert({
        'grupo_id': grupoId,
        'aluno_id': alunoId,
      });
    } catch (e) {
      throw 'Erro ao adicionar aluno: $e';
    }
  }

  Future<List<Map<String, dynamic>>> buscarMembrosDoGrupo(
    String grupoId,
  ) async {
    try {
      final response = await _supabase
          .from('grupo_alunos')
          .select('aluno_id, perfis(id, nome, peso_atual, altura, anamnese)')
          .eq('grupo_id', grupoId);
      return (response as List)
          .map((item) => item['perfis'] as Map<String, dynamic>)
          .toList();
    } catch (e) {
      throw 'Erro ao carregar membros: $e';
    }
  }

  Future<void> removerAlunoDoGrupo(String grupoId, String alunoId) async {
    try {
      await _supabase.from('grupo_alunos').delete().match({
        'grupo_id': grupoId,
        'aluno_id': alunoId,
      });
    } catch (e) {
      throw 'Erro ao remover aluno: $e';
    }
  }

  // --- MÉTODOS DE TREINAMENTO (COLETIVO) ---

  Future<void> salvarTreinoColetivo({
    required String grupoId,
    required String titulo,
    required String treino,
    required String dieta,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw 'Acesso negado';
    try {
      await _supabase.from('treinos_coletivos').upsert({
        'grupo_id': grupoId,
        'titulo': titulo,
        'descricao_treino': treino,
        'plano_alimentar': dieta,
        'professor_id': user.id,
      });
    } catch (e) {
      throw 'Erro ao salvar treino: $e';
    }
  }

  /// Busca todos os treinos que o aluno já "pagou"
  Future<List<Map<String, dynamic>>> buscarHistoricoAluno() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    try {
      final response = await _supabase
          .from('treinos_concluidos')
          .select(
            '*, treinos_coletivos(titulo)',
          ) // Traz o título da outra tabela
          .eq('aluno_id', user.id)
          .order('data_conclusao', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  // Adicione/Substitua no seu grupo_repository.dart
  Future<List<String>> buscarIdsAlunosNoGrupo(String grupoId) async {
    try {
      final response = await _supabase
          .from('grupo_alunos')
          .select('aluno_id')
          .eq('grupo_id', grupoId);

      // Converte a lista de maps para uma lista de Strings (IDs)
      return (response as List)
          .map((item) => item['aluno_id'].toString())
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// BUSCA o treino do grupo que o aluno faz parte
  Future<Map<String, dynamic>?> buscarTreinoDoMeuGrupo() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    try {
      // 1. Busca o grupo_id do perfil
      final perfil = await _supabase
          .from('perfis')
          .select('grupo_id')
          .eq('id', user.id)
          .single();
      final grupoId = perfil['grupo_id'];
      if (grupoId == null) return null;

      // 2. Verifica se o aluno JÁ CONCLUIU algo hoje
      final hoje = DateTime.now().toIso8601String().substring(0, 10);
      final conclusaoHoje = await _supabase
          .from('treinos_concluidos')
          .select('id')
          .eq('aluno_id', user.id)
          .gte('data_conclusao', hoje)
          .maybeSingle();

      // SE JÁ CONCLUIU HOJE, não retorna o treino (o card some)
      if (conclusaoHoje != null) return null;

      // 3. Caso contrário, busca o treino coletivo
      return await _supabase
          .from('treinos_coletivos')
          .select()
          .eq('grupo_id', grupoId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
    } catch (e) {
      return null;
    }
  }

  /// NOVO: VINCULA o aluno a um grupo usando o código do professor
  Future<void> vincularAlunoAoGrupo(String codigo) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw 'Faça login para continuar';

    // Limpa o código de espaços em branco e garante que está igual ao banco
    final codigoLimpo = codigo.trim();

    try {
      // 1. Busca o grupo
      final response = await _supabase
          .from('grupos')
          .select('id')
          .eq('codigo_convite', codigoLimpo)
          .maybeSingle(); // Usar maybeSingle evita erro de exceção imediata

      if (response == null) {
        throw 'Código "$codigoLimpo" não encontrado no sistema.';
      }

      // 2. Vincula na tabela perfis
      await _supabase
          .from('perfis')
          .update({'grupo_id': response['id']})
          .eq('id', user.id);
    } on PostgrestException catch (e) {
      throw 'Erro no banco: ${e.message}';
    } catch (e) {
      throw 'Erro: $e';
    }
  }

  /// FINALIZA o treino do grupo (Marcar como pago)

  Future<void> finalizarTreino({
    required String treinoId, // String para o UUID
    required String feedback,
    required int intensidade,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      // 1. Registra na tabela CORRETA: 'treinos_concluidos'
      // Ajustado conforme o seu diagrama (colunas: aluno_id, feedback_texto, intensidade)
      await _supabase.from('treinos_concluidos').insert({
        'aluno_id': user.id,
        'exercicio_id':
            null, // Como é treino coletivo, o ID do exercício individual pode ser nulo
        'feedback_texto': feedback, // Nome exato na sua tabela
        'intensidade': intensidade,
        'data_conclusao': DateTime.now().toIso8601String(),
        // 'treino_coletivo_id': treinoId, // Adicione se você criou essa FK na tabela
      });
    } catch (e) {
      throw 'Erro ao finalizar treino: $e';
    }
  }
}
