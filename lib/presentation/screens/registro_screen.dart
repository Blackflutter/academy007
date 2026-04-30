import 'package:flutter/material.dart';
import '../../data/models/aluno_model.dart';
import '../../data/repositories/aluno_repository.dart';
import 'dashboard_screen.dart';

class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();
  final AlunoRepository _repository = AlunoRepository();

  // Dados do Perfil
  double _peso = 75.0;
  double _altura = 1.75;
  bool _isLoading = false;

  // Controle de Fluxo: 0 = Físico, 1 = Anamnese, 2 = E-mail/Senha
  int _etapaAtual = 0;
  int _perguntaIndex = 0;
  Map<String, dynamic> _respostasAnamnese = {};

  final List<Map<String, dynamic>> _perguntas = [
    {
      "id": "objetivo",
      "q": "Qual seu objetivo?",
      "ops": ["Emagrecer", "Massa Muscular", "Saúde"],
    },
    {
      "id": "lesao",
      "q": "Possui lesões?",
      "ops": ["Não", "Sim (Joelhos/Coluna)", "Outras"],
    },
    {
      "id": "experiencia",
      "q": "Nível de experiência?",
      "ops": ["Iniciante", "Intermediário", "Avançado"],
    },
    {
      "id": "treinos_semana",
      "q": "Treinos por semana?",
      "ops": ["1-2 dias", "3-4 dias", "5+ dias"],
    },
    {
      "id": "dieta",
      "q": "Faz dieta hoje?",
      "ops": ["Sim", "Não", "Mais ou menos"],
    },
    {
      "id": "medicamentos",
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
      "id": "suplementos",
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
    _emailController.dispose();
    _senhaController.dispose();
    super.dispose();
  }

  void _proximoPasso() {
    if (_nomeController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Digite seu nome")));
      return;
    }
    setState(() => _etapaAtual = 1);
  }

  Future<void> _finalizarTudo() async {
    if (_emailController.text.isEmpty || _senhaController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("E-mail válido e senha de 6 dígitos são obrigatórios"),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final novoAluno = AlunoModel(
        nome: _nomeController.text,
        peso: _peso,
        altura: _altura,
        categoriaId: 1,
        anamnese: _respostasAnamnese,
      );

      // Aqui o seu repository cria o Auth e depois o registro na tabela 'perfis'
      await _repository.salvarOuAtualizarPerfil(
        novoAluno,
        email: _emailController.text,
        senha: _senhaController.text,
      );

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
        ).showSnackBar(SnackBar(content: Text("Erro ao cadastrar: $e")));
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
          child: _renderizarEtapa(),
        ),
      ),
    );
  }

  Widget _renderizarEtapa() {
    if (_etapaAtual == 0) return _buildDadosFisicos();
    if (_etapaAtual == 1) return _buildAnamnese();
    return _buildAcessoAuth();
  }

  // ETAPA 1: NOME, PESO, ALTURA
  Widget _buildDadosFisicos() {
    double imc = _peso / (_altura * _altura);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          const Text(
            "Dados Iniciais",
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
              labelText: "Nome",
              filled: true,
              fillColor: Colors.white10,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
          const SizedBox(height: 30),
          _cardIMC(imc),
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
          const SizedBox(height: 40),
          _botaoAcao("AVANÇAR", _proximoPasso),
        ],
      ),
    );
  }

  // ETAPA 2: AS 10 PERGUNTAS DE SAÚDE
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
          "Pergunta ${_perguntaIndex + 1}/10",
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
        const SizedBox(height: 30),
        ...List.generate(
          p['ops'].length,
          (i) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
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
                onPressed: () => setState(() {
                  _respostasAnamnese[p['id']] = p['ops'][i];
                  if (_perguntaIndex < 9)
                    _perguntaIndex++;
                  else
                    _etapaAtual = 2; // Vai para Auth
                }),
                child: Text(
                  p['ops'][i],
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
            ),
          ),
        ),
        if (_perguntaIndex > 0)
          TextButton(
            onPressed: () => setState(() => _perguntaIndex--),
            child: const Text("Voltar pergunta"),
          ),
      ],
    );
  }

  // ETAPA 3: E-MAIL E SENHA
  Widget _buildAcessoAuth() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          "Crie sua Conta",
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          "Para salvar seu histórico e treinos",
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 30),
        TextField(
          controller: _emailController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: "E-mail",
            labelStyle: TextStyle(color: Colors.grey),
          ),
        ),
        const SizedBox(height: 15),
        TextField(
          controller: _senhaController,
          obscureText: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            labelText: "Senha (mín. 6 dígitos)",
            labelStyle: TextStyle(color: Colors.grey),
          ),
        ),
        const SizedBox(height: 40),
        _botaoAcao("FINALIZAR CADASTRO", _finalizarTudo),
      ],
    );
  }

  // Widgets Auxiliares
  Widget _cardIMC(double imc) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    margin: const EdgeInsets.only(bottom: 20),
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
