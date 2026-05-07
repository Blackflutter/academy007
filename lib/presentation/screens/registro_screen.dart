import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dashboard_screen.dart'; // Certifique-se que o caminho está correto

class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  State<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  final _supabase = Supabase.instance.client;

  // 1. CONTROLLERS
  String _cargoSelecionado = 'aluno'; // Inicia como aluno

  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _idadeController = TextEditingController();
  final TextEditingController _cpfController = TextEditingController();
  final TextEditingController _whatsappController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();

  // Novos campos para Academia
  final TextEditingController _cnpjController = TextEditingController();
  final TextEditingController _nomeAcademiaController = TextEditingController();
  final TextEditingController _enderecoController = TextEditingController();
  final TextEditingController _anoFundacaoController = TextEditingController();

  // 2. ESTADO DOS DADOS
  double _peso = 75.0;
  double _altura = 1.75;
  bool _isLoading = false;
  int _etapaAtual = 0;
  int _perguntaIndex = 0;
  final Map<String, dynamic> _respostasAnamnese = {};

  // 3. LISTA DE PERGUNTAS (10 PERGUNTAS)
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
    _idadeController.dispose();
    _cpfController.dispose();
    _whatsappController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    _cnpjController.dispose();
    _nomeAcademiaController.dispose();
    _enderecoController.dispose();
    _anoFundacaoController.dispose();
    super.dispose();
  }

  // 4. LÓGICA DE NAVEGAÇÃO E SALVAMENTO
  void _proximoPasso() {
    if (_nomeController.text.isEmpty) {
      _showSnackBar("O nome é obrigatório");
      return;
    }
    setState(() {
      if (_cargoSelecionado == 'professor') {
        _etapaAtual = 2; // Pula Anamnese e vai para Auth
      } else {
        if (_idadeController.text.isEmpty || _cpfController.text.isEmpty) {
          _showSnackBar("Idade e CPF são obrigatórios");
          return;
        }
        _etapaAtual = 1; // Vai para Anamnese
      }
    });
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _finalizarTudo() async {
    setState(() => _isLoading = true);
    try {
      // 1. Criar Auth SIMPLES (Sem metadados complexos agora para evitar o erro 422)
      final AuthResponse res = await _supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _senhaController.text.trim(),
      );

      if (res.user != null) {
        final userId = res.user!.id;
        int? novaAcademiaId;

        // 2. Se for ACADEMIA, cria a empresa PRIMEIRO
        if (_cargoSelecionado == 'professor') {
          final academiaData = await _supabase
              .from('academias')
              .insert({
                'nome': _nomeAcademiaController.text.trim(),
                'cnpj': _cnpjController.text.trim(),
                'endereco': _enderecoController.text.trim(),
                'responsavel_id': userId,
              })
              .select()
              .single();

          novaAcademiaId = academiaData['id'];
        }

        // 3. Salva o Perfil na tabela 'perfis'
        // Se der erro aqui, o problema é uma coluna no banco que não aceita nulo
        await _supabase.from('perfis').insert({
          'id': userId,
          'nome': _nomeController.text.trim(),
          'email': _emailController.text.trim(),
          'cargo': _cargoSelecionado,
          'academia_id': novaAcademiaId,
          'telefone': _whatsappController.text.trim(),
          'cpf': _cpfController.text
              .trim(), // Certifique-se que o banco aceita nulo se for academia
          'idade': int.tryParse(_idadeController.text),
          // Mude para os nomes que você definiu no início do seu State
          'peso_atual': _cargoSelecionado == 'aluno' ? _peso : null,
          'altura': _cargoSelecionado == 'aluno' ? _altura : null,
          'anamnese': _cargoSelecionado == 'aluno' ? _respostasAnamnese : null,
          'categoria_id': 1,
        });

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const DashboardScreen()),
          );
        }
      }
    } catch (e) {
      debugPrint("ERRO DETALHADO: $e");
      if (mounted) _showSnackBar("Erro ao salvar: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Melhore o SnackBar para ver as cores
  void _showSnackBar1(String msg, {Color color = Colors.redAccent}) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
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
    if (_etapaAtual == 0) return _buildDadosIniciais();
    if (_etapaAtual == 1) return _buildAnamnese();
    return _buildAcessoAuth();
  }

  // ETAPA 0: DADOS INICIAIS (DINÂMICO)
  Widget _buildDadosIniciais() {
    double imc = _peso / (_altura * _altura);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          const Text(
            "Dados Iniciais",
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          // SELETOR NEON
          Row(
            children: [
              _seletorPerfilBtn("SOU ALUNO", 'aluno'),
              const SizedBox(width: 10),
              _seletorPerfilBtn("SOU ACADEMIA", 'professor'),
            ],
          ),
          const SizedBox(height: 20),

          _inputFielCustom(
            _cargoSelecionado == 'aluno' ? "Seu Nome" : "Nome do Responsável",
            _nomeController,
            TextInputType.name,
          ),
          const SizedBox(height: 15),

          if (_cargoSelecionado == 'aluno') ...[
            Row(
              children: [
                Expanded(
                  child: _inputFielCustom(
                    "Idade",
                    _idadeController,
                    TextInputType.number,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: _inputFielCustom(
                    "CPF",
                    _cpfController,
                    TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            _inputFielCustom(
              "WhatsApp",
              _whatsappController,
              TextInputType.phone,
            ),
            const SizedBox(height: 20),
            _cardIMC(imc),
            _sliderWidget(
              "Peso",
              "${_peso.toStringAsFixed(1)} kg",
              _peso,
              40,
              150,
              (v) => setState(() => _peso = v),
            ),
            _sliderWidget(
              "Altura",
              "${_altura.toStringAsFixed(2)} m",
              _altura,
              1.2,
              2.2,
              (v) => setState(() => _altura = v),
            ),
          ] else ...[
            _inputFielCustom(
              "Nome da Academia",
              _nomeAcademiaController,
              TextInputType.text,
            ),
            const SizedBox(height: 15),
            _inputFielCustom("CNPJ", _cnpjController, TextInputType.number),
            const SizedBox(height: 15),
            _inputFielCustom(
              "Endereço Completo",
              _enderecoController,
              TextInputType.streetAddress,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _inputFielCustom(
                    "Ano Fundação",
                    _anoFundacaoController,
                    TextInputType.number,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _inputFielCustom(
                    "WhatsApp Comercial",
                    _whatsappController,
                    TextInputType.phone,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 30),
          _botaoAcao("AVANÇAR", _proximoPasso),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  // ETAPA 1: ANAMNESE (APENAS ALUNO)
  Widget _buildAnamnese() {
    var p = _perguntas[_perguntaIndex];
    return Column(
      children: [
        const SizedBox(height: 40),
        LinearProgressIndicator(
          value: (_perguntaIndex + 1) / 10,
          color: const Color(0xFF00FF00),
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
                    _etapaAtual = 2;
                }),
                child: Text(
                  p['ops'][i],
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ETAPA 2: ACESSO
  Widget _buildAcessoAuth() {
    return Column(
      children: [
        const SizedBox(height: 40),
        const Text(
          "Configurar Acesso",
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 40),
        _inputFielCustom(
          "E-mail",
          _emailController,
          TextInputType.emailAddress,
        ),
        const SizedBox(height: 20),
        _inputFielCustom(
          "Senha",
          _senhaController,
          TextInputType.visiblePassword,
        ),
        const SizedBox(height: 50),
        _botaoAcao("CONCLUIR CADASTRO", _finalizarTudo, loading: _isLoading),
        TextButton(
          onPressed: () => setState(
            () => _etapaAtual = _cargoSelecionado == 'professor' ? 0 : 1,
          ),
          child: const Text("Voltar", style: TextStyle(color: Colors.grey)),
        ),
      ],
    );
  }

  // WIDGETS AUXILIARES
  Widget _seletorPerfilBtn(String label, String cargo) {
    bool sel = _cargoSelecionado == cargo;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _cargoSelecionado = cargo),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            color: sel ? const Color(0xFF00FF00) : Colors.white10,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: sel ? Colors.black : Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _inputFielCustom(
    String label,
    TextEditingController controller,
    TextInputType type,
  ) {
    return TextField(
      controller: controller,
      keyboardType: type,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _botaoAcao(String label, VoidCallback onTap, {bool loading = false}) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00FF00),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        onPressed: loading ? null : onTap,
        child: loading
            ? const CircularProgressIndicator(color: Colors.black)
            : Text(
                label,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _cardIMC(double imc) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("IMC Estimado", style: TextStyle(color: Colors.white)),
          Text(
            imc.toStringAsFixed(1),
            style: const TextStyle(
              color: Color(0xFF00FF00),
              fontSize: 34,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sliderWidget(
    String label,
    String value,
    double val,
    double min,
    double max,
    Function(double) onChanged,
  ) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(color: Colors.grey)),
              Text(value, style: const TextStyle(color: Colors.white)),
            ],
          ),
        ),
        Slider(
          value: val,
          min: min,
          max: max,
          activeColor: const Color(0xFF00FF00),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
