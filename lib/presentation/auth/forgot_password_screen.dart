import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_bloc/theme_bloc.dart';
import '../../core/theme/theme_bloc/theme_event.dart';
import '../../core/theme/theme_bloc/theme_state.dart';
import '../../core/assets/app_images.dart';
import '../../core/responsive/responsive.dart';
import '../../core/utils/app_validators.dart';
import '../../core/utils/labels.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../widgets/custom_text_form_field.dart';
import '../../widgets/custom_elevated_button.dart';
import 'bloc/auth_bloc.dart';
import 'bloc/auth_event.dart';
import 'bloc/auth_state.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _emailFocusNode = FocusNode();

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
    _emailFocusNode.dispose();
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
              listener: (context, state) {
                if (state.forgotPasswordStatus ==
                    ForgotPasswordStatus.success) {
                  SnackBarHelper.showSuccess(
                    context,
                    title: 'Password Reset',
                    subtitle: 'Password reset link sent to your email',
                  );
                } else if (state.forgotPasswordStatus ==
                    ForgotPasswordStatus.error) {
                  SnackBarHelper.showError(
                    context,
                    title: 'Password Reset Error',
                    subtitle:
                        state.forgotPasswordError ??
                        'Failed to send reset link',
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
        const SizedBox(height: 48),
        _buildForm(context),
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
                const SizedBox(height: 40),
                _buildForm(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

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
        Icons.home_work_rounded,
        size: width * 0.7,
        color: Theme.of(context).primaryColor,
      ),
    );
  }

  // ── Form ──────────────────────────────────────────────────────────────────

  Widget _buildForm(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Text(
            Labels.resetYourPassword,
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
              fontSize: 26,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            Labels.enterYourRegisteredEmailToRecoverYourHomeEaseAccount,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontSize: 13, height: 1.6),
          ),
          const SizedBox(height: 32),

          // Email field
          CustomTextFormField(
            hint: Labels.emailAddress,
            textEditingController: _emailController,
            focusNode: _emailFocusNode,
            textInputType: TextInputType.emailAddress,
            validator: AppValidators.validateEmail,
          ),

          const SizedBox(height: 28),

          // Submit button
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              return CustomElevatedButton(
                text: Labels.sendResetLink,
                isLoading:
                    state.forgotPasswordStatus == ForgotPasswordStatus.loading,
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    context.read<AuthBloc>().add(
                      ForgotPasswordEvent(email: _emailController.text),
                    );
                  }
                },
              );
            },
          ),

          const SizedBox(height: 20),

          // Back to login
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.arrow_back_rounded,
                size: 14,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () {
                  context.read<AuthBloc>().add(ResetAuthStatusEvent());
                  Navigator.of(context).pop();
                },
                child: Text(
                  Labels.backToLogin,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // Footer
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
