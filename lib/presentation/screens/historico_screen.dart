import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/treino_repository.dart';

class HistoricoScreen extends StatefulWidget {
  const HistoricoScreen({super.key});

  @override
  State<HistoricoScreen> createState() => _HistoricoScreenState();
}

class _HistoricoScreenState extends State<HistoricoScreen> {
  final TreinoRepository _repository = TreinoRepository();
  late Future<List<Map<String, dynamic>>> _historicoFuture;

  @override
  void initState() {
    super.initState();
    _carregarHistorico();
  }

  // Função para carregar/recarregar os dados
  void _carregarHistorico() {
    setState(() {
      _historicoFuture = _repository.buscarHistoricoCompleto();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Histórico'),
        actions: [
          // Botão manual de refresh no AppBar
          IconButton(
            onPressed: _carregarHistorico,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      // RefreshIndicator permite "puxar para baixo" para atualizar
      body: RefreshIndicator(
        color: AppTheme.primaryNeon,
        onRefresh: () async {
          _carregarHistorico();
        },
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _historicoFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryNeon),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  "Erro ao carregar: ${snapshot.error}",
                  style: const TextStyle(color: Colors.white),
                ),
              );
            }

            final historico = snapshot.data ?? [];

            if (historico.isEmpty) {
              // ListView necessário para o RefreshIndicator funcionar em telas vazias
              return ListView(
                children: const [
                  SizedBox(height: 100),
                  Center(
                    child: Text("Você ainda não concluiu nenhum exercício."),
                  ),
                ],
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(15),
              itemCount: historico.length,
              itemBuilder: (context, index) {
                final item = historico[index];
                final exercicio = item['exercicios'];

                // Tratamento seguro caso o exercício tenha sido deletado
                final nomeExercicio = exercicio != null
                    ? exercicio['nome']
                    : "Exercício removido";

                final data = DateTime.parse(item['data_conclusao']);
                final dataFormatada = DateFormat(
                  'dd/MM/yyyy - HH:mm',
                ).format(data.toLocal());

                return Card(
                  color: AppTheme.glassColor,
                  margin: const EdgeInsets.only(bottom: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: AppTheme.primaryNeon,
                      child: Icon(Icons.check, color: Colors.black),
                    ),
                    title: Text(
                      nomeExercicio,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    subtitle: Text(
                      "Concluído em: $dataFormatada",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: Colors.white24,
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
