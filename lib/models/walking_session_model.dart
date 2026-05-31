// data/models/walking_session_model.dart
class WalkingSessionModel {
  final String? id;
  final String alunoId;
  final double distanciaKm;
  final int passos;
  final int calorias;
  final int duracaoSegundos;
  final double velocidadeMediaKmh;
  final List<Map<String, double>> trajeto; // [{lat: x, lng: y}]
  final DateTime? createdAt;

  WalkingSessionModel({
    this.id,
    required this.alunoId,
    required this.distanciaKm,
    required this.passos,
    required this.calorias,
    required this.duracaoSegundos,
    required this.velocidadeMediaKmh,
    required this.trajeto,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'aluno_id': alunoId,
      'distancia_km': distanciaKm,
      'passos': passos,
      'calorias': calorias,
      'duracao_segundos': duracaoSegundos,
      'velocidade_media_kmh': velocidadeMediaKmh,
      'trajeto': trajeto,
    };
  }

  factory WalkingSessionModel.fromMap(Map<String, dynamic> map) {
    return WalkingSessionModel(
      id: map['id'],
      alunoId: map['aluno_id'],
      distanciaKm: (map['distancia_km'] as num).toDouble(),
      passos: map['passos'],
      calorias: map['calorias'],
      duracaoSegundos: map['duracao_segundos'],
      velocidadeMediaKmh: (map['velocidade_media_kmh'] as num).toDouble(),
      trajeto: List<Map<String, double>>.from(
        (map['trajeto'] as List).map(
          (e) => {
            'lat': (e['lat'] as num).toDouble(),
            'lng': (e['lng'] as num).toDouble(),
          },
        ),
      ),
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}
