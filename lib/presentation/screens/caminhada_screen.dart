import 'dart:async';

import 'package:academy007/data/relatorios/relatorio_caminhada_screen.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/caminhada_repository.dart';

class CaminhadaScreen extends StatefulWidget {
  const CaminhadaScreen({super.key});

  @override
  State<CaminhadaScreen> createState() => _CaminhadaScreenState();
}

class _CaminhadaScreenState extends State<CaminhadaScreen> {
  final _repo = CaminhadaRepository();
  final _supabase = Supabase.instance.client;

  // Estado da caminhada
  bool _isWalking = false;
  bool _isLoading = false;
  String _error = '';

  // Dados em tempo real
  int _passos = 0;
  double _distanciaKm = 0.0;
  double _calorias = 0.0;
  int _duracaoSegundos = 0;
  List<LatLng> _trajeto = [];
  double _velocidadeMedia = 0.0;

  // Google Maps
  GoogleMapController? _mapController;
  Set<Polyline> _polylines = {};
  LatLng? _posicaoAtual;

  // Stream de passos
  StreamSubscription<StepCount>? _stepSubscription;
  StreamSubscription<Position>? _positionSubscription;
  DateTime? _startTime;

  // Dados do usuário
  double _pesoAluno = 70.0; // Valor padrão (vamos buscar do perfil)

  @override
  void initState() {
    super.initState();
    _buscarPesoAluno();
  }

  Future<void> _buscarPesoAluno() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final response = await _supabase
        .from('perfis')
        .select('peso_atual')
        .eq('id', user.id)
        .maybeSingle();

