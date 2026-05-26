import 'package:flutter/material.dart';
import 'package:homeease/presentation/auth/change_password_screen.dart';
import 'package:homeease/presentation/faqs/faqs_screen.dart';
import 'package:homeease/presentation/languages/languages_screen.dart';
import 'package:homeease/presentation/navbar/navbar_screen.dart';
import 'package:homeease/presentation/profile/about_screen.dart';
import '../presentation/auth/forgot_password_screen.dart';
import '../presentation/auth/login_screen.dart';
import '../presentation/auth/signup_screen.dart';
import '../presentation/auth/suspended_screen.dart';
import '../presentation/splash/splash_screen.dart';
import 'route_names.dart';

class AppRoutes {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RouteNames.splash:
        debugPrint('✅ Splash route matched');
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case RouteNames.login:
        return MaterialPageRoute(builder: (_) => LoginScreen());
      case RouteNames.signupScreen:
        return MaterialPageRoute(builder: (_) => SignupScreen());
      case RouteNames.forgotPassword:
        return MaterialPageRoute(builder: (_) => ForgotPasswordScreen());
      case RouteNames.nav:
        return MaterialPageRoute(builder: (_) => const NavbarScreen());

      case RouteNames.suspendedScreen:
        return MaterialPageRoute(builder: (_) => const SuspendedScreen());

      case RouteNames.language:
        return MaterialPageRoute(builder: (_) => const LanguageScreen());

      case RouteNames.faqs:
        return MaterialPageRoute(builder: (_) => const FaqsScreen());

      case RouteNames.changePassword:
        return MaterialPageRoute(builder: (_) => const ChangePasswordScreen());
      case RouteNames.about:
        return MaterialPageRoute(builder: (_) => const AboutScreen());

      default:
        debugPrint('❌ Unknown route: ${settings.name}');
        return MaterialPageRoute(
          builder: (_) =>
              const Scaffold(body: Center(child: Text('No route found'))),
        );
    }
  }
}
