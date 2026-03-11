import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:web_smooth_scroll/web_smooth_scroll.dart';
import 'custom_navbar.dart';

// ==========================================
// WIDGET PENTRU EFECT DE HOVER RAFINAT
// ==========================================
class HoverCard extends StatefulWidget {
  final Widget child;
  final double scale;
  const HoverCard({super.key, required this.child, this.scale = 1.02});

  @override
  State<HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<HoverCard> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250), // Animație mai fină
        curve: Curves.easeOutCubic,
        transform: isHovered ? (Matrix4.identity()..translate(0.0, -8.0)) : Matrix4.identity(), // Se ridică în loc să se mărească brusc
        child: widget.child,
      ),
    );
  }
}
// ==========================================

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey _howItWorksKey = GlobalKey();
  final GlobalKey _profesoriKey = GlobalKey();
  final GlobalKey _preturiKey = GlobalKey();
  final GlobalKey _faqKey = GlobalKey();

  // 🚀 Acestea două lipseau:
  final GlobalKey _testimonialsKey = GlobalKey();
  final GlobalKey _footerKey = GlobalKey();

  final ScrollController _pageScrollController = ScrollController();

  @override
  void dispose() {
    _pageScrollController.dispose();
    super.dispose();
  }

  void _scrollToSection(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeOutQuint,
      );
    }
  }

  // 🚀 NOU: Container centralizat pentru a opri lățimea să o ia razna pe PC (Fix ca la MyTutor)
  Widget _buildConstrainedSection(Widget child, {Color? bgColor, EdgeInsetsGeometry? padding}) {
    return Container(
      width: double.infinity,
      color: bgColor ?? Colors.transparent,
      padding: padding ?? const EdgeInsets.symmetric(vertical: 80, horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1150), // Lățimea perfectă pentru Web
          child: child,
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // HERO SECTION
  // --------------------------------------------------------------------------
  Widget _heroSection(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;
    const String backgroundImageUrl = "https://i.imgur.com/Wvoh2pk.png";

    Widget visualCard = Container(
      width: isWide ? 450 : double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 40, offset: const Offset(0, 20))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 250,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              image: const DecorationImage(image: NetworkImage(backgroundImageUrl), fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Învață Interactiv', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: Color(0xFF0F172A), letterSpacing: -0.5)),
          const SizedBox(height: 8),
          Text('Platformă cu apel video integrat, tablă virtuală și exerciții inteligente.', style: TextStyle(color: Colors.grey.shade600, fontSize: 16, height: 1.5)),
        ],
      ),
    );

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        image: DecorationImage(image: NetworkImage(backgroundImageUrl), fit: BoxFit.cover, opacity: 0.03),
      ),
      child: _buildConstrainedSection(
        padding: const EdgeInsets.symmetric(vertical: 100, horizontal: 24),
        isWide
            ? Row(
          children: [
            Expanded(flex: 11, child: _heroTextContent(isWide)),
            const SizedBox(width: 60),
            Expanded(flex: 9, child: visualCard),
          ],
        )
            : Column(
          children: [
            _heroTextContent(isWide),
            const SizedBox(height: 60),
            visualCard,
          ],
        ),
      ),
    );
  }

  Widget _heroTextContent(bool isWide) {
    return Column(
      crossAxisAlignment: isWide ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(color: const Color(0xFF3B82F6).withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
          child: const Text('🚀 Metoda dovedită pentru note mari', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 24),
        Text('Meditații online\ncare îți deblochează potențialul.',
            style: TextStyle(fontSize: isWide ? 56 : 40, fontWeight: FontWeight.w900, color: Colors.white, height: 1.15, letterSpacing: -1),
            textAlign: isWide ? TextAlign.left : TextAlign.center),
        const SizedBox(height: 24),
        Text('Găsește profesorul perfect, programează-ți ședințele flexibil și învață eficient din confortul casei tale.',
            style: TextStyle(fontSize: isWide ? 18 : 16, color: Colors.grey.shade400, height: 1.6),
            textAlign: isWide ? TextAlign.left : TextAlign.center),
        const SizedBox(height: 40),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          alignment: isWide ? WrapAlignment.start : WrapAlignment.center,
          children: [
            ElevatedButton(
                onPressed: () => context.go('/materii'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 24),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: const Text('Găsește Profesor', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
            TextButton(
                onPressed: () => _scrollToSection(_howItWorksKey),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                ),
                child: const Text('Cum funcționează?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600))),
          ],
        ),
        const SizedBox(height: 60),
        Wrap(
          spacing: 32,
          runSpacing: 20,
          alignment: isWide ? WrapAlignment.start : WrapAlignment.center,
          children: [
            _statDotDark('Profesori verificați', '100%'),
            _statDotDark('Lecții', 'Live Video'),
          ],
        ),
      ],
    );
  }

  Widget _statDotDark(String title, String value) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white.withOpacity(0.15))),
            child: Center(child: Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13)))
        ),
        const SizedBox(width: 12),
        Text(title, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 16))
      ]);

  // --------------------------------------------------------------------------
  // MATERII POPULARE
  // --------------------------------------------------------------------------
  Widget _popularSubjectsSection() {
    final subjects = ['Matematică', 'Limba Română', 'Engleză', 'Informatică', 'Fizică', 'Chimie'];

    return _buildConstrainedSection(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      Column(
        children: [
          Text('CELE MAI CĂUTATE MATERII', style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.5)),
          const SizedBox(height: 24),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: subjects.map((subj) {
              return ActionChip(
                onPressed: () {
                  final encoded = Uri.encodeComponent(subj);
                  context.go('/lista-exercitii?materie=$encoded');
                },
                backgroundColor: Colors.white,
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                label: Text(subj, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF0F172A))),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // DE CE SĂ NE ALEGI (Wrap în loc de ListView)
  // --------------------------------------------------------------------------
  Widget _ceOferimSection() {
    final items = [
      {"icon": Icons.verified_user_outlined, "title": "Profesori de top", "desc": "Doar mentori cu experiență, verificați riguros."},
      {"icon": Icons.laptop_mac_outlined, "title": "100% Online", "desc": "Înveți din confortul casei tale, pe platforma noastră video."},
      {"icon": Icons.auto_graph_outlined, "title": "Note mai mari", "desc": "Metode interactive care garantează progresul rapid."},
      {"icon": Icons.schedule, "title": "Program flexibil", "desc": "Alege ziua și ora care ți se potrivesc cel mai bine."},
    ];

    return Wrap(
      spacing: 32,
      runSpacing: 32,
      alignment: WrapAlignment.center,
      children: items.map((item) {
        return HoverCard(
          child: Container(
            width: 260, // Lățime fixă pentru grilă perfectă
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.grey.shade200)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFF3B82F6).withOpacity(0.1), borderRadius: BorderRadius.circular(16)), child: Icon(item['icon'] as IconData, color: const Color(0xFF3B82F6), size: 32)),
              const SizedBox(height: 24),
              Text(item['title'] as String, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
              const SizedBox(height: 12),
              Text(item['desc'] as String, style: TextStyle(color: Colors.grey.shade600, fontSize: 15, height: 1.5)),
            ]),
          ),
        );
      }).toList(),
    );
  }

  // --------------------------------------------------------------------------
  // CUM FUNCȚIONEAZĂ (Wrap)
  // --------------------------------------------------------------------------
  Widget _howItWorksSection() {
    final items = [
      {'icon': Icons.search_rounded, 'title': '1. Găsești mentorul', 'desc': 'Răsfoiește profilurile profesorilor noștri.'},
      {'icon': Icons.calendar_month_rounded, 'title': '2. Rezervi ședința', 'desc': 'Stabiliți ora și plătești securizat.'},
      {'icon': Icons.video_camera_front_rounded, 'title': '3. Începi să înveți', 'desc': 'Intri pe apelul video direct din cont.'},
    ];

    return Wrap(
      spacing: 32,
      runSpacing: 32,
      alignment: WrapAlignment.center,
      children: items.map((item) {
        return Container(
          width: 320,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.grey.shade200)),
          child: Column(children: [
            Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF3B82F6).withOpacity(0.1)), child: Icon(item['icon'] as IconData, size: 36, color: const Color(0xFF3B82F6))),
            const SizedBox(height: 24),
            Text(item['title'] as String, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Text(item['desc'] as String, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600, fontSize: 16, height: 1.5)),
          ]),
        );
      }).toList(),
    );
  }

  // --------------------------------------------------------------------------
  // PROFESORI (Grilă dinamică din Firebase, limitată la 4 pe Home)
  // --------------------------------------------------------------------------
  Widget _profesoriSection() {
    final query = FirebaseFirestore.instance
        .collection('teachers')
        .where('hasAccount', isEqualTo: true)
        .where('active', isEqualTo: true)
        .limit(4); // Pe Home arătăm maxim 4 pentru aspect curat

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) return const Center(child: Text('Nu există profesori disponibili.', style: TextStyle(fontSize: 16)));

        return Column(
          children: [
            Wrap(
              spacing: 24,
              runSpacing: 24,
              alignment: WrapAlignment.center,
              children: docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final teacherId = doc.id;
                final name = data['name'] as String? ?? '';
                final subject = data['subject'] as String? ?? '';
                final image = data['image'] as String? ?? '';

                return HoverCard(
                  child: Container(
                    width: 260,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: const Offset(0, 5))],
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: const Color(0xFF3B82F6).withOpacity(0.1),
                          backgroundImage: image.isNotEmpty ? NetworkImage(image) : null,
                          child: image.isEmpty ? const Icon(Icons.person, size: 40, color: Color(0xFF3B82F6)) : null,
                        ),
                        const SizedBox(height: 20),
                        Text(name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF0F172A)), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 8),
                        Text(subject, style: const TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF0F172A),
                              side: BorderSide(color: Colors.grey.shade300),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () => context.go('/profesor/$teacherId'),
                            child: const Text('Vezi profil', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => context.go('/materii'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text("Vezi toți profesorii", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  // --------------------------------------------------------------------------
  // TESTIMONIALE (Wrap)
  // --------------------------------------------------------------------------
  Widget _testimonialsSection() {
    final testimonials = [
      {'quote': 'Datorită profesorului găsit aici, am reușit să iau nota 10 la examen. Platforma este uimitoare!', 'name': 'Andrei P.', 'subject': 'Elev', 'stars': 5},
      {'quote': 'Foarte sigură. Îmi place că pot vedea rapoartele copilului și plățile sunt transparente.', 'name': 'Elena D.', 'subject': 'Părinte', 'stars': 5},
      {'quote': 'Am înțeles în 3 ședințe ce nu am înțeles un semestru întreg la școală. Recomand!', 'name': 'Maria I.', 'subject': 'Elevă', 'stars': 5},
    ];

    return Wrap(
      spacing: 24,
      runSpacing: 24,
      alignment: WrapAlignment.center,
      children: testimonials.map((t) {
        final stars = t['stars'] as int;
        return HoverCard(
          child: Container(
            width: 350,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: Colors.grey.shade200)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: List.generate(5, (index) => Icon(Icons.star_rounded, color: index < stars ? Colors.amber : Colors.grey.shade300, size: 22))),
              const SizedBox(height: 20),
              Text('"${t['quote']}"', style: TextStyle(fontSize: 16, color: Colors.grey.shade800, height: 1.5, fontWeight: FontWeight.w500)),
              const SizedBox(height: 24),
              Row(children: [
                CircleAvatar(radius: 22, backgroundColor: const Color(0xFF0F172A), child: Text((t['name'] as String).substring(0, 1), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16))),
                const SizedBox(width: 16),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(t['name'] as String, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0F172A))),
                  Text(t['subject'] as String, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                ])
              ])
            ]),
          ),
        );
      }).toList(),
    );
  }

  // --------------------------------------------------------------------------
  // FAQ
  // --------------------------------------------------------------------------
  Widget _faqSection() {
    final faqs = [
      {'q': 'Cum se desfășoară o ședință?', 'a': 'Direct pe platforma noastră, prin apel video. Aveți acces la partajare de ecran și chat.'},
      {'q': 'Sunt profesorii calificați?', 'a': 'Da, toți profesorii sunt verificați manual de echipa noastră înainte de a preda.'},
      {'q': 'Cum se face plata?', 'a': 'Securizat prin Stripe, fix înainte de a intra în ședința video.'},
    ];

    return Column(
      children: faqs.map((faq) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                iconColor: const Color(0xFF3B82F6),
                collapsedIconColor: Colors.grey[800],
                title: Text(faq['q']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Color(0xFF0F172A))),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    child: Text(faq['a']!, style: TextStyle(color: Colors.grey.shade600, fontSize: 15, height: 1.5)),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // MINOR UI HELPERS
  Widget _sectionTitle(String title, {Key? key, String? subtitle}) => Padding(
      key: key, padding: const EdgeInsets.only(bottom: 50),
      child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Text(title, style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -1), textAlign: TextAlign.center),
        if (subtitle != null) ...[
          const SizedBox(height: 16),
          Text(subtitle, style: TextStyle(fontSize: 18, color: Colors.grey.shade600), textAlign: TextAlign.center),
        ]
      ]));

  Widget _buildFooter() {
    return Container(
      key: _footerKey,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
      decoration: const BoxDecoration(color: Color(0xFF0F172A)),
      child: Center(
        child: Column(children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.school, color: Colors.white, size: 32),
              SizedBox(width: 12),
              Text('iMeditatii', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white)),
            ],
          ),
          const SizedBox(height: 40),
          const Text('Platforma de încredere pentru educația ta.', style: TextStyle(color: Colors.white70, fontSize: 16), textAlign: TextAlign.center),
          const SizedBox(height: 20),
          const Text('© 2024 - 2025 iMeditatii. Toate drepturile rezervate.', style: TextStyle(color: Colors.white38, fontSize: 14), textAlign: TextAlign.center),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
          children: [
          const CustomNavbar(),
      Expanded(
        child: Scrollbar(
          controller: _pageScrollController,
          // 🚀 Am scos complet WebSmoothScroll. Revenim la structura curată și stabilă.
          child: SingleChildScrollView(
            controller: _pageScrollController,
            physics: const BouncingScrollPhysics(), // Oferă un efect elastic, natural
            child: Column(
              children: [
                _heroSection(context),
                _popularSubjectsSection(),

                _buildConstrainedSection(
                    Column(
                        children: [
                          _sectionTitle('De ce ne aleg părinții și elevii', subtitle: 'Calitate garantată, siguranță și flexibilitate totală.'),
                          _ceOferimSection(),
                        ]
                    )
                ),

                    _buildConstrainedSection(
                        bgColor: Colors.white,
                        Column(
                            children: [
                              _sectionTitle('Cum găsești mentorul perfect', key: _howItWorksKey),
                              _howItWorksSection(),
                            ]
                        )
                    ),

                    _buildConstrainedSection(
                        Column(
                            children: [
                              _sectionTitle('Cei mai apreciați profesori', key: _profesoriKey, subtitle: 'Alege dintre cei mai buni și rezervă o ședință azi.'),
                              _profesoriSection(),
                            ]
                        )
                    ),

                    _buildConstrainedSection(
                        bgColor: const Color(0xFFF1F5F9), // Un gri foarte deschis pentru contrast vizual
                        Column(
                            children: [
                              _sectionTitle('Povești de succes', key: _testimonialsKey),
                              _testimonialsSection(),
                            ]
                        )
                    ),

                    _buildConstrainedSection(
                        Column(
                            children: [
                              _sectionTitle('Ai întrebări?', key: _faqKey),
                              _faqSection(),
                            ]
                        )
                    ),

                    _buildFooter(),
                  ],
                ),
              ),
            ),
            ),
        ],
    ),
    );

  }
}
