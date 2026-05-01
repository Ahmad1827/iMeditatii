import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'firebase_options.dart';

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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const IMeditatiiApp());
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
  ],
);

class IMeditatiiApp extends StatelessWidget {
  const IMeditatiiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'iMeditatii',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: false,
        textTheme: GoogleFonts.vt323TextTheme(Theme.of(context).textTheme),
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
      routerConfig: _router,
    );
  }
}