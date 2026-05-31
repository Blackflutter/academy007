import 'package:academy007/data/relatorios/relatorio_caminhada_screen.dart';
import 'package:academy007/data/repositories/caminhada_repository.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';

class HistoricoCaminhadasScreen extends StatelessWidget {
  const HistoricoCaminhadasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = CaminhadaRepository();
    final user = Supabase.instance.client.auth.currentUser!;

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: const Text("Histórico de Caminhadas"),
        backgroundColor: Colors.transparent,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: repo.buscarHistorico(user.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryNeon),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                "Nenhuma caminhada registrada",
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          final caminhadas = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: caminhadas.length,
            itemBuilder: (context, index) {
              final caminhada = caminhadas[index];
              final trajeto =
                  (caminhada['trajeto'] as List<dynamic>?)
                      ?.map((e) => LatLng(e['lat'], e['lng']))
                      .toList() ??
                  [];

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RelatorioCaminhadaScreen(
                        distanciaKm: (caminhada['distancia_km'] as num)
                            .toDouble(),
                        passos: caminhada['passos'] as int,
                        calorias: (caminhada['calorias'] as num).toDouble(),
                        duracaoMinutos: caminhada['duracao_minutos'] as int,
                        trajeto: trajeto,
                        velocidadeMedia: (caminhada['velocidade_media'] as num)
                            .toDouble(),
                      ),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 15),
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: const Color(0xFF111111),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryNeon.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.directions_walk,
                          color: AppTheme.primaryNeon,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              DateFormat(
                                'dd/MM/yyyy – HH:mm',
                              ).format(DateTime.parse(caminhada['created_at'])),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              "${(caminhada['distancia_km'] as num).toDouble().toStringAsFixed(2)} km • ${caminhada['passos']} passos",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              "${(caminhada['calorias'] as num).toDouble().toStringAsFixed(0)} kcal • ${caminhada['duracao_minutos']} min",
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.grey,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
