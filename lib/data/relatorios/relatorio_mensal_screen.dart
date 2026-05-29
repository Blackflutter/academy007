import 'package:academy007/data/repositories/aluno_repository.dart';
import 'package:academy007/presentation/widgets/evolucao_chart.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class RelatorioMensalScreen extends StatelessWidget {
  final String alunoId;

  const RelatorioMensalScreen({super.key, required this.alunoId});

  String _formatarMes(String dataIso) {
    final data = DateTime.parse(dataIso);
    const meses = [
      "Jan",
      "Fev",
      "Mar",
      "Abr",
      "Mai",
      "Jun",
      "Jul",
      "Ago",
      "Set",
      "Out",
      "Nov",
      "Dez",
    ];
    return "${meses[data.month - 1]} / ${data.year}";
  }

  @override
  Widget build(BuildContext context) {
    final repo = AlunoRepository();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("Relatório Mensal"),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: repo.buscarRelatorioMensal(alunoId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryNeon),
            );
          }

          final dados = snapshot.data!;
          if (dados.isEmpty) {
            return const Center(
              child: Text(
                "Sem dados no período",
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: dados.length,
            itemBuilder: (context, index) {
              final item = dados[index];

              final pesoInicial =
                  (item['peso_inicial'] as num?)?.toDouble() ?? 0.0;
              final pesoFinal = (item['peso_final'] as num?)?.toDouble() ?? 0.0;
              final pesoMedio = (item['peso_medio'] as num?)?.toDouble() ?? 0.0;
              final variacao =
                  (item['variacao_mes'] as num?)?.toDouble() ?? 0.0;

              /// ✅ COMPARATIVO COM MÊS ANTERIOR
              double? variacaoAnterior;
              double? diferencaComparativa;

              if (index + 1 < dados.length) {
                variacaoAnterior =
                    (dados[index + 1]['variacao_mes'] as num?)?.toDouble() ??
                    0.0;
                diferencaComparativa = variacao - variacaoAnterior;
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 25),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF111111),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// 🔹 TÍTULO DO MÊS
                    Text(
                      _formatarMes(item['mes']),
                      style: const TextStyle(
                        color: AppTheme.primaryNeon,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 15),

                    /// 🔹 DADOS
                    _linhaInfo(
                      "Peso Inicial",
                      "${pesoInicial.toStringAsFixed(2)} kg",
                    ),
                    _linhaInfo(
                      "Peso Final",
                      "${pesoFinal.toStringAsFixed(2)} kg",
                    ),
                    _linhaInfo("Média", "${pesoMedio.toStringAsFixed(2)} kg"),

                    const SizedBox(height: 8),

                    Text(
                      variacao < 0
                          ? "✅ Reduziu ${variacao.abs().toStringAsFixed(2)} kg"
                          : "⚠️ Aumentou ${variacao.toStringAsFixed(2)} kg",
                      style: TextStyle(
                        color: variacao < 0
                            ? Colors.greenAccent
                            : Colors.redAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    /// ✅ COMPARATIVO MÊS ANTERIOR
                    if (diferencaComparativa != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          diferencaComparativa < 0
                              ? "Melhorou ${diferencaComparativa.abs().toStringAsFixed(2)} kg em relação ao mês anterior"
                              : "Piorou ${diferencaComparativa.toStringAsFixed(2)} kg em relação ao mês anterior",
                          style: TextStyle(
                            color: diferencaComparativa < 0
                                ? Colors.greenAccent
                                : Colors.redAccent,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                    const SizedBox(height: 25),

                    /// 🔹 GRÁFICO DE BARRAS
                    _buildGraficoBarras(pesoInicial, pesoMedio, pesoFinal),

                    const SizedBox(height: 25),

                    /// 🔹 GRÁFICO DE EVOLUÇÃO DIÁRIA
                    FutureBuilder<List<Map<String, dynamic>>>(
                      future: repo.buscarGraficoMensalAluno(
                        alunoId: alunoId,
                        mesSelecionado: DateTime.parse(item['mes']),
                      ),
                      builder: (context, snap) {
                        if (!snap.hasData || snap.data!.isEmpty) {
                          return const SizedBox();
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Evolução Diária",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 15),
                            EvolucaoChart(historico: snap.data!),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _linhaInfo(String titulo, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(titulo, style: const TextStyle(color: Colors.white70)),
          Text(
            valor,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGraficoBarras(double inicial, double medio, double fimMes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Comparativo do Mês",
          style: TextStyle(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 15),
        SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              gridData: FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(show: false),
              barGroups: [
                _barGroup(0, inicial, Colors.blueAccent),
                _barGroup(1, medio, Colors.orangeAccent),
                _barGroup(
                  2,
                  fimMes,
                  fimMes < inicial ? Colors.greenAccent : Colors.redAccent,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Text("Inicial", style: TextStyle(color: Colors.blueAccent)),
            Text("Média", style: TextStyle(color: Colors.orangeAccent)),
            Text("Final", style: TextStyle(color: Colors.white)),
          ],
        ),
      ],
    );
  }

  BarChartGroupData _barGroup(int x, double valor, Color cor) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: valor,
          color: cor,
          width: 18,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }
}
