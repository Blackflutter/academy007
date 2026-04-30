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
  final TextEditingController _nomeController = TextEditingController();
  final AlunoRepository _repository = AlunoRepository();

  double _peso = 75.0;
  double _altura = 1.75;
  bool _isLoading = false;

  // Controle de Fluxo
  int _etapaAtual = 0; // 0: Dados Físicos, 1: Anamnese
  int _perguntaIndex = 0;
  Map<String, dynamic> _respostasAnamnese = {};

  final List<Map<String, dynamic>> _perguntas = [
    {
      "id": "obj",
      "q": "Qual seu objetivo?",
      "ops": ["Emagrecer", "Massa Muscular", "Saúde"],
    },
    {
      "id": "lesao",
      "q": "Possui lesões?",
      "ops": ["Não", "Sim (Joelhos/Coluna)", "Outras"],
    },
    {
      "id": "exp",
      "q": "Experiência de treino?",
      "ops": ["Iniciante", "Intermediário", "Avançado"],
    },
    {
      "id": "freq",
      "q": "Treinos por semana?",
      "ops": ["1-2 dias", "3-4 dias", "5+ dias"],
    },
    {
      "id": "dieta",
      "q": "Faz dieta hoje?",
      "ops": ["Sim", "Não", "Mais ou menos"],
    },
    {
      "id": "meds",
      "q": "Toma medicamentos?",
      "ops": ["Sim", "Não"],
    },
    {
      "id": "vicios",
      "q": "Tabagismo/Vícios?",
      "ops": ["Sim", "Não"],
    },
    {
      "id": "sono",
      "q": "Qualidade do sono?",
      "ops": ["Boa", "Regular", "Ruim"],
    },
    {
      "id": "suples",
      "q": "Usa suplementos?",
      "ops": ["Sim", "Não"],
    },
    {
      "id": "cardio",
      "q": "Problemas cardíacos?",
      "ops": ["Sim", "Não"],
    },
  ];

  @override
  void dispose() {
    _nomeController.dispose();
    super.dispose();
  }

  void _avancarOuSalvar() async {
    if (_nomeController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Digite seu nome")));
      return;
    }

    if (_etapaAtual == 0) {
      // Sai dos dados físicos e entra na Anamnese
      setState(() => _etapaAtual = 1);
    } else {
      // Se já estiver na anamnese e terminou as 10 perguntas
      _finalizarCadastro();
    }
  }

  Future<void> _finalizarCadastro() async {
    setState(() => _isLoading = true);
    try {
      final novoAluno = AlunoModel(
        nome: _nomeController.text,
        peso: _peso,
        altura: _altura,
        categoriaId: 1,
        anamnese: _respostasAnamnese,
      );

      await _repository.salvarOuAtualizarPerfil(novoAluno);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Erro: $e")));
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
          child: _etapaAtual == 0 ? _buildDadosFisicos() : _buildAnamnese(),
        ),
      ),
    );
  }

  // TELA 1: DADOS PESSOAIS
  Widget _buildDadosFisicos() {
    double imc = _peso / (_altura * _altura);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 40),
        const Text(
          "Configurar Perfil",
          style: TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _nomeController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: "Nome Completo",
            filled: true,
            fillColor: Colors.white10,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
          ),
        ),
        const SizedBox(height: 30),
        _cardIMC(imc),
        const SizedBox(height: 30),
        _slider(
          "Peso",
          "${_peso.toStringAsFixed(1)} kg",
          _peso,
          40,
          150,
          (v) => setState(() => _peso = v),
        ),
        _slider(
          "Altura",
          "${_altura.toStringAsFixed(2)} m",
          _altura,
          1.2,
          2.2,
          (v) => setState(() => _altura = v),
        ),
        const Spacer(),
        _botaoAcao("PRÓXIMO: AVALIAÇÃO FÍSICA", _avancarOuSalvar),
        const SizedBox(height: 30),
      ],
    );
  }

  // TELA 2: ANAMNESE (AS 10 PERGUNTAS)
  Widget _buildAnamnese() {
    var p = _perguntas[_perguntaIndex];
    return Column(
      children: [
        const SizedBox(height: 40),
        LinearProgressIndicator(
          value: (_perguntaIndex + 1) / 10,
          color: Theme.of(context).primaryColor,
        ),
        const SizedBox(height: 20),
        Text(
          "Pergunta ${_perguntaIndex + 1} de 10",
          style: const TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 20),
        Text(
          p['q'],
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 40),
        ...List.generate(
          p['ops'].length,
          (i) => Padding(
            padding: const EdgeInsets.only(bottom: 15),
            child: SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white10,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                onPressed: () {
                  setState(() {
                    _respostasAnamnese[p['id']] = p['ops'][i];
                    if (_perguntaIndex < 9) {
                      _perguntaIndex++;
                    } else {
                      _finalizarCadastro(); // Auto-finaliza na última resposta
                    }
                  });
                },
                child: Text(
                  p['ops'][i],
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
            child: const Text("Voltar pergunta"),
          ),
        const SizedBox(height: 30),
      ],
    );
  }

  // Widgets de suporte
  Widget _cardIMC(double imc) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white10,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      children: [
        const Text("IMC", style: TextStyle(color: Colors.grey)),
        Text(
          imc.toStringAsFixed(1),
          style: TextStyle(
            fontSize: 48,
            color: Theme.of(context).primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  );
  Widget _slider(
    String l,
    String v,
    double val,
    double min,
    double max,
    Function(double) n,
  ) => Column(
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(l, style: const TextStyle(color: Colors.white)),
          Text(
            v,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      Slider(
        value: val,
        min: min,
        max: max,
        activeColor: Theme.of(context).primaryColor,
        onChanged: n,
      ),
    ],
  );
  Widget _botaoAcao(String t, VoidCallback f) => SizedBox(
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
              t,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
    ),
  );
}
