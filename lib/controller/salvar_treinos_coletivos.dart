import 'package:supabase_flutter/supabase_flutter.dart';

class GrupoRepositorySalvarTreinosColetivos {
  final _supabase = Supabase.instance.client;

  // 🟢 Deixe o topo da sua função de salvar treino coletivo no GRUPO_REPOSITORY assim:
  Future<void> salvarTreinoColetivo({
    required String grupoId,
    required dynamic academiaId,
    required String titulo,
    required String treino,
    required String dieta,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw 'Acesso negado. Faça login para continuar.';

    try {
      int? academiaIdInt;

      // Se a tela não enviou o ID da academia, buscamos a primeira cadastrada do professor
      if (academiaId == null || academiaId.toString().isEmpty) {
        final buscarAcademia = await _supabase
            .from('academias')
            .select('id')
            .eq('responsavel_id', user.id)
            .limit(
              1,
            ) // 🛑 ISSO EVITA O ERRO 406 CASO EXISTA MAIS DE UMA FILIAL!
            .maybeSingle();

        if (buscarAcademia != null) {
          academiaIdInt = int.tryParse(buscarAcademia['id'].toString());
        }
      } else {
        academiaIdInt = int.tryParse(academiaId.toString());
      }

      if (academiaIdInt == null) {
        throw 'Nenhuma filial cadastrada ou vinculada encontrada para publicar este treino.';
      }

      // Agora insere com segurança o treino coletivo no banco
      await _supabase.from('treinos_coletivos').insert({
        'grupo_id': grupoId.toString().trim(),
        'academia_id': academiaIdInt,
        'titulo': titulo.trim(),
        'descricao_treino': treino.trim(),
        'plano_alimentar': dieta.trim(),
        'professor_id': user.id,
      });
    } catch (e) {
      throw 'Erro ao publicar treino: $e';
    }
  }
}
