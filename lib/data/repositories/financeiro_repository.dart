import 'package:supabase_flutter/supabase_flutter.dart';

class FinanceiroRepository {
  final _supabase = Supabase.instance.client;

  /// Retorna o faturamento total e um resumo estatístico do professor logado
  Future<Map<String, dynamic>> buscarResumoFinanceiro() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw 'Usuário não autenticado';

    try {
      final response = await _supabase
          .from('financeiro_alunos')
          .select('valor_pago, status_pagamento')
          .eq('professor_id', user.id);

      final lista = response as List;

      double faturamentoTotal = 0.0;
      int totalAtivos = 0;
      int totalInadimplentes = 0;

      for (var item in lista) {
        final valor = double.tryParse(item['valor_pago'].toString()) ?? 0.0;
        faturamentoTotal += valor;

        if (item['status_pagamento'] == 'pago') {
          totalAtivos++;
        } else if (item['status_pagamento'] == 'atrasado') {
          totalInadimplentes++;
        }
      }

      return {
        'faturamento_total': faturamentoTotal,
        'alunos_ativos': totalAtivos,
        'alunos_inadimplentes': totalInadimplentes,
      };
    } catch (e) {
      throw 'Erro ao calcular resumo financeiro: $e';
    }
  }

  /// Lista detalhada de alunos trazendo o status financeiro de cada um (Join com perfis)
  Future<List<Map<String, dynamic>>> listarReceitasPorAluno() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    try {
      final response = await _supabase
          .from('financeiro_alunos')
          .select('*, perfis(nome, id)')
          .eq('professor_id', user.id)
          .order('data_pagamento', ascending: false);

      return (response as List).map((item) {
        final map = item as Map<String, dynamic>;
        final perfil = map['perfis'] as Map<String, dynamic>?;

        return {
          'id': map['id'],
          'aluno_nome': perfil?['nome'] ?? 'Aluno Sem Nome',
          'valor': double.tryParse(map['valor_pago'].toString()) ?? 0.0,
          'vencimento': map['proximo_vencimento']?.toString() ?? '',
          'status': map['status_pagamento'] ?? 'pendente',
        };
      }).toList();
    } catch (e) {
      throw 'Erro ao puxar fluxo por aluno: $e';
    }
  }

  /// Registra um novo pagamento feito por um aluno
  Future<void> registrarPagamentoAluno({
    required String alunoId,
    required double valor,
    required int mesesValidade, // ex: 1 para plano mensal
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw 'Sessão expirada. Faça login novamente.';

    try {
      final dataHoje = DateTime.now();
      // Calcula a próxima data de vencimento (ex: hoje + 30 dias)
      final dataVencimento = DateTime(
        dataHoje.year,
        dataHoje.month + mesesValidade,
        dataHoje.day,
      );

      await _supabase.from('financeiro_alunos').insert({
        'aluno_id': alunoId,
        'professor_id': user.id,
        'valor_pago': valor,
        'data_pagamento': dataHoje.toIso8601String().substring(0, 10),
        'proximo_vencimento': dataVencimento.toIso8601String().substring(0, 10),
        'status_pagamento': 'pago',
      });
    } catch (e) {
      throw 'Erro ao salvar pagamento no banco: $e';
    }
  }
}
