import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:homeease/core/theme/app_theme.dart';
import 'package:homeease/models/user_model.dart';
import 'package:homeease/presentation/customer_drawer/bloc/customer_drawer_bloc.dart';
import 'package:homeease/presentation/customer_drawer/bloc/customer_drawer_event.dart';
import 'package:homeease/presentation/customer_drawer/bloc/customer_drawer_state.dart';
import 'package:homeease/presentation/customer_drawer/models/customer_drawer_route.dart';
import 'package:homeease/presentation/customer_drawer/models/customer_history_drawer_intent.dart';
import 'package:homeease/presentation/customer_drawer/widgets/customer_drawer_header.dart';
import 'package:homeease/presentation/customer_drawer/widgets/customer_drawer_tile.dart';
import 'package:homeease/presentation/navbar/bloc/navbar_bloc.dart';
import 'package:homeease/presentation/navbar/bloc/navbar_event.dart';
import 'package:homeease/presentation/navbar/bloc/navbar_state.dart';
import 'package:homeease/presentation/profile/bloc/profile_bloc.dart';
import 'package:homeease/presentation/profile/bloc/profile_event.dart';
import 'package:homeease/presentation/profile/edit_profile_screen.dart';
import 'package:homeease/repositories/user_repository.dart';
import 'package:homeease/routes/route_names.dart';
import 'package:homeease/widgets/dialogs/logout_dialog.dart';

class CustomerAppDrawer extends StatefulWidget {
  const CustomerAppDrawer({super.key});

  @override
  State<CustomerAppDrawer> createState() => _CustomerAppDrawerState();
}

