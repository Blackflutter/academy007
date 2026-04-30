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

  // 2. Vincula um aluno ao grupo na tabela 'grupo_alunos'
  Future<void> adicionarAlunoAoGrupo(String grupoId, String alunoId) async {
    try {
      await _supabase.from('grupo_alunos').insert({
        'grupo_id': grupoId,
        'aluno_id': alunoId,
      });
    } catch (e) {
      // Se o aluno já estiver no grupo, o Supabase retornará um erro de duplicidade
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
      await _supabase.from('treinos_coletivos').upsert({
        'grupo_id': grupoId,
        'titulo': titulo,
        'descricao_treino': treino,
        'plano_alimentar': dieta,
        'professor_id': user.id,
      });
    } catch (e) {
      throw 'Erro ao salvar treino coletivo: $e';
    }
  }
  // Adicione ao seu grupo_repository.dart

  Future<Map<String, dynamic>?> buscarTreinoDoMeuGrupo() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    try {
      // 1. Busca explicitamente o grupo onde o aluno ID está vinculado
      final vinculo = await _supabase
          .from('grupo_alunos')
          .select('grupo_id')
          .eq('aluno_id', user.id)
          .maybeSingle();

      // Se o retorno for nulo, o aluno NÃO está em nenhum grupo.
      if (vinculo == null || vinculo['grupo_id'] == null) {
        print("Aluno ${user.id} não possui vínculo em grupo_alunos");
        return null;
      }

      final String grupoId = vinculo['grupo_id'];

      // 2. Busca o treino específico desse grupo
      final treino = await _supabase
          .from('treinos_coletivos')
          .select()
          .eq('grupo_id', grupoId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      return treino;
    } catch (e) {
      print("Erro ao buscar treino do grupo: $e");
      return null;
    }
  }
  // Adicione ao seu grupo_repository.dart

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
