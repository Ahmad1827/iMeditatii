import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_colors.dart';
import 'retro_widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _completed = 0;
  bool _loading = true;

  // (exerciții necesare, nume rang)
  static const _ranks = [(0, 'Începător'), (4, 'Argint'), (11, 'Aur')];

  (int, String) get _currentRank => _ranks.lastWhere((r) => _completed >= r.$1);

  (int, String)? get _nextRank {
    for (final r in _ranks) {
      if (_completed < r.$1) return r;
    }
    return null;
  }

  double get _progress {
    final next = _nextRank;
    if (next == null) return 1;
    final cur = _currentRank.$1;
    return (_completed - cur) / (next.$1 - cur);
  }

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final done = prefs.getKeys().where((k) => prefs.get(k) == true).length;
      if (!mounted) return;
      setState(() {
        _completed = done;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Error loading stats: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  void _startDailyQuest() {
    final materie = Uri.encodeComponent('Informatică');
    final clasa = Uri.encodeComponent('9');
    context.go('/exercitiu/1?materie=$materie&clasa=$clasa');
  }

  @override
  Widget build(BuildContext context) {
    return RetroPage(
      footerSubtitle: 'Învață în ritmul tău. Crește în nivel în fiecare zi.',
      builder: (context, m) => [_hero(m), _paths(m), _masters(m)],
    );
  }

  // ---------------- HERO ----------------

  Widget _hero(bool m) {
    final left = RetroBlock(
      bgColor: AppColors.mustard,
      padding: m ? 20 : 36,
      shadowOffset: Retro.shadow(m),
      child: Column(
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
                  RetroTag('Online', color: AppColors.cardBg, dot: Colors.green),
                  RetroTag('Sezonul 1', color: AppColors.sunset),
                ],
              ),
              SizedBox(height: m ? 18 : 26),
              Text('CREȘTE-ȚI\nNIVELUL.', style: Retro.display(m ? 34 : 56, color: Retro.darkInk)),
              SizedBox(height: m ? 12 : 16),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Text(
                  'Alege o materie, găsește un mentor verificat și rezolvă exerciții interactive ca să avansezi.',
                  style: Retro.body(m ? 15 : 17, color: Retro.darkInk).copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          SizedBox(height: m ? 22 : 32),
          _heroActions(m),
        ],
      ),
    );

    final right = RetroBlock(
      bgColor: AppColors.cardBg,
      padding: m ? 20 : 28,
      shadowOffset: Retro.shadow(m),
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
                  Text('Progresul tău', style: Retro.title(16)),
                  if (!_loading) RetroTag(_currentRank.$2, color: AppColors.sky),
                ],
              ),
              const SizedBox(height: 14),
              _progressBlock(m),
              const SizedBox(height: 20),
              Container(height: 2, color: AppColors.cloud),
              const SizedBox(height: 18),
              Row(
                children: [
                  Icon(Icons.star, color: AppColors.mustard, size: 18),
                  const SizedBox(width: 6),
                  Text('Provocarea zilei',
                      style: TextStyle(color: AppColors.sunset, fontWeight: FontWeight.w800, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 6),
              Text('Informatică, clasa a 9-a', style: Retro.title(m ? 18 : 20)),
              const SizedBox(height: 2),
              Text('+50 XP, verificare automată', style: Retro.body(13, color: AppColors.forest)),
            ],
          ),
          SizedBox(height: m ? 18 : 24),
          RetroButton(
            text: 'Începe provocarea',
            icon: Icons.play_arrow,
            bgColor: AppColors.sunset,
            isFullWidth: true,
            onPressed: _startDailyQuest,
          ),
        ],
      ),
    );

    return RetroSection(
      padding: EdgeInsets.fromLTRB(Retro.gutter(m), m ? 20 : 40, Retro.gutter(m), m ? 12 : 24),
      child: m
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [left, const SizedBox(height: 16), right],
            )
          : IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(flex: 3, child: left),
                  const SizedBox(width: 24),
                  Expanded(flex: 2, child: right),
                ],
              ),
            ),
    );
  }

  Widget _heroActions(bool m) {
    final find = RetroButton(
      text: 'Găsește un mentor',
      icon: Icons.search,
      bgColor: AppColors.forest,
      isFullWidth: m,
      onPressed: () => context.go('/materii'),
    );
    final practice = RetroButton(
      text: 'Exersează',
      icon: Icons.track_changes,
      bgColor: AppColors.cardBg,
      isFullWidth: m,
      onPressed: () => context.go('/exercitii'),
    );
    return m
        ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [find, const SizedBox(height: 12), practice])
        : Wrap(spacing: 14, runSpacing: 14, children: [find, practice]);
  }

  Widget _progressBlock(bool m) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 18),
        child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
      );
    }
    final next = _nextRank;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text('$_completed', style: Retro.display(m ? 38 : 46)),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(_completed == 1 ? 'exercițiu rezolvat' : 'exerciții rezolvate', style: Retro.body(14)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          height: 14,
          decoration: BoxDecoration(color: AppColors.cloud, border: Border.all(color: AppColors.border, width: 2)),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: _progress.clamp(0.0, 1.0),
            child: ColoredBox(color: AppColors.forest),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          next == null ? 'Ai atins rangul maxim.' : 'Încă ${next.$1 - _completed} până la rangul ${next.$2}.',
          style: Retro.body(12.5),
        ),
      ],
    );
  }

  // ---------------- PATHS ----------------

  Widget _paths(bool m) {
    final paths = [
      (Icons.functions, 'Matematică', 'Algebră și geometrie', AppColors.sunset, 'Matematică'),
      (Icons.data_object, 'Informatică', 'Algoritmi și C++', AppColors.forest, 'Informatică'),
      (Icons.language, 'Limbi străine', 'Engleză și română', AppColors.sky, 'Engleză'),
    ];

    final cards = paths.map((p) {
      return RetroPressable(
        onTap: () => context.go('/lista-exercitii?materie=${Uri.encodeComponent(p.$5)}'),
        shadow: m ? 4 : 5,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: p.$4, border: Border.all(color: AppColors.border, width: 2)),
              child: Icon(p.$1, size: 26, color: Retro.onAccent(p.$4)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.$2.toUpperCase(), style: Retro.display(18)),
                  const SizedBox(height: 2),
                  Text(p.$3, style: Retro.body(13.5)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward, color: AppColors.ink, size: 20),
          ],
        ),
      );
    }).toList();

    return RetroSection(
      padding: EdgeInsets.symmetric(horizontal: Retro.gutter(m), vertical: m ? 24 : 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RetroSectionHeader(
            title: 'Alege-ți drumul',
            subtitle: 'Selectează o materie și începe antrenamentul.',
            isMobile: m,
          ),
          SizedBox(height: m ? 20 : 28),
          RetroGrid(minItemWidth: 280, spacing: m ? 12 : 20, children: cards),
        ],
      ),
    );
  }

  // ---------------- MASTERS ----------------

  Widget _masters(bool m) {
    final left = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(m ? 'CUNOAȘTE MENTORII.' : 'CUNOAȘTE\nMENTORII.', style: Retro.display(m ? 26 : 40)),
        const SizedBox(height: 10),
        Text(
          'Mentori verificați, gata să lucreze cu tine 1-la-1 pe o tablă interactivă live.',
          style: Retro.body(m ? 14 : 16, color: AppColors.ink),
        ),
        SizedBox(height: m ? 18 : 24),
        RetroButton(
          text: 'Explorează profesorii',
          icon: Icons.groups,
          bgColor: AppColors.sunset,
          isFullWidth: m,
          onPressed: () => context.go('/materii'),
        ),
      ],
    );

    final right = GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: m ? 1.3 : 1.15,
      children: [
        _avatar(Icons.calculate, 'Matematică', AppColors.sky),
        _avatar(Icons.terminal, 'Informatică', AppColors.mustard),
        _avatar(Icons.bolt, 'Fizică', AppColors.forest),
        _avatar(Icons.science, 'Chimie', AppColors.sunset),
      ],
    );

    return RetroSection(
      padding: EdgeInsets.symmetric(horizontal: Retro.gutter(m), vertical: m ? 16 : 32),
      child: RetroBlock(
        bgColor: AppColors.cloud,
        padding: m ? 18 : 36,
        shadowOffset: Retro.shadow(m),
        child: m
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [left, const SizedBox(height: 22), right],
              )
            : Row(
                children: [
                  Expanded(child: left),
                  const SizedBox(width: 40),
                  Expanded(child: right),
                ],
              ),
      ),
    );
  }

  Widget _avatar(IconData icon, String label, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: AppColors.border, width: Retro.borderWidth),
        boxShadow: [BoxShadow(color: AppColors.shadow, offset: const Offset(3, 3))],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 32, color: Retro.onAccent(color)),
          const SizedBox(height: 8),
          RetroTag(label),
        ],
      ),
    );
  }
}