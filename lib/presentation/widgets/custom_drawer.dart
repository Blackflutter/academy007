import 'package:academy007/data/repositories/grupo_repository.dart';
import 'package:academy007/presentation/screens/criar_grupo_screen.dart';
import 'package:academy007/presentation/screens/login_screen.dart';
import 'package:academy007/presentation/screens/meus_grupos_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';

class CustomDrawer extends StatelessWidget {
  const CustomDrawer({super.key});

  // Função para mostrar o campo de digitação do código
  void _mostrarDialogVincular(BuildContext context) {
    final TextEditingController codigoController = TextEditingController();
    final repo = GrupoRepository();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          "Vincular Professor",
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: codigoController,
          style: const TextStyle(color: AppTheme.primaryNeon),
          decoration: const InputDecoration(
            hintText: "Digite o código (ex: 3b957a3)",
            hintStyle: TextStyle(color: Colors.white24),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppTheme.primaryNeon),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCELAR", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryNeon,
            ),
            onPressed: () async {
              try {
                await repo.vincularAlunoAoGrupo(codigoController.text.trim());
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Sucesso! Grupo vinculado.")),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text("Erro: $e")));
                }
              }
            },
            child: const Text(
              "VINCULAR",
              style: TextStyle(color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final bool isProfessor = true; // Mantido conforme seu código

    return Drawer(
      backgroundColor: const Color(0xFF121212),
      child: Column(
        children: [
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

          _drawerItem(
            icon: Icons.dashboard_customize,
            label: "Dashboard Principal",
            onTap: () => Navigator.pop(context),
          ),

          // NOVO ITEM: Vincular Professor (Disponível para todos)
          _drawerItem(
            icon: Icons.vpn_key,
            label: "Vincular ao Professor",
            color: AppTheme.primaryNeon,
            onTap: () {
              Navigator.pop(context);
              _mostrarDialogVincular(context);
            },
          ),

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
              onTap: () => Navigator.pop(context),
            ),
          ],

          const Divider(color: Colors.white10),

          _drawerItem(
            icon: Icons.settings,
            label: "Configurações",
            onTap: () => Navigator.pop(context),
          ),

          const Spacer(),

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
