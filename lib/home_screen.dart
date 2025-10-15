import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'login_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart'; // Pentru un font modern (Inter)
import 'login_screen.dart';
import 'main.dart';
import 'teachers_dashboard.dart';
import 'teacher_list_screen.dart';
import 'teacher_profile_screen.dart';
import 'user_profile_screen.dart';
import 'specialization_screen.dart';
import 'exercises_screen.dart';
import 'user_dashboard.dart';
class VideoCard extends StatefulWidget {
  final String url;
  const VideoCard({super.key, required this.url});

  @override
  State<VideoCard> createState() => _VideoCardState();
}

class _VideoCardState extends State<VideoCard> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        setState(() {
          _isInitialized = true;
          _controller.setLooping(true);
          _controller.play();
        });
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    //_oferimScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _isInitialized
        ? ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: AspectRatio(
        aspectRatio: _controller.value.aspectRatio,
        child: VideoPlayer(_controller),
      ),
    )
        : const Center(child: CircularProgressIndicator());
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const IMeditatiiApp());
}
class IMeditatiiApp extends StatelessWidget {
  const IMeditatiiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'iMeditatii',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomePageState();
}

class _HomePageState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _profesoriKey = GlobalKey();
  final GlobalKey _proiecteKey = GlobalKey();
  final GlobalKey _motivKey = GlobalKey();
  final GlobalKey _preturiKey = GlobalKey();
  final GlobalKey _footerKey = GlobalKey();


  // Controlere pentru carusele (pastrate din codul initial)
  final ScrollController _oferimScrollController = ScrollController();
  final ScrollController _proiecteScrollController = ScrollController();
  final ScrollController _profesoriScrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    _oferimScrollController.dispose();
    _proiecteScrollController.dispose();
    _profesoriScrollController.dispose();
    super.dispose();
  }

  // Functie pentru scroll la sectiune (pastrata din codul initial)
  void _scrollToSection(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    }
  }

  // Nav Bar cu efect de Glassmorphism (DESIGN NOU)
  // ⚠️ Presupunem că aceste funcții helper sunt definite în _HomePageState
