import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminDashboardDetalhes extends StatefulWidget {
  final int academiaId; // Recebe o ID da filial logada

  const AdminDashboardDetalhes({super.key, required this.academiaId});

  @override
  State<AdminDashboardDetalhes> createState() => _AdminDashboardDetalhesState();
}

class _AdminDashboardDetalhesState extends State<AdminDashboardDetalhes>
    with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  late TabController _tabController;
  bool _isLoading = true;

  List<dynamic> _treinosConcluidos = [];
  List<dynamic> _treinosColetivos = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _carregarDadosFilial();
  }

  Future<void> _carregarDadosFilial() async {
    setState(() => _isLoading = true);
    try {
      final hoje = DateTime.now().toIso8601String().split('T')[0];

      // 1. Busca treinos concluídos hoje nesta filial
      final concluidos = await _supabase
          .from('treinos_concluidos')
          .select('*, perfis(nome)') // Join para pegar nome do aluno
          .eq('academia_id', widget.academiaId)
          .gte('data_conclusao', hoje);

      // 2. Busca treinos coletivos agendados para esta filial
      final coletivos = await _supabase
          .from('treinos_coletivos')
          .select()
          .eq('academia_id', widget.academiaId)
          .order('horario', ascending: true);

      setState(() {
        _treinosConcluidos = concluidos;
        _treinosColetivos = coletivos;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Erro ao carregar dados: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          "Gestão da Unidade",
          style: TextStyle(color: Colors.white),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF00FF00),
          labelColor: const Color(0xFF00FF00),
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(
              text: "Concluídos Hoje",
              icon: Icon(Icons.check_circle_outline),
            ),
            Tab(text: "Treinos Coletivos", icon: Icon(Icons.groups_outlined)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF00FF00)),
            )
          : TabBarView(
              controller: _tabController,
              children: [_buildListaConcluidos(), _buildListaColetivos()],
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF00FF00),
        child: const Icon(Icons.add, color: Colors.black),
        onPressed: () {
          // Aqui você abriria a tela para criar um NOVO treino coletivo
          _showSnackBar("Funcionalidade de criar treino coletivo em breve!");
        },
      ),
    );
  }

  // ABA 1: LISTA DE QUEM TREINOU HOJE
  Widget _buildListaConcluidos() {
    if (_treinosConcluidos.isEmpty) {
      return const Center(
        child: Text(
          "Nenhum treino concluído hoje.",
          style: TextStyle(color: Colors.grey),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(15),
      itemCount: _treinosConcluidos.length,
      itemBuilder: (context, index) {
        final item = _treinosConcluidos[index];
        return Card(
          color: Colors.white.withOpacity(0.05),
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            title: Text(
              item['perfis']['nome'] ?? "Aluno",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              "Concluído às ${item['data_conclusao'].toString().substring(11, 16)}",
              style: const TextStyle(color: Colors.grey),
            ),
            trailing: const Icon(
              Icons.star,
              color: Color(0xFF00FF00),
              size: 18,
            ),
          ),
        );
      },
    );
  }

  // ABA 2: LISTA DE TREINOS COLETIVOS (Agenda da Academia)
  Widget _buildListaColetivos() {
    if (_treinosColetivos.isEmpty) {
      return const Center(
        child: Text(
          "Sem treinos coletivos agendados.",
          style: TextStyle(color: Colors.grey),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(15),
      itemCount: _treinosColetivos.length,
      itemBuilder: (context, index) {
        final item = _treinosColetivos[index];
        return Card(
          color: Colors.white10,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: const BorderSide(color: Colors.white12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                Column(
                  children: [
                    Text(
                      item['horario'] ?? "--:--",
                      style: const TextStyle(
                        color: Color(0xFF00FF00),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      "Horário",
                      style: TextStyle(color: Colors.grey, fontSize: 10),
                    ),
                  ],
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['nome_aula'] ?? "Aula",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "${item['vagas_ocupadas']}/${item['vagas_total']} Alunos",
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.white24),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
