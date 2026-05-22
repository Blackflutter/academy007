// ignore_for_file: unnecessary_null_comparison

import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/grupo_model.dart';

class GrupoRepository {
  final _supabase = Supabase.instance.client;

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

  Future<void> removerAlunoDoGrupo(String grupoId, String alunoId) async {
    try {
      // Força o filtro exato combinando as duas colunas
      // Isso garante que APENAS o vínculo com ESTE grupo seja deletado
      await _supabase
          .from('grupo_alunos')
          .delete()
          .eq('grupo_id', grupoId.trim())
          .eq('aluno_id', alunoId.trim());
    } catch (e) {
      throw 'Erro ao desvincular aluno do grupo específico: $e';
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

  /// CORRIGIDO: Proteção contra retornos nulos do perfil devido ao RLS

  /// BUSCA o treino coletivo mais recente do grupo que o aluno faz parte
  Future<Map<String, dynamic>?> buscarTreinoDoMeuGrupo() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    try {
      // 1. Busca o grupo do aluno limitando a 1 para evitar o erro 406 anterior
      final vinculo = await _supabase
          .from('grupo_alunos')
          .select('grupo_id')
          .eq('aluno_id', user.id)
          .limit(1)
          .maybeSingle();

      if (vinculo == null || vinculo['grupo_id'] == null) {
        return null;
      }

      final String grupoIdUuid = vinculo['grupo_id'].toString();

      // 2. Busca o treino coletivo mais recente publicado para este grupo
      final treinoResponse = await _supabase
          .from('treinos_coletivos')
          .select()
          .eq('grupo_id', grupoIdUuid)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      // Se o professor não publicou nenhum treino para este grupo, não mostra nada
      if (treinoResponse == null) {
        return null;
      }

      final String treinoId = treinoResponse['id'].toString();
      final String hojeLocal = DateTime.now().toIso8601String().substring(
        0,
        10,
      ); // YYYY-MM-DD

      // 3. SOLUÇÃO COMPATÍVEL: Busca as conclusões de hoje deste aluno
      final conclusoeshoje = await _supabase
          .from('treinos_concluidos')
          .select()
          .eq('aluno_id', user.id)
          .gte('data_conclusao', hojeLocal);

      // 4. Varre a lista de hoje para ver se o ID deste treino coletivo consta lá dentro
      // Funciona mesmo se a coluna se chamar 'treino_coletivo_id' ou apenas 'treino_id'
      final List listaConclusoes = conclusoeshoje as List;
      bool jaRealizouEsteTreino = false;

      for (var conclusao in listaConclusoes) {
        // Verifica dinamicamente qual nome de coluna você usou no banco
        if (conclusao['treino_coletivo_id']?.toString() == treinoId ||
            conclusao['treino_id']?.toString() == treinoId) {
          jaRealizouEsteTreino = true;
          break;
        }
      }

      // Se ele já concluiu ESTE treino hoje, o card some
      if (jaRealizouEsteTreino) {
        return null;
      }

      // 5. Se não concluiu, retorna o treino perfeito para o visor da Dashboard carregar!
      return {
        'id': treinoId,
        'grupo_id': treinoResponse['grupo_id']?.toString() ?? '',
        'titulo': treinoResponse['titulo']?.toString() ?? 'Treino do Dia',
        'descricao_treino':
            treinoResponse['descricao_treino']?.toString() ??
            'Sem descrição disponível.',
        'plano_alimentar':
            treinoResponse['plano_alimentar']?.toString() ??
            'Nenhuma dieta vinculada.',
        'professor_id': treinoResponse['professor_id']?.toString() ?? '',
        'academia_id':
            int.tryParse(treinoResponse['academia_id']?.toString() ?? '') ?? 0,
      };
    } catch (e) {
      // Evita o travamento da dashboard se houver falha de digitação em colunas do banco
      return null;
    }
  }

  /// NOVO: VINCULA o aluno a um grupo usando o código do professor
  Future<void> vincularAlunoAoGrupo(String codigo) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw 'Faça login para continuar';

    final codigoLimpo = codigo.trim();

    try {
      dynamic grupoId;

      // 1. PASSO 1: Tenta buscar na tabela de grupos (Turma do Professor)
      final buscaGrupo = await _supabase
          .from('grupos')
          .select('id')
          .eq('codigo_convite', codigoLimpo)
          .limit(1)
          .maybeSingle();
      if (buscaGrupo != null) {
        grupoId = buscaGrupo['id'];
      } else {
        // 2. PASSO 2: Se não achou, o código pode ser de uma ACADEMIA.
        // Busca a academia para encontrar o responsável por ela
        final buscaAcademia = await _supabase
            .from('academias')
            .select('id, responsavel_id')
            .eq('codigo_acesso', codigoLimpo)
            .limit(1)
            .maybeSingle();

        if (buscaAcademia != null) {
          final String responsavelId = buscaAcademia['responsavel_id']
              .toString();

          // Busca o primeiro grupo que pertence a esse professor responsável
          final buscaGrupoResponsavel = await _supabase
              .from('grupos')
              .select('id')
              .eq('professor_id', responsavelId)
              .limit(1)
              .maybeSingle();

          if (buscaGrupoResponsavel != null) {
            grupoId = buscaGrupoResponsavel['id'];
          }
        }
      }

      // Se não encontrou o grupo em nenhuma das tabelas
      if (grupoId == null) {
        throw 'O código "$codigoLimpo" não foi encontrado no sistema.';
      }

      // 3. PASSO 3: Insere o vínculo na tabela intermediária grupo_alunos
      await _supabase.from('grupo_alunos').insert({
        'grupo_id': grupoId,
        'aluno_id': user.id,
      });
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        throw 'Você já está vinculado a este grupo.';
      }
      throw 'Erro no banco: [${e.code}] ${e.message}';
    } catch (e) {
      // Repassa o erro de negócio tratado acima
      rethrow;
    }
  }

  /// Busca todos os alunos vinculados à academia/unidade através dos grupos do responsável
  Future<List<Map<String, dynamic>>> buscarAlunosDaAcademia(
    String codigoAcesso,
  ) async {
    try {
      // 1. Busca academia
      final academiaResponse = await _supabase
          .from('academias')
          .select('responsavel_id')
          .eq('codigo_acesso', codigoAcesso);

      if (academiaResponse.isEmpty) {
        return [];
      }

      final responsavelId = academiaResponse.first['responsavel_id'].toString();

      // 2. Busca grupos do professor
      final gruposProfessor = await _supabase
          .from('grupos')
          .select('id')
          .eq('professor_id', responsavelId);

      if (gruposProfessor.isEmpty) {
        return [];
      }

      final grupoIds = (gruposProfessor as List)
          .map((g) => g['id'].toString())
          .toList();

      // 3. Busca IDs dos alunos
      final grupoAlunos = await _supabase
          .from('grupo_alunos')
          .select('aluno_id')
          .inFilter('grupo_id', grupoIds);

      if (grupoAlunos.isEmpty) {
        return [];
      }

      final alunoIds = (grupoAlunos as List)
          .map((a) => a['aluno_id'].toString())
          .toSet()
          .toList();

      // 4. Busca perfis separado
      final perfis = await _supabase
          .from('perfis')
          .select('id, nome, peso_atual, altura, anamnese')
          .inFilter('id', alunoIds)
          .order('nome');

      return List<Map<String, dynamic>>.from(perfis);
    } catch (e) {
      return [];
    }
  }

  /// CORRIGIDO: Busca múltiplos IDs de alunos no grupo sem quebrar por duplicidade
  Future<List<String>> buscarIdsAlunosNoGrupo(String grupoId) async {
    try {
      final response = await _supabase
          .from('grupo_alunos')
          .select('aluno_id')
          .eq(
            'grupo_id',
            grupoId.trim(),
          ); // 🛑 REMOVIDO .single() ou .maybeSingle()

      // ignore: unnecessary_null_comparison
      if (response == null) return [];

      // Mapeia o retorno garantindo uma lista limpa de Strings de IDs
      return (response as List)
          .map((item) => item['aluno_id'].toString())
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<String?> uploadComprovanteTreino(
    String fileName,
    Uint8List fileBytes,
  ) async {
    try {
      final String path =
          'treinos/${DateTime.now().millisecondsSinceEpoch}_$fileName';

      // Envia os bytes diretamente para o bucket público
      await _supabase.storage
          .from('comprovantes_treino')
          .uploadBinary(
            path,
            fileBytes,
            fileOptions: const FileOptions(contentType: 'image/png'),
          );

      // Captura e retorna a URL pública gerada
      final String publicUrl = _supabase.storage
          .from('comprovantes_treino')
          .getPublicUrl(path);

      return publicUrl;
    } catch (e) {
      return null;
    }
  }

  // Substitua a assinatura em grupo_repository.dart por esta versão flexível:
  Future<void> finalizarTreino({
    required String treinoId,
    required String feedback,
    required dynamic intensidade,
    String? fotoUrl,
  }) async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      throw 'Sessão expirada. Faça login novamente.';
    }

    try {
      await _supabase.from('treinos_concluidos').insert({
        'aluno_id': user.id,

        // ESSA LINHA É A CORREÇÃO DO BUG
        'treino_coletivo_id': treinoId,

        'feedback_texto': feedback.trim(),

        'intensidade': int.tryParse(intensidade.toString()) ?? 3,

        'data_conclusao': DateTime.now().toIso8601String(),

        'foto_comprovante': fotoUrl,
      });
    } catch (e) {
      throw 'Erro ao finalizar treino no banco: $e';
    }
  }

  /// Busca o histórico de treinos pagos de um aluno específico
  Future<List<Map<String, dynamic>>> buscarDesempenhoDoAluno(
    String alunoId,
  ) async {
    try {
      final response = await _supabase
          .from('treinos_concluidos')
          .select(
            'id, feedback_texto, intensidade, data_conclusao, foto_comprovante',
          )
          .eq('aluno_id', alunoId)
          .order('data_conclusao', ascending: false);

      return List<Map<String, dynamic>>.from(response ?? []);
    } catch (e) {
      return [];
    }
  }
}
