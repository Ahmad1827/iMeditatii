import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'resources_screen.dart';
import 'resource_detail_screen.dart';
import 'theme_manager.dart';

import 'home_screen.dart';
import 'login_screen.dart';
import 'signup_screen.dart';
import 'complete_profile_screen.dart';
import 'choose_role_screen.dart';
import 'legal_screens.dart';

import 'specialization_screen.dart';
import 'teacher_list_screen.dart';
import 'teacher_profile_screen.dart';
import 'teacher_detail_screen.dart';

import 'user_dashboard.dart';
import 'teachers_dashboard.dart';
import 'user_profile_screen.dart';
import 'user_profile_view_screen.dart';

import 'chat_screen.dart';
import 'video_call_screen.dart';
import 'paid_message_screen.dart';
import 'review_screen.dart';
import 'all_reviews_screen.dart';

import 'exercises_screen.dart';
import 'exercise_list_screen.dart';
import 'exercise_detail_screen.dart';
import 'add_exercise_screen.dart';
import 'seed_problems.dart';

import 'add_article_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();

  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("DotEnv loading warning: $e");
  }

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("Firebase init error: $e");
  }

  try {
    await ThemeManager.loadTheme();
  } catch (e) {
    debugPrint("ThemeManager error: $e");
  }

  // Randăm aplicația imediat pentru a preveni ecranul alb
  runApp(const IMeditatiiApp());

  // Rulăm seeder-ul asincron în background cu protecție la erori de rețea/AdBlock
  try {
    populeazaCele50DeProbleme().catchError((e) {
      debugPrint("Seeder warning (ignorat): $e");
    });
  } catch (e) {
    debugPrint("Seeder error: $e");
  }
}

final GoRouter _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/alege-rol',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;
        return ChooseRoleScreen(uid: extra['uid']!, email: extra['email']!);
      },
    ),
    GoRoute(
      path: '/',
      pageBuilder: (context, state) => const NoTransitionPage(
        child: HomeScreen(),
      ),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/inregistrare',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return SignupScreen(
          googleUser: extra?['googleUser'] ?? false,
          initialEmail: extra?['initialEmail'],
          initialName: extra?['initialName'],
        );
      },
    ),
    GoRoute(
      path: '/completare-profil',
      builder: (context, state) => const CompleteProfileScreen(),
    ),
    GoRoute(
      path: '/termeni-si-conditii',
      builder: (context, state) => const TermsScreen(),
    ),
    GoRoute(
      path: '/politica-confidentialitate',
      builder: (context, state) => const PrivacyScreen(),
    ),
    GoRoute(
      path: '/panou-elev',
      builder: (context, state) => const UserDashboard(),
    ),
    GoRoute(
      path: '/adauga-articol',
      builder: (context, state) => const AddArticleScreen(),
    ),
    GoRoute(
      path: '/panou-profesor',
      builder: (context, state) => const TeachersDashboard(),
    ),
    GoRoute(
      path: '/profesor/:id',
      builder: (context, state) => TeacherProfileScreen(teacherId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/elev/:id',
      builder: (context, state) => UserProfileScreen(userId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/chat/:chatId',
      builder: (context, state) {
        final chatId = state.pathParameters['chatId']!;
        final teacherName = state.extra as String? ?? 'Mesaje';
        return ChatScreen(chatId: chatId, teacherName: teacherName);
      },
    ),
    GoRoute(
      path: '/mesaj-platit/:teacherId',
      builder: (context, state) {
        final teacherId = state.pathParameters['teacherId']!;
        final teacherName = state.extra as String? ?? 'Profesor';
        return PaidMessageScreen(teacherId: teacherId, teacherName: teacherName);
      },
    ),
    GoRoute(
      path: '/video-call/:roomId',
      builder: (context, state) => VideoCallScreen(roomId: state.pathParameters['roomId']!),
    ),
    GoRoute(
      path: '/toate-recenziile/:teacherId',
      builder: (context, state) => AllReviewsScreen(teacherId: state.pathParameters['teacherId']!),
    ),
    GoRoute(
      path: '/adauga-recenzie',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        return ReviewScreen(
          teacherId: extra['teacherId'] ?? '',
          chatId: extra['chatId'] ?? '',
          teacherName: extra['teacherName'] ?? 'Profesor',
        );
      },
    ),
    GoRoute(
      path: '/materii',
      pageBuilder: (context, state) => const NoTransitionPage(
        child: SpecializationScreen(),
      ),
    ),
    GoRoute(
      path: '/materii/:numeMaterie',
      builder: (context, state) {
        final specMap = state.extra as Map<String, dynamic>? ?? {'name': state.pathParameters['numeMaterie']};
        return TeacherListScreen(specialization: specMap);
      },
    ),
    GoRoute(
      path: '/exercitii',
      pageBuilder: (context, state) => const NoTransitionPage(
        child: ExercisesScreen(),
      ),
    ),
    GoRoute(
      path: '/resurse',
      pageBuilder: (context, state) => const NoTransitionPage(
        child: ResourcesScreen(),
      ),
    ),
    GoRoute(
      path: '/resurse/:articleId',
      builder: (context, state) {
        final articleId = state.pathParameters['articleId']!;
        return ResourceDetailScreen(articleId: articleId);
      },
    ),
    GoRoute(
      path: '/lista-exercitii',
      builder: (context, state) {
        final materie = state.uri.queryParameters['materie'] ?? 'Matematică';
        return ExerciseListScreen(subject: materie);
      },
    ),
    GoRoute(
      path: '/exercitiu/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        final materie = state.uri.queryParameters['materie'] ?? 'Matematică';
        final clasa = state.uri.queryParameters['clasa'] ?? '9';

        return ExerciseDetailScreen(
          subject: materie,
          grade: clasa,
          id: id,
        );
      },
    ),
    GoRoute(
      path: '/adauga-exercitiu',
      builder: (context, state) => const AddExerciseScreen(),
    ),
  ],
);

