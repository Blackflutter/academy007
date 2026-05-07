import 'package:academy007/data/models/profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  final _supabase = Supabase.instance.client;

  // --- ADICIONE ESTE MÉTODO AQUI ---
  Future<Map<String, dynamic>> getUserProfile() async {
    final user =
        _supabase.auth.currentUser; // Aqui usamos o _supabase da classe
    if (user == null) throw "Usuário não autenticado";

    try {
      final response = await _supabase
          .from('perfis')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (response == null) throw "Perfil não encontrado";
      return response;
    } catch (e) {
      throw "Erro ao buscar perfil: $e";
    }
  }

  // Seu método signIn atualizado para retornar o perfil também se quiser
  Future<AuthResponse> signIn(String email, String password) async {
    try {
      return await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } on AuthException catch (e) {
      throw 'Login inválido: ${e.message}';
    } catch (e) {
      throw 'Erro ao entrar: $e';
    }
  }

  // ... resto do seu código (registroCompleto, signOut, etc)

  /// Realiza o cadastro completo: Auth + Inserção na Tabela Perfis
  /// Realiza o cadastro completo: Auth + Inserção na Tabela Perfis com escolha de cargo
  Future<void> registroCompleto({
    required String email,
    required String password,
    required String nome,
    required String cpf,
    required String telefone,
    required int idade,
    required double peso,
    required double altura,
    required String cargo, // 'aluno' ou 'professor'
  }) async {
    try {
      // 1. Criar o usuário no Supabase Auth
      final AuthResponse res = await _supabase.auth.signUp(
        email: email,
        password: password,
        // Remova ou deixe nulo se não estiver usando links de redirecionamento
        emailRedirectTo: null,
      );

      final String? userId = res.user?.id;

      if (userId != null) {
        // 2. Insere os dados na tabela perfis
        await _supabase.from('perfis').insert({
          'id': userId,
          'nome': nome,
          'cpf': cpf,
          'telefone': telefone,
          'idade': idade,
          'email': email,
          'peso_atual': peso,
          'altura': altura,
          'cargo': cargo, // Define se é aluno ou professor
          'academia_id': null, // Começa sempre nulo
          'categoria_id': 1,
        });
      } else {
        throw 'Não foi possível obter o ID do usuário após o cadastro.';
      }
    } on PostgrestException catch (e) {
      throw 'Erro no banco de dados: ${e.message}';
    } on AuthException catch (e) {
      throw 'Erro de autenticação: ${e.message}';
    } catch (e) {
      throw 'Ocorreu um erro inesperado: $e';
    }

    /// Realiza o Login
    Future<AuthResponse> signIn(String email, String password) async {
      try {
        return await _supabase.auth.signInWithPassword(
          email: email,
          password: password,
        );
      } on AuthException catch (e) {
        throw 'Login inválido: ${e.message}';
      } catch (e) {
        throw 'Erro ao entrar: $e';
      }
    }
  }

  /// Realiza o Logout (Sair)
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  /// Verifica se existe um usuário logado no momento
  User? get currentUser => _supabase.auth.currentUser;
}

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<UserProfile?> login(String email, String password) async {
    try {
      // 1. Faz o login no Supabase Auth
      final res = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (res.user != null) {
        // 2. Busca os dados extras (academia_id, cargo) na tabela perfis
        final data = await _supabase
            .from('perfis')
            .select()
            .eq('id', res.user!.id)
            .single();

        return UserProfile.fromMap(data);
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  Future<Map<String, dynamic>> getUserProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw "Sessão expirada";

    final response = await _supabase
        .from('perfis')
        .select()
        .eq('id', user.id)
        .maybeSingle(); // Mais seguro que .single()

    if (response == null) throw "Perfil não encontrado no banco.";
    return response;
  }
}
