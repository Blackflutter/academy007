import 'package:academy007/data/repositories/grupo_repository.dart';
import 'package:academy007/presentation/screens/criar_grupo_screen.dart';
import 'package:academy007/presentation/screens/login_screen.dart';
import 'package:academy007/presentation/screens/meus_grupos_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    // Lógica de acesso restrito definida por você
    // E-mail: admin@academy007.com | Senha: (validada no login)

    // No build do CustomDrawer, mude temporariamente para:
    final bool isProfessor = true; // Força a aparecer para qualquer um

    return Drawer(
      backgroundColor: const Color(0xFF121212), // Fundo Dark Academy007
      child: Column(
        children: [
          // Cabeçalho dinâmico: Muda conforme o tipo de usuário
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              color: isProfessor ? AppTheme.primaryNeon : Colors.blueGrey,
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.black,
              child: Icon(
                isProfessor ? Icons.admin_panel_settings : Icons.person,
                color: Colors.white,
                size: 40,
              ),
            ),
            accountName: Text(
              isProfessor ? "Painel do Professor" : "Perfil do Aluno",
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            accountEmail: Text(
              user?.email ?? "",
              style: const TextStyle(color: Colors.black87),
            ),
          ),

          // OPÇÕES PÚBLICAS (Todos vêem)
          _drawerItem(
            icon: Icons.dashboard_customize,
            label: "Dashboard Principal",
            onTap: () => Navigator.pop(context),
          ),

          // OPÇÕES EXCLUSIVAS DO PROFESSOR (Bloqueado para alunos)
          if (isProfessor) ...[
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Text(
                "GESTÃO ACADEMY007",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _drawerItem(
              icon: Icons.group,
              label: "Meus Grupos",
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        MeusGruposScreen(grupoId: '', nomeGrupo: ''),
                  ),
                );
              },
            ),
            _drawerItem(
              icon: Icons.group_add,
              label: "Criar Novo Grupo",
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CriarGrupoScreen()),
                );
              },
            ),
            _drawerItem(
              icon: Icons.analytics,
              label: "Avaliações Diárias",
              onTap: () {
                // Futura implementação das avaliações
                Navigator.pop(context);
              },
            ),
          ],

          const Divider(color: Colors.white10),

          // OPÇÕES DE CONFIGURAÇÃO
          _drawerItem(
            icon: Icons.settings,
            label: "Configurações",
            onTap: () => Navigator.pop(context),
          ),

          const Spacer(), // Empurra o Sair para o rodapé

          _drawerItem(
            icon: Icons.logout,
            label: "Sair do Sistema",
            color: Colors.redAccent,
            onTap: () async {
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // Widget auxiliar para manter o padrão visual dos itens
  Widget _drawerItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = Colors.white,
  }) {
    return ListTile(
      leading: Icon(icon, color: color, size: 26),
      title: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      dense: true,
    );
  }
}
