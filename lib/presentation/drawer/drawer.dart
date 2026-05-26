import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:homeease/core/theme/app_theme.dart';
import 'package:homeease/core/theme/theme_bloc/theme_bloc.dart';
import 'package:homeease/core/theme/theme_bloc/theme_event.dart';
import 'package:homeease/core/theme/theme_bloc/theme_state.dart';
import 'package:homeease/core/utils/labels.dart';
import 'package:homeease/models/user_model.dart';
import 'package:homeease/presentation/navbar/bloc/navbar_bloc.dart';
import 'package:homeease/presentation/navbar/bloc/navbar_event.dart';
import 'package:homeease/presentation/profile/edit_profile_screen.dart';
import 'package:homeease/repositories/user_repository.dart';
import 'package:homeease/widgets/dialogs/logout_dialog.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Drawer(
      backgroundColor: theme.scaffoldBackgroundColor,
      child: SafeArea(
        child: Column(
          children: [
            // Header Section - Reactive to user changes
            StreamBuilder<UserModel?>(
              stream: UserRepository().userStream,
              initialData: UserRepository().currentUser,
              builder: (context, snapshot) {
                final user = snapshot.data;
                return _buildDrawerHeader(context, user);
              },
            ),

            const Divider(height: 1),

            // Navigation Items
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildNavItem(
                    context: context,
                    icon: Icons.home_outlined,
                    title: 'Home',
                    onTap: () => _navigateToTab(context, 0),
                  ),
                  _buildNavItem(
                    context: context,
                    icon: Icons.description_outlined,
                    title: 'Requests',
                    onTap: () => _navigateToTab(context, 1),
                  ),
                  _buildNavItem(
                    context: context,
                    icon: Icons.timeline_outlined,
                    title: 'Activities',
                    onTap: () => _navigateToTab(context, 2),
                  ),
                  _buildNavItem(
                    context: context,
                    icon: Icons.person_outline_rounded,
                    title: 'Profile',
                    onTap: () => _navigateToTab(context, 3),
                  ),

                  const Divider(height: 32, indent: 16, endIndent: 16),

                  // Theme Toggle
                  BlocBuilder<ThemeBloc, ThemeState>(
                    builder: (context, themeState) {
                      return _buildNavItem(
                        context: context,
                        icon: themeState.themeMode == AppThemeMode.dark
                            ? Icons.light_mode
                            : Icons.dark_mode,
                        title: themeState.themeMode == AppThemeMode.dark
                            ? Labels.lightMode
                            : Labels.darkMode,
                        trailing: Switch(
                          value: themeState.themeMode == AppThemeMode.dark,
                          onChanged: (value) {
                            context.read<ThemeBloc>().add(
                              SwitchThemeEvent(
                                value ? AppThemeMode.dark : AppThemeMode.light,
                              ),
                            );
                          },
                        ),
                        onTap: () {
                          context.read<ThemeBloc>().add(
                            SwitchThemeEvent(
                              themeState.themeMode == AppThemeMode.dark
                                  ? AppThemeMode.light
                                  : AppThemeMode.dark,
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),

            // Logout Button
            _buildLogoutSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerHeader(BuildContext context, UserModel? user) {
    return DrawerHeader(
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Profile Picture with fallback
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                backgroundImage:
                    user?.profileImage != null && user!.profileImage!.isNotEmpty
                    ? CachedNetworkImageProvider(user.profileImage!)
                    : null,
                child: user?.profileImage == null || user!.profileImage!.isEmpty
                    ? Icon(
                        Icons.person,
                        size: 36,
                        color: Colors.white.withValues(alpha: 0.9),
                      )
                    : null,
              ),

              // User Name
              Column(
                children: [
                  Text(
                    user?.name ?? "Guest User",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSecondary,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // User Email or Phone
                  Text(
                    user?.email ?? user?.phoneNumber ?? "Not logged in",
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EditProfileScreen(),
                    ),
                  );
                },
                icon: Icon(
                  Icons.edit_outlined,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListTile(
      leading: Icon(icon, color: colorScheme.primary, size: 24),
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
      ),
      trailing: trailing,
      onTap: () {
        onTap();
        Navigator.pop(context); // Close drawer
      },
    );
  }

  Widget _buildLogoutSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        border: Border(
          top: BorderSide(color: Colors.red.withValues(alpha: 0.3), width: 1),
        ),
      ),
      child: ListTile(
        leading: Icon(Icons.logout_rounded, color: Colors.red, size: 24),
        title: Text(
          Labels.logout,
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
        ),
        onTap: () {
          // Show logout confirmation dialog
          showDialog(
            context: context,
            builder: (dialogContext) => LogoutDialog(),
          );
        },
      ),
    );
  }

  void _navigateToTab(BuildContext context, int index) {
    context.read<NavbarBloc>().add(ChangeTabEvent(index));
  }
}
