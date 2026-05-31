// presentation/screens/walking_active_screen.dart
import 'dart:async';
import 'dart:math' show sqrt, pow, sin, cos, atan2, pi;
import 'package:academy007/models/walking_session_model.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/walking_repository.dart';
import 'walking_report_screen.dart';

class WalkingActiveScreen extends StatefulWidget {
  const WalkingActiveScreen({super.key});

  @override
  State<WalkingActiveScreen> createState() => _WalkingActiveScreenState();
}

class _WalkingActiveScreenState extends State<WalkingActiveScreen> {
  // Serviços
  final WalkingRepository _repository = WalkingRepository();
  StreamSubscription<Position>? _gpsSubscription;
  StreamSubscription<StepCount>? _stepSubscription;

  // Estados
  bool _isActive = false;
  bool _isPaused = false;
  DateTime? _startTime;
  DateTime? _pauseTime;
  int _totalPausedSeconds = 0;

  // Dados
  List<LatLng> _routePoints = [];
  int _steps = 0;
  int _initialSteps = 0;
  double _distanceKm = 0.0;
  double _pesoUsuario = 70.0;

  // Mapa
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _checkPermissions();
    _pesoUsuario = await _repository.buscarPesoUsuario();
    _startTracking();
  }

  Future<void> _checkPermissions() async {
    await Permission.location.request();
    await Permission.activityRecognition.request();
  }

  void _startTracking() {
    // Inicia GPS
    _gpsSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // Atualiza a cada 5 metros
      ),
    ).listen(_onPositionUpdate);

    // Inicia Pedômetro
    _stepSubscription = Pedometer.stepCountStream.listen(_onStepUpdate);

    setState(() {
      _isActive = true;
      _startTime = DateTime.now();
    });
  }

  void _onPositionUpdate(Position position) {
    if (_isPaused || !_isActive) return;

    final newPoint = LatLng(position.latitude, position.longitude);

    setState(() {
      if (_routePoints.isNotEmpty) {
        _distanceKm += _calculateDistance(
          _routePoints.last.latitude,
          _routePoints.last.longitude,
          newPoint.latitude,
          newPoint.longitude,
        );
      }
      _routePoints.add(newPoint);
    });

    // Move câmera
    _mapController?.animateCamera(CameraUpdate.newLatLng(newPoint));
  }

  void _onStepUpdate(StepCount event) {
    if (_isPaused || !_isActive) return;

    if (_initialSteps == 0) {
      _initialSteps = event.steps;
    }

    setState(() {
      _steps = event.steps - _initialSteps;
    });
  }

  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const R = 6371; // Raio da Terra em km
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a =
        pow(sin(dLat / 2), 2) +
        cos(_deg2rad(lat1)) * cos(_deg2rad(lat2)) * pow(sin(dLon / 2), 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _deg2rad(double deg) => deg * (pi / 180);

  int _calculateCalories() {
    // Fórmula: MET(3.5) * peso * tempo(horas) + fator distância
    final duracaoHoras = _currentDuration.inSeconds / 3600;
    final calorias = 3.5 * _pesoUsuario * duracaoHoras;
    return calorias.round();
  }

  Duration get _currentDuration {
    if (_startTime == null) return Duration.zero;
    final now = DateTime.now();
    final paused = _isPaused && _pauseTime != null
        ? now.difference(_pauseTime!).inSeconds
        : 0;
    return now.difference(_startTime!) -
        Duration(seconds: _totalPausedSeconds + paused);
  }

  void _togglePause() {
    setState(() {
      if (_isPaused) {
        // Resume
        _totalPausedSeconds += DateTime.now().difference(_pauseTime!).inSeconds;
        _isPaused = false;
        _pauseTime = null;
      } else {
        // Pause
        _isPaused = true;
        _pauseTime = DateTime.now();
      }
    });
  }

  Future<void> _finishWalk() async {
    _gpsSubscription?.cancel();
    _stepSubscription?.cancel();

    final duration = _currentDuration;
    final velocidadeMedia = duration.inSeconds > 0
        ? (_distanceKm / (duration.inSeconds / 3600))
        : 0.0;

    final session = WalkingSessionModel(
      alunoId: Supabase.instance.client.auth.currentUser!.id,
      distanciaKm: double.parse(_distanceKm.toStringAsFixed(2)),
      passos: _steps,
      calorias: _calculateCalories(),
      duracaoSegundos: duration.inSeconds,
      velocidadeMediaKmh: double.parse(velocidadeMedia.toStringAsFixed(2)),
      trajeto: _routePoints
          .map((e) => {'lat': e.latitude, 'lng': e.longitude})
          .toList(),
    );

    await _repository.salvarCaminhada(session);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => WalkingReportScreen(session: session),
        ),
      );
    }
  }

  @override
  void dispose() {
    _gpsSubscription?.cancel();
    _stepSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => _showExitDialog(),
                  ),
                  Text(
                    _isPaused ? "PAUSADO" : "EM ANDAMENTO",
                    style: TextStyle(
                      color: _isPaused ? Colors.orange : AppTheme.primaryNeon,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // Mapa
            Expanded(
              flex: 2,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: GoogleMap(
                  initialCameraPosition: const CameraPosition(
                    target: LatLng(
                      -23.550520,
                      -46.633308,
                    ), // São Paulo (default)
                    zoom: 16,
                  ),
                  onMapCreated: (controller) => _mapController = controller,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  polylines: {
                    Polyline(
                      polylineId: const PolylineId('route'),
                      points: _routePoints,
                      color: AppTheme.primaryNeon,
                      width: 5,
                    ),
                  },
                ),
              ),
            ),

            // Stats
            Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF111111),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _statColumn(
                    Icons.timer,
                    "${_currentDuration.inMinutes}:${(_currentDuration.inSeconds % 60).toString().padLeft(2, '0')}",
                    "Tempo",
                  ),
                  _statColumn(
                    Icons.location_on,
                    "${_distanceKm.toStringAsFixed(2)} km",
                    "Distância",
                  ),
                  _statColumn(
                    Icons.local_fire_department,
                    "${_calculateCalories()}",
                    "Kcal",
                  ),
                  _statColumn(Icons.directions_walk, "$_steps", "Passos"),
                ],
              ),
            ),

            // Controles
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _togglePause,
                      icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause),
                      label: Text(_isPaused ? "RETOMAR" : "PAUSAR"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isPaused
                            ? Colors.green
                            : Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _finishWalk,
                      icon: const Icon(Icons.stop),
                      label: const Text("FINALIZAR"),
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
          ],
        ),
      ),
    );
  }

  Widget _statColumn(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryNeon, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          "Cancelar Caminhada?",
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          "Você perderá o progresso atual.",
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Continuar",
              style: TextStyle(color: Colors.green),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text("Descartar", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
