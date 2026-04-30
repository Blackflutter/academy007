import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/aluno_model.dart';

class AlunoRepository {
  final _supabase = Supabase.instance.client;

  /// Salva ou atualiza os dados básicos do perfil do aluno.
  /// Utiliza 'upsert' para garantir que o registro seja vinculado ao UID da Auth.
  Future<void> salvarOuAtualizarPerfil(
    AlunoModel aluno, {
    required String email,
    required String senha,
  }) async {
    try {
      // 1. Verificar se o usuário já está logado (Atualização)
      // ou se precisa criar conta (Novo Cadastro)
      var user = _supabase.auth.currentUser;

      if (user == null) {
        // CADASTRO NOVO: Cria o acesso no Supabase Auth primeiro
        final AuthResponse res = await _supabase.auth.signUp(
          email: email,
          password: senha,
        );
        user = res.user;
      }

      if (user == null) throw 'Falha ao processar autenticação.';

      // 2. Agora com o UID em mãos (user.id), salvamos na tabela 'perfis'
      // O 'upsert' resolve tanto o primeiro cadastro quanto atualizações futuras
      await _supabase.from('perfis').upsert({
        'id': user.id,
        'nome': aluno.nome,
        'peso_atual': aluno.peso,
        'altura': aluno.altura,
        'categoria_id': aluno.categoriaId,
        'email': user.email,
        'anamnese': aluno.anamnese, // <--- SALVANDO AS 10 PERGUNTAS AQUI
      });

      // 3. Registra no histórico de peso para o gráfico
      await registrarNovoPeso(aluno.peso);
    } catch (e) {
      throw 'Erro no processo de cadastro: $e';
    }
  }

  /// Busca os dados do perfil do usuário que está logado no momento.
  Future<Map<String, dynamic>?> buscarMeuPerfil() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    try {
      final data = await _supabase
          .from('perfis')
          .select()
          .eq('id', user.id)
          .single();
      return data;
    } catch (e) {
      // Retorna null se o perfil ainda não existir
      return null;
    }
  }

  /// Registra um novo peso na tabela de histórico para alimentar o gráfico de evolução.
  Future<void> registrarNovoPeso(double peso) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      // 1. Adiciona ao histórico temporal
      await _supabase.from('historico_peso').insert({
        'aluno_id': user.id,
        'peso': peso,
      });

      // 2. Atualiza o peso atual na tabela principal de perfis
      await _supabase
          .from('perfis')
          .update({'peso_atual': peso})
          .eq('id', user.id);
    } catch (e) {
      throw 'Erro ao registrar evolução de peso: $e';
    }
  }

  /// Busca as estatísticas coletivas da View SQL baseada na categoria do aluno.
  Future<Map<String, dynamic>?> buscarEstatisticasGrupo(
    String categoriaNome,
  ) async {
    try {
      final response = await _supabase
          .from('dashboard_stats')
          .select()
          .eq('categoria_nome', categoriaNome)
          .maybeSingle(); // Usamos maybeSingle para não estourar erro se a view estiver vazia

      return response;
    } catch (e) {
      return null;
    }
  }

  /// Busca todo o histórico de peso do aluno para o componente de gráfico (fl_chart).
  Future<List<Map<String, dynamic>>> buscarHistoricoPeso() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    try {
      return await _supabase
          .from('historico_peso')
          .select()
          .eq('aluno_id', user.id)
          .order('data_registro', ascending: true);
    } catch (e) {
      return [];
    }
  }
}
