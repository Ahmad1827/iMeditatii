import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app_colors.dart';
import 'retro_widgets.dart';

class ExercisesScreen extends StatelessWidget {
  const ExercisesScreen({super.key});

  void _open(BuildContext context, String materie) {
    context.go('/lista-exercitii?materie=${Uri.encodeComponent(materie)}');
  }

  @override
  Widget build(BuildContext context) {
    return RetroPage(
      footerSubtitle: 'Exersează zilnic. Stăpânește programa.',
      builder: (context, m) => [_hero(context, m), _subjects(context, m)],
    );
  }

  Widget _hero(BuildContext context, bool m) {
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                RetroTag('Arena de antrenament', color: AppColors.cardBg, dot: Colors.green),
                RetroTag('+50 XP bonus', color: AppColors.sunset),
              ],
            ),
            SizedBox(height: m ? 18 : 24),
            Text('EXERSEAZĂ.\nAVANSEAZĂ ZILNIC.', style: Retro.display(m ? 30 : 48, color: Retro.darkInk)),
            SizedBox(height: m ? 12 : 16),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Text(
                'Alege o disciplină. Testele automate îți verifică codul C++ și răspunsurile pe loc.',
                style: Retro.body(m ? 15 : 17, color: Retro.darkInk).copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        SizedBox(height: m ? 20 : 30),
        RetroButton(
          text: 'Începe cu Informatică',
          icon: Icons.code,
          isFullWidth: m,
          bgColor: AppColors.forest,
          onPressed: () => _open(context, 'Informatică'),
        ),
      ],
    );

    return RetroSection(
      padding: EdgeInsets.fromLTRB(Retro.gutter(m), m ? 20 : 40, Retro.gutter(m), 0),
      child: RetroBlock(
        bgColor: AppColors.mustard,
        padding: m ? 20 : 36,
        shadowOffset: Retro.shadow(m),
        child: m
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [text, const SizedBox(height: 20), _registry(m)],
              )
            : IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(flex: 3, child: text),
                    const SizedBox(width: 32),
                    Expanded(flex: 2, child: _registry(m)),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _registry(bool m) {
    return RetroBlock(
      bgColor: AppColors.cardBg,
      padding: m ? 16 : 22,
      shadowOffset: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Cum funcționează', style: Retro.title(16)),
                  Icon(Icons.shield, color: AppColors.forest, size: 20),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.cloud, border: Border.all(color: AppColors.border, width: 2)),
                child: Column(
                  children: [
                    _row('Exerciții', '50+'),
                    const SizedBox(height: 8),
                    _row('Evaluare', 'Judge0, C++20'),
                    const SizedBox(height: 8),
                    _row('Feedback', 'Instant'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, color: AppColors.forest, size: 16),
              const SizedBox(width: 6),
              Text('Gata de evaluare', style: Retro.title(13)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Retro.body(13)),
        Text(value, style: Retro.title(13)),
      ],
    );
  }

  Widget _subjects(BuildContext context, bool m) {
    final materii = [
      (Icons.functions, 'Matematică', 'Algebră și geometrie', AppColors.sunset),
      (Icons.menu_book, 'Limba Română', 'Gramatică și literatură', AppColors.sky),
      (Icons.language, 'Engleză', 'Gramatică și vocabular', AppColors.mustard),
      (Icons.data_object, 'Informatică', 'Algoritmi și C++', AppColors.forest),
      (Icons.bolt, 'Fizică', 'Mecanică și optică', AppColors.sunset),
      (Icons.science, 'Chimie', 'Anorganică și organică', AppColors.sky),
    ];

    return RetroSection(
      padding: EdgeInsets.fromLTRB(Retro.gutter(m), m ? 32 : 56, Retro.gutter(m), 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RetroSectionHeader(
            title: 'Alege disciplina',
            subtitle: 'Fiecare set are teste automate, deci știi imediat dacă ai rezolvat corect.',
            isMobile: m,
          ),
          SizedBox(height: m ? 20 : 32),
          RetroGrid(
            minItemWidth: 300,
            spacing: m ? 16 : 24,
            children: materii
                .map((x) => RetroSubjectCard(
                      icon: x.$1,
                      title: x.$2,
                      tag: x.$3,
                      color: x.$4,
                      cta: 'Intră în arenă',
                      isMobile: m,
                      onTap: () => _open(context, x.$2),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}