    if (response != null && response['peso_atual'] != null) {
      setState(() {
        _pesoAluno = (response['peso_atual'] as num).toDouble();
      });
    }
  }

  @override
  void dispose() {
    _stepSubscription?.cancel();
    _positionSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  // Calcula calorias com base no peso e distância
  double _calcularCalorias() {
    return _pesoAluno * _distanciaKm * 0.75; // Fórmula padrão para caminhada
  }

  // Calcula velocidade média em km/h
  double _calcularVelocidadeMedia() {
    if (_duracaoSegundos == 0 || _distanciaKm == 0) return 0.0;
    final horas = _duracaoSegundos / 3600;
    return _distanciaKm / horas;
  }

  // Inicia a caminhada
  Future<void> _iniciarCaminhada() async {
    // Verifica permissões
    final locationStatus = await Permission.locationWhenInUse.request();
    final activityStatus = await Permission.activityRecognition.request();

    if (locationStatus.isDenied || activityStatus.isDenied) {
      setState(() {
        _error = "Permissão de localização ou atividade negada";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      // Verifica se GPS está ligado
      final isGpsEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isGpsEnabled) {
        setState(() {
          _error = "Ative o GPS para continuar";
          _isLoading = false;
        });
        return;
      }

      // Reseta dados
      _passos = 0;
      _distanciaKm = 0.0;
      _calorias = 0.0;
      _duracaoSegundos = 0;
      _trajeto = [];
      _polylines = {};
      _startTime = DateTime.now();

      // Obtém posição inicial
      final position = await Geolocator.getCurrentPosition();
      _posicaoAtual = LatLng(position.latitude, position.longitude);
      _trajeto.add(_posicaoAtual!);

      // Inicia stream de passos
      _stepSubscription = Pedometer.stepCountStream.listen((event) {
        setState(() {
          _passos = event.steps;
        });
      });

      // Inicia stream de localização
      _positionSubscription =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 5, // Atualiza a cada ~5 metros
            ),
          ).listen((position) {
            final novaPosicao = LatLng(position.latitude, position.longitude);

            // Calcula distância desde a última posição
            if (_posicaoAtual != null) {
              final distancia =
                  Geolocator.distanceBetween(
                    _posicaoAtual!.latitude,
                    _posicaoAtual!.longitude,
                    novaPosicao.latitude,
                    novaPosicao.longitude,
                  ) /
                  1000; // Converte para km

              setState(() {
                _distanciaKm += distancia;
                _calorias = _calcularCalorias();
                _velocidadeMedia = _calcularVelocidadeMedia();
              });
            }

            // Atualiza trajeto e mapa
            setState(() {
              _posicaoAtual = novaPosicao;
              _trajeto.add(novaPosicao);
              _atualizarPolyline();
              _atualizarCamera(novaPosicao);
            });
          });

      // Inicia cronômetro
      Timer.periodic(const Duration(seconds: 1), (timer) {
        if (_isWalking) {
          setState(() {
            _duracaoSegundos++;
            _velocidadeMedia = _calcularVelocidadeMedia();
          });
        } else {
          timer.cancel();
        }
      });

      setState(() {
        _isWalking = true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = "Erro ao iniciar: ${e.toString()}";
        _isLoading = false;
      });
    }
  }

  // Atualiza a polyline no mapa
  void _atualizarPolyline() {
    _polylines = {
      Polyline(
        polylineId: const PolylineId('trajeto'),
        points: _trajeto,
        color: AppTheme.primaryNeon,
        width: 5,
      ),
    };
  }

  // Atualiza a câmera do mapa
  void _atualizarCamera(LatLng posicao) {
    if (_mapController != null) {
      _mapController!.animateCamera(CameraUpdate.newLatLng(posicao));
    }
  }

  // Pausa a caminhada
  void _pausarCaminhada() {
    setState(() {
      _isWalking = false;
    });
    _stepSubscription?.pause();
    _positionSubscription?.pause();
  }

  // Finaliza a caminhada
  Future<void> _finalizarCaminhada() async {
    if (_isWalking) {
      _pausarCaminhada();
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        setState(() {
          _error = "Usuário não autenticado";
          _isLoading = false;
        });
        return;
      }

      // Prepara o trajeto para salvar no banco
      final trajetoJson = _trajeto
          .map((point) => {'lat': point.latitude, 'lng': point.longitude})
          .toList();

      // Salva no banco
      await _repo.salvarCaminhada(
        alunoId: user.id,
        distanciaKm: _distanciaKm,
        passos: _passos,
        calorias: _calorias,
        duracaoMinutos: _duracaoSegundos ~/ 60,
        trajeto: trajetoJson,
        velocidadeMedia: _velocidadeMedia,
      );

      // Navega para o relatório
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => RelatorioCaminhadaScreen(
              distanciaKm: _distanciaKm,
              passos: _passos,
              calorias: _calorias,
              duracaoMinutos: _duracaoSegundos ~/ 60,
              trajeto: _trajeto,
              velocidadeMedia: _velocidadeMedia,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = "Erro ao salvar: ${e.toString()}";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      appBar: AppBar(
        title: const Text("Caminhada"),
        backgroundColor: Colors.transparent,
        actions: [
          if (_isWalking)
            IconButton(
              icon: const Icon(Icons.pause, color: Colors.orange),
              onPressed: _pausarCaminhada,
            ),
        ],
      ),
      body: Stack(
        children: [
          // Mapa
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: LatLng(-23.5505, -46.6333), // São Paulo (default)
              zoom: 15,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            polylines: _polylines,
            onMapCreated: (controller) {
              setState(() {
                _mapController = controller;
              });
            },
          ),

          // Overlay de dados
          Positioned(
            bottom: 100,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.primaryNeon),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatCard(
                        "Passos",
                        "${_passos.toStringAsFixed(0)}",
                        Icons.directions_walk,
                        Colors.blueAccent,
                      ),
                      _buildStatCard(
                        "Distância",
                        "${_distanciaKm.toStringAsFixed(2)} km",
                        Icons.straighten,
                        Colors.greenAccent,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatCard(
                        "Calorias",
                        "${_calorias.toStringAsFixed(0)}",
                        Icons.local_fire_department,
                        Colors.orangeAccent,
                      ),
                      _buildStatCard(
                        "Tempo",
                        "${(_duracaoSegundos ~/ 60).toStringAsFixed(0)}:${(_duracaoSegundos % 60).toString().padLeft(2, '0')} min",
                        Icons.timer,
                        Colors.purpleAccent,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatCard(
                        "Velocidade",
                        "${_velocidadeMedia.toStringAsFixed(1)} km/h",
                        Icons.speed,
                        Colors.redAccent,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Botão principal
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : _isWalking
                  ? _finalizarCaminhada
                  : _iniciarCaminhada,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isWalking
                    ? Colors.redAccent
                    : AppTheme.primaryNeon,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      _isWalking ? "FINALIZAR" : "INICIAR CAMINHADA",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
            ),
          ),

          // Mensagem de erro
          if (_error.isNotEmpty)
            Positioned(
              top: 100,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.white),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _error,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => setState(() => _error = ''),
                    ),
                  ],
                ),
              ),
            ),
        ],
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
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
