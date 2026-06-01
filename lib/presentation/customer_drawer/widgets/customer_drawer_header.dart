import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:homeease/core/theme/app_theme.dart';
import 'package:homeease/models/user_model.dart';

class CustomerDrawerHeader extends StatelessWidget {
  final UserModel? user;
  final VoidCallback? onEditProfile;

  const CustomerDrawerHeader({
    super.key,
    required this.user,
    this.onEditProfile,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  AppTheme.mainDarkColor,
                  cs.primary.withValues(alpha: 0.85),
                  AppTheme.secondDarkColor,
                ]
              : [
                  AppTheme.mainColor,
                  AppTheme.mainColor.withValues(alpha: 0.92),
                  AppTheme.secondColor,
                ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 16, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Avatar(user: user),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _displayName(user),
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        if (_contactLine(user).isNotEmpty)
                          Text(
                            _contactLine(user),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.88),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        if (_addressLine(user).isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 13,
                                color: Colors.white.withValues(alpha: 0.75),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  _addressLine(user),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.78),
                                    fontSize: 11,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            _StatusChip(
                              label: _statusLabel(user),
                              color: _statusColor(user),
                            ),
                            if (_isVerified(user))
                              _StatusChip(
                                label: 'Verified',
                                color: AppTheme.successColor,
                                icon: Icons.verified_rounded,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (onEditProfile != null)
                    IconButton(
                      onPressed: onEditProfile,
                      icon: Icon(
                        Icons.edit_outlined,
                        color: Colors.white.withValues(alpha: 0.9),
                        size: 20,
                      ),
                      tooltip: 'Edit profile',
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _displayName(UserModel? user) {
    final name = user?.name?.trim();
    if (name != null && name.isNotEmpty) return name;
    return 'Guest User';
  }

  String _contactLine(UserModel? user) {
    final email = user?.email?.trim();
    if (email != null && email.isNotEmpty) return email;
    final phone = user?.phoneNumber?.trim();
    if (phone != null && phone.isNotEmpty) return phone;
    return '';
  }

  String _addressLine(UserModel? user) {
    return user?.address?.address?.trim() ?? '';
  }

  String _statusLabel(UserModel? user) {
    if (user?.isActive == false) return 'Blocked';
    final status = user?.status?.toLowerCase().trim();
    switch (status) {
      case 'approved':
        return 'Approved';
      case 'pending':
        return 'Pending';
      case 'blocked':
      case 'suspended':
        return 'Blocked';
      default:
        return status != null && status.isNotEmpty
            ? status[0].toUpperCase() + status.substring(1)
            : 'Pending';
    }
  }

  Color _statusColor(UserModel? user) {
    if (user?.isActive == false) return AppTheme.errorColor;
    final status = user?.status?.toLowerCase();
    if (status == 'approved') return AppTheme.successColor;
    if (status == 'blocked' || status == 'suspended') {
      return AppTheme.errorColor;
    }
    return AppTheme.warningColor;
  }

  bool _isVerified(UserModel? user) {
    final v = user?.verification?.toLowerCase().trim();
    return v == 'verified' || v == 'approved' || v == 'true';
  }
}

class _Avatar extends StatelessWidget {
  final UserModel? user;

  const _Avatar({required this.user});

  @override
  Widget build(BuildContext context) {
    final imageUrl = user?.profileImage?.trim();

    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.35),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(
        child: imageUrl != null && imageUrl.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => _placeholder(),
                errorWidget: (_, __, ___) => _placeholder(),
              )
            : _placeholder(),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: Colors.white.withValues(alpha: 0.15),
      child: Icon(
        Icons.person_rounded,
        size: 32,
        color: Colors.white.withValues(alpha: 0.9),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const _StatusChip({
    required this.label,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: Colors.white),
            const SizedBox(width: 4),
          ] else
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          if (icon == null) const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
