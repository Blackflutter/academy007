import 'package:academy007/main_screens.dart';
import 'package:academy007/presentation/screens/registro_screen.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/auth_repository.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authRepo = AuthRepository();

  // Controle de visibilidade da senha
  bool _obscurePassword = true;
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showSnackBar("Preencha todos os campos");
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authRepo.signIn(email, password);
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
      }
    } catch (e) {
      if (mounted) _showSnackBar("Erro ao entrar: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // SafeArea evita que o conteúdo bata no topo em iPhones/Androids modernos
      body: SafeArea(
        // SingleChildScrollView resolve o erro de Overflow com o teclado
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 50.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "ACADEMY",
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryNeon,
                  letterSpacing: 2,
                ),
              ),
              const Text(
                "Seu treino começa aqui.",
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: 60),

              // Campo de E-mail com teclado específico
              TextField(
                controller: _emailController,
                keyboardType:
                    TextInputType.emailAddress, // Chama teclado de email
                autofillHints: const [
                  AutofillHints.email,
                ], // Sugestão do sistema
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: "E-mail",
                  prefixIcon: Icon(
                    Icons.email_outlined,
                    color: AppTheme.primaryNeon,
                  ),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 25),

              // Campo de Senha com Toggle On/Off
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Senha",
                  prefixIcon: const Icon(
                    Icons.lock_outline,
                    color: AppTheme.primaryNeon,
                  ),
                  border: const OutlineInputBorder(),
                  // Botão para mostrar/esconder senha
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // Botão de Login com estado de carregamento
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryNeon,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isLoading ? null : _handleLogin,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.black)
                      : const Text(
                          "ENTRAR",
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 20),
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RegistroScreen()),
                    );
                  },
                  child: RichText(
                    text: const TextSpan(
                      text: "Ainda não tem conta? ",
                      style: TextStyle(color: Colors.grey),
                      children: [
                        TextSpan(
                          text: "Cadastre-se",
                          style: TextStyle(
                            color: AppTheme.primaryNeon,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