// Widget _signInBtn(BuildContext context) { ... }
// Widget _actionRow({required bool isTeacher, required String userId}) { ... }
// Clasa SpecializationScreen trebuie să fie importată.
// ⚠️ Asigură-te că toate ecranele (TeachersDashboard, UserDashboard, etc.) sunt importate
// și că ai acces la 'context' și 'mounted' (de unde și nevoia de a fi o metodă a _HomePageState).

  Widget _actionRow({required bool isTeacher, required String userId}) {
    final String dashboardText = isTeacher ? 'Dashboard Profesor' : 'Contul Meu';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. Dashboard (Buton Principal/Plin)
        ElevatedButton(
          onPressed: () {
            // Folosim MaterialPageRoute fără const în builder pentru a evita erori
            if (isTeacher) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const TeachersDashboard()),
              );
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const UserDashboard()),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3B82F6), // Culoarea principală
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 4, // Păstrăm umbra de pe navbar
          ),
          child: Text(dashboardText, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ),

        const SizedBox(width: 8),

        // 2. Profil (Buton cu Iconiță)
        // Folosim un IconButton standard, dar îl stilizăm
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.person, color: Color(0xFF3B82F6), size: 20),
            tooltip: 'Profilul meu',
            onPressed: () async {
              final user = FirebaseAuth.instance.currentUser;
              if (user == null) return;

              // Logica ta complexă de creare/verificare document profesor (foarte bine!)
              if (isTeacher) {
                final teacherDoc = FirebaseFirestore.instance.collection('teachers').doc(user.uid);
                final docSnapshot = await teacherDoc.get();

                if (!docSnapshot.exists) {
                  final userData =
                  await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
                  final data = userData.data() ?? {};
                  await teacherDoc.set({
                    'name': data['name'] ?? '',
                    'email': user.email ?? '',
                    'subject': data['subject'] ?? '',
                    'contact': data['contact'] ?? '',
                    'experience': 0,
                    'image': data['image'] ?? '',
                    'hasAccount': true,
                    'active': true,
                  });
                }

                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TeacherProfileScreen()),
                );
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const UserProfileScreen()),
                );
              }
            },
          ),
        ),

        const SizedBox(width: 8),

        // 3. Logout (Buton de tip OutlinedButton/Secundar)
        OutlinedButton(
          onPressed: () async {
            await FirebaseAuth.instance.signOut();
            if (mounted) {
              Navigator.pushReplacement(
                context,
                // Fără const pentru a evita erorile de expresie constantă
                MaterialPageRoute(builder: (_) => LoginScreen()),
              );
            }
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.grey[800],
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            side: BorderSide(color: Colors.grey.shade400, width: 1),
            elevation: 0,
          ),
          child: const Text('Logout', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
  // ... (Restul importurilor și metodelor, inclusiv _navText, _scrollToSection, etc.)

// Nav Bar cu efect de Glassmorphism (DESIGN NOU)
  Widget _glassNavBar(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final bool isWide = width > 800;

    // ⚠️ Presupunem că aceste ecrane sunt importate:
    // SpecializationScreen
    // ExercisesScreen
    // HomeScreen

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            color: Colors.white.withOpacity(0.65),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // ----------------------------------------------------
                // STÂNGA: Logo și Link-uri (Logică de Comutare Adăugată)
                // ----------------------------------------------------
                Row(
                  children: [
                    // Logo Gradient
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF6366F1)]),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))],
                      ),
                      child: const Icon(Icons.school, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Text('iMeditatii', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1F2937))),

                    if (isWide) const SizedBox(width: 30),

                    // 💡 AICI VINE LOGICA DE COMUTARE A LINK-URILOR
                    if (isWide)
                      StreamBuilder<User?>(
                        stream: FirebaseAuth.instance.authStateChanges(),
                        builder: (context, snap) {
                          final user = snap.data;

                          if (user != null) {
                            // ➡️ CAZ 1: Utilizatorul este AUTENTIFICAT (Afișăm link-urile statice)
                            return Row(
                              children: [
                                // Buton Profesori → SpecializationScreen
                                _navText('Profesori', () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const SpecializationScreen()),
                                  );
                                }),
                                // Buton Exerciții → ExercisesScreen
                                _navText('Exerciții', () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => ExercisesScreen()),
                                  );
                                }),
                              ],
                            );
                          }

                          // ⬅️ CAZ 2: Utilizatorul NU este autentificat (Afișăm link-urile de marketing/scroll)
                          return Row(
                            children: [
                              _navText('Proiecte', () => _scrollToSection(_proiecteKey)),
                              _navText('Profesori', () => _scrollToSection(_profesoriKey)),
                              _navText('De ce iMeditatii', () => _scrollToSection(_motivKey)),
                              _navText('Prețuri', () => _scrollToSection(_preturiKey)),
                            ],
                          );
                        },
                      ),
                  ],
                ),

                // ----------------------------------------------------
                // DREAPTA: LOGICĂ DE AUTENTIFICARE DINAMICĂ (Păstrată)
                // ----------------------------------------------------
                StreamBuilder<User?>(
                  stream: FirebaseAuth.instance.authStateChanges(),
                  builder: (context, snap) {
                    // ... (Logica de așteptare/user null/user logat)

                    if (snap.connectionState == ConnectionState.waiting) {
                      return const SizedBox(
                        width: 80,
                        child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF3B82F6)))),
                      );
                    }

                    final user = snap.data;

                    // CAZ 1: Utilizatorul NU este autentificat (Afișăm Login + Contact)
                    if (user == null) {
                      return Row(
                        children: [
                          TextButton(
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LoginScreen())),
                            child: Text('Login', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey[800])),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3B82F6),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 4,
                            ),
                            child: const Text('Contact'),
                          ),
                        ],
                      );
                    }

                    // CAZ 2: Utilizatorul ESTE autentificat (Afișăm acțiunile dinamice prin _actionRow)
                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid)
                          .get(),
                      builder: (context, userDoc) {
                        String? role;
                        if (userDoc.hasData && userDoc.data!.exists) {
                          role = (userDoc.data!.data() as Map<String, dynamic>)['role'] as String?;
                        }

                        // Apelăm _actionRow definit anterior
                        return _actionRow(
                          isTeacher: role == 'teacher',
                          userId: user.uid,
                        );
                      },
                    );
                  },
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navText(String t, VoidCallback onTap) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: GestureDetector(
          onTap: onTap,
          child: Text(
            t,
            style: const TextStyle(fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4B5563)),
          ),
        ),
      );

  // Sectiunea Hero (DESIGN NOU)
  Widget _heroSection(BuildContext context) {
    // Simulați definirea cheii _preturiKey și a funcției _scrollToSection
    // Acestea trebuie să fie membrii clasei _HomePageState reală.
    final GlobalKey _preturiKey = GlobalKey();
    void _scrollToSection(GlobalKey key) {
      // Logica de scroll lipsește în acest fragment, dar presupunem că există.
      print("Navigare către secțiunea prețuri...");
    }

    // Asigurați-vă că ExercisesScreen este importat și accesibil.
    // final ExercisesScreen = const Placeholder(); // Placeholder pentru compilare

    final isWide = MediaQuery
        .of(context)
        .size
        .width > 800;

    // URL-ul imaginii de fundal sugerate
    const String backgroundImageUrl = "http://googleusercontent.com/image_collection/image_retrieval/1699885920043024494_0";

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 40),
      // 🎨 Adăugăm imaginea de fundal estompată aici:
      decoration: BoxDecoration(
        color: const Color(0xFF3B82F6).withOpacity(0.05),
        image: const DecorationImage(
          image: NetworkImage(backgroundImageUrl),
          fit: BoxFit.cover,
          // Opacitate mică pentru lizibilitatea textului
          opacity: 0.1,
        ),
      ),

      child: isWide
          ? Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Meditații online pentru clasele 1–12',
                  style: TextStyle(fontSize: 42,
                      fontWeight: FontWeight.w900,
                      color: Colors.grey[900]),
                ),
                const SizedBox(height: 16),
                Text(
                  'Exerciții inteligente și meditații personalizate pentru ritmul tău de învățare. Practic — Reflectiv — Eficient.',
                  style: TextStyle(fontSize: 18, color: Colors.grey[700]),
                ),
                const SizedBox(height: 30),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 26, vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 6,
                      ),
                      child: const Text(
                          'Începe acum', style: TextStyle(fontSize: 16)),
                    ),
                    const SizedBox(width: 16),
                    OutlinedButton(
                      // ⚠️ Presupune că _scrollToSection și _preturiKey sunt definite
                      onPressed: () => _scrollToSection(_preturiKey),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF3B82F6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        side: const BorderSide(
                            color: Color(0xFF3B82F6), width: 1.5),
                      ),
                      child: const Text(
                          'Vezi planurile', style: TextStyle(fontSize: 16)),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                // Stats Row
                Row(
                  children: [
                    _statDot('Profesori', '120+', context),
                    const SizedBox(width: 24),
                    _statDot('Elevi', '5k+', context),
                    const SizedBox(width: 24),
                    _statDot('Proiecte', '60+', context),
                  ],
                )
              ],
            ),
          ),
          const SizedBox(width: 40),
          // Visual Card on the right (Navigare către ExercisesScreen)
          Expanded(
            child: Center(
              child: InkWell( // 👈 InkWell pentru a răspunde la click
                onTap: () {
                  // Logica de navigare la ecranul de exerciții
                  // ⚠️ Aici trebuie să navigați la ecranul real:

                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ExercisesScreen()),
                  );
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.blue.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10))
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(16),
                          image: const DecorationImage(
                            image: NetworkImage(
                                "http://googleusercontent.com/image_collection/image_retrieval/978914853007179582_0"),
                            // Imaginea cardului
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text('Exerciții interactive', style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 18)),
                      const SizedBox(height: 8),
                      Text(
                          'Platforma noastră combină lecțiile live cu exerciții personalizate.',
                          style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                ),
              ),
            ),
          )
        ],
      )
          : Column(
        // Mobile/Small Screen Layout
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text('Meditații online pentru clasele 1–12',
              style: TextStyle(fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: Colors.grey[900]), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Text(
              'Exerciții inteligente și meditații personalizate pentru ritmul tău de învățare.',
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              textAlign: TextAlign.center),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 6,
            ),
            child: const Text('Începe acum', style: TextStyle(fontSize: 16)),
          ),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _statDot('Profesori', '120+', context),
              const SizedBox(width: 24),
              _statDot('Elevi', '5k+', context),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statDot(String title, String value, BuildContext context) {
    return Row(
      // Alinierea pe centru pentru a arăta bine pe o singură linie
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 40, // Dimensiune puțin mai mică
          height: 40, // Dimensiune puțin mai mică
          decoration: BoxDecoration(
            // Gradient dinamic, modern
            gradient: const LinearGradient(
              colors: [Color(0xFF3B82F6), Color(0xFF6366F1)],
              // Albastru la Indigo
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10), // Rotunjire mai subtilă
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF3B82F6).withOpacity(0.4),
                // Culoarea umbrei se potrivește cu gradientul
                blurRadius: 8,
                offset: const Offset(0, 3),
              )
            ],
          ),
          child: Center(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800, // Mai bold
                fontSize: 16, // Font explicit
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: Colors.grey[700],
            fontWeight: FontWeight.w600,
            fontSize: 15, // O dimensiune bună pentru label
          ),
        ),
      ],
    );
  }

  // CE OFERIM - Redesigned card carousel
  Widget _ceOferimSection() {
    // Am schimbat tipul Listei pentru a folosi IconData direct
    final items = [
      {
        "icon": Icons.school_outlined,
        "title": "Meditații personalizate",
        "desc": "Lecții adaptate nivelului și nevoilor tale.",
        "IconData": Icons.school_outlined
      },
      {
        "icon": Icons.people_outline,
        "title": "Profesori dedicați",
        "desc": "Mentori cu experiență, pasionați de predare.",
        "IconData": Icons.people_outline
      },
      {
        "icon": Icons.lightbulb_outline,
        "title": "Exerciții practice",
        "desc": "Punerea în aplicare a cunoștințelor imediat.",
        "IconData": Icons.lightbulb_outline
      },
      {
        "icon": Icons.auto_graph_outlined,
        "title": "Evaluări periodice",
        "desc": "Monitorizarea progresului și feedback constant.",
        "IconData": Icons.auto_graph_outlined
      },
      {
        "icon": Icons.schedule,
        "title": "Program flexibil",
        "desc": "Ore seara și weekend-uri, adaptate programului tău.",
        "IconData": Icons.schedule
      },
    ];

    return SizedBox(
      height: 240,
      child: Scrollbar(
        controller: _oferimScrollController,
        thumbVisibility: true,
        trackVisibility: true,
        thickness: 8,
        radius: const Radius.circular(8),
        // Scrollbar trebuie să înconjoare un widget scrollabil
        child: ListView.builder( // <--- Am înlocuit cu ListView.builder
          controller: _oferimScrollController,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return Padding(
              padding: EdgeInsets.only(right: 20), // Spațiere între elemente
              child: _featureCard(
                // Am folosit as IconData direct pe IconData stocat.
                  icon: item['icon'] as IconData,
                  // Corecțiile inițiale pentru String
                  title: item['title'] as String,
                  desc: item['desc'] as String),
            );
          },
        ),
      ),
    );
  }

  Widget _featureCard(
      {required IconData icon, required String title, required String desc}) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black12, blurRadius: 18, offset: const Offset(0, 8))
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF3B82F6), size: 28),
          ),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1F2937))),
          const SizedBox(height: 8),
          Text(desc, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
        ],
      ),
    );
  }

  // Proiecte - orizontal list with image/video cards (DESIGN NOU)
  Widget _proiecteStudentiSection() {
    final List<Map<String, String>> proiecte = [
      {
        "image": "https://i.imgur.com/Wvoh2pk.png",
        "title": "Flying Cat",
        "desc": "Joc cu pisici zburatoare."
      },
      {
        "image": "https://i.imgur.com/piqaqRU.jpeg",
        "title": "RockCat",
        "desc": "Pisica astronauta."
      },
      {
        "image": "https://i.imgur.com/vLX6ctE.png",
        "title": "Kitty Jump",
        "desc": "Joc saritor."
      },
      {
        "image": "https://i.imgur.com/ZOAVEqb.jpeg",
        "title": "Cat Word Search",
        "desc": "Joc de cuvinte."
      },
      {
        "image": "https://i.imgur.com/B8Aty98.png",
        "title": "Snake",
        "desc": "Clasicul Snake."
      },
    ];

    return SizedBox(
      height: 300,
      child: Scrollbar( // <--- NOU: Am adăugat Scrollbar-ul
        controller: _proiecteScrollController,
        thumbVisibility: true,
        trackVisibility: true,
        thickness: 8,
        radius: const Radius.circular(8),
        child: ListView.builder(
          controller: _proiecteScrollController,
          // <--- NOU: Am asociat controller-ul
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: proiecte.length,
          itemBuilder: (context, index) {
            final p = proiecte[index];
            // ... (restul codului pentru elementul din listă)
            return Container(
              width: 300,
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black12,
                      blurRadius: 10,
                      offset: const Offset(0, 4))
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // VideoCard sau Image.network
                    p.containsKey("video") ? VideoCard(url: p["video"]!) : Image
                        .network(p['image']!, fit: BoxFit.cover),
                    // Gradient Overlay
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          Colors.black.withOpacity(0.6),
                          Colors.transparent
                        ], begin: Alignment.bottomCenter, end: Alignment
                            .center),
                      ),
                    ),
                    // Text Overlay
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p['title']!, style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          Text(p['desc']!,
                              style: const TextStyle(color: Colors.white70)),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // Profesori - uses Firestore (DESIGN NOU)
  Widget _profesoriSection() {
    final query = FirebaseFirestore.instance
        .collection('teachers')
        .where('hasAccount', isEqualTo: true)
        .where('active', isEqualTo: true)
        .orderBy('name');

    return SizedBox(
      height: 300,
      child: StreamBuilder<QuerySnapshot>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Eroare: ${snapshot.error}'));
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) return const Center(
              child: Text('Nu există profesori activi încă.'));

          return Scrollbar( // <--- NOU: Am adăugat Scrollbar-ul
            controller: _profesoriScrollController,
            thumbVisibility: true,
            trackVisibility: true,
            thickness: 8,
            radius: const Radius.circular(8),
            child: ListView.builder(
              controller: _profesoriScrollController,
              // <--- NOU: Am asociat controller-ul
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final data = docs[index].data() as Map<String, dynamic>;
                final name = data['name'] as String? ?? ''; // Corecție tip
                final subject = data['subject'] as String? ??
                    ''; // Corecție tip
                final image = data['image'] as String? ?? ''; // Corecție tip

                return Container(
                  width: 240,
                  margin: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 12),
                  child: Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Imaginea profesorului
                          CircleAvatar(
                            radius: 50,
                            backgroundColor: Theme
                                .of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.1),
                            backgroundImage: image.isNotEmpty ? NetworkImage(
                                image) : null,
                            child: image.isEmpty ? Icon(
                                Icons.person, size: 50, color: Theme
                                .of(context)
                                .colorScheme
                                .primary) : null,
                          ),
                          const SizedBox(height: 16),
                          Text(name, style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 18)),
                          const SizedBox(height: 4),
                          Text(subject, style: TextStyle(color: Theme
                              .of(context)
                              .colorScheme
                              .secondary, fontSize: 14)),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme
                                  .of(context)
                                  .colorScheme
                                  .primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text('Vezi profil'),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  // Beneficii (DESIGN NOU - folosind Wrap pentru flexibilitate)
  Widget _beneficiiSection() {
    final items = [
      'Profesori dedicați',
      'Materiale moderne',
      'Program flexibil',
      'Rezultate vizibile rapid',
      'Focus pe practică',
      'Evaluare permanentă'
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Wrap(
        spacing: 14,
        runSpacing: 12,
        children: items.map((t) {
          return Chip(
            label: Text(t, style: const TextStyle(fontWeight: FontWeight.w600)),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            elevation: 0,
            backgroundColor: Theme
                .of(context)
                .colorScheme
                .primary
                .withOpacity(0.1),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          );
        }).toList(),
      ),
    );
  }

  // Preturi (DESIGN NOU - carduri aliniate)
  Widget _preturiSection() {
    final plans = [
      {
        'name': 'Basic',
        'price': '50 RON',
        'features': '1 sesiune / săptămână. Resurse limitate.',
        'isFeatured': false
      },
      {
        'name': 'Standard',
        'price': '90 RON',
        'features': 'Sesiuni + exerciții adaptate. Suport sporit.',
        'isFeatured': true
      },
      {
        'name': 'Premium',
        'price': '150 RON',
        'features': 'Totul + suport dedicat. Acces 24/7 la mentor.',
        'isFeatured': false
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: plans.map((p) {
          final isFeatured = p['isFeatured'] as bool;
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: isFeatured ? const LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF6366F1)]) : null,
                color: isFeatured ? null : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black12,
                      blurRadius: 14,
                      offset: Offset(0, isFeatured ? 10 : 4))
                ],
                border: isFeatured ? null : Border.all(
                    color: Colors.grey.shade200),
              ),
              // SECȚIUNEA CORECTATĂ
// ...
              child: Column(
                children: [
                  Text(p['name'] as String, // <-- CORECȚIE APLICATĂ
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                          color: isFeatured ? Colors.white : Colors.grey[900])),
                  const SizedBox(height: 16),
                  Text(p['price'] as String, // <-- CORECȚIE APLICATĂ
                      style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: isFeatured ? Colors.white : Colors.black)),
                  const SizedBox(height: 4),
                  Text('/ lună',
                      style: TextStyle(
                          color: isFeatured ? Colors.white70 : Colors
                              .grey[600])),
                  const SizedBox(height: 16),
                  Text(p['features'] as String, // <-- CORECȚIE APLICATĂ
                      style: TextStyle(
                          color: isFeatured ? Colors.white70 : Colors
                              .grey[600]),
                      textAlign: TextAlign.center),
// ..
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isFeatured ? Colors.white : const Color(
                          0xFF3B82F6),
                      foregroundColor: isFeatured
                          ? const Color(0xFF3B82F6)
                          : Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20,
                          vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius
                          .circular(10)),
                    ),
                    child: Text(
                        isFeatured ? 'Cel mai popular' : 'Alege planul'),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // Footer (DESIGN NOU)
  Widget _buildFooter() {
    return Container(
      key: _footerKey,
      color: const Color(0xFF1F2937),
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 50),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('iMeditatii', style: TextStyle(fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white)),
                const SizedBox(height: 12),
                Text('Învățăm prin practică și reflecție.',
                    style: TextStyle(color: Colors.white70, fontSize: 16)),
                const SizedBox(height: 24),
                Row(children: const [
                  Icon(Icons.facebook, color: Colors.white, size: 28),
                  SizedBox(width: 16),
                  Icon(Icons.link, color: Colors.white, size: 28),
                  SizedBox(width: 16),
                  Icon(Icons.email, color: Colors.white, size: 28)
                ]),
                const SizedBox(height: 40),
                Text('© 2018 - 2025 iMeditatii. All rights reserved.',
                    style: TextStyle(color: Colors.white54, fontSize: 14))
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Linkuri Rapide', style: TextStyle(color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 18)),
                const SizedBox(height: 12),
                _footerLink('Proiecte', () => _scrollToSection(_proiecteKey)),
                _footerLink('Profesori', () => _scrollToSection(_profesoriKey)),
                _footerLink('Prețuri', () => _scrollToSection(_preturiKey)),
                const SizedBox(height: 20),
                Text('Legal', style: TextStyle(color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 18)),
                const SizedBox(height: 12),
                _footerLink('Termeni și Condiții', () {}),
                _footerLink('Privacy Policy', () {}),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _footerLink(String text, VoidCallback onTap) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
          padding: EdgeInsets.zero, alignment: Alignment.centerLeft),
      child: Text(text, style: TextStyle(color: Colors.white70, fontSize: 15)),
    );
  }

  // Titlu secțiune (DESIGN NOU)
  Widget _sectionTitle(String title, {Key? key}) {
    return Padding(
      key: key,
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 50,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1F2937))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Background color este deja setat in IMeditatiiApp
      body: SafeArea(
        child: Column(
          children: [
            // Bara de navigație deasupra conținutului, dar în interiorul Safe Area
            _glassNavBar(context),

            // Conținut scrollabil
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _heroSection(context),

                    // CE OFERIM
                    _sectionTitle('Ce oferim'),
                    _ceOferimSection(),

                    // PROIECTELE STUDENȚILOR
                    _sectionTitle(
                        'Proiectele studenților noștri', key: _proiecteKey),
                    _proiecteStudentiSection(),

                    // PROFESORII NOȘTRI
                    _sectionTitle(
                        'Profesorii noștri activi', key: _profesoriKey),
                    _profesoriSection(),

                    // DE CE I MEDITATII (BENEFICII)
                    _sectionTitle('De ce să alegi iMeditatii', key: _motivKey),
                    _beneficiiSection(),

                    // PREȚURI
                    _sectionTitle('Prețuri', key: _preturiKey),
                    _preturiSection(),

                    const SizedBox(height: 50),

                    // FOOTER
                    _buildFooter(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}