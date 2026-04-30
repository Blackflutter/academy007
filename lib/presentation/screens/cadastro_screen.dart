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
  // Controllers para os campos de texto
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();

  final AlunoRepository _repository = AlunoRepository();

  // Estado dos Dados Físicos
  double _peso = 75.0;
  double _altura = 1.75;
  bool _isLoading = false;

  // Gerenciamento de Etapas: 0 = Perfil, 1 = Anamnese, 2 = Auth
  int _etapaAtual = 0;
  int _perguntaIndex = 0;
  final Map<String, dynamic> _respostasAnamnese = {};

  // Lista oficial de 10 perguntas para o Professor Academy007
  final List<Map<String, dynamic>> _perguntas = [
    {
      "id": "objetivo",
      "q": "Qual seu objetivo principal?",
      "ops": ["Emagrecer", "Ganhar Massa", "Saúde/Longevidade"],
    },
    {
      "id": "experiencia",
      "q": "Qual seu nível de experiência?",
      "ops": ["Iniciante (Nunca treinei)", "Intermediário", "Avançado"],
    },
    {
      "id": "frequencia",
      "q": "Quantas vezes pretende treinar?",
      "ops": ["1-2 dias", "3-4 dias", "5+ dias"],
    },
    {
      "id": "lesao",
      "q": "Possui alguma lesão ou dor?",
      "ops": ["Não", "Sim (Joelhos/Coluna)", "Sim (Ombros/Outros)"],
    },
    {
      "id": "doenca",
      "q": "Possui histórico de doenças?",
      "ops": ["Não", "Diabetes/Hipertensão", "Cardíacas"],
    },
    {
      "id": "dieta",
      "q": "Você segue alguma dieta?",
      "ops": ["Sim, rigorosa", "Tento comer bem", "Não sigo"],
    },
    {
      "id": "medicamento",
      "q": "Usa medicamentos contínuos?",
      "ops": ["Sim", "Não"],
    },
    {
      "id": "suplemento",
      "q": "Utiliza algum suplemento?",
      "ops": ["Sim", "Não"],
    },
    {
      "id": "sono",
      "q": "Como avalia seu sono?",
      "ops": ["Bom (7h+)", "Regular", "Ruim (Insonia)"],
    },
    {
      "id": "disponibilidade",
      "q": "Onde irá treinar?",
      "ops": ["Academia", "Em Casa", "Ar Livre"],
    },
  ];

  @override
  void dispose() {
    _nomeController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  // Lógica para avançar as etapas
  void _proximoPasso() {
    if (_nomeController.text.trim().isEmpty) {
      _showSnackBar("Por favor, digite seu nome");
      return;
    }
    setState(() => _etapaAtual = 1);
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // Função final que envia tudo para o Supabase
  Future<void> _finalizarCadastroCompleto() async {
    if (_emailController.text.isEmpty || _senhaController.text.length < 6) {
      _showSnackBar("E-mail e senha (mín. 6 caracteres) são obrigatórios");
      return;
    }

    setState(() => _isLoading = true);
    try {
      final novoAluno = AlunoModel(
        nome: _nomeController.text.trim(),
        peso: _peso,
        altura: _altura,
        categoriaId: 1,
        anamnese: _respostasAnamnese, // As 10 perguntas salvas como JSONB
      );

      // Envia para o repository tratar Auth + Tabela Perfis
      await _repository.salvarOuAtualizarPerfil(
        novoAluno,
        email: _emailController.text.trim(),
        senha: _senhaController.text.trim(),
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      }
    } catch (e) {
      if (mounted) _showSnackBar("Erro ao salvar: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25),
          child: _renderizarEtapaAtual(),
        ),
      ),
    );
  }

  Widget _renderizarEtapaAtual() {
    switch (_etapaAtual) {
      case 0:
        return _buildStepDadosFisicos();
      case 1:
        return _buildStepAnamnese();
      case 2:
        return _buildStepAuth();
      default:
        return _buildStepDadosFisicos();
    }
  }

  // --- ETAPA 0: DADOS FÍSICOS ---
  Widget _buildStepDadosFisicos() {
    double imc = _peso / (_altura * _altura);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 30),
          const Text(
            "Configurar Perfil",
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "Dados básicos para o seu professor",
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 30),

          TextField(
            controller: _nomeController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: "Nome Completo",
              filled: true,
              fillColor: Colors.white10,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          const SizedBox(height: 30),
          _cardIMC(imc),
          const SizedBox(height: 30),

          _sliderWidget(
            "Peso",
            "${_peso.toStringAsFixed(1)} kg",
            _peso,
            40,
            160,
            (v) => setState(() => _peso = v),
          ),
          const SizedBox(height: 20),
          _sliderWidget(
            "Altura",
            "${_altura.toStringAsFixed(2)} m",
            _altura,
            1.3,
            2.3,
            (v) => setState(() => _altura = v),
          ),

          const SizedBox(height: 50),
          _botaoPrincipal("PRÓXIMO: AVALIAÇÃO", _proximoPasso),
        ],
      ),
    );
  }

  // --- ETAPA 1: ANAMNESE (10 PERGUNTAS) ---
  Widget _buildStepAnamnese() {
    var pergunta = _perguntas[_perguntaIndex];
    return Column(
      children: [
        const SizedBox(height: 30),
        LinearProgressIndicator(
          value: (_perguntaIndex + 1) / 10,
          color: Theme.of(context).primaryColor,
          backgroundColor: Colors.white10,
        ),
        const SizedBox(height: 20),
        Text(
          "Pergunta ${_perguntaIndex + 1} de 10",
          style: const TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 30),
        Text(
          pergunta['q'],
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 40),

        ...List.generate(
          pergunta['ops'].length,
          (i) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.05),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                    side: const BorderSide(color: Colors.white10),
                  ),
                ),
                onPressed: () {
                  setState(() {
                    _respostasAnamnese[pergunta['id']] = pergunta['ops'][i];
                    if (_perguntaIndex < 9) {
                      _perguntaIndex++;
                    } else {
                      _etapaAtual = 2; // Vai para a última tela de Auth
                    }
                  });
                },
                child: Text(
                  pergunta['ops'][i],
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
            ),
          ),
        ),
        const Spacer(),
        if (_perguntaIndex > 0)
          TextButton(
            onPressed: () => setState(() => _perguntaIndex--),
            child: const Text("Voltar Pergunta"),
          ),
        const SizedBox(height: 20),
      ],
    );
  }

  // --- ETAPA 2: AUTH (E-MAIL E SENHA) ---
  Widget _buildStepAuth() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.lock_outline, size: 80, color: Colors.white24),
        const SizedBox(height: 20),
        const Text(
          "Finalizar Acesso",
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 30),

        TextField(
          controller: _emailController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: "E-mail",
            filled: true,
            fillColor: Colors.white10,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _senhaController,
          obscureText: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: "Senha (mín. 6 caracteres)",
            filled: true,
            fillColor: Colors.white10,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
          ),
        ),

        const SizedBox(height: 50),
        _botaoPrincipal("CRIAR MINHA CONTA", _finalizarCadastroCompleto),
        TextButton(
          onPressed: () => setState(() => _etapaAtual = 1),
          child: const Text("Revisar Anamnese"),
        ),
      ],
    );
  }

  // Widgets de Apoio (UI)
  Widget _cardIMC(double imc) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(25),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.05),
      borderRadius: BorderRadius.circular(25),
      border: Border.all(color: Colors.white10),
    ),
    child: Column(
      children: [
        const Text("SEU IMC ESTIMADO", style: TextStyle(color: Colors.grey)),
        Text(
          imc.toStringAsFixed(1),
          style: TextStyle(
            fontSize: 60,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
      ],
    ),
  );

  Widget _sliderWidget(
    String label,
    String valor,
    double atual,
    double min,
    double max,
    Function(double) onChanged,
  ) => Column(
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          Text(
            valor,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
      Slider(
        value: atual,
        min: min,
        max: max,
        activeColor: Theme.of(context).primaryColor,
        onChanged: onChanged,
      ),
    ],
  );

  Widget _botaoPrincipal(String texto, VoidCallback f) => SizedBox(
    width: double.infinity,
    height: 60,
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).primaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
      onPressed: _isLoading ? null : f,
      child: _isLoading
          ? const CircularProgressIndicator(color: Colors.black)
          : Text(
              texto,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
    ),
  );
}
