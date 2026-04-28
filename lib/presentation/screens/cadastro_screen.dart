import 'package:flutter/material.dart';
import '../../data/models/aluno_model.dart';
import '../../data/repositories/aluno_repository.dart';
import 'dashboard_screen.dart';

class CadastroScreen extends StatefulWidget {
  const CadastroScreen({super.key});

  @override
  State<CadastroScreen> createState() => _CadastroScreenState();
}

class _CadastroScreenState extends State<CadastroScreen> {
  // Inicialização correta do Controller
  final TextEditingController _nomeController = TextEditingController();
  final AlunoRepository _repository = AlunoRepository();

  double _peso = 75.0;
  double _altura = 1.75;
  bool _isLoading = false;

  @override
  void dispose() {
    // É essencial descartar o controller ao fechar a tela
    _nomeController.dispose();
    super.dispose();
  }

  Future<void> _salvarEProsseguir() async {
    if (_nomeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor, digite seu nome")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final novoAluno = AlunoModel(
        nome: _nomeController.text,
        peso: _peso,
        altura: _altura,
        categoriaId: 1, // ID padrão (ex: Futebol)
      );

      // Salva no Supabase vinculado ao UID do usuário logado
      await _repository.salvarOuAtualizarPerfil(novoAluno);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Erro ao salvar: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    double imc = _peso / (_altura * _altura);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Text(
                "Configurar Perfil",
                style: Theme.of(context).textTheme.displayLarge,
              ),
              const SizedBox(height: 20),

              // Campo de Nome corrigido
              TextField(
                controller: _nomeController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Nome Completo",
                  labelStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.05),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Card de IMC em tempo real
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  children: [
                    const Text(
                      "SEU IMC ATUAL",
                      style: TextStyle(color: Colors.grey),
                    ),
                    Text(
                      imc.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 64,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              _labelSlider("Peso", "${_peso.toStringAsFixed(1)} kg"),
              Slider(
                value: _peso,
                min: 40,
                max: 150,
                activeColor: Theme.of(context).primaryColor,
                onChanged: (v) => setState(() => _peso = v),
              ),

              const SizedBox(height: 20),

              _labelSlider("Altura", "${_altura.toStringAsFixed(2)} m"),
              Slider(
                value: _altura,
                min: 1.20,
                max: 2.20,
                activeColor: Theme.of(context).primaryColor,
                onChanged: (v) => setState(() => _altura = v),
              ),

              const SizedBox(height: 50),

              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: _isLoading ? null : _salvarEProsseguir,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.black)
                      : const Text(
                          "PRÓXIMO",
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
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

  Widget _labelSlider(String label, String valor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 16)),
        Text(
          valor,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    );
  }
}
