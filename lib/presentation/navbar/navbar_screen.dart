import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:homeease/core/assets/app_images.dart';
import 'package:homeease/presentation/drawer/drawer.dart';
import 'package:homeease/presentation/home/home_screen.dart';
import 'package:homeease/presentation/profile/profile_screen.dart';
import '../map_requests/map_requests_screen.dart';
import 'bloc/navbar_bloc.dart';
import 'bloc/navbar_event.dart';
import 'bloc/navbar_state.dart';
import 'screens/activities_tab_screen.dart';

class NavbarScreen extends StatelessWidget {
  const NavbarScreen({super.key});

  static const List<Widget> _screens = [
    HomeScreen(),
    MapRequestsScreen(),
    ActivitiesTabScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => NavbarBloc(),
      child: NavbarView(screens: _screens),
    );
  }
}

class NavbarView extends StatelessWidget {
  final List<Widget> screens;
  const NavbarView({super.key, required this.screens});

  static const List<String> screenTitles = [
    'Home',
    'Requests',
    'History',
    'Profile',
  ];
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: BlocBuilder<NavbarBloc, NavbarState>(
          builder: (context, state) {
            return state.selectedIndex == 0
                ? Image.asset(
                    isDark
                        ? AppImages.homeEaseDarkLogo
                        : AppImages.homeEaseLogo,
                    height: 50,
                    fit: BoxFit.contain,
                  )
                : Text(
                    screenTitles[state.selectedIndex],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSecondary,
                    ),
                  );
          },
        ),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.onPrimary,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(
              Icons.menu_rounded,
              color: Theme.of(context).colorScheme.onSecondary,
            ),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: const AppDrawer(),

      extendBody:
          true, // allows body to go behind the nav bar for glassmorphism
      body: BlocBuilder<NavbarBloc, NavbarState>(
        builder: (context, state) {
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeInOut,
                ),
                child: SlideTransition(
                  position:
                      Tween<Offset>(
                        begin: const Offset(0.04, 0),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutCubic,
                        ),
                      ),
                  child: child,
                ),
              );
            },
            child: KeyedSubtree(
              key: ValueKey(state.selectedIndex),
              child: screens[state.selectedIndex],
            ),
          );
        },
      ),
      bottomNavigationBar: BlocBuilder<NavbarBloc, NavbarState>(
        builder: (context, state) {
          return PremiumNavBar(
            selectedIndex: state.selectedIndex,
            onTabSelected: (index) {
              HapticFeedback.lightImpact();
              context.read<NavbarBloc>().add(ChangeTabEvent(index));
            },
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Premium Nav Bar Widget
// ─────────────────────────────────────────────

class PremiumNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  const PremiumNavBar({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  static const _items = [
    _NavItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Home',
    ),
    _NavItem(
      icon: Icons.description_outlined,
      activeIcon: Icons.description_rounded,
      label: 'Requests',
    ),
    _NavItem(
      icon: Icons.timeline_outlined,
      activeIcon: Icons.timeline_rounded,
      label: 'Activities',
    ),
    _NavItem(
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      margin: EdgeInsets.only(left: 16, right: 16, bottom: bottomPadding + 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.surface.withOpacity(0.92),
            colorScheme.surfaceContainerHighest.withOpacity(0.88),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.18),
            blurRadius: 32,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(
              _items.length,
              (index) => _NavBarItem(
                item: _items[index],
                isSelected: selectedIndex == index,
                onTap: () => onTabSelected(index),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Individual Nav Item
// ─────────────────────────────────────────────

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

class _NavBarItem extends StatefulWidget {
  final _NavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavBarItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_NavBarItem> createState() => _NavBarItemState();
}

class _NavBarItemState extends State<_NavBarItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _scaleAnim = Tween<double>(
      begin: 1.0,
      end: 1.12,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
    _glowAnim = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    if (widget.isSelected) _controller.forward();
  }

  @override
  void didUpdateWidget(_NavBarItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected != oldWidget.isSelected) {
      if (widget.isSelected) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return SizedBox(
            width: 72,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: widget.isSelected
                        ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [colorScheme.primary, colorScheme.primary],
                          )
                        : null,
                    boxShadow: widget.isSelected
                        ? [
                            BoxShadow(
                              color: colorScheme.primary.withValues(
                                alpha: 0.45 * _glowAnim.value,
                              ),
                              blurRadius: 14,
                              spreadRadius: 1,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: ScaleTransition(
                    scale: _scaleAnim,
                    child: Icon(
                      widget.isSelected
                          ? widget.item.activeIcon
                          : widget.item.icon,
                      size: 22,
                      color: widget.isSelected
                          ? Colors.white
                          : colorScheme.onSecondary.withValues(alpha: .5),
                    ),
                  ),
                ),

                const SizedBox(height: 4),

                // Animated label
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 250),
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: widget.isSelected
                        ? FontWeight.w700
                        : FontWeight.w500,
                    letterSpacing: widget.isSelected ? 0.3 : 0,
                    color: widget.isSelected
                        ? colorScheme.onSecondary
                        : colorScheme.onSecondary.withValues(alpha: .5),
                  ),
                  child: Text(widget.item.label),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
