import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:homeease/firebase_options.dart';
import 'package:homeease/presentation/languages/bloc/languages_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:responsive_framework/responsive_framework.dart';

import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_bloc/theme_bloc.dart';
import 'core/theme/theme_bloc/theme_event.dart';
import 'core/theme/theme_bloc/theme_state.dart';
import 'core/theme/theme_repository.dart';
import 'presentation/auth/bloc/auth_bloc.dart';
import 'presentation/home/bloc/home_bloc.dart';
import 'presentation/profile/bloc/profile_bloc.dart';
import 'presentation/splash/splash_screen.dart';
import 'repositories/auth_repository.dart';
import 'repositories/home_repository.dart';
import 'repositories/user_repository.dart';
import 'routes/app_routes.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // We use the top-level handler defined in NotificationService
  debugPrint(
    '📩 Background message handled in main.dart: ${message.messageId}',
  );
  await NotificationService().handleBackgroundMessage(message);
}

void main() async {
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('Warning: .env file not found. Using default values.');
  }

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  await EasyLocalization.ensureInitialized();

  // Initialize Notifications
  final notificationService = NotificationService();
  await notificationService.init();

  // Create UserRepository for initialization
  final userRepository = UserRepository();
  await userRepository.init();

  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('en'),
        Locale('ar'),
        Locale('es'),
        Locale('fr'),
        Locale('fr', 'CA'), // French (Canada)
        Locale('ko'),
        Locale('pt', 'BR'), // Portuguese (Brazil)
      ],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: RepositoryProvider(
        create: (context) => AuthRepository(),
        child: MultiRepositoryProvider(
          providers: [
            RepositoryProvider<UserRepository>(
              create: (_) => UserRepository(),
            ),
            RepositoryProvider<HomeRepository>(
              create: (_) => HomeRepository(),
            ),
          ],
          child: MultiBlocProvider(
            providers: [
              BlocProvider<ThemeBloc>(
                create: (_) {
                  final themeRepository = ThemeRepository();
                  final themeBloc = ThemeBloc(themeRepository);
                  // Load saved theme on app startup
                  themeBloc.add(const LoadThemeEvent());
                  return themeBloc;
                },
              ),
              BlocProvider<AuthBloc>(
                create: (context) => AuthBloc(context.read<AuthRepository>()),
              ),
              BlocProvider<LanguageBloc>(create: (context) => LanguageBloc()),
              BlocProvider<ProfileBloc>(
                create: (context) =>
                    ProfileBloc(userRepository: context.read<UserRepository>()),
              ),
              // BlocProvider<DrawerBloc>(create: (context) => DrawerBloc()),
            ],
            child: BlocProvider<HomeBloc>(
              create: (context) => HomeBloc(context.read<HomeRepository>()),
              child: const MyApp(),
            ),
          ),
        ),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, state) {
        return MaterialApp(
          navigatorKey: NotificationService.navigatorKey,
          title: 'HomeEase',
          debugShowCheckedModeBanner: false,
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
          onGenerateRoute: AppRoutes.generateRoute,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: state.themeMode == AppThemeMode.light
              ? ThemeMode.light
              : ThemeMode.dark,
          builder: (context, child) => ResponsiveBreakpoints.builder(
            child: child!,
            breakpoints: [
              const Breakpoint(start: 0, end: 450, name: MOBILE),
              const Breakpoint(start: 451, end: 800, name: TABLET),
              const Breakpoint(start: 801, end: 1920, name: DESKTOP),
              const Breakpoint(start: 1921, end: double.infinity, name: '4K'),
            ],
          ),
          home: SplashScreen(), // Changed from HomeScreen to DrawerScreen
        );
      },
    );
  }
}
