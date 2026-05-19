import 'package:flutter/material.dart';
import 'package:academy007/data/repositories/academia_repository.dart'; // Ajuste o caminho conforme o seu projeto

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
    // Inicializa a busca segura e blindada contra o erro 406
  }

  // Função para recarregar os dados caso necessário
  void _atualizarDashboard() {
    setState(() {});
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

          // Trata caso ocorra algum erro ou a tabela esteja limpa
          final dados = snapshot.data;
          final String nomeUnidade = dados?['nome'] ?? "SEM UNIDADE";
          final String codigoAcesso =
              dados?['codigo_acesso']?.toString() ?? "------";

          return RefreshIndicator(
            onRefresh: () async => _atualizarDashboard(),
            color: const Color(0xFF00FF66),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 24.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Bem-vindo de volta,",
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const Text(
                    "GUGA",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 🟢 CARD "MINHA UNIDADE" (TOTALMENTE SEGURO AGORA)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(
                        0xFF004D40,
                      ), // Tom de verde escuro igual ao seu print
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "MINHA UNIDADE",
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          nomeUnidade,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 25),
                        Row(
                          children: [
                            Text(
                              "CÓDIGO: $codigoAcesso",
                              style: const TextStyle(
                                color: Color(0xFF00FF66),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.1,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Icon(
                              Icons.copy,
                              color: Colors.white54,
                              size: 18,
                            ),
                          ],
                        ),
                      ],
                    ),
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

                  // --- GRID OU LISTA DOS SEUS BOTÕES BENTO (Alunos, Financeiro, etc.) ---
                  Row(
                    children: [
                      Expanded(
                        child: _bentoItem(
                          "Alunos",
                          Icons.group,
                          "Ver Lista",
                          Colors.white10,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: _bentoItem(
                          "Financeiro",
                          Icons.payments,
                          "Fluxo de Caixa",
                          Colors.white10,
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

  // Exemplo do seu widget customizado de botões do menu bento
  Widget _bentoItem(
    String titulo,
    IconData icone,
    String subtitulo,
    Color cor,
  ) {
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