class _CustomerAppDrawerState extends State<CustomerAppDrawer> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final profileBloc = context.read<ProfileBloc>();
      if (profileBloc.state.user == null) {
        profileBloc.add(LoadProfile());
      }
      context.read<CustomerDrawerBloc>().add(const LoadCustomerDrawerData());
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userRepo = context.read<UserRepository>();

    return Drawer(
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            StreamBuilder<UserModel?>(
              stream: userRepo.userStream,
              initialData: userRepo.currentUser,
              builder: (context, snapshot) {
                final user = snapshot.data ?? userRepo.currentUser;
                return CustomerDrawerHeader(
                  user: user,
                  onEditProfile: () => _openEditProfile(context),
                );
              },
            ),
            Expanded(
              child: BlocBuilder<CustomerDrawerBloc, CustomerDrawerState>(
                builder: (context, drawerState) {
                  return BlocBuilder<NavbarBloc, NavbarState>(
                    builder: (context, navState) {
                      final active = navState.activeDrawerRoute;

                      return ListView(
                        padding: const EdgeInsets.only(bottom: 8),
                        children: [
                          CustomerDrawerPendingInvoiceCard(
                            count: drawerState.pendingInvoiceCount,
                            onViewInvoice: () => _navigate(
                              context,
                              tabIndex: 2,
                              route: CustomerDrawerRoute.payments,
                              historyIntent:
                                  CustomerHistoryDrawerIntent.pendingInvoices,
                            ),
                          ),
                          const CustomerDrawerSectionTitle(title: 'Main'),
                          CustomerDrawerTile(
                            icon: Icons.home_outlined,
                            label: 'Home',
                            isActive: active == CustomerDrawerRoute.home,
                            onTap: () => _navigate(
                              context,
                              tabIndex: 0,
                              route: CustomerDrawerRoute.home,
                            ),
                          ),
                          CustomerDrawerTile(
                            icon: Icons.grid_view_rounded,
                            label: 'Services',
                            isActive: active == CustomerDrawerRoute.services,
                            onTap: () => _navigate(
                              context,
                              tabIndex: 0,
                              route: CustomerDrawerRoute.services,
                            ),
                          ),
                          CustomerDrawerTile(
                            icon: Icons.flash_on_outlined,
                            label: 'Instant Booking',
                            isActive:
                                active == CustomerDrawerRoute.instantBooking,
                            onTap: () => _navigate(
                              context,
                              tabIndex: 1,
                              route: CustomerDrawerRoute.instantBooking,
                            ),
                          ),
                          CustomerDrawerTile(
                            icon: Icons.event_available_outlined,
                            label: 'Scheduled Booking',
                            isActive:
                                active == CustomerDrawerRoute.scheduledBooking,
                            onTap: () => _navigate(
                              context,
                              tabIndex: 0,
                              route: CustomerDrawerRoute.scheduledBooking,
                            ),
                          ),
                          CustomerDrawerTile(
                            icon: Icons.assignment_outlined,
                            label: 'My Requests',
                            isActive: active == CustomerDrawerRoute.myRequests,
                            onTap: () => _navigate(
                              context,
                              tabIndex: 1,
                              route: CustomerDrawerRoute.myRequests,
                            ),
                          ),
                          const CustomerDrawerSectionTitle(title: 'History'),
                          CustomerDrawerTile(
                            icon: Icons.calendar_month_outlined,
                            label: 'Scheduled History',
                            isActive:
                                active == CustomerDrawerRoute.scheduledHistory,
                            onTap: () => _navigate(
                              context,
                              tabIndex: 2,
                              route: CustomerDrawerRoute.scheduledHistory,
                              historyIntent:
                                  CustomerHistoryDrawerIntent.scheduledHistory,
                            ),
                          ),
                          CustomerDrawerTile(
                            icon: Icons.bolt_outlined,
                            label: 'Instant Orders',
                            isActive:
                                active == CustomerDrawerRoute.instantOrders,
                            onTap: () => _navigate(
                              context,
                              tabIndex: 2,
                              route: CustomerDrawerRoute.instantOrders,
                              historyIntent:
                                  CustomerHistoryDrawerIntent.instantOrders,
                            ),
                          ),
                          CustomerDrawerTile(
                            icon: Icons.receipt_long_outlined,
                            label: 'Payments / Invoices',
                            isActive: active == CustomerDrawerRoute.payments,
                            badgeCount: drawerState.pendingInvoiceCount,
                            onTap: () => _navigate(
                              context,
                              tabIndex: 2,
                              route: CustomerDrawerRoute.payments,
                              historyIntent:
                                  CustomerHistoryDrawerIntent.pendingInvoices,
                            ),
                          ),
                          CustomerDrawerTile(
                            icon: Icons.star_outline_rounded,
                            label: 'Reviews',
                            isActive: active == CustomerDrawerRoute.reviews,
                            onTap: () => _navigate(
                              context,
                              tabIndex: 2,
                              route: CustomerDrawerRoute.reviews,
                              historyIntent:
                                  CustomerHistoryDrawerIntent.reviews,
                            ),
                          ),
                          const CustomerDrawerSectionTitle(title: 'Account'),
                          CustomerDrawerTile(
                            icon: Icons.person_outline_rounded,
                            label: 'Profile',
                            isActive: active == CustomerDrawerRoute.profile,
                            onTap: () => _navigate(
                              context,
                              tabIndex: 3,
                              route: CustomerDrawerRoute.profile,
                            ),
                          ),
                          CustomerDrawerTile(
                            icon: Icons.notifications_none_rounded,
                            label: 'Notifications',
                            isActive:
                                active == CustomerDrawerRoute.notifications,
                            badgeCount: drawerState.unreadNotificationCount,
                            onTap: () => _navigate(
                              context,
                              tabIndex: 3,
                              route: CustomerDrawerRoute.notifications,
                            ),
                          ),
                          CustomerDrawerTile(
                            icon: Icons.settings_outlined,
                            label: 'Settings',
                            isActive: active == CustomerDrawerRoute.settings,
                            onTap: () => _navigate(
                              context,
                              tabIndex: 3,
                              route: CustomerDrawerRoute.settings,
                            ),
                          ),
                          CustomerDrawerTile(
                            icon: Icons.help_outline_rounded,
                            label: 'Help & Support',
                            isActive: active == CustomerDrawerRoute.helpSupport,
                            onTap: () {
                              Navigator.pop(context);
                              context.read<NavbarBloc>().add(
                                    NavigateFromDrawerEvent(
                                      tabIndex: navState.selectedIndex,
                                      route: CustomerDrawerRoute.helpSupport,
                                    ),
                                  );
                              Navigator.pushNamed(context, RouteNames.faqs);
                            },
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
            _LogoutTile(onTap: () => _showLogoutDialog(context)),
          ],
        ),
      ),
    );
  }

  void _navigate(
    BuildContext context, {
    required int tabIndex,
    required CustomerDrawerRoute route,
    CustomerHistoryDrawerIntent? historyIntent,
  }) {
    final navbar = context.read<NavbarBloc>();
    final current = navbar.state;

    final isDuplicate = current.selectedIndex == tabIndex &&
        current.activeDrawerRoute == route &&
        historyIntent == null;

    Navigator.pop(context);

    if (isDuplicate) return;

    navbar.add(
      NavigateFromDrawerEvent(
        tabIndex: tabIndex,
        route: route,
        historyIntent: historyIntent,
      ),
    );

    if (route == CustomerDrawerRoute.scheduledBooking ||
        route == CustomerDrawerRoute.services) {
      _showBookingHint(context, route);
    }
  }

  void _showBookingHint(BuildContext context, CustomerDrawerRoute route) {
    final message = route == CustomerDrawerRoute.scheduledBooking
        ? 'Select a service from Home to book a scheduled visit.'
        : 'Browse categories and services on Home.';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _openEditProfile(BuildContext context) {
    Navigator.pop(context);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(
          value: context.read<ProfileBloc>(),
          child: const EditProfileScreen(),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    Navigator.pop(context);
    showDialog<void>(
      context: context,
      builder: (_) => const LogoutDialog(),
    );
  }
}

class _LogoutTile extends StatelessWidget {
  final VoidCallback onTap;

  const _LogoutTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: CustomerDrawerTile(
        icon: Icons.logout_rounded,
        label: 'Logout',
        isActive: false,
        iconColor: AppTheme.errorColor,
        textColor: AppTheme.errorColor,
        onTap: onTap,
      ),
    );
  }
}
