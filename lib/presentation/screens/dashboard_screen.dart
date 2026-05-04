import 'package:academy007/presentation/screens/admin_treino_screen.dart';
import 'package:academy007/presentation/screens/criar_grupo_screen.dart';
import 'package:academy007/presentation/screens/membros_grupo_screen.dart';
import 'package:academy007/presentation/screens/treino_grupos_screen.dart';
import 'package:academy007/presentation/screens/treino_screen.dart';
import 'package:academy007/presentation/widgets/custom_drawer.dart';
import 'package:academy007/presentation/widgets/evolucao_chart.dart';
import 'package:flutter/material.dart';
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
                  setState(() {}); // Recarrega a Dashboard com o novo peso
                }
              }
            },
            child: const Text("Salvar"),
          ),
        ],
      ),
    );
  }

  // Função de Logout
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
      key: _scaffoldKey, // Chave essencial para o IconButton abrir o Drawer
      drawer: const CustomDrawer(), // Menu lateral
      backgroundColor: AppTheme.darkBackground, // Garante o fundo padrão
      body: SafeArea(
        child: FutureBuilder<Map<String, dynamic>?>(
          future: _repository.buscarMeuPerfil(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryNeon),
              );
            }

            final dados = snapshot.data;

            // Cálculo do IMC
            double imc = 0;
            if (dados != null &&
                dados['peso_atual'] != null &&
                dados['altura'] != null) {
              double peso = (dados['peso_atual'] as num).toDouble();
              double altura = (dados['altura'] as num).toDouble();
              imc = peso / (altura * altura);
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(dados?['nome'] ?? "Atleta"),
                  const SizedBox(height: 30),
                  _buildIMCCard(context, imc),
                  const SizedBox(height: 30),
                  const Text(
                    "Seu Ecossistema",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),
                  const ViewTreinoGrupoWidget(),
                  // Adicione aqui
                  _buildBentoGrid(dados),
                  const SizedBox(height: 30),
                  _buildActionCard(),
                  const Text(
                    "Sua Evolução",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
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
                  const SizedBox(height: 30),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(String nome) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Lado Esquerdo: Menu e Boas-vindas
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

        // Lado Direito: Logout e Perfil
        Expanded(
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                onPressed: _handleLogout,
              ),

              PopupMenuButton<String>(
                offset: const Offset(0, 50),
                icon: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.primaryNeon, Colors.blue],
                    ),
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
                      MaterialPageRoute(
                        builder: (_) => const AdminTreinoScreen(),
                      ),
                    );
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'perfil',
                    child: Text("Meu Perfil"),
                  ),
                  const PopupMenuItem(
                    value: 'admin',
                    child: Text(
                      "Painel do Professor",
                      style: TextStyle(color: AppTheme.primaryNeon),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
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

  Widget _buildBentoGrid(Map<String, dynamic>? dados) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: [
        GestureDetector(
          onTap: () => _mostrarDialogoPeso(context),
          child: _bentoItem(
            "Peso",
            Icons.monitor_weight_outlined,
            "${dados?['peso_atual'] ?? 0} kg",
            Colors.blueAccent,
          ),
        ),
        _bentoItem(
          "Altura",
          Icons.height,
          "${dados?['altura'] ?? 0} m",
          Colors.orangeAccent,
        ),
        _bentoItem(
          "Idade",
          Icons.calendar_today,
          "${dados?['idade'] ?? 0} anos",
          Colors.purpleAccent,
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
            ), // Use o ID numérico aqui
          ),

          child: _bentoItem(
            "Gestão",
            Icons.admin_panel_settings,
            "Treinos",
            Colors.tealAccent,
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CriarGrupoScreen()),
          ),
          child: _bentoItem(
            "Grupos",
            Icons.group_add,
            "Grupos",
            Colors.tealAccent,
          ),
        ),
      ],
    );
  }

  Widget _bentoItem(String title, IconData icon, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.glassColor,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildActionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primaryNeon.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(Icons.bolt, color: AppTheme.primaryNeon),
          SizedBox(width: 15),
          Text(
            "Pronto para o treino",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
