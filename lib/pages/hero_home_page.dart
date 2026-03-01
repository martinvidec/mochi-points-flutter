import 'package:flutter/material.dart';
import 'child/hero_home_page.dart';

/// Wrapper that redirects to the full ChildHeroHomePage implementation
class HeroHomePage extends StatelessWidget {
  const HeroHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ChildHeroHomePage();
  }
}
