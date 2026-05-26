import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0D0F14)
          : const Color(0xFFF5F7FA),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(context, theme, isDark),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 28),
                  _buildMissionCard(theme, isDark),
                  const SizedBox(height: 24),
                  _buildSectionLabel(theme, 'Our Services'),
                  const SizedBox(height: 14),
                  _buildServicesGrid(theme, isDark),
                  const SizedBox(height: 24),
                  _buildSectionLabel(theme, 'Why HomeEase'),
                  const SizedBox(height: 14),
                  _buildWhyUsColumn(theme, isDark),
                  const SizedBox(height: 24),
                  _buildSectionLabel(theme, 'By The Numbers'),
                  const SizedBox(height: 14),
                  _buildStatsRow(theme, isDark),
                  const SizedBox(height: 24),
                  _buildTeamCard(theme, isDark),
                  const SizedBox(height: 24),
                  _buildVersionBadge(theme, isDark),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Sliver App Bar ───────────────────────────────────────────────────────

  Widget _buildSliverAppBar(
    BuildContext context,
    ThemeData theme,
    bool isDark,
  ) {
    return SliverAppBar(
      expandedHeight: 260,
      pinned: true,
      backgroundColor: isDark
          ? const Color(0xFF0D0F14)
          : const Color(0xFFF5F7FA),
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 16,
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Gradient backdrop
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withValues(alpha: 0.8),
                    const Color(0xFF1A2340),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
            // Decorative circles
            Positioned(
              top: -40,
              right: -40,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
            Positioned(
              bottom: -20,
              left: -30,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.04),
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 80, 24, 28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App icon
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.home_repair_service_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'HomeEase',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your trusted home service partner',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Section Label ────────────────────────────────────────────────────────

  Widget _buildSectionLabel(ThemeData theme, String label) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontSize: 17,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }

  // ─── Mission Card ─────────────────────────────────────────────────────────

  Widget _buildMissionCard(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: _cardDecoration(theme, isDark),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.primary.withValues(alpha: 0.6),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.flag_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Our Mission',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'HomeEase connects homeowners with skilled, vetted professionals for every home service need — fast, reliable, and hassle-free.',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    fontSize: 13.5,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Services Grid ────────────────────────────────────────────────────────

  Widget _buildServicesGrid(ThemeData theme, bool isDark) {
    final services = [
      _ServiceItem(
        Icons.electrical_services_rounded,
        'Electrical',
        const Color(0xFFFFB300),
      ),
      _ServiceItem(Icons.plumbing_rounded, 'Plumbing', const Color(0xFF29B6F6)),
      _ServiceItem(
        Icons.cleaning_services_rounded,
        'Cleaning',
        const Color(0xFF66BB6A),
      ),
      _ServiceItem(
        Icons.carpenter_rounded,
        'Carpentry',
        const Color(0xFFFF7043),
      ),
      _ServiceItem(Icons.ac_unit_rounded, 'AC Repair', const Color(0xFF42A5F5)),
      _ServiceItem(
        Icons.format_paint_rounded,
        'Painting',
        const Color(0xFFAB47BC),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: services.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.95,
      ),
      itemBuilder: (context, index) {
        final s = services[index];
        return _buildServiceTile(s, theme, isDark);
      },
    );
  }

  Widget _buildServiceTile(_ServiceItem s, ThemeData theme, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161A24) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.grey.withValues(alpha: 0.1),
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: s.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(s.icon, color: s.color, size: 24),
          ),
          const SizedBox(height: 10),
          Text(
            s.label,
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Why Us ───────────────────────────────────────────────────────────────

  Widget _buildWhyUsColumn(ThemeData theme, bool isDark) {
    final reasons = [
      _ReasonItem(
        Icons.verified_user_rounded,
        'Vetted Professionals',
        'Every technician is background-checked and certified.',
        const Color(0xFF26A69A),
      ),
      _ReasonItem(
        Icons.flash_on_rounded,
        'Fast Booking',
        'Book a service in under 60 seconds, anytime.',
        const Color(0xFFFFB300),
      ),
      _ReasonItem(
        Icons.support_agent_rounded,
        '24/7 Support',
        'Our support team is always available to help you.',
        const Color(0xFF5C6BC0),
      ),
    ];

    return Column(
      children: reasons.map((r) => _buildReasonTile(r, theme, isDark)).toList(),
    );
  }

  Widget _buildReasonTile(_ReasonItem r, ThemeData theme, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(theme, isDark),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: r.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(r.icon, color: r.color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r.title,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  r.subtitle,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Stats Row ────────────────────────────────────────────────────────────

  Widget _buildStatsRow(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
      decoration: _cardDecoration(theme, isDark),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStat('10K+', 'Clients', theme),
          _buildStatDivider(theme),
          _buildStat('500+', 'Experts', theme),
          _buildStatDivider(theme),
          _buildStat('4.9★', 'Rating', theme),
          _buildStatDivider(theme),
          _buildStat('6', 'Services', theme),
        ],
      ),
    );
  }

  Widget _buildStat(String value, String label, ThemeData theme) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: theme.colorScheme.primary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStatDivider(ThemeData theme) {
    return Container(
      width: 1,
      height: 30,
      color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
    );
  }

  // ─── Team Card ────────────────────────────────────────────────────────────

  Widget _buildTeamCard(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withValues(alpha: 0.75),
            const Color(0xFF1A2340),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.35),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Built with ❤️',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'A passionate team dedicated to simplifying home maintenance for everyone.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  child: const Text(
                    'contact@homeease.com',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.groups_rounded,
              color: Colors.white,
              size: 40,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Version Badge ────────────────────────────────────────────────────────

  Widget _buildVersionBadge(ThemeData theme, bool isDark) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF161A24) : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.info_outline_rounded,
              size: 14,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            const SizedBox(width: 6),
            Text(
              'HomeEase  ·  v1.0.0  ·  © 2025',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Shared Card Decoration ───────────────────────────────────────────────

  BoxDecoration _cardDecoration(ThemeData theme, bool isDark) {
    return BoxDecoration(
      color: isDark ? const Color(0xFF161A24) : Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.grey.withValues(alpha: 0.1),
      ),
      boxShadow: isDark
          ? []
          : [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 20,
                spreadRadius: -4,
                offset: const Offset(0, 6),
              ),
            ],
    );
  }
}

// ─── Data Models ─────────────────────────────────────────────────────────────

class _ServiceItem {
  final IconData icon;
  final String label;
  final Color color;
  const _ServiceItem(this.icon, this.label, this.color);
}

class _ReasonItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  const _ReasonItem(this.icon, this.title, this.subtitle, this.color);
}
