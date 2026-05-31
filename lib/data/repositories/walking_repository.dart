// data/repositories/walking_repository.dart
import 'package:academy007/models/walking_session_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WalkingRepository {
  final _client = Supabase.instance.client;

  Future<void> salvarCaminhada(WalkingSessionModel session) async {
    await _client.from('caminhadas').insert(session.toMap());
  }

  Future<List<WalkingSessionModel>> buscarHistorico() async {
    final response = await _client
        .from('caminhadas')
        .select()
        .eq('aluno_id', _client.auth.currentUser!.id)
        .order('created_at', ascending: false);

    return response.map((e) => WalkingSessionModel.fromMap(e)).toList();
  }

  Future<double> buscarPesoUsuario() async {
    final response = await _client
        .from('perfis')
        .select('peso_atual')
        .eq('id', _client.auth.currentUser!.id)
        .single();

    return (response['peso_atual'] as num?)?.toDouble() ?? 70.0; // default 70kg
  }
}
