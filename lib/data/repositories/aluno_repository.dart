import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/aluno_model.dart';

class AlunoRepository {
  final _supabase = Supabase.instance.client;

  /// Salva ou atualiza os dados básicos do perfil do aluno.
  Future<void> salvarOuAtualizarPerfil(
    AlunoModel aluno, {
    required String email,
    required String senha,
  }) async {
    try {
      var user = _supabase.auth.currentUser;

      if (user == null) {
        final AuthResponse res = await _supabase.auth.signUp(
          email: email,
          password: senha,
        );
        user = res.user;
      }

      if (user == null) throw 'Falha ao processar autenticação.';

      // AQUI ESTAVA O PROBLEMA: ADICIONAMOS OS CAMPOS NO UPSERT
      await _supabase.from('perfis').upsert({
        'id': user.id,
        'nome': aluno.nome,
        'idade': aluno.idade, // <--- ADICIONADO
        'cpf': aluno.cpf, // <--- ADICIONADO
        'telefone': aluno
            .telefone, // <--- ADICIONADO (verifique se no banco é 'telefone' ou 'whatsapp')
        'peso_atual': aluno.peso,
        'altura': aluno.altura,
        'categoria_id': aluno.categoriaId,
        'email': user.email,
        'anamnese': aluno.anamnese,
      });

      await registrarNovoPeso(aluno.peso);
    } catch (e) {
      throw 'Erro no processo de cadastro: $e';
    }
  }

  /// Busca os dados do perfil do usuário que está logado no momento.
  Future<Map<String, dynamic>?> buscarMeuPerfil() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    final response = await _supabase
        .from('perfis')
        .select('*')
        .eq('id', user.id)
        .maybeSingle();

    return response;
  }

  Future<Map<String, dynamic>?> calcularVariacao30Dias() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return null;

    final historico = await Supabase.instance.client
        .from('historico_peso')
        .select()
        .eq('aluno_id', user.id)
        .order('data_registro', ascending: true);

    if (historico.length < 2) return null;

    final agora = DateTime.now();
    final dataLimite = agora.subtract(const Duration(days: 30));

    Map<String, dynamic>? registroAntigo;

    for (var registro in historico) {
      final data = DateTime.parse(registro['data_registro']);
      if (data.isAfter(dataLimite)) {
        registroAntigo = registro;
        break;
      }
    }

    if (registroAntigo == null) return null;

    final pesoAtual = historico.last['peso'] as num;
    final pesoAntigo = registroAntigo['peso'] as num;

    final diferenca = pesoAtual.toDouble() - pesoAntigo.toDouble();

    return {
      "atual": pesoAtual.toDouble(),
      "antigo": pesoAntigo.toDouble(),
      "diferenca": diferenca,
    };
  }

  Future<Map<String, dynamic>?> calcularMetaInteligente() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return null;

    final perfil = await Supabase.instance.client
        .from('perfis')
        .select('peso_atual, meta_peso, data_meta')
        .eq('id', user.id)
        .single();

    if (perfil['meta_peso'] == null) return null;

    final historico = await Supabase.instance.client
        .from('historico_peso')
        .select()
        .eq('aluno_id', user.id)
        .order('data_registro', ascending: true);

    if (historico.length < 2) return null;

    final pesoInicial = historico.first['peso'] as num;
    final pesoAtual = perfil['peso_atual'] as num;
    final meta = perfil['meta_peso'] as num;

    final progressoTotal = (pesoInicial - meta).toDouble();
    final progressoAtual = (pesoInicial - pesoAtual).toDouble();

    double percentual = 0;
    if (progressoTotal != 0) {
      percentual = (progressoAtual / progressoTotal) * 100;
    }

    final diasDesdeInicio = DateTime.now()
        .difference(DateTime.parse(historico.first['data_registro']))
        .inDays;

    double ritmoPorDia = 0;
    if (diasDesdeInicio > 0) {
      ritmoPorDia = progressoAtual / diasDesdeInicio;
    }

    double diasRestantes = 0;
    if (ritmoPorDia != 0) {
      diasRestantes = ((pesoAtual - meta) / ritmoPorDia).abs();
    }

    return {
      "pesoAtual": pesoAtual,
      "meta": meta,
      "percentual": percentual.clamp(0, 100),
      "diasPrevistos": diasRestantes.isFinite ? diasRestantes : null,
    };
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
