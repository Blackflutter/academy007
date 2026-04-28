import 'package:academy007/presentation/screens/treino_screen.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/repositories/treino_repository.dart';

class GruposScreen extends StatefulWidget {
  const GruposScreen({super.key});

  @override
  State<GruposScreen> createState() => _GruposScreenState();
}

class _GruposScreenState extends State<GruposScreen> {
  final TreinoRepository _repository = TreinoRepository();
  late Future<List<Map<String, dynamic>>> _futureCategorias;

  @override
  void initState() {
    super.initState();
    // Busca as categorias cadastradas no banco de dados
    _futureCategorias = _repository.buscarCategorias();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Categorias de Treino"),
        centerTitle: true,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _futureCategorias,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryNeon),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text("Erro ao carregar categorias: ${snapshot.error}"),
            );
          }

          final categorias = snapshot.data ?? [];

          if (categorias.isEmpty) {
            return const Center(child: Text("Nenhuma categoria encontrada."));
          }

          return GridView.builder(
            padding: const EdgeInsets.all(20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // 2 itens por linha
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              childAspectRatio: 1.1, // Ajuste de proporção do card
            ),
            itemCount: categorias.length,
            itemBuilder: (context, index) {
              final cat = categorias[index];

              return InkWell(
                onTap: () {
                  // NAVEGAÇÃO ENVIANDO O ID DA CATEGORIA
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          TreinoScreen(categoriaId: cat['id']),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.glassColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _getIconForCategoria(cat['nome']),
                        color: AppTheme.primaryNeon,
                        size: 40,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        cat['nome'].toString().toUpperCase(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
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

  // Função simples para retornar um ícone baseado no nome da categoria
  IconData _getIconForCategoria(String nome) {
    nome = nome.toLowerCase();
    if (nome.contains('futebol')) return Icons.sports_soccer;
    if (nome.contains('academia')) return Icons.fitness_center;
    if (nome.contains('basquete')) return Icons.sports_basketball;
    if (nome.contains('natação')) return Icons.pool;
    if (nome.contains('corrida')) return Icons.directions_run;
    if (nome.contains('voley')) return Icons.sports_volleyball;
    if (nome.contains('ciclismo')) return Icons.directions_bike;
    return Icons.bolt; // Ícone padrão
  }
}
