import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/grupo_model.dart';

class GrupoRepository {
  final _supabase = Supabase.instance.client;

  // Cria um novo grupo vinculado ao professor logado
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

  // Busca todos os grupos criados por este professor
  Future<List<GrupoModel>> listarMeusGrupos() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    final response = await _supabase
        .from('grupos')
        .select()
        .eq('professor_id', user.id);

    return (response as List).map((map) => GrupoModel.fromMap(map)).toList();
  }
  // Adicione ao grupo_repository.dart

  // 1. Busca todos os alunos cadastrados no Academy007 para listar na seleção
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

  Future<List<String>> buscarIdsAlunosNoGrupo(String grupoId) async {
    final response = await _supabase
        .from('grupo_alunos')
        .select('aluno_id')
        .eq('grupo_id', grupoId);

    return (response as List)
        .map((item) => item['aluno_id'].toString())
        .toList();
  }

  // 2. Vincula um aluno ao grupo na tabela 'grupo_alunos'
  Future<void> adicionarAlunoAoGrupo(String grupoId, String alunoId) async {
    print("DEBUG: Tentando adicionar no Grupo: $grupoId");
    print("DEBUG: ID do Aluno enviado: $alunoId");
    print(
      "DEBUG: ID do Usuário Logado (Professor): ${_supabase.auth.currentUser?.id}",
    );

    try {
      final response = await _supabase.from('grupo_alunos').insert({
        'grupo_id': grupoId,
        'aluno_id': alunoId,
      }).select(); // O select() ajuda a confirmar o que foi inserido

      print("DEBUG: Inserção concluída com sucesso: $response");
    } catch (e) {
      print("DEBUG: O erro exato retornado pelo Supabase é: $e");
      throw 'Erro ao adicionar aluno: $e';
    }
  }

  // Adicione ao seu GrupoRepository

  // Salva ou atualiza o treino do grupo
  Future<void> salvarTreinoColetivo({
    required String grupoId,
    required String titulo,
    required String treino,
    required String dieta,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw 'Acesso negado';

    try {
      // Usamos upsert para que, se o professor editar, ele atualize o treino existente do grupo
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
  // Adicione ao seu grupo_repository.dart

  Future<Map<String, dynamic>?> buscarTreinoDoMeuGrupo() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    try {
      // 1. Busca o vínculo na tabela grupo_alunos
      final response = await _supabase
          .from('grupo_alunos')
          .select('grupo_id')
          .eq('aluno_id', user.id);

      // Se o retorno for nulo ou vazio, o aluno não está no grupo
      if (response == null || (response as List).isEmpty) {
        print("LOG: Nenhum grupo encontrado para o aluno ${user.id}");
        return null;
      }

      // Acessa o grupo_id corretamente da lista
      final String grupoId = response[0]['grupo_id'];

      // 2. Busca o treino coletivo usando o ID do grupo
      final treino = await _supabase
          .from('treinos_coletivos')
          .select()
          .eq('grupo_id', grupoId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      return treino;
    } catch (e) {
      print("ERRO AO BUSCAR: $e");
      return null;
    }
  }

  // 1. Busca os alunos que pertencem a um grupo específico (Join entre grupo_alunos e perfis)
  Future<List<Map<String, dynamic>>> buscarMembrosDoGrupo(
    String grupoId,
  ) async {
    try {
      final response = await _supabase
          .from('grupo_alunos')
          .select('aluno_id, perfis(id, nome, peso_atual, altura, anamnese)')
          .eq('grupo_id', grupoId);

      // Mapeia o retorno para facilitar o uso no Flutter
      return (response as List)
          .map((item) => item['perfis'] as Map<String, dynamic>)
          .toList();
    } catch (e) {
      throw 'Erro ao carregar membros: $e';
    }
  }

  // 2. Remove um aluno de um grupo específico
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
}
