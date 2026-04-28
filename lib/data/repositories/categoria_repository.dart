import 'package:supabase_flutter/supabase_flutter.dart';

class CategoriaRepository {
  final _supabase = Supabase.instance.client;

  /// Busca todas as categorias cadastradas no banco
  Future<List<Map<String, dynamic>>> buscarCategorias() async {
    try {
      final response = await _supabase
          .from('categorias')
          .select()
          .order('nome', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      // Isso vai te mostrar no VS Code se o erro é permissão, nome de tabela errado, etc.

      return [];
    }
  }
}
