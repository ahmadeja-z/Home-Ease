import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:homeease/core/theme/app_theme.dart';
import 'package:homeease/core/theme/theme_bloc/theme_bloc.dart';
import 'package:homeease/core/theme/theme_bloc/theme_event.dart';
import 'package:homeease/core/theme/theme_bloc/theme_state.dart';
import 'package:homeease/core/utils/labels.dart';
import 'package:homeease/models/user_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:homeease/presentation/profile/bloc/profile_bloc.dart';
import 'package:homeease/presentation/profile/bloc/profile_state.dart';
import 'package:homeease/presentation/profile/edit_profile_screen.dart';
import 'package:homeease/repositories/user_repository.dart';
import 'package:homeease/routes/route_names.dart';
import 'package:homeease/presentation/languages/bloc/languages_bloc.dart';
import 'package:homeease/presentation/languages/bloc/languages_state.dart';
import 'package:homeease/models/languages_model.dart';
import 'package:homeease/widgets/dialogs/logout_dialog.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: BlocBuilder<ProfileBloc, ProfileState>(
          builder: (context, state) {
            final UserModel user = context.read<UserRepository>().currentUser!;

            return FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 12),
                            _buildHeroCard(isDark, user),

                            const SizedBox(height: 28),
                            _buildSectionLabel(Labels.settings),
                            const SizedBox(height: 12),
                            _buildSettingsGroup(isDark),
                            const SizedBox(height: 20),
                            _buildLogoutTile(),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // HERO CARD
  // ─────────────────────────────────────────────
  Widget _buildHeroCard(bool isDark, UserModel user) {
    final primary = Theme.of(context).colorScheme.primary;
    final secondary = Theme.of(context).colorScheme.secondary;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(22, 28, 22, 22),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                primary.withValues(alpha: 1.0),
                primary.withValues(alpha: 0.88),
                secondary,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: primary.withValues(alpha: 0.38),
                blurRadius: 36,
                spreadRadius: -6,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildAvatar(user),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name ?? 'Guest User',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 20,
                                letterSpacing: -0.3,
                                height: 1.2,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        _buildInfoChip(
                          Icons.mail_outline_rounded,
                          user.email ?? 'guest@homeease.com',
                        ),
                        const SizedBox(height: 5),
                        _buildInfoChip(
                          Icons.phone_outlined,
                          user.phoneNumber ?? '0300-0000000',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Decorative orb top-right
        Positioned(
          top: -16,
          right: -16,
          child: IgnorePointer(
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.1),
                    Colors.white.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Edit pill button
        Positioned(
          top: 14,
          right: 14,
          child: GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => BlocProvider.value(
                    value: context.read<ProfileBloc>(),
                    child: const EditProfileScreen(),
                  ),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.28),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.edit_rounded, color: Colors.white, size: 12),
                  const SizedBox(width: 4),
                  Text(
                    Labels.edit,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAvatar(UserModel user) {
    return Stack(
      children: [
        Container(
          width: 82,
          height: 82,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: SweepGradient(
              colors: [
                Colors.white.withValues(alpha: 0.7),
                Colors.white.withValues(alpha: 0.12),
                Colors.white.withValues(alpha: 0.7),
              ],
            ),
          ),
          padding: const EdgeInsets.all(2.5),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).colorScheme.primary,
            ),
            child: ClipOval(
              child: user.profileImage != null && user.profileImage!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: user.profileImage!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => _defaultAvatarChild(),
                      errorWidget: (_, __, ___) => _defaultAvatarChild(),
                    )
                  : _defaultAvatarChild(),
            ),
          ),
        ),
        // Online dot
        Positioned(
          bottom: 3,
          right: 3,
          child: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: const Color(0xFF4ADE80),
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4ADE80).withValues(alpha: 0.5),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _defaultAvatarChild() =>
      const Icon(Icons.person_rounded, size: 46, color: Colors.white);

  Widget _buildInfoChip(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.65), size: 13),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 12,
              letterSpacing: 0.1,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // MEMBERSHIP BADGE
  // ─────────────────────────────────────────────
  // Widget _buildMembershipBadge(ThemeData theme) {
  //   final isDark =Theme.of(context).brightness == Brightness.dark;
  //   return Container(
  //     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  //     decoration: BoxDecoration(
  //       color:Theme.of(context).cardTheme.color,
  //       borderRadius: BorderRadius.circular(20),
  //       border: Border.all(
  //         color: const Color(0xFFF5A623).withValues(alpha: 0.3),
  //         width: 1,
  //       ),
  //       boxShadow: [
  //         BoxShadow(
  //           color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.05),
  //           blurRadius: 12,
  //           offset: const Offset(0, 4),
  //         ),
  //       ],
  //     ),
  //     child: Row(
  //       children: [
  //         Container(
  //           width: 42,
  //           height: 42,
  //           decoration: BoxDecoration(
  //             borderRadius: BorderRadius.circular(13),
  //             gradient: const LinearGradient(
  //               colors: [Color(0xFFF7B844), Color(0xFFF5A623)],
  //               begin: Alignment.topLeft,
  //               end: Alignment.bottomRight,
  //             ),
  //             boxShadow: [
  //               BoxShadow(
  //                 color: const Color(0xFFF5A623).withValues(alpha: 0.35),
  //                 blurRadius: 10,
  //                 offset: const Offset(0, 4),
  //               ),
  //             ],
  //           ),
  //           child: const Icon(
  //             Icons.star_rounded,
  //             color: Colors.white,
  //             size: 20,
  //           ),
  //         ),
  //         const SizedBox(width: 12),
  //         Expanded(
  //           child: Column(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               Text(
  //                 'Gold Member',
  //                 style:Theme.of(context).textTheme.titleSmall?.copyWith(
  //                   fontWeight: FontWeight.w700,
  //                   fontSize: 13,
  //                 ),
  //               ),
  //               const SizedBox(height: 2),
  //               Text(
  //                 'Exclusive perks & priority support',
  //                 style:Theme.of(context).textTheme.bodySmall?.copyWith(
  //                   color:
  //                      Theme.of(context).textTheme.bodySmall?.color?.withValues(
  //                         alpha: 0.6,
  //                       ) ??
  //                       Colors.grey,
  //                   fontSize: 11,
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //         Icon(
  //           Icons.chevron_right_rounded,
  //           color:Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
  //           size: 20,
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // ─────────────────────────────────────────────
  // SECTION LABEL
  // ─────────────────────────────────────────────
  Widget _buildSectionLabel(String label) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 18,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // SETTINGS GROUP (all tiles in one card)
  // ─────────────────────────────────────────────
  Widget _buildSettingsGroup(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onPrimary,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Theme.of(
              context,
            ).colorScheme.onSecondary.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildTile(
            icon: Icons.language_rounded,
            title: Labels.appLanguage,
            isFirst: true,
            onTap: () => Navigator.pushNamed(context, RouteNames.language),
            valueWidget: BlocBuilder<LanguageBloc, LanguageState>(
              builder: (context, state) {
                final languageName = _getLanguageName(state.currentLocale);
                return Text(
                  languageName,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color:
                        Theme.of(
                          context,
                        ).textTheme.bodySmall?.color?.withValues(alpha: 0.55) ??
                        Colors.grey,
                    fontSize: 12,
                  ),
                );
              },
            ),
          ),
          _buildDivider(),
          _buildTile(
            icon: Icons.help_outline_rounded,
            title: Labels.helpAndSupport,
            onTap: () => Navigator.pushNamed(context, RouteNames.faqs),
          ),
          _buildDivider(),
          _buildThemeTileGrouped(isDark),
          _buildDivider(),
          _buildTile(
            icon: Icons.lock_outline_rounded,
            title: Labels.changePassword,
            onTap: () =>
                Navigator.pushNamed(context, RouteNames.changePassword),
          ),
          _buildDivider(),
          _buildNotificationTile(),
          _buildDivider(),
          _buildTile(
            icon: Icons.info_outline_rounded,
            title: Labels.about,
            isLast: true,
            onTap: () => Navigator.pushNamed(context, RouteNames.about),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 0.8,
      indent: 60,
      endIndent: 16,
      color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
    );
  }

  Widget _buildTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    String? value,
    Widget? valueWidget,
    Widget? trailing,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.vertical(
        top: isFirst ? const Radius.circular(22) : Radius.zero,
        bottom: isLast ? const Radius.circular(22) : Radius.zero,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.vertical(
          top: isFirst ? const Radius.circular(22) : Radius.zero,
          bottom: isLast ? const Radius.circular(22) : Radius.zero,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  icon,
                  color: Theme.of(context).colorScheme.primary,
                  size: 19,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSecondary,
                    fontSize: 14,
                  ),
                ),
              ),
              if (valueWidget != null) ...[
                valueWidget,
                const SizedBox(width: 4),
              ] else if (value != null) ...[
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color:
                        Theme.of(
                          context,
                        ).textTheme.bodySmall?.color?.withValues(alpha: 0.55) ??
                        Colors.grey,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 4),
              ],
              trailing ??
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.45),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemeTileGrouped(bool isDark) {
    return BlocBuilder<ThemeBloc, ThemeState>(
      builder: (context, state) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                  color: Theme.of(context).colorScheme.primary,
                  size: 19,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  Labels.theme,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSecondary,
                  ),
                ),
              ),
              Switch.adaptive(
                value: isDark,
                activeColor: Theme.of(context).colorScheme.primary,
                onChanged: (val) {
                  context.read<ThemeBloc>().add(
                    SwitchThemeEvent(
                      val ? AppThemeMode.dark : AppThemeMode.light,
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNotificationTile() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              Icons.notifications_none_rounded,
              color: Theme.of(context).colorScheme.primary,
              size: 19,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              Labels.notifications,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSecondary,
              ),
            ),
          ),
          Switch.adaptive(
            value: true,
            activeColor: Theme.of(context).colorScheme.primary,
            onChanged: (val) {
              // TODO: Toggle notifications
            },
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // LOGOUT
  // ─────────────────────────────────────────────
  Widget _buildLogoutTile() {
    final error = Theme.of(context).colorScheme.error;
    return Material(
      color: error.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () => _showLogoutDialog(context),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: error.withValues(alpha: 0.22), width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.logout_rounded, color: error, size: 20),
              ),
              const SizedBox(width: 14),
              Text(
                Labels.logout,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: error,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.chevron_right_rounded,
                color: error.withValues(alpha: 0.5),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // DIALOGS
  // ─────────────────────────────────────────────
  void _showLogoutDialog(BuildContext context) {
    showDialog(context: context, builder: (context) => const LogoutDialog());
  }

  // ─────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────
  String _getLanguageName(Locale locale) {
    // Get the language name from the LanguagesList
    final languagesList = _LanguagesList();
    final language = languagesList.languages.firstWhere(
      (lang) =>
          lang.locale.languageCode == locale.languageCode &&
          (lang.locale.countryCode ?? '') == (locale.countryCode ?? ''),
      orElse: () => LanguageModel(
        locale: locale,
        englishName: locale.languageCode.toUpperCase(),
        localName: locale.languageCode.toUpperCase(),
        flag: '',
      ),
    );

    return language.englishName;
  }
}

// ─────────────────────────────────────────────
// LANGUAGES LIST (copied from languages_screen)
// ─────────────────────────────────────────────
class _LanguagesList {
  final List<LanguageModel> _languages = [
    LanguageModel(
      locale: const Locale('en'),
      englishName: "English",
      localName: "English",
      flag: "assets/images/united-states-of-america.png",
    ),
    LanguageModel(
      locale: const Locale('ar'),
      englishName: "Arabic",
      localName: "العربية",
      flag: "assets/images/united-arab-emirates.png",
    ),
    LanguageModel(
      locale: const Locale('es'),
      englishName: "Spanish",
      localName: "Español",
      flag: "assets/images/spain.png",
    ),
    LanguageModel(
      locale: const Locale('fr'),
      englishName: "French (France)",
      localName: "Français - France",
      flag: "assets/images/france.png",
    ),
    LanguageModel(
      locale: const Locale('fr', 'CA'),
      englishName: "French (Canada)",
      localName: "Français - Canadien",
      flag: "assets/images/canada.png",
    ),
    LanguageModel(
      locale: const Locale('pt', 'BR'),
      englishName: "Portuguese (Brazil)",
      localName: "Português - Brasil",
      flag: "assets/images/brazil.png",
    ),
    LanguageModel(
      locale: const Locale('ko'),
      englishName: "Korean",
      localName: "한국어",
      flag: "assets/images/united-states-of-america.png",
    ),
  ];

  List<LanguageModel> get languages => _languages;
}
