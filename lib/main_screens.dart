import 'package:academy007/presentation/screens/cadastro_screen.dart';
import 'package:academy007/presentation/screens/dashboard_screen.dart';
import 'package:academy007/presentation/screens/historico_screen.dart';
import 'package:academy007/presentation/screens/perfil_screen.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // Lista das abas do aplicativo
  final List<Widget> _paginas = [
    const DashboardScreen(), // Aba 1: Resumo e Progresso
    const HistoricoScreen(), // Aba 2: Lista de Categorias
    const CadastroScreen(), // Aba 3: Histórico detalhado
    const PerfilScreen(), // Aba 4: Perfil e Configurações
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _paginas),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          labelTextStyle: WidgetStateProperty.all(
            const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) =>
              setState(() => _currentIndex = index),
          backgroundColor: AppTheme.glassColor, // Use o seu esquema de cores
          indicatorColor: AppTheme.primaryNeon,
          surfaceTintColor: Colors.transparent,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard, color: Colors.black),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.food_bank_outlined),
              selectedIcon: Icon(Icons.fitness_center, color: Colors.black),
              label: 'Food',
            ),
            NavigationDestination(
              icon: Icon(Icons.history),
              selectedIcon: Icon(Icons.history, color: Colors.black),
              label: 'Histórico',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person, color: Colors.black),
              label: 'Perfil',
            ),
          ],
        ),
      ),
    );
  }
}
