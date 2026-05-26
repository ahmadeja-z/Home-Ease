import 'package:flutter/material.dart';
import '../../core/services/permission_service.dart';
import '../../repositories/user_repository.dart';
import '../../repositories/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/assets/app_images.dart';
import '../../core/responsive/responsive.dart';
import '../../routes/route_names.dart';
import '../../core/services/notification_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _logoCtrl;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;

  late final AnimationController _contentCtrl;
  late final Animation<double> _contentFade;
  late final Animation<Offset> _contentSlide;

  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();

    _logoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _logoScale = Tween<double>(
      begin: .8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOutBack));
    _logoFade = CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOut);

    _contentCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _contentFade = CurvedAnimation(parent: _contentCtrl, curve: Curves.easeOut);
    _contentSlide = Tween<Offset>(begin: const Offset(0, .25), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _contentCtrl, curve: Curves.easeOutCubic),
        );

    _runSequence();
  }

  Future<void> _runSequence() async {
    await Future.delayed(const Duration(milliseconds: 250));
    _logoCtrl.forward();
    NotificationService().init();
    await Future.delayed(const Duration(milliseconds: 500));
    _contentCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 2200));
    
    // Request location permission on app startup
    await PermissionService.requestLocationPermission();
    
    _navigate();
  }

  Future<void> _navigate() async {
    if (!mounted) return;

    final session = supabase.auth.currentSession;
    final userId = session?.user.id;

    if (userId != null) {
      try {
        final freshUser = await AuthRepository()
            .getProfile(userId)
            .timeout(const Duration(seconds: 5));
        if (freshUser != null) await UserRepository().setUser(freshUser);
      } catch (e) {
        debugPrint('⚠️ [SplashScreen] Profile sync failed: $e');
      }
    }

    final user = UserRepository().currentUser;

    if (user != null) {
      if (user.isActive == false) {
        Navigator.pushReplacementNamed(context, RouteNames.suspendedScreen);
      } else if (user.status == 'approved' && session != null) {
        Navigator.pushReplacementNamed(context, RouteNames.nav);
      } else {
        Navigator.pushReplacementNamed(context, RouteNames.login);
      }
    } else {
      Navigator.pushReplacementNamed(context, RouteNames.login);
    }
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = Responsive.isTablet(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          _buildBackground(context),
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: isTablet ? 80 : 40),
              child: _buildContent(context, logoWidth: isTablet ? 320 : 240),
            ),
          ),
        ],
      ),
    );
  }

  // ── Background ────────────────────────────────────────────────────────────

  Widget _buildBackground(BuildContext context) {
    final c = Theme.of(context).primaryColor;

    return Stack(
      children: [
        // Corner orbs
        Positioned(
          top: -80,
          left: -80,
          child: _BgCircle(size: 260, color: c.withValues(alpha: .05)),
        ),
        Positioned(
          bottom: -80,
          right: -80,
          child: _BgCircle(size: 300, color: c.withValues(alpha: .04)),
        ),

        // Customer-context service icons — subtly placed
        Positioned(
          bottom: 110,
          left: 36,
          child: Icon(
            Icons.home_repair_service_rounded,
            size: 88,
            color: c.withValues(alpha: .045),
          ),
        ),
        Positioned(
          top: 130,
          right: 44,
          child: Icon(
            Icons.cleaning_services_rounded,
            size: 76,
            color: c.withValues(alpha: .045),
          ),
        ),
        Positioned(
          bottom: 220,
          right: 28,
          child: Icon(
            Icons.plumbing_rounded,
            size: 52,
            color: c.withValues(alpha: .03),
          ),
        ),
        Positioned(
          top: 260,
          left: 28,
          child: Icon(
            Icons.electrical_services_rounded,
            size: 48,
            color: c.withValues(alpha: .03),
          ),
        ),
      ],
    );
  }

  // ── Main content ──────────────────────────────────────────────────────────

  Widget _buildContent(BuildContext context, {required double logoWidth}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Logo
        ScaleTransition(
          scale: _logoScale,
          child: FadeTransition(
            opacity: _logoFade,
            child: Image.asset(
              Theme.of(context).brightness == Brightness.dark
                  ? AppImages.homeEaseDarkLogo
                  : AppImages.homeEaseLogo,
              width: logoWidth,
              errorBuilder: (_, __, ___) => Icon(
                Icons.home_work_rounded,
                size: logoWidth * 0.4,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
        ),

        const SizedBox(height: 40),

        // Tagline + loader
        SlideTransition(
          position: _contentSlide,
          child: FadeTransition(
            opacity: _contentFade,
            child: Column(
              children: [
                // Divider label
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
                        'HOME SERVICES',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 3.2,
                          color: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.color?.withValues(alpha: .40),
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

                const SizedBox(height: 28),

                // Service chips row
                _buildServiceChips(context),

                const SizedBox(height: 28),

                // Dots loader
                _DotsLoader(color: Theme.of(context).primaryColor),

                const SizedBox(height: 16),

                Text(
                  'Getting your services ready…',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 12,
                    letterSpacing: .3,
                    color: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.color?.withValues(alpha: .35),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Service chips ─────────────────────────────────────────────────────────

  Widget _buildServiceChips(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final services = [
      (Icons.handyman_rounded, 'Repair'),
      (Icons.cleaning_services_rounded, 'Cleaning'),
      (Icons.electrical_services_rounded, 'Electric'),
      (Icons.plumbing_rounded, 'Plumbing'),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: services.asMap().entries.map((entry) {
        final i = entry.key;
        final item = entry.value;
        return Padding(
          padding: EdgeInsets.only(left: i == 0 ? 0 : 10),
          child: Column(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: primary.withValues(alpha: .15)),
                ),
                child: Icon(item.$1, size: 18, color: primary),
              ),
              const SizedBox(height: 6),
              Text(
                item.$2,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.color?.withValues(alpha: .40),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Staggered dots loader
// ═══════════════════════════════════════════════════════════════════════════

class _DotsLoader extends StatefulWidget {
  final Color color;
  const _DotsLoader({required this.color});

  @override
  State<_DotsLoader> createState() => _DotsLoaderState();
}

class _DotsLoaderState extends State<_DotsLoader>
    with TickerProviderStateMixin {
  late final List<AnimationController> _ctrls;
  late final List<Animation<double>> _anims;

  @override
  void initState() {
    super.initState();
    _ctrls = List.generate(
      3,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      ),
    );
    _anims = _ctrls
        .map(
          (c) => Tween<double>(
            begin: .25,
            end: 1.0,
          ).animate(CurvedAnimation(parent: c, curve: Curves.easeInOut)),
        )
        .toList();

    for (int i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 160), () {
        if (mounted) _ctrls[i].repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    for (final c in _ctrls) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        return Padding(
          padding: EdgeInsets.only(left: i == 0 ? 0 : 8),
          child: FadeTransition(
            opacity: _anims[i],
            child: Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.color,
              ),
            ),
          ),
        );
      }),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Background circle
// ═══════════════════════════════════════════════════════════════════════════

class _BgCircle extends StatelessWidget {
  final double size;
  final Color color;
  const _BgCircle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
