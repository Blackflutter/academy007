import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';

class RelatorioCaminhadaScreen extends StatelessWidget {
  final double distanciaKm;
  final int passos;
  final double calorias;
  final int duracaoMinutos;
  final List<LatLng> trajeto;
  final double velocidadeMedia;

  const RelatorioCaminhadaScreen({
    super.key,
    required this.distanciaKm,
    required this.passos,
    required this.calorias,
    required this.duracaoMinutos,
    required this.trajeto,
    required this.velocidadeMedia,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: const Text("Relatório da Caminhada"),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: AppTheme.primaryNeon),
            onPressed: () {
              // TODO: Implementar compartilhamento
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header com data e hora
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF004D40), Color(0xFF00695C)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "RELATÓRIO",
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    DateFormat('dd/MM/yyyy – HH:mm').format(DateTime.now()),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Mapa com trajeto
            const Text(
              "Trajeto Percorrido",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 250,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: trajeto.isNotEmpty
                        ? trajeto.first
                        : const LatLng(-23.5505, -46.6333),
                    zoom: 15,
                  ),
                  polylines: {
                    Polyline(
                      polylineId: const PolylineId('trajeto'),
                      points: trajeto,
                      color: AppTheme.primaryNeon,
                      width: 5,
                    ),
                  },
                  markers: {
                    Marker(
                      markerId: const MarkerId('start'),
                      position: trajeto.isNotEmpty
                          ? trajeto.first
                          : const LatLng(0, 0),
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueGreen,
                      ),
                    ),
                    Marker(
                      markerId: const MarkerId('end'),
                      position: trajeto.isNotEmpty
                          ? trajeto.last
                          : const LatLng(0, 0),
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueRed,
                      ),
                    ),
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Estatísticas
            const Text(
              "Estatísticas",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),

            // Cards de estatísticas
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    "Distância",
                    "${distanciaKm.toStringAsFixed(2)} km",
                    Icons.straighten,
                    Colors.greenAccent,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildStatCard(
                    "Passos",
                    passos.toStringAsFixed(0),
                    Icons.directions_walk,
                    Colors.blueAccent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    "Calorias",
                    calorias.toStringAsFixed(0),
                    Icons.local_fire_department,
                    Colors.orangeAccent,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildStatCard(
                    "Duração",
                    "$duracaoMinutos min",
                    Icons.timer,
                    Colors.purpleAccent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _buildStatCard(
              "Velocidade Média",
              "${velocidadeMedia.toStringAsFixed(1)} km/h",
              Icons.speed,
              Colors.redAccent,
            ),
            const SizedBox(height: 20),

            // Botão para salvar ou voltar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryNeon,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: const Text(
                  "VOLTAR AO DASHBOARD",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
