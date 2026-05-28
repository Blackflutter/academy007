import 'package:flutter/material.dart';
import 'package:academy007/data/repositories/academia_repository.dart';

class DashboardProfessorScreen extends StatefulWidget {
  const DashboardProfessorScreen({super.key});

  @override
  State<DashboardProfessorScreen> createState() =>
      _DashboardProfessorScreenState();
}

class _DashboardProfessorScreenState extends State<DashboardProfessorScreen> {
  final _academiaRepository = AcademiaRepository();
  late Future<Map<String, dynamic>?> _dadosUnidadeFuture;

  @override
  void initState() {
    super.initState();
    _dadosUnidadeFuture = _academiaRepository.buscarDadosConsolidados();
  }

  void _atualizarDashboard() {
    setState(() {
      _dadosUnidadeFuture = _academiaRepository.buscarDadosConsolidados();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _dadosUnidadeFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF00FF66)),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                "Erro ao carregar dados",
                style: TextStyle(color: Colors.redAccent),
              ),
            );
          }

          final dados = snapshot.data;

          final String nomeUnidade = dados?['nome'] ?? "SEM UNIDADE";
          final String codigoAcesso =
              dados?['codigo_acesso']?.toString() ?? "------";

          final int totalAlunos = dados?['total_alunos'] ?? 0;

          final double mediaImc =
              (dados?['media_imc'] as num?)?.toDouble() ?? 0.0;

          return RefreshIndicator(
            onRefresh: () async => _atualizarDashboard(),
            color: const Color(0xFF00FF66),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Dashboard da Unidade",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // CARD UNIDADE
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF004D40),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "MINHA UNIDADE",
                          style: TextStyle(color: Colors.white60, fontSize: 12),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          nomeUnidade,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 15),
                        Text(
                          "CÓDIGO: $codigoAcesso",
                          style: const TextStyle(
                            color: Color(0xFF00FF66),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  const Text(
                    "Indicadores",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 15),

                  Row(
                    children: [
                      Expanded(
                        child: _metricCard("Alunos", totalAlunos.toString()),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: _metricCard(
                          "Média IMC",
                          mediaImc.toStringAsFixed(2),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  const Text(
                    "Gestão da Unidade",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 15),

                  Row(
                    children: [
                      Expanded(
                        child: _bentoItem("Alunos", Icons.group, "Ver Lista"),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: _bentoItem(
                          "Financeiro",
                          Icons.payments,
                          "Fluxo de Caixa",
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _metricCard(String titulo, String valor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(15),
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
            style: const TextStyle(
              color: Color(0xFF00FF66),
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _bentoItem(String titulo, IconData icone, String subtitulo) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, color: const Color(0xFF00FF66), size: 30),
          const SizedBox(height: 20),
          Text(
            titulo,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            subtitulo,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
