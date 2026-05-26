import 'package:flutter/material.dart';
import '../../core/assets/app_images.dart';
import '../../core/responsive/responsive.dart';
import '../../core/utils/labels.dart';
import '../../core/services/mail_service.dart';
import '../../repositories/auth_repository.dart';
import '../../repositories/user_repository.dart';
import '../../routes/route_names.dart';
import '../../models/user_model.dart';
import '../../widgets/custom_elevated_button.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'bloc/auth_bloc.dart';
import 'bloc/auth_event.dart';
import 'bloc/auth_state.dart';

class SuspendedScreen extends StatefulWidget {
  const SuspendedScreen({super.key});

  @override
  State<SuspendedScreen> createState() => _SuspendedScreenState();
}

class _SuspendedScreenState extends State<SuspendedScreen>
    with TickerProviderStateMixin {
  late final AnimationController _fadeCtrl;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

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

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(
      begin: 0.85,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogout() async {
    await AuthRepository().logout();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        RouteNames.login,
        (route) => false,
      );
    }
  }

  void _handleContactTeam() {
    final user = UserRepository().currentUser;
    final body =
        """
Hello HomeEase Team,

I am writing regarding my suspended profile.

--- User Details ---
Name: ${user?.name ?? 'N/A'}
Email: ${user?.email ?? 'N/A'}
Phone: ${user?.phoneNumber ?? 'N/A'}
Role: ${user?.role ?? 'N/A'}

[Please write your message here]
""";

    MailService.sendMail(
      subject: 'Suspended Profile query',
      body: body,
    ).catchError((e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    });
  }

  Future<void> _handleRefresh() async {
    final user = UserRepository().currentUser;
    if (user?.id != null) {
      context.read<AuthBloc>().add(FetchUserDetailEvent(userId: user!.id!));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User session not found. Please login again.'),
        ),
      );
    }
  }

  void _navigateToCorrectScreen(UserModel user) {
    if (!mounted) return;

    if (user.isActive == true) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        RouteNames.nav,
        (route) => false,
      );
    } else {
      // Stay here, but show a message if it was a manual refresh
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No updates yet. We\'ll notify you soon.'),
          backgroundColor: Theme.of(context).primaryColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _buildAppBar(context),
      body: SafeArea(
        child: BlocListener<AuthBloc, AuthState>(
          listenWhen: (previous, current) =>
              previous.refreshStatus != current.refreshStatus,
          listener: (context, state) {
            if (state.refreshStatus == RefreshUserStatusStatus.success) {
              if (state.user != null) {
                _navigateToCorrectScreen(state.user!);
              }
            } else if (state.refreshStatus == RefreshUserStatusStatus.error) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    state.refreshError ?? 'Failed to refresh status',
                  ),
                  backgroundColor: Colors.redAccent,
                ),
              );
            }
          },
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: Responsive.isTablet(context)
                  ? _buildTabletLayout(context)
                  : _buildMobileLayout(context),
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      title: Image.asset(
        Theme.of(context).brightness == Brightness.dark
            ? AppImages.homeEaseDarkLogo
            : AppImages.homeEaseLogo,
        width: 120,
        errorBuilder: (_, __, ___) => Icon(
          Icons.home_work_rounded,
          color: Theme.of(context).primaryColor,
        ),
      ),
      centerTitle: false,
      actions: [
        BlocBuilder<AuthBloc, AuthState>(
          buildWhen: (previous, current) =>
              previous.refreshStatus != current.refreshStatus,
          builder: (context, state) {
            final isLoading =
                state.refreshStatus == RefreshUserStatusStatus.loading;
            return IconButton(
              onPressed: isLoading ? null : _handleRefresh,
              icon: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.orange,
                        ),
                      ),
                    )
                  : const Icon(Icons.refresh_rounded, size: 22),
              tooltip: Labels.refreshStatus,
              color: Theme.of(context).primaryColor,
            );
          },
        ),
        const SizedBox(width: 8),
        TextButton.icon(
          onPressed: _handleLogout,
          icon: const Icon(Icons.logout_rounded, size: 16),
          label: const Text('Logout', style: TextStyle(fontSize: 13)),
          style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
        child: _buildContent(context),
      ),
    );
  }

  Widget _buildTabletLayout(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
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
              padding: const EdgeInsets.all(48),
              child: _buildContent(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _pulseAnim,
          builder: (_, child) =>
              Transform.scale(scale: _pulseAnim.value, child: child),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.orange.withValues(alpha: 0.06),
                  border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.12),
                    width: 1,
                  ),
                ),
              ),
              Container(
                width: 86,
                height: 86,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.orange.withValues(alpha: 0.10),
                  border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.20),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withValues(alpha: 0.12),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.pause_circle_outline_rounded,
                  size: 38,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        Text(
          Labels.profileOnHold,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.displayLarge?.copyWith(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
          ),
        ),

        const SizedBox(height: 10),

        Text(
          Labels.yourProfileIsOnHoldForFurtherDetails,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontSize: 13,
            height: 1.6,
            color: Theme.of(
              context,
            ).textTheme.bodyMedium?.color?.withValues(alpha: 0.55),
          ),
        ),

        const SizedBox(height: 48),

        CustomElevatedButton(
          text: Labels.contactTeam,
          onPressed: _handleContactTeam,
        ),

        const SizedBox(height: 24),

        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.info_outline_rounded,
              size: 14,
              color: Theme.of(
                context,
              ).textTheme.bodyMedium?.color?.withValues(alpha: 0.35),
            ),
            const SizedBox(width: 8),
            Text(
              "Account Status: Suspended",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 12,
                color: Theme.of(
                  context,
                ).textTheme.bodyMedium?.color?.withValues(alpha: 0.35),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
