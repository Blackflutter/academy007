import 'package:academy007/data/relatorios/selecionar_aluno_relatorio_screen.dart';
import 'package:academy007/data/repositories/academia_repository.dart';
import 'package:academy007/data/repositories/grupo_repository.dart';
import 'package:academy007/presentation/screens/admin_treino_screen.dart';
import 'package:academy007/presentation/screens/alunos_academia_screen.dart';
import 'package:academy007/presentation/screens/auditoria_treinos_screen.dart';
import 'package:academy007/presentation/screens/financeiro_screen.dart';
import 'package:academy007/presentation/screens/historico_treino_aluno.dart';
import 'package:academy007/presentation/screens/treino_grupos_screen.dart';
import 'package:academy007/presentation/screens/treino_screen.dart';
import 'package:academy007/presentation/widgets/custom_drawer.dart';
import 'package:academy007/presentation/widgets/evolucao_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/aluno_repository.dart';
import 'nutricao_screen.dart';
import 'login_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final AlunoRepository _repository = AlunoRepository();
  final supabase = Supabase.instance.client;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Busca dados completos incluindo a academia via JOIN
  Future<Map<String, dynamic>?> _buscarPerfilCompleto() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return null;

      // Busca o perfil com os dados da academia (usando Left Join)
      final data = await supabase
          .from('perfis')
          .select('*, academias(*)')
          .eq('id', user.id)
          .maybeSingle(); // Retorna null em vez de dar erro se não achar na hora

      return data;
    } catch (e) {
      debugPrint("Erro ao buscar dados: $e");
      return null;
    }
  }

  // 🟢 NOVO: Calcula variação de peso nos últimos 30 dias
  Future<Map<String, dynamic>?> _calcularVariacao30Dias() async {
    final user = supabase.auth.currentUser;
    if (user == null) return null;

    try {
      final historico = await supabase
          .from('historico_peso')
          .select()
          .eq('aluno_id', user.id)
          .order('data_registro', ascending: true);

      if (historico.length < 2) return null;

      final agora = DateTime.now();
      final dataLimite = agora.subtract(const Duration(days: 30));

      Map<String, dynamic>? registroAntigo;

      for (var registro in historico) {
        final data = DateTime.parse(registro['data_registro']);
        if (data.isAfter(dataLimite)) {
          registroAntigo = registro;
          break;
        }
      }

      if (registroAntigo == null) return null;

      final pesoAtual = historico.last['peso'] as num;
      final pesoAntigo = registroAntigo['peso'] as num;
      final diferenca = pesoAtual.toDouble() - pesoAntigo.toDouble();

      return {
        "atual": pesoAtual.toDouble(),
        "antigo": pesoAntigo.toDouble(),
        "diferenca": diferenca,
      };
    } catch (e) {
      debugPrint("Erro ao calcular variação: $e");
      return null;
    }
  }

  void _mostrarDialogoPeso(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.glassColor,
        title: const Text("Registrar Peso de Hoje"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: "Ex: 82.5"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await _repository.registrarNovoPeso(
                  double.parse(controller.text),
                );
                if (context.mounted) {
                  Navigator.pop(context);
                  setState(() {});
                }
              }
            },
            child: const Text("Salvar"),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout() async {
    await supabase.auth.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: const CustomDrawer(),
      backgroundColor: AppTheme.darkBackground,
      body: SafeArea(
        child: FutureBuilder<Map<String, dynamic>?>(
          future: _buscarPerfilCompleto(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryNeon),
              );
            }

            final dados = snapshot.data;
            if (dados == null) {
              return const Center(child: Text("Perfil não encontrado"));
            }

            final bool isProfessor = dados['cargo'] == 'professor';

            double imc = 0;
            if (!isProfessor &&
                dados['peso_atual'] != null &&
                dados['altura'] != null) {
              double peso = (dados['peso_atual'] as num).toDouble();
              double altura = (dados['altura'] as num).toDouble();
              if (altura > 0) imc = peso / (altura * altura);
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(dados['nome'] ?? "Atleta"),
                  const SizedBox(height: 30),

                  isProfessor
                      ? _buildAcademiaCard(dados['academias'])
                      : _buildIMCCard(context, imc),

                  // ✅ MÉTRICAS DO PROFESSOR FORA DO GRID
                  if (isProfessor) ...[
                    const SizedBox(height: 20),
                    _buildMetricasProfessor(),
                  ],

                  // ✅ VARIAÇÃO DO ALUNO
                  if (!isProfessor) ...[
                    const SizedBox(height: 15),
                    _buildVariacaoPesoCard(),
                  ],

                  Text(
                    isProfessor ? "Gestão da Unidade" : "Seu Ecossistema",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 15),

                  if (!isProfessor) const ViewTreinoGrupoWidget(),

                  _buildBentoGrid(dados, isProfessor),

                  if (!isProfessor) ...[
                    _buildActionCard(),
                    const SizedBox(height: 15),
                    FutureBuilder<List<Map<String, dynamic>>>(
                      future: _repository.buscarHistoricoPeso(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const LinearProgressIndicator();
                        }
                        return EvolucaoChart(historico: snapshot.data!);
                      },
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  //* NOVO: Widget que mostra as principais métricas para o professor
  Widget _buildMetricasProfessor() {
    final repo = AcademiaRepository();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// 🔹 MÉTRICAS RESPONSIVAS
        FutureBuilder<Map<String, dynamic>?>(
          future: repo.buscarDadosConsolidados(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox();

            final dados = snapshot.data!;
            final totalAlunos = dados['total_alunos'] ?? 0;
            final mediaImc = (dados['media_imc'] as num?)?.toDouble() ?? 0.0;

            return FutureBuilder<double>(
              future: repo.buscarEvolucaoMedia(),
              builder: (context, snapshotEvo) {
                final variacao = snapshotEvo.data ?? 0.0;

                return LayoutBuilder(
                  builder: (context, constraints) {
                    int colunas;

                    if (constraints.maxWidth < 450) {
                      colunas = 2; // 📱 Mobile
                    } else if (constraints.maxWidth < 800) {
                      colunas = 3; // 📲 Tablet
                    } else {
                      colunas = 4; // 💻 Desktop
                    }

                    return GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: colunas,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.3,
                      children: [
                        _metricCard(
                          "Alunos",
                          totalAlunos.toString(),
                          AppTheme.primaryNeon,
                        ),
                        _metricCard(
                          "Média IMC",
                          mediaImc.toStringAsFixed(2),
                          Colors.orangeAccent,
                        ),
                        _metricCard(
                          "Evolução 30d",
                          variacao.toStringAsFixed(2),
                          variacao < 0 ? Colors.greenAccent : Colors.redAccent,
                        ),
                      ],
                    );
                  },
                );
              },
            );
          },
        ),

        //* 🔹 GRÁFICO CONSOLIDADO
        _buildGraficoAcademia(),
      ],
    );
  }

  //* NOVO: Card de ações rápidas para o aluno
  Widget _buildGraficoAcademia() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: AcademiaRepository().buscarGraficoAcademia(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox();
        }

        final dados = snapshot.data!;

        return Container(
          margin: const EdgeInsets.only(top: 20),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF111111),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Evolução Média da Unidade",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 15),
              EvolucaoChart(historico: dados),
            ],
          ),
        );
      },
    );
  }

  //* NOVO: Widget que mostra o ranking de evolução dos alunos para o professor
  Widget _buildRankingProfessor() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: AcademiaRepository().buscarRankingEvolucao(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox();
        }

        final ranking = snapshot.data!;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF111111),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Top 3 Evolução (30 dias)",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              ...ranking.map((aluno) {
                final evolucao =
                    (aluno['evolucao_30d'] as num?)?.toDouble() ?? 0.0;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        aluno['nome'],
                        style: const TextStyle(color: Colors.white),
                      ),
                      Text(
                        evolucao.toStringAsFixed(2),
                        style: TextStyle(
                          color: evolucao < 0
                              ? Colors.greenAccent
                              : Colors.redAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _metricCard(String titulo, String valor, Color cor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Text(
            valor,
            style: TextStyle(
              color: cor,
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // 🟢 NOVO: Widget que mostra a variação de peso nos últimos 30 dias
  Widget _buildVariacaoPesoCard() {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _calcularVariacao30Dias(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(
              child: SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.primaryNeon,
                ),
              ),
            ),
          );
        }

        if (!snapshot.hasData) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.grey),
                SizedBox(width: 10),
                Text(
                  "Sem dados suficientes para comparação (30 dias)",
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
          );
        }

        final dados = snapshot.data!;
        final diferenca = dados['diferenca'] as double;

        IconData icone;
        Color cor;
        String texto;
        String subtitulo;

        if (diferenca < 0) {
          icone = Icons.arrow_downward;
          cor = Colors.greenAccent;
          texto = "-${diferenca.abs().toStringAsFixed(2)} kg";
          subtitulo = "Nos últimos 30 dias";
        } else if (diferenca > 0) {
          icone = Icons.arrow_upward;
          cor = Colors.redAccent;
          texto = "+${diferenca.toStringAsFixed(2)} kg";
          subtitulo = "Nos últimos 30 dias";
        } else {
          icone = Icons.remove;
          cor = Colors.grey;
          texto = "Sem alteração";
          subtitulo = "Nos últimos 30 dias";
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: cor.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(icone, color: cor, size: 28),
              const SizedBox(width: 15),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    texto,
                    style: TextStyle(
                      color: cor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    subtitulo,
                    style: TextStyle(color: cor.withOpacity(0.7), fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetaInteligente() {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _repository.calcularMetaInteligente(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return const SizedBox();
        }

        final dados = snapshot.data!;
        final percentual = dados['percentual'] as double;
        final dias = dados['diasPrevistos'];

        return Container(
          margin: const EdgeInsets.only(top: 15),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: AppTheme.primaryNeon.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "META INTELIGENTE",
                style: TextStyle(fontSize: 12, color: Colors.white70),
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: percentual / 100,
                color: AppTheme.primaryNeon,
                backgroundColor: Colors.white10,
              ),
              const SizedBox(height: 8),
              Text(
                "${percentual.toStringAsFixed(1)}% da meta concluída",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (dias != null)
                Text(
                  "Previsão: ${dias.toStringAsFixed(0)} dias",
                  style: const TextStyle(color: Colors.white70),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(String nome) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.menu, color: AppTheme.primaryNeon),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
            const SizedBox(width: 5),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Bem-vindo de volta,",
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                Text(
                  nome,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        // 🟢 ALTERADO: Mantido apenas o botão de logout vermelho
        IconButton(
          icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
          onPressed: _handleLogout,
        ),
      ],
    );
  }

  Widget _buildProfilePopup() {
    return PopupMenuButton<String>(
      offset: const Offset(0, 50),
      icon: Container(
        padding: const EdgeInsets.all(3),
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [AppTheme.primaryNeon, Colors.blue]),
          shape: BoxShape.circle,
        ),
        child: const CircleAvatar(
          radius: 10,
          backgroundColor: AppTheme.darkBackground,
          child: Icon(Icons.person, color: Colors.white, size: 10),
        ),
      ),
      onSelected: (value) {
        if (value == 'admin') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminTreinoScreen()),
          );
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'perfil', child: Text("Meu Perfil")),
        const PopupMenuItem(
          value: 'admin',
          child: Text(
            "Painel do Professor",
            style: TextStyle(color: AppTheme.primaryNeon),
          ),
        ),
      ],
    );
  }

  // NOVO: Card de Academia para o Professor
  Widget _buildAcademiaCard(Map<String, dynamic>? academia) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF004D40), Color(0xFF00695C)],
        ),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "MINHA UNIDADE",
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          Text(
            academia?['nome'] ?? "Academia Principal",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Text("CÓDIGO: ", style: TextStyle(color: Colors.white60)),
              Text(
                academia?['codigo_acesso'] ?? "---",
                style: const TextStyle(
                  color: AppTheme.primaryNeon,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy, size: 18, color: Colors.white70),
                onPressed: () {
                  Clipboard.setData(
                    ClipboardData(text: academia?['codigo_acesso'] ?? ""),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Código copiado!")),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIMCCard(BuildContext context, double imcValue) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A237E), Color(0xFF311B92)],
        ),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "MEU IMC ATUAL",
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                imcValue.toStringAsFixed(1),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Icon(Icons.speed, color: AppTheme.primaryNeon, size: 50),
            ],
          ),
          Text(
            imcValue < 25 ? "Peso Ideal" : "Acima do Peso",
            style: const TextStyle(
              color: AppTheme.primaryNeon,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBentoGrid(Map<String, dynamic>? dados, bool isProfessor) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.1,
      children: isProfessor
          ? [
              GestureDetector(
                onTap: () async {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.primaryNeon,
                      ),
                    ),
                  );

                  try {
                    final repository = GrupoRepository();
                    final supabase = Supabase.instance.client;
                    final user = supabase.auth.currentUser;

                    if (user == null) {
                      throw 'Sessão expirada. Faça login novamente.';
                    }

                    // Busca o código de acesso da academia do professor logado
                    final academiaResponse = await supabase
                        .from('academias')
                        .select('codigo_acesso')
                        .eq('responsavel_id', user.id)
                        .maybeSingle();

                    if (academiaResponse == null ||
                        academiaResponse['codigo_acesso'] == null) {
                      throw 'Você não possui nenhuma academia vinculada ao seu perfil.';
                    }

                    final String codigoDinamico =
                        academiaResponse['codigo_acesso'].toString();

                    // Busca os alunos cadastrados
                    final listaAlunos = await repository.buscarAlunosDaAcademia(
                      codigoDinamico,
                    );

                    if (context.mounted)
                      Navigator.pop(context); // Fecha o loading

                    if (context.mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              AlunosAcademiaScreen(alunos: listaAlunos),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted)
                      Navigator.pop(context); // Garante que o loading fecha

                    // TRATAMENTO AMIGÁVEL DO ERRO: Transforma a exceção em um aviso visual na tela
                    if (context.mounted) {
                      final String mensagemErro = e
                          .toString()
                          .replaceAll('Exception: ', '')
                          .replaceAll('DartError: ', '');

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            mensagemErro,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          backgroundColor:
                              Colors.orangeAccent, // Cor de aviso/alerta
                          duration: const Duration(seconds: 4),
                        ),
                      );
                    }
                  }
                },
                child: _bentoItem(
                  "Alunos",
                  Icons.people,
                  "Ver Lista",
                  AppTheme.primaryNeon,
                ),
              ),

              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FinanceiroScreen(),
                    ),
                  );
                },
                child: _bentoItem(
                  "Financeiro",
                  Icons.payments,
                  "Fluxo de Caixa",
                  Colors.blueAccent,
                ),
              ),

              // 🟢 MODIFICADO: De "Minha Filial" para "Treino Alunos" com rota para Auditoria
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AuditoriaTreinosScreen(),
                    ),
                  );
                },
                child: _bentoItem(
                  "Treinos",
                  Icons.fitness_center,
                  "Treino Alunos",
                  Colors.purpleAccent,
                ),
              ),

              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SelecionarAlunoRelatorioScreen(),
                    ),
                  );
                },
                child: _bentoItem(
                  "Relatórios",
                  Icons.analytics,
                  "Desempenho",
                  Colors.orangeAccent,
                ),
              ),
            ]
          // Para ALUNO
          : [
              GestureDetector(
                onTap: () => _mostrarDialogoPeso(context),
                child: _bentoItem(
                  "Peso",
                  Icons.monitor_weight_outlined,
                  "${(dados?['peso_atual'] ?? 0).toStringAsFixed(2)} kg",
                  Colors.blueAccent,
                ),
              ),
              _bentoItem(
                "Altura",
                Icons.height,
                "${(dados?['altura'] ?? 0).toStringAsFixed(2)} m",
                Colors.orangeAccent,
              ),
              _bentoItem(
                "Idade",
                Icons.calendar_today,
                "${dados?['idade'] ?? '--'} anos",
                Colors.purpleAccent,
              ),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const HistoricoAlunosScreen(),
                  ),
                ),
                child: _bentoItem(
                  "Histórico",
                  Icons.history,
                  "Treinos Pagos",
                  AppTheme.primaryNeon,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const NutricaoScreen()),
                ),
                child: _bentoItem(
                  "Dieta",
                  Icons.restaurant,
                  "Ver Plano",
                  Colors.redAccent,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TreinoScreen(categoriaId: 1),
                  ),
                ),
                child: _bentoItem(
                  "Gestão",
                  Icons.admin_panel_settings,
                  "Treinos",
                  Colors.tealAccent,
                ),
              ),
            ],
    );
  }

  Widget _bentoItem(String title, IconData icon, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppTheme.glassColor,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 2),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primaryNeon.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        children: [
          Icon(Icons.bolt, color: AppTheme.primaryNeon),
          SizedBox(width: 15),
          Text(
            "Pronto para o treino",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
