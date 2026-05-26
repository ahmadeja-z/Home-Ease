import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../core/assets/font_family.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/assets/app_images.dart';
import '../../core/responsive/responsive.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_bloc/theme_bloc.dart';
import '../../core/theme/theme_bloc/theme_event.dart';
import '../../core/theme/theme_bloc/theme_state.dart';
import '../../core/utils/app_validators.dart';
import '../../core/utils/labels.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../routes/route_names.dart';
import '../../widgets/custom_text_form_field.dart';
import '../../widgets/custom_elevated_button.dart';
import 'bloc/auth_bloc.dart';
import 'bloc/auth_event.dart';
import 'bloc/auth_state.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(
    text: kDebugMode ? 'behzadfarhan55@gmail.com' : '',
  );
  final _passwordController = TextEditingController(
    text: kDebugMode ? '11223344' : '',
  );
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            // Theme Toggle Button
            Positioned(
              top: 10,
              right: 10,
              child: BlocBuilder<ThemeBloc, ThemeState>(
                builder: (context, state) {
                  final isDark = state.themeMode == AppThemeMode.dark;
                  return IconButton(
                    onPressed: () {
                      context.read<ThemeBloc>().add(
                        SwitchThemeEvent(
                          isDark ? AppThemeMode.light : AppThemeMode.dark,
                        ),
                      );
                    },
                    icon: Icon(
                      isDark
                          ? Icons.light_mode_rounded
                          : Icons.dark_mode_rounded,
                      color: Theme.of(context).primaryColor,
                    ),
                  );
                },
              ),
            ),
            BlocListener<AuthBloc, AuthState>(
              listenWhen: (prev, curr) => prev.loginStatus != curr.loginStatus,
              listener: (context, state) {
                if (state.loginStatus == LoginStatus.success) {
                  final user = state.user;
                  if (user == null) return;

                  if (user.isActive == false) {
                    Navigator.pushReplacementNamed(
                      context,
                      RouteNames.suspendedScreen,
                    );
                  } else {
                    Navigator.pushReplacementNamed(context, RouteNames.nav);
                  }
                } else if (state.loginStatus == LoginStatus.error) {
                  SnackBarHelper.showError(
                    context,
                    title: 'Login Error',
                    subtitle: state.loginError ?? 'Login Failed',
                  );
                }
              },
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 40,
                  ),
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: SlideTransition(
                      position: _slideAnim,
                      child: _buildLayout(context),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLayout(BuildContext context) {
    if (Responsive.isTablet(context)) return _buildTabletView(context);
    return _buildMobileView(context);
  }

  // ── Mobile ──────────────────────────────────────────────────────────────

  Widget _buildMobileView(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildLogo(context),
        const SizedBox(height: 12),
        _buildBrandLabel(context),
        const SizedBox(height: 48),
        _buildLoginForm(context),
        const SizedBox(height: 28),
        _buildCreateAccountButton(context),
      ],
    );
  }

  // ── Tablet ───────────────────────────────────────────────────────────────

  Widget _buildTabletView(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        child: _buildCard(
          context,
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildLogo(context),
                const SizedBox(height: 12),
                _buildBrandLabel(context),
                const SizedBox(height: 40),
                _buildLoginForm(context),
                const SizedBox(height: 28),
                _buildCreateAccountButton(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Shared helpers ────────────────────────────────────────────────────────

  Widget _buildCard(BuildContext context, {required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 40,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(borderRadius: BorderRadius.circular(20), child: child),
    );
  }

  Widget _buildLogo(BuildContext context, {double width = 200}) {
    return Image.asset(
      Theme.of(context).brightness == Brightness.dark
          ? AppImages.homeEaseDarkLogo
          : AppImages.homeEaseLogo,
      width: width,
      errorBuilder: (_, __, ___) => Icon(
        Icons.home_rounded,
        size: width * 0.7,
        color: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildBrandLabel(BuildContext context, {bool large = false}) {
    return Column(
      children: [
        Text(
          // ✅ Customer-facing welcome text
          Labels.welcomeToHomeEase,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.displayLarge?.copyWith(
            fontSize: large ? 22 : 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          // ✅ Customer-facing subtitle
          Labels.bookTrustedHomeServicesWithEase,
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontSize: 13, height: 1.5),
        ),
      ],
    );
  }

  Widget _buildCreateAccountButton(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          Labels.dontHaveAnAccount,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 13),
        ),
        GestureDetector(
          onTap: () {
            context.read<AuthBloc>().add(ResetAuthStatusEvent());
            Navigator.pushNamed(context, RouteNames.signupScreen);
          },
          child: Text(
            Labels.registerNow,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ),
      ],
    );
  }

  // ── Login Form ────────────────────────────────────────────────────────────

  Widget _buildLoginForm(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            Labels.signIn,
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            // ✅ Customer-facing credentials hint
            Labels.enterYourCredentialsToAccessYourAccount,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontSize: 13, height: 1.5),
          ),

          const SizedBox(height: 32),

          CustomTextFormField(
            hint: Labels.emailAddress,
            textEditingController: _emailController,
            focusNode: _emailFocusNode,
            nextFocusNode: _passwordFocusNode,
            textInputType: TextInputType.emailAddress,
            validator: AppValidators.validateEmail,
          ),

          const SizedBox(height: 16),

          CustomTextFormField(
            hint: Labels.password,
            textEditingController: _passwordController,
            focusNode: _passwordFocusNode,
            obscureText: true,
            validator: AppValidators.validatePassword,
          ),

          const SizedBox(height: 4),

          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () {
                FocusScope.of(context).unfocus();
                context.read<AuthBloc>().add(ResetAuthStatusEvent());
                Navigator.pushNamed(context, RouteNames.forgotPassword);
              },
              child: Text(
                Labels.forgotPassword,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).primaryColor,
                  fontFamily: FontFamily.fontsPoppinsMedium,
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              return CustomElevatedButton(
                text: Labels.login,
                isLoading: state.loginStatus == LoginStatus.loading,
                onPressed: () {
                  FocusScope.of(context).unfocus();
                  if (_formKey.currentState!.validate()) {
                    context.read<AuthBloc>().add(
                      LoginEvent(
                        email: _emailController.text,
                        password: _passwordController.text,
                      ),
                    );
                  }
                },
              );
            },
          ),

          const SizedBox(height: 28),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline_rounded,
                size: 12,
                color: Theme.of(
                  context,
                ).textTheme.bodyMedium?.color?.withValues(alpha: 0.35),
              ),
              const SizedBox(width: 6),
              Text(
                Labels.securedWithEndToEndEncryption,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 11,
                  letterSpacing: 0.2,
                  color: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.color?.withValues(alpha: 0.35),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
