import 'package:academy007/data/models/grupo_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GrupoRepositoryListarMeusGrupos {
  final _supabase = Supabase.instance.client;

  Future<List<GrupoModel>> listarMeusGrupos() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];
    final response = await _supabase
        .from('grupos')
        .select()
        .eq('professor_id', user.id);
    return (response as List).map((map) => GrupoModel.fromMap(map)).toList();
  }
}
