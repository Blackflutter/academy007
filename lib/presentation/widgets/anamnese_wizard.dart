import 'package:flutter/material.dart';

class AnamneseWizard extends StatefulWidget {
  const AnamneseWizard({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _AnamneseWizardState createState() => _AnamneseWizardState();
}

class _AnamneseWizardState extends State<AnamneseWizard> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  // Respostas que serão enviadas de volta
  Map<String, dynamic> respostas = {};

  // Exemplo de perguntas (você pode completar as 10)
  final List<Map<String, dynamic>> perguntas = [
    {
      "id": "objetivo",
      "p": "Qual seu objetivo principal?",
      "opcoes": ["Emagrecer", "Ganhar Massa", "Saúde"],
    },
    {
      "id": "lesao",
      "p": "Possui alguma lesão?",
      "opcoes": ["Não", "Sim, Joelho", "Sim, Coluna", "Outros"],
    },
    {
      "id": "experiencia",
      "p": "Nível de experiência:",
      "opcoes": ["Iniciante", "Intermediário", "Avançado"],
    },
    // ... adicione as outras 7 aqui
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        controller: _pageController,
        physics:
            NeverScrollableScrollPhysics(), // Obriga a responder para avançar
        itemCount: perguntas.length,
        itemBuilder: (context, index) {
          var item = perguntas[index];
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Pergunta ${index + 1}/10",
                style: TextStyle(color: Colors.grey),
              ),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  item['p'],
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              ...List.generate(item['opcoes'].length, (i) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 8,
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 50),
                    ),
                    onPressed: () {
                      respostas[item['id']] = item['opcoes'][i];
                      if (index < perguntas.length - 1) {
                        _pageController.nextPage(
                          duration: Duration(milliseconds: 300),
                          curve: Curves.ease,
                        );
                      } else {
                        Navigator.pop(
                          context,
                          respostas,
                        ); // Retorna as respostas
                      }
                    },
                    child: Text(item['opcoes'][i]),
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }
}
