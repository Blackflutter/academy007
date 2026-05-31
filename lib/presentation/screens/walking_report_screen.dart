// presentation/screens/walking_report_screen.dart
import 'package:academy007/models/walking_session_model.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/theme/app_theme.dart';

class WalkingReportScreen extends StatelessWidget {
  final WalkingSessionModel session;

  const WalkingReportScreen({super.key, required this.session});

  @override
  Widget build(BuildContext context) {
    final points = session.trajeto
        .map((e) => LatLng(e['lat']!, e['lng']!))
        .toList();

    final duration = Duration(seconds: session.duracaoSegundos);
    final pace = session.distanciaKm > 0
        ? duration.inMinutes / session.distanciaKm
        : 0;

    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      "Caminhada Concluída! 🎉",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Mapa da rota
              Container(
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white10),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: points.isNotEmpty
                          ? points.first
                          : const LatLng(0, 0),
                      zoom: 15,
                    ),
                    polylines: {
                      Polyline(
                        polylineId: const PolylineId('route'),
                        points: points,
                        color: AppTheme.primaryNeon,
                        width: 5,
                      ),
                    },
                    markers: points.isNotEmpty
                        ? {
                            Marker(
                              markerId: const MarkerId('start'),
                              position: points.first,
                              icon: BitmapDescriptor.defaultMarkerWithHue(
                                BitmapDescriptor.hueGreen,
                              ),
                            ),
                            Marker(
                              markerId: const MarkerId('end'),
                              position: points.last,
                              icon: BitmapDescriptor.defaultMarkerWithHue(
                                BitmapDescriptor.hueRed,
                              ),
                            ),
                          }
                        : {},
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Cards de resultado
              _resultCard(
                "Distância",
                "${session.distanciaKm.toStringAsFixed(2)} km",
                Icons.location_on,
                Colors.blue,
              ),

              _resultCard(
                "Duração",
                "${duration.inMinutes}m ${duration.inSeconds % 60}s",
                Icons.timer,
                Colors.orange,
              ),

              _resultCard(
                "Calorias",
                "${session.calorias} kcal",
                Icons.local_fire_department,
                Colors.red,
              ),

              _resultCard(
                "Passos",
                "${session.passos}",
                Icons.directions_walk,
                Colors.green,
              ),

              _resultCard(
                "Ritmo Médio",
                "${pace.toStringAsFixed(1)} min/km",
                Icons.speed,
                Colors.purple,
              ),

              const SizedBox(height: 30),

              // Botão compartilhar
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Implementar share depois
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Relatório salvo no histórico!"),
                      ),
                    );
                  },
                  icon: const Icon(Icons.share),
                  label: const Text("COMPARTILHAR RESULTADO"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryNeon,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _resultCard(String title, String value, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
