// lib/presentation/screens/onboarding_screen.dart

import 'package:fixli_app/presentation/providers/onboarding_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:introduction_screen/introduction_screen.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const pageDecoration = PageDecoration(
      titleTextStyle: TextStyle(fontSize: 28.0, fontWeight: FontWeight.w700),
      bodyTextStyle: TextStyle(fontSize: 19.0),
      bodyPadding: EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
      pageColor: Colors.white,
      imagePadding: EdgeInsets.zero,
    );

    return IntroductionScreen(
      pages: [
        PageViewModel(
          title: "Välkommen till Fixli",
          body: "Din nya mötesplats för att hitta och erbjuda hjälp med vardagssysslor i ditt närområde.",
          image: SvgPicture.asset('assets/illustrations/welcome.svg', width: 250.0),
          decoration: pageDecoration,
        ),
        PageViewModel(
          title: "Skapa & Sök Uppdrag",
          body: "Behöver du hjälp med något eller vill erbjuda din hjälp till andra? Skapa ett uppdrag med bild och plats. Letar du efter ett jobb eller en syssla? Sök och filtrera för att hitta uppdrag nära dig.",
          image: SvgPicture.asset('assets/illustrations/Skapesok.svg', width: 250.0),
          decoration: pageDecoration,
        ),
        PageViewModel(
          title: "Trygghet med Betyg",
          body: "Både uppdragsgivare och fixare kan betygsätta varandra efter ett slutfört jobb. Bygg ditt rykte och välj hjälp med förtroende.",
          image: SvgPicture.asset('assets/illustrations/rating.svg', width: 250.0),
          decoration: pageDecoration,
        ),
      ],
      onDone: () {
        // När användaren klickar på "Klar", markera onboarding som visad
        ref.read(onboardingNotifierProvider.notifier).setOnboardingComplete();
      },
      showSkipButton: true,
      skip: const Text('Hoppa över', style: TextStyle(fontWeight: FontWeight.w600)),
      next: const Icon(Icons.arrow_forward),
      done: const Text('Kom igång', style: TextStyle(fontWeight: FontWeight.w600)),
      curve: Curves.fastLinearToSlowEaseIn,
      dotsDecorator: const DotsDecorator(
        size: Size(10.0, 10.0),
        color: Color(0xFFBDBDBD),
        activeSize: Size(22.0, 10.0),
        activeShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(25.0)),
        ),
      ),
    );
  }
}