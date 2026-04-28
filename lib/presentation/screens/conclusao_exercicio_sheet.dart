import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class ConclusaoExercicioSheet extends StatelessWidget {
  final String nomeExercicio;

  const ConclusaoExercicioSheet({super.key, required this.nomeExercicio});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A), // Um tom escuro para combinar com o Neon
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 20),
          const Icon(
            Icons.check_circle_outline,
            color: AppTheme.primaryNeon,
            size: 80,
          ),
          const SizedBox(height: 15),
          Text(
            "EXERCÍCIO CONCLUÍDO!",
            style: TextStyle(
              color: AppTheme.primaryNeon,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Você finalizou: $nomeExercicio",
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryNeon,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "CONTINUAR TREINO",
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
