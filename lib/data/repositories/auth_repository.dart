import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  final _supabase = Supabase.instance.client;

  /// Realiza o cadastro completo: Auth + Inserção na Tabela Perfis
  Future<void> registroCompleto({
    required String email,
    required String password,
    required String nome,
    required String cpf,
    required String telefone,
    required int idade,
    required double peso,
    required double altura,
  }) async {
    try {
      // 1. Criar o usuário no Supabase Auth
      // No método registroCompleto, altere a parte do signUp:
final AuthResponse res = await _supabase.auth.signUp(
  email: email,
  password: password,
  // Esta linha força o Supabase a não exigir confirmação para este cadastro
  emailRedirectTo: null, 
);


      final String? userId = res.user?.id;

      // 2. Se o usuário foi criado com sucesso, insere os dados na tabela perfis
      if (userId != null) {
        await _supabase.from('perfis').insert({
          'id': userId,
          'nome': nome,
          'cpf': cpf,
          'telefone': telefone,
          'idade': idade,
          'email': email,
          'peso_atual': peso,
          'altura': altura,
          'categoria_id': 1, // Valor padrão inicial
        });
      } else {
        throw 'Não foi possível obter o ID do usuário após o cadastro.';
      }
    } on PostgrestException catch (e) {
      // Erro específico do Banco de Dados (ex: CPF duplicado)
      throw 'Erro no banco de dados: ${e.message}';
    } on AuthException catch (e) {
      // Erro específico de Autenticação (ex: E-mail já cadastrado)
      throw 'Erro de autenticação: ${e.message}';
    } catch (e) {
      // Erros genéricos
      throw 'Ocorreu um erro inesperado: $e';
    }
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

  /// Realiza o Logout (Sair)
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  /// Verifica se existe um usuário logado no momento
  User? get currentUser => _supabase.auth.currentUser;
}
