import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/auth_repository.dart';
import 'dashboard_screen.dart';

class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final PageController _pageController = PageController();
  final _authRepo = AuthRepository();
  int _currentPage = 0;
  bool _isLoading = false;

  // Controllers para capturar os dados
  final _nomeController = TextEditingController();
  final _cpfController = TextEditingController();
  final _idadeController = TextEditingController();
  final _telController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  double _peso = 75.0;
  double _altura = 1.75;

  Future<void> _finalizarRegistro() async {
    setState(() => _isLoading = true);
    try {
      await _authRepo.registroCompleto(
        email: _emailController.text.trim(),
        password: _senhaController.text.trim(),
        nome: _nomeController.text,
        cpf: _cpfController.text,
        telefone: _telController.text,
        idade: int.parse(_idadeController.text),
        peso: _peso,
        altura: _altura,
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(
        // ignore: use_build_context_synchronously
        context,
      ).showSnackBar(SnackBar(content: Text("Erro no cadastro: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildStepIndicator(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) => setState(() => _currentPage = page),
                children: [
                  _stepDadosPessoais(),
                  _stepDadosFisicos(),
                  _stepCredenciais(),
                ],
              ),
            ),
            _buildBottomNav(),
          ],
        ),
      ),
    );
  }

  // ETAPA 1: Nome, CPF, Idade, Telefone
  Widget _stepDadosPessoais() {
    return _buildPageLayout("Dados Pessoais", [
      _buildTextField(_nomeController, "Nome Completo", Icons.person),
      _buildTextField(_cpfController, "CPF", Icons.badge),
      Row(
        children: [
          Expanded(
            child: _buildTextField(
              _idadeController,
              "Idade",
              Icons.cake,
              type: TextInputType.number,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: _buildTextField(
              _telController,
              "Telefone",
              Icons.phone,
              type: TextInputType.phone,
            ),
          ),
        ],
      ),
    ]);
  }

  // ETAPA 2: Peso e Altura (Visual 2026)
  Widget _stepDadosFisicos() {
    double imc = _peso / (_altura * _altura);
    return _buildPageLayout("Sua Condição", [
      Text(
        "Peso: ${_peso.toStringAsFixed(1)} kg",
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      Slider(
        value: _peso,
        min: 30,
        max: 200,
        activeColor: AppTheme.primaryNeon,
        onChanged: (v) => setState(() => _peso = v),
      ),
      const SizedBox(height: 20),
      Text(
        "Altura: ${_altura.toStringAsFixed(2)} m",
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      Slider(
        value: _altura,
        min: 1.0,
        max: 2.3,
        activeColor: AppTheme.primaryNeon,
        onChanged: (v) => setState(() => _altura = v),
      ),
      const SizedBox(height: 40),
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.primaryNeon.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(
            "IMC ESTIMADO: ${imc.toStringAsFixed(1)}",
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryNeon,
            ),
          ),
        ),
      ),
    ]);
  }

  // ETAPA 3: E-mail e Senha
  Widget _stepCredenciais() {
    return _buildPageLayout("Segurança", [
      const Text("Para finalizar, crie suas credenciais de acesso."),
      const SizedBox(height: 20),
      _buildTextField(_emailController, "E-mail", Icons.email),
      _buildTextField(_senhaController, "Senha", Icons.lock, obscure: true),
    ]);
  }

  // --- WIDGETS DE SUPORTE ---

  Widget _buildPageLayout(String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.all(25.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 30),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool obscure = false,
    TextInputType type = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        keyboardType: type,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: AppTheme.primaryNeon),
          labelText: label,
          filled: true,
          fillColor: AppTheme.glassColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        children: List.generate(
          3,
          (index) => Expanded(
            child: Container(
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: index <= _currentPage
                    ? AppTheme.primaryNeon
                    : Colors.white10,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Padding(
      padding: const EdgeInsets.all(25.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentPage > 0)
            TextButton(
              onPressed: () => _pageController.previousPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              ),
              child: const Text("VOLTAR", style: TextStyle(color: Colors.grey)),
            ),
          const Spacer(),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryNeon,
              minimumSize: const Size(120, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            onPressed: _isLoading
                ? null
                : () {
                    if (_currentPage < 2) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    } else {
                      _finalizarRegistro();
                    }
                  },
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.black)
                : Text(
                    _currentPage == 2 ? "FINALIZAR" : "PRÓXIMO",
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