class IMeditatiiApp extends StatelessWidget {
  const IMeditatiiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeManager.themeNotifier,
      builder: (context, currentMode, _) {
        final isDark = currentMode == ThemeMode.dark;

        return MaterialApp.router(
          title: 'iMeditatii',
          debugShowCheckedModeBanner: false,
          themeMode: currentMode,
          
          // TEMA LIGHT
          theme: ThemeData(
            useMaterial3: false,
            brightness: Brightness.light,
            textTheme: GoogleFonts.vt323TextTheme(ThemeData.light().textTheme),
            scaffoldBackgroundColor: const Color(0xFFF9F7F1),
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2C363F),
              secondary: Color(0xFFE75A41),
            ),
            splashFactory: NoSplash.splashFactory,
            highlightColor: Colors.transparent,
            scrollbarTheme: ScrollbarThemeData(
              thumbVisibility: WidgetStateProperty.all(true),
              trackVisibility: WidgetStateProperty.all(true),
              thickness: WidgetStateProperty.all(16.0),
              radius: const Radius.circular(0),
              thumbColor: WidgetStateProperty.all(const Color(0xFF2C363F)),
              trackColor: WidgetStateProperty.all(const Color(0xFFE2DFD2)),
              interactive: true,
            ),
          ),

          // TEMA DARK
          darkTheme: ThemeData(
            useMaterial3: false,
            brightness: Brightness.dark,
            textTheme: GoogleFonts.vt323TextTheme(ThemeData.dark().textTheme),
            scaffoldBackgroundColor: const Color(0xFF141A1F),
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF5BA8B5),
              secondary: Color(0xFFE75A41),
              surface: Color(0xFF1B242B),
            ),
            splashFactory: NoSplash.splashFactory,
            highlightColor: Colors.transparent,
            scrollbarTheme: ScrollbarThemeData(
              thumbVisibility: WidgetStateProperty.all(true),
              trackVisibility: WidgetStateProperty.all(true),
              thickness: WidgetStateProperty.all(16.0),
              radius: const Radius.circular(0),
              thumbColor: WidgetStateProperty.all(const Color(0xFF5BA8B5)),
              trackColor: WidgetStateProperty.all(const Color(0xFF1B242B)),
              interactive: true,
            ),
          ),

          routerConfig: _router,

          // BUTONUL FLOTANT PERMANENT (RESPONSIVE: ROTUND PE MOBIL, DREPTUNGHIULAR PE DESKTOP)
          builder: (context, child) {
            final isMobile = MediaQuery.of(context).size.width < 750;

            return Stack(
              children: [
                child ?? const SizedBox(),
                Positioned(
                  bottom: isMobile ? 14 : 20,
                  left: isMobile ? 14 : 20,
                  child: Material(
                    color: Colors.transparent,
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => ThemeManager.toggleTheme(),
                        child: Container(
                          width: isMobile ? 42 : null,
                          height: isMobile ? 42 : null,
                          padding: isMobile
                              ? EdgeInsets.zero
                              : const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1B242B) : Colors.white,
                            shape: isMobile ? BoxShape.circle : BoxShape.rectangle,
                            border: Border.all(
                              color: isDark ? const Color(0xFF55EFC4) : const Color(0xFF2C363F),
                              width: isMobile ? 2.0 : 2.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isDark ? Colors.black87 : const Color(0xFF2C363F),
                                offset: isMobile ? const Offset(2.5, 2.5) : const Offset(3.5, 3.5),
                                blurRadius: 0,
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: isMobile
                              ? Icon(
                                  isDark ? Icons.light_mode : Icons.dark_mode,
                                  color: isDark ? const Color(0xFFF9CA24) : const Color(0xFF2C363F),
                                  size: 20,
                                )
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isDark ? Icons.light_mode : Icons.dark_mode,
                                      color: isDark ? const Color(0xFFF9CA24) : const Color(0xFF2C363F),
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      isDark ? "LIGHT THEME" : "DARK THEME",
                                      style: TextStyle(
                                        fontFamily: 'monospace',
                                        fontWeight: FontWeight.w900,
                                        fontSize: 12,
                                        color: isDark ? const Color(0xFF55EFC4) : const Color(0xFF2C363F),
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}