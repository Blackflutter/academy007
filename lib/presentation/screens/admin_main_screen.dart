import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart'; // Para copiar o código

class AdminMainScreen extends StatefulWidget {
  const AdminMainScreen({super.key});

  @override
  State<AdminMainScreen> createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  final _supabase = Supabase.instance.client;
  Map<String, dynamic>? _dadosAcademia;
  List<dynamic> _alunos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarDadosDashboard();
  }

  Future<void> _carregarDadosDashboard() async {
    try {
      final user = _supabase.auth.currentUser;

      // 1. Buscar a academia vinculada ao professor
      final perfilData = await _supabase
          .from('perfis')
          .select('academia_id, academias(*)')
          .eq('id', user!.id)
          .single();

      final academia = perfilData['academias'];
      final academiaId = perfilData['academia_id'];

      // 2. Buscar todos os alunos desta academia
      final alunosData = await _supabase
          .from('perfis')
          .select()
          .eq('academia_id', academiaId)
          .eq('cargo', 'aluno');

      setState(() {
        _dadosAcademia = academia;
        _alunos = alunosData;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Erro ao carregar dashboard: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          "Gestão Academy007",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () async {
              await _supabase.auth.signOut();
              // ignore: use_build_context_synchronously
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF00FF00)),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // CARD DA ACADEMIA E CÓDIGO
                  _buildCardInfo(),
                  const SizedBox(height: 30),
                  const Text(
                    "Seus Alunos",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 15),

                  // LISTA DE ALUNOS
                  _alunos.isEmpty
                      ? const Text(
                          "Nenhum aluno vinculado ainda.",
                          style: TextStyle(color: Colors.grey),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _alunos.length,
                          itemBuilder: (context, index) {
                            final aluno = _alunos[index];
                            return _buildCardAluno(aluno);
                          },
                        ),
                ],
              ),
            ),
    );
  }

  Widget _buildCardInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF00FF00).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _dadosAcademia?['nome'] ?? "Minha Academia",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "Código de Acesso para Alunos:",
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF00FF00),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _dadosAcademia?['codigo_acesso'] ?? "---",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy, color: Colors.white70),
                onPressed: () {
                  Clipboard.setData(
                    ClipboardData(text: _dadosAcademia?['codigo_acesso'] ?? ""),
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

  // 1. Buscar Treinos Coletivos da Unidade
  Future<List<dynamic>> _buscarColetivos(int academiaId) async {
    return await _supabase
        .from('treinos_coletivos')
        .select()
        .eq('academia_id', academiaId);
  }

  // 2. Buscar Alunos que treinaram hoje (Concluídos)
  Future<List<dynamic>> _buscarTreinosHoje(int academiaId) async {
    final hoje = DateTime.now().toIso8601String().split(
      'T',
    )[0]; // Pega apenas a data YYYY-MM-DD

    return await _supabase
        .from('treinos_concluidos')
        .select(
          '*, perfis(nome)',
        ) // Faz join com perfis para pegar o nome do aluno
        .eq('academia_id', academiaId)
        .gte('data_conclusao', hoje); // Maior ou igual a hoje
  }

  Widget _buildCardAluno(dynamic aluno) {
    return Card(
      color: Colors.white.withValues(alpha: 0.05),
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Color(0xFF00FF00),
          child: Icon(Icons.person, color: Colors.black),
        ),
        title: Text(
          aluno['nome'] ?? "Sem nome",
          style: const TextStyle(color: Colors.white),
        ),
        subtitle: Text(
          "WhatsApp: ${aluno['telefone'] ?? 'N/A'}",
          style: const TextStyle(color: Colors.grey),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          color: Colors.white24,
          size: 16,
        ),
        onTap: () {
          // Aqui você poderá abrir a ficha do aluno para passar o treino
        },
      ),
    );
  }
}
