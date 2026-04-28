import 'package:academy007/data/repositories/categoria_repository.dart';
import 'package:flutter/material.dart';

class CategoriasScreen extends StatelessWidget {
  const CategoriasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Escolha o Grupo Muscular")),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: CategoriaRepository().buscarCategorias(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError ||
              !snapshot.hasData ||
              snapshot.data!.isEmpty) {
            return const Center(
              child: Text("Nenhuma categoria encontrada ou erro de RLS."),
            );
          }

          final categorias = snapshot.data!;

          return ListView.builder(
            itemCount: categorias.length,
            itemBuilder: (context, index) {
              final cat = categorias[index];
              return ListTile(
                title: Text(cat['nome'] ?? 'Sem nome'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  // Aqui você navegará para a tela de exercícios passando o ID
                  Text("Clicou na categoria: ${cat['id']}");
                },
              );
            },
          );
        },
      ),
    );
  }
}
