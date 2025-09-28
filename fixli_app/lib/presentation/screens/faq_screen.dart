// lib/presentation/screens/faq_screen.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

// En enkel datamodell för våra FAQ-items
class FaqItem {
  final String question;
  final String answer;
  const FaqItem({required this.question, required this.answer});
}

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  final List<FaqItem> _faqItems = const [
    FaqItem(
        question: 'Vad är Fixli?',
        answer: 'Fixli är en lokal plattform designad för att förenkla vardagen. Här kan du skapa uppdrag när du behöver hjälp med allt från montering och trädgårdsarbete till tekniksupport, eller själv hitta och utföra uppdrag för andra i ditt närområde.'
    ),
    FaqItem(
        question: 'Hur skapar jag ett uppdrag?',
        answer: 'Gå till Hem-skärmen och tryck på plusknappen (+). Fyll i en tydlig titel, en beskrivning, välj plats via kartan och ange vilken ersättning du erbjuder. Du kan även ladda upp en bild för att göra ditt uppdrag tydligare!'
    ),
    FaqItem(
        question: 'Hur fungerar uppdragsflödet?',
        answer: '1. Skapa ett uppdrag (status "Öppen").\n2. Andra användare anmäler intresse.\n3. Du granskar de sökande och deras betyg, och väljer en "Fixare" (status ändras till "Pågående").\n4. När jobbet är klart markerar du det som "Slutfört".\n5. Både du och Fixaren kan nu betygsätta varandra.'
    ),
    FaqItem(
        question: 'Hur länge är ett uppdrag synligt?',
        answer: 'Ett vanligt uppdrag är synligt i 30 dagar. Utvalda företag, som hanteras av administratörer, är synliga i 365 dagar.'
    ),
    FaqItem(
        question: 'Hur hanterar jag mina uppdrag?',
        answer: 'Gå till "Min profil" i menyn. Under "Mina upplagda uppdrag" kan du se status på dina uppdrag. Svep ett uppdrag åt vänster för att få fram alternativ för att redigera eller radera det.'
    ),
    FaqItem(
        question: 'Ansvar, Skatter och Lagar',
        answer: 'Fixli är en plattform som förmedlar kontakt. Användarna är själva fullt ansvariga för att följa svenska lagar och regler gällande ersättning, skatter (t.ex. RUT/ROT-avdrag) och eventuella anställningsförhållanden. Vi uppmanar alla att agera ansvarsfullt och tar starkt avstånd från all form av svartarbete.'
    ),
  ];

  Future<void> _launchEmailApp(BuildContext context) async {
    const email = 'Fixli-konto@outlook.com';
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=Fråga om Fixli Appen&body=Hej,\n\nJag har en fråga:\n',
    );

    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        throw 'Could not launch $emailUri';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kunde inte öppna e-postappen. Kopiera adressen manuellt: $email'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // 🟢 Ny hjälpfunktion för att öppna webblänkar
  Future<void> _launchUrl(String url, BuildContext context) async {
    final Uri uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $uri';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kunde inte öppna länken.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vanliga frågor & Info'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          ..._faqItems.map((item) {
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: ExpansionTile(
                title: Text(item.question, style: const TextStyle(fontWeight: FontWeight.bold)),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(item.answer, style: const TextStyle(height: 1.5)),
                  ),
                ],
              ),
            );
          }).toList(),

          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 10),
          Center(
            child: TextButton.icon(
              icon: const Icon(Icons.email_outlined),
              label: const Text('Kontakta oss på Fixli-konto@outlook.com'),
              onPressed: () => _launchEmailApp(context),
            ),
          ),

          // 🟢 NY SEKTION MED LÄNKAR
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 16.0, // Mellanrum mellan länkarna
            runSpacing: 8.0,
            children: [
              TextButton(
                onPressed: () => _launchUrl('https://subsequent-light-d64.notion.site/Anv-ndarvillkor-f-r-Fixli-2521962d298780b88bcec47e5d7b35a7', context),
                child: Text('Användarvillkor', style: TextStyle(color: Colors.red.shade700)),
              ),
              TextButton(
                onPressed: () => _launchUrl('https://subsequent-light-d64.notion.site/Integritetspolicy-f-r-Fixli-2521962d298780a18606c78fedbc9d00', context),
                child: Text('Integritetspolicy', style: TextStyle(color: Colors.red.shade700)),
              ),
              TextButton(
                onPressed: () => _launchUrl('https://subsequent-light-d64.notion.site/FAQ-Vanliga-Fr-gor-Svar-f-r-Fixli-2521962d298780e9bfdefe01f72ff224', context),
                child: Text('FAQ', style: TextStyle(color: Colors.red.shade700)),
              ),
            ],
          )
        ],
      ),
    );
  }
}