// ignore_for_file: curly_braces_in_flow_control_structures

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

  // ─── HELPERS DE RESPONSIVIDADE ────────────────────────────────────────────
  // Retornam valores escalados com base na largura real da tela.
  // Referência base: 390 px (iPhone 14 / média dos Android modernos).
  double _rw(BuildContext ctx, double px) =>
      px * MediaQuery.of(ctx).size.width / 390;

  double _rh(BuildContext ctx, double px) =>
      px * MediaQuery.of(ctx).size.height / 844;

  double _rf(BuildContext ctx, double sp) =>
      sp * MediaQuery.of(ctx).size.width / 390;
  // ──────────────────────────────────────────────────────────────────────────

  // 1. CONTROLLERS
  String _cargoSelecionado = 'aluno';

  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _idadeController = TextEditingController();
  final TextEditingController _cpfController = TextEditingController();
  final TextEditingController _whatsappController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _senhaController = TextEditingController();

  // Campos para Academia
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

  // 4. LÓGICA DE NAVEGAÇÃO E SALVAMENTO (inalterada)
  void _proximoPasso() {
    if (_nomeController.text.isEmpty) {
      _showSnackBar("O nome é obrigatório");
      return;
    }
    setState(() {
      if (_cargoSelecionado == 'professor') {
        _etapaAtual = 2;
      } else {
        if (_idadeController.text.isEmpty || _cpfController.text.isEmpty) {
          _showSnackBar("Idade e CPF são obrigatórios");
          return;
        }
        _etapaAtual = 1;
      }
    });
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _finalizarTudo() async {
    setState(() => _isLoading = true);
    try {
      // 1. Criar Auth
      final AuthResponse res = await _supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _senhaController.text.trim(),
      );

      if (res.user != null) {
        final userId = res.user!.id;
        int? novaAcademiaId;

        // 2. Se for Professor/Academia, cria a empresa primeiro
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

        // 3. Salva o Perfil (Ajustado conforme o seu Diagrama)
        // IMPORTANTE: Verifique se existe o ID 1 na sua tabela 'categorias'
        await _supabase.from('perfis').insert({
          'id': userId,
          'nome': _nomeController.text.trim(),
          'email': _emailController.text.trim(),
          'cargo': _cargoSelecionado, // 'aluno' ou 'professor'
          'cpf': _cpfController.text.trim().isEmpty
              ? null
              : _cpfController.text.trim(),
          'telefone': _whatsappController.text.trim(),
          'idade': int.tryParse(_idadeController.text.trim()) ?? 0,
          'peso_atual': _cargoSelecionado == 'aluno' ? _peso : null,
          'altura': _cargoSelecionado == 'aluno' ? _altura : null,
          'anamnese': _cargoSelecionado == 'aluno' ? _respostasAnamnese : null,
          'academia_id':
              novaAcademiaId, // Se for aluno, pode ser null inicialmente
          'categoria_id':
              1, // <--- CERTIFIQUE-SE QUE ESTE ID EXISTE NA TABELA CATEGORIAS
        });

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const DashboardScreen()),
          );
        }
      }
    } on AuthException catch (e) {
      _showSnackBar("Erro na conta: ${e.message}");
    } catch (e) {
      debugPrint("ERRO DE BANCO: $e");
      _showSnackBar("Erro ao salvar perfil: Verifique os dados.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─── BUILD ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Calcula o padding horizontal de forma responsiva:
    // telas muito largas (tablet) recebem um padding maior para centralizar.
    final screenWidth = MediaQuery.of(context).size.width;
    final hPad = screenWidth > 600
        ? screenWidth *
              0.15 // tablet: 15% de cada lado
        : _rw(context, 25); // celular: ~25 px escalados

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: hPad,
                    vertical: _rh(context, 20),
                  ),
                  child: IntrinsicHeight(child: _renderizarEtapa()),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _renderizarEtapa() {
    if (_etapaAtual == 0) return _buildDadosIniciais();
    if (_etapaAtual == 1) return _buildAnamnese();
    return _buildAcessoAuth();
  }

  // ─── ETAPA 0: DADOS INICIAIS ──────────────────────────────────────────────

  Widget _buildDadosIniciais() {
    double imc = _peso / (_altura * _altura);
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: _rh(context, 20)),
          Text(
            "Dados Iniciais",
            style: TextStyle(
              color: Colors.white,
              fontSize: _rf(context, 32), // ← responsivo
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: _rh(context, 20)),

          // SELETOR NEON
          Row(
            children: [
              _seletorPerfilBtn("SOU ALUNO", 'aluno'),
              SizedBox(width: _rw(context, 10)),
              _seletorPerfilBtn("SOU ACADEMIA", 'professor'),
            ],
          ),
          SizedBox(height: _rh(context, 20)),

          _inputFielCustom(
            _cargoSelecionado == 'aluno' ? "Seu Nome" : "Nome do Responsável",
            _nomeController,
            TextInputType.name,
          ),
          SizedBox(height: _rh(context, 15)),

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
                SizedBox(width: _rw(context, 10)),
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
            SizedBox(height: _rh(context, 15)),
            _inputFielCustom(
              "WhatsApp",
              _whatsappController,
              TextInputType.phone,
            ),
            SizedBox(height: _rh(context, 20)),
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
            SizedBox(height: _rh(context, 15)),
            _inputFielCustom("CNPJ", _cnpjController, TextInputType.number),
            SizedBox(height: _rh(context, 15)),
            _inputFielCustom(
              "Endereço Completo",
              _enderecoController,
              TextInputType.streetAddress,
            ),
            SizedBox(height: _rh(context, 10)),
            Row(
              children: [
                Expanded(
                  child: _inputFielCustom(
                    "Ano Fundação",
                    _anoFundacaoController,
                    TextInputType.number,
                  ),
                ),
                SizedBox(width: _rw(context, 10)),
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
          SizedBox(height: _rh(context, 30)),
          _botaoAcao("AVANÇAR", _proximoPasso),
          SizedBox(height: _rh(context, 10)),
        ],
      ),
    );
  }

  // ─── ETAPA 1: ANAMNESE ────────────────────────────────────────────────────

  Widget _buildAnamnese() {
    var p = _perguntas[_perguntaIndex];
    return Column(
      children: [
        SizedBox(height: _rh(context, 40)),
        LinearProgressIndicator(
          value: (_perguntaIndex + 1) / 10,
          color: const Color(0xFF00FF00),
        ),
        SizedBox(height: _rh(context, 20)),
        Text(
          p['q'],
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: _rf(context, 24), // ← responsivo
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: _rh(context, 30)),
        ...List.generate(
          p['ops'].length,
          (i) => Padding(
            padding: EdgeInsets.only(bottom: _rh(context, 12)),
            child: SizedBox(
              width: double.infinity,
              height: _rh(context, 55), // ← altura do botão responsiva
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white10,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(_rw(context, 15)),
                  ),
                ),
                onPressed: () => setState(() {
                  _respostasAnamnese[p['id']] = p['ops'][i];
                  if (_perguntaIndex < 9)
                    // ignore: duplicate_ignore
                    // ignore: curly_braces_in_flow_control_structures
                    _perguntaIndex++;
                  else
                    _etapaAtual = 2;
                }),
                child: Text(
                  p['ops'][i],
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: _rf(context, 15), // ← responsivo
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── ETAPA 2: ACESSO AUTH ─────────────────────────────────────────────────

  Widget _buildAcessoAuth() {
    return Column(
      children: [
        SizedBox(height: _rh(context, 40)),
        Text(
          "Configurar Acesso",
          style: TextStyle(
            color: Colors.white,
            fontSize: _rf(context, 28), // ← responsivo
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: _rh(context, 40)),
        _inputFielCustom(
          "E-mail",
          _emailController,
          TextInputType.emailAddress,
        ),
        SizedBox(height: _rh(context, 20)),
        _inputFielCustom(
          "Senha",
          _senhaController,
          TextInputType.visiblePassword,
          isPassword: true,
        ),
        SizedBox(height: _rh(context, 50)),
        _botaoAcao("CONCLUIR CADASTRO", _finalizarTudo, loading: _isLoading),
        TextButton(
          onPressed: () => setState(
            () => _etapaAtual = _cargoSelecionado == 'professor' ? 0 : 1,
          ),
          child: Text(
            "Voltar",
            style: TextStyle(
              color: Colors.grey,
              fontSize: _rf(context, 14), // ← responsivo
            ),
          ),
        ),
      ],
    );
  }

  // ─── WIDGETS AUXILIARES ───────────────────────────────────────────────────

  Widget _seletorPerfilBtn(String label, String cargo) {
    bool sel = _cargoSelecionado == cargo;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _cargoSelecionado = cargo),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: _rh(context, 15)),
          decoration: BoxDecoration(
            color: sel ? const Color(0xFF00FF00) : Colors.white10,
            borderRadius: BorderRadius.circular(_rw(context, 15)),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: sel ? Colors.black : Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: _rf(
                context,
                13,
              ), // ← responsivo (cabe em telas pequenas)
            ),
          ),
        ),
      ),
    );
  }

  // Adicionei o bool isPassword = false aqui no final do parâmetro
  Widget _inputFielCustom(
    String label,
    TextEditingController controller,
    TextInputType type, {
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: type,
      obscureText: isPassword, // ← ESSA LINHA FAZ O TEXTO VIRAR ASTERISCO
      style: TextStyle(color: Colors.white, fontSize: _rf(context, 15)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey, fontSize: _rf(context, 14)),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        contentPadding: EdgeInsets.symmetric(
          horizontal: _rw(context, 16),
          vertical: _rh(context, 14),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_rw(context, 15)),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _botaoAcao(String label, VoidCallback onTap, {bool loading = false}) {
    return SizedBox(
      width: double.infinity,
      height: _rh(context, 55), // ← responsivo
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00FF00),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_rw(context, 15)),
          ),
        ),
        onPressed: loading ? null : onTap,
        child: loading
            ? const CircularProgressIndicator(color: Colors.black)
            : Text(
                label,
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: _rf(context, 15), // ← responsivo
                ),
              ),
      ),
    );
  }

  Widget _cardIMC(double imc) {
    return Container(
      padding: EdgeInsets.all(_rw(context, 20)),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(_rw(context, 15)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "IMC Estimado",
            style: TextStyle(
              color: Colors.white,
              fontSize: _rf(context, 15), // ← responsivo
            ),
          ),
          Text(
            imc.toStringAsFixed(1),
            style: TextStyle(
              color: const Color(0xFF00FF00),
              fontSize: _rf(context, 34), // ← responsivo
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
          padding: EdgeInsets.symmetric(vertical: _rh(context, 10)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: _rf(context, 14), // ← responsivo
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: _rf(context, 14), // ← responsivo
                ),
              ),
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
