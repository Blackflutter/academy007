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

  /// NOVA FUNÇÃO: Cadastra uma nova filial gerando um código único de acesso
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
}
