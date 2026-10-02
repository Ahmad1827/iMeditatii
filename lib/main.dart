import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';

import 'theme_manager.dart';
import 'app_colors.dart';

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
import 'resources_screen.dart';
import 'resource_detail_screen.dart';
import 'add_article_screen.dart';
import 'seed_problems.dart';

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

  runApp(const IMeditatiiApp());

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
    GoRoute(
      path: '/resurse',
      pageBuilder: (context, state) => const NoTransitionPage(
        child: ResourcesScreen(),
      ),
    ),
    GoRoute(
      path: '/resurse/:articleId',
      builder: (context, state) => ResourceDetailScreen(articleId: state.pathParameters['articleId']!),
    ),
    GoRoute(
      path: '/adauga-articol',
      builder: (context, state) => const AddArticleScreen(),
    ),
  ],
);

class IMeditatiiApp extends StatelessWidget {
  const IMeditatiiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([ThemeManager.themeNotifier, ThemeManager.styleNotifier]),
      builder: (context, _) {
        final currentMode = ThemeManager.themeNotifier.value;
        final currentStyle = ThemeManager.styleNotifier.value;
        final isDark = currentMode == ThemeMode.dark;
        final isRetro = currentStyle == AppStyleMode.retro;

        TextTheme getTextTheme(Brightness brightness) {
          final base = brightness == Brightness.dark 
              ? ThemeData.dark().textTheme 
              : ThemeData.light().textTheme;
          return isRetro ? GoogleFonts.vt323TextTheme(base) : GoogleFonts.interTextTheme(base);
        }

        return MaterialApp.router(
          title: 'iMeditatii',
          debugShowCheckedModeBanner: false,
          themeMode: currentMode,

          // TEMA LIGHT
          theme: ThemeData(
            useMaterial3: false,
            brightness: Brightness.light,
            textTheme: getTextTheme(Brightness.light),
            scaffoldBackgroundColor: const Color(0xFFF9F7F1),
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2C363F),
              secondary: Color(0xFFE75A41),
            ),
            splashFactory: isRetro ? NoSplash.splashFactory : null,
            highlightColor: Colors.transparent,
          ),

          // TEMA DARK
          darkTheme: ThemeData(
            useMaterial3: false,
            brightness: Brightness.dark,
            textTheme: getTextTheme(Brightness.dark),
            scaffoldBackgroundColor: const Color(0xFF141A1F),
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF5BA8B5),
              secondary: Color(0xFFE75A41),
              surface: Color(0xFF1B242B),
            ),
            splashFactory: isRetro ? NoSplash.splashFactory : null,
            highlightColor: Colors.transparent,
          ),

          routerConfig: _router,

          // DUAL FLOATING CONTROL DECK: THEME + STYLE TOGGLES
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
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 1. Theme Button (Dark/Light)
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () => ThemeManager.toggleTheme(),
                            child: Container(
                              width: isMobile ? 40 : null,
                              height: isMobile ? 40 : null,
                              padding: isMobile ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1B242B) : Colors.white,
                                shape: isMobile ? BoxShape.circle : BoxShape.rectangle,
                                borderRadius: isMobile ? null : (isRetro ? BorderRadius.zero : BorderRadius.circular(8)),
                                border: Border.all(
                                  color: isDark ? const Color(0xFF55EFC4) : const Color(0xFF2C363F),
                                  width: isRetro ? 2.5 : 1.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: isDark ? Colors.black87 : const Color(0xFF2C363F).withOpacity(isRetro ? 1.0 : 0.1),
                                    offset: Offset(isMobile ? 2.5 : 3.5, isMobile ? 2.5 : 3.5),
                                    blurRadius: isRetro ? 0 : 6,
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: isMobile
                                  ? Icon(
                                      isDark ? Icons.light_mode : Icons.dark_mode,
                                      color: isDark ? const Color(0xFFF9CA24) : const Color(0xFF2C363F),
                                      size: 18,
                                    )
                                  : Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isDark ? Icons.light_mode : Icons.dark_mode,
                                          color: isDark ? const Color(0xFFF9CA24) : const Color(0xFF2C363F),
                                          size: 16,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          isDark ? "LIGHT" : "DARK",
                                          style: TextStyle(
                                            fontWeight: FontWeight.w900,
                                            fontSize: 11,
                                            color: isDark ? const Color(0xFF55EFC4) : const Color(0xFF2C363F),
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // 2. Style Button (Retro / Clean)
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () => ThemeManager.toggleStyle(),
                            child: Container(
                              width: isMobile ? 40 : null,
                              height: isMobile ? 40 : null,
                              padding: isMobile ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: isRetro ? AppColors.mustard : AppColors.sky,
                                shape: isMobile ? BoxShape.circle : BoxShape.rectangle,
                                borderRadius: isMobile ? null : (isRetro ? BorderRadius.zero : BorderRadius.circular(8)),
                                border: Border.all(
                                  color: AppColors.border,
                                  width: isRetro ? 2.5 : 1.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.shadow.withOpacity(isRetro ? 1.0 : 0.1),
                                    offset: Offset(isMobile ? 2.5 : 3.5, isMobile ? 2.5 : 3.5),
                                    blurRadius: isRetro ? 0 : 6,
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: isMobile
                                  ? Icon(
                                      isRetro ? Icons.videogame_asset : Icons.auto_stories,
                                      color: Colors.white,
                                      size: 18,
                                    )
                                  : Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isRetro ? Icons.videogame_asset : Icons.auto_stories,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          isRetro ? "STYLE: RETRO" : "STYLE: CLEAN",
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w900,
                                            fontSize: 11,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ],
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