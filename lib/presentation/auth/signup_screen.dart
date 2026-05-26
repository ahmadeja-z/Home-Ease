import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/utils/labels.dart';
import '../../core/assets/app_images.dart';
import '../../core/responsive/responsive.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/theme_bloc/theme_bloc.dart';
import '../../core/theme/theme_bloc/theme_event.dart';
import '../../core/theme/theme_bloc/theme_state.dart';
import '../../core/utils/app_validators.dart';
import '../../core/utils/snackbar_helper.dart';
import '../../routes/route_names.dart';
import '../../widgets/custom_elevated_button.dart';
import '../../widgets/custom_text_form_field.dart';
import 'bloc/auth_bloc.dart';
import 'bloc/auth_event.dart';
import 'bloc/auth_state.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _nameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _phoneFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();

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
      begin: const Offset(0, .06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameFocusNode.dispose();
    _emailFocusNode.dispose();
    _phoneFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            BlocListener<AuthBloc, AuthState>(
              listenWhen: (p, c) => p.signupStatus != c.signupStatus,
              listener: (context, state) {
                if (state.signupStatus == SignupStatus.success) {
                  SnackBarHelper.showSuccess(
                    context,
                    title: 'Account Created',
                    subtitle:
                    'A confirmation email has been sent. Please verify before signing in.',
                  );
                  Future.delayed(const Duration(seconds: 2), () {
                    if (context.mounted) {
                      Navigator.pushReplacementNamed(context, RouteNames.login);
                    }
                  });
                } else if (state.signupStatus == SignupStatus.error) {
                  SnackBarHelper.showError(
                    context,
                    title: 'Signup Error',
                    subtitle: state.signupError ?? 'Signup failed',
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
            Positioned(top: 8, right: 8, child: _ThemeToggle()),
          ],
        ),
      ),
    );
  }

  Widget _buildLayout(BuildContext context) {
    if (Responsive.isTablet(context)) return _buildTabletView(context);
    return _buildMobileView(context);
  }

  // ── Mobile ────────────────────────────────────────────────────────────────

  Widget _buildMobileView(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildLogo(context),
        const SizedBox(height: 36),
        _buildCustomerBadge(context),  // ✅ Customer badge instead of Worker badge
        const SizedBox(height: 32),
        _buildSignupForm(context),
      ],
    );
  }

  // ── Tablet ────────────────────────────────────────────────────────────────

  Widget _buildTabletView(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
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
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildLogo(context),
                const SizedBox(height: 20),
                _buildCustomerBadge(context),  // ✅ Customer badge
                const SizedBox(height: 32),
                _buildSignupForm(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Logo ──────────────────────────────────────────────────────────────────

  Widget _buildLogo(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Image.asset(
      isDark ? AppImages.homeEaseDarkLogo : AppImages.homeEaseLogo,
      width: 160,
      errorBuilder: (_, __, ___) => Icon(
        Icons.home_rounded,  // ✅ Customer icon (home, not home_work)
        size: 64,
        color: Theme.of(context).primaryColor,
      ),
    );
  }

  // ── Customer identity badge ───────────────────────────────────────────────
  // ✅ Replaced worker service icons with customer-relevant service categories

  Widget _buildCustomerBadge(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    return Column(
      children: [
        // Service category icons a customer would browse
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _ServiceIcon(icon: Icons.handyman_rounded, color: primary),
            const SizedBox(width: 16),
            _ServiceIcon(icon: Icons.electrical_services_rounded, color: primary),
            const SizedBox(width: 16),
            _ServiceIcon(icon: Icons.plumbing_rounded, color: primary),
            const SizedBox(width: 16),
            _ServiceIcon(icon: Icons.cleaning_services_rounded, color: primary),
          ],
        ),
        const SizedBox(height: 16),
        // Divider with customer portal label
        Row(
          children: [
            Expanded(
              child: Divider(
                color: Theme.of(context).dividerColor,
                thickness: 1,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text(
                Labels.customerPortalCapital,  // ✅ "CUSTOMER PORTAL" label
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 3.0,
                  color: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.color?.withValues(alpha: 0.40),
                ),
              ),
            ),
            Expanded(
              child: Divider(
                color: Theme.of(context).dividerColor,
                thickness: 1,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Signup Form ───────────────────────────────────────────────────────────

  Widget _buildSignupForm(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Heading
          Text(
            Labels.createAccount,
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            // ✅ Customer-facing subtitle
            Labels.registerToBookHomeServicesOnHomeEase,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontSize: 13, height: 1.5),
          ),

          const SizedBox(height: 28),

          // Full Name
          _FieldLabel(
            label: Labels.fullName,
            icon: Icons.person_outline_rounded,
          ),
          const SizedBox(height: 8),
          CustomTextFormField(
            hint: Labels.fullName,
            textEditingController: _nameController,
            focusNode: _nameFocusNode,
            nextFocusNode: _emailFocusNode,
            validator: AppValidators.validateName,
          ),

          const SizedBox(height: 18),

          // Email
          _FieldLabel(label: Labels.email, icon: Icons.alternate_email_rounded),
          const SizedBox(height: 8),
          CustomTextFormField(
            hint: Labels.email,
            textEditingController: _emailController,
            focusNode: _emailFocusNode,
            nextFocusNode: _phoneFocusNode,
            textInputType: TextInputType.emailAddress,
            validator: AppValidators.validateEmail,
          ),

          const SizedBox(height: 18),

          // Phone
          _FieldLabel(label: Labels.phoneNumber, icon: Icons.phone_outlined),
          const SizedBox(height: 8),
          CustomTextFormField(
            hint: '0000000000',
            textEditingController: _phoneController,
            focusNode: _phoneFocusNode,
            nextFocusNode: _passwordFocusNode,
            textInputType: TextInputType.phone,
            validator: AppValidators.validatePhone,
          ),

          const SizedBox(height: 18),

          // Password
          _FieldLabel(label: Labels.password, icon: Icons.lock_outline_rounded),
          const SizedBox(height: 8),
          CustomTextFormField(
            hint: Labels.password,
            obscureText: true,
            textEditingController: _passwordController,
            focusNode: _passwordFocusNode,
            nextFocusNode: _confirmPasswordFocusNode,
            validator: AppValidators.validatePassword,
          ),

          const SizedBox(height: 18),

          // Confirm Password
          _FieldLabel(
            label: Labels.confirmPassword,
            icon: Icons.lock_outline_rounded,
          ),
          const SizedBox(height: 8),
          CustomTextFormField(
            hint: Labels.confirmPassword,
            obscureText: true,
            textEditingController: _confirmPasswordController,
            focusNode: _confirmPasswordFocusNode,
            validator: (value) => AppValidators.validateConfirmPassword(
              _passwordController.text,
              value,
            ),
          ),

          const SizedBox(height: 32),

          // Sign Up Button
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              return CustomElevatedButton(
                text: Labels.signup,
                isLoading: state.signupStatus == SignupStatus.loading,
                onPressed: () {
                  FocusScope.of(context).unfocus();
                  if (_formKey.currentState!.validate()) {
                    context.read<AuthBloc>().add(
                      SignupEvent(
                        name: _nameController.text.trim(),
                        email: _emailController.text.trim(),
                        phone: _phoneController.text.trim(),
                        password: _passwordController.text,
                      ),
                    );
                  }
                },
              );
            },
          ),

          const SizedBox(height: 24),

          // Footer note
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

          const SizedBox(height: 20),

          // Already have account
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                Labels.alreadyHaveAnAccount,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontSize: 13),
              ),
              GestureDetector(
                onTap: () {
                  context.read<AuthBloc>().add(ResetAuthStatusEvent());
                  Navigator.pop(context);
                },
                child: Text(
                  Labels.signInCapital,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Field label with icon
// ═══════════════════════════════════════════════════════════════════════════

class _FieldLabel extends StatelessWidget {
  final String label;
  final IconData icon;
  const _FieldLabel({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 13,
          color: Theme.of(
            context,
          ).textTheme.bodyMedium?.color?.withValues(alpha: 0.45),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
            color: Theme.of(
              context,
            ).textTheme.bodyMedium?.color?.withValues(alpha: 0.55),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Service icon chip
// ═══════════════════════════════════════════════════════════════════════════

class _ServiceIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _ServiceIcon({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Icon(icon, size: 18, color: color),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Theme toggle button
// ═══════════════════════════════════════════════════════════════════════════

class _ThemeToggle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, state) {
        final isDark = state.themeMode == AppThemeMode.dark;
        return IconButton(
          onPressed: () => context.read<ThemeBloc>().add(
            SwitchThemeEvent(isDark ? AppThemeMode.light : AppThemeMode.dark),
          ),
          icon: Icon(
            isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            size: 20,
            color: Theme.of(
              context,
            ).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
          ),
        );
      },
    );
  }
}