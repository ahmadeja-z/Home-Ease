import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:homeease/models/nearby_worker_model.dart';
import 'package:homeease/models/worker_profile_model.dart';
import 'package:homeease/widgets/app_cache_image.dart';

class WorkerDetailsBottomSheet extends StatefulWidget {
  final NearbyWorkerModel worker;
  final Future<WorkerProfileModel?> Function() fetchProfile;
  final VoidCallback? onRequestService;

  const WorkerDetailsBottomSheet({
    super.key,
    required this.worker,
    required this.fetchProfile,
    this.onRequestService,
  });

  @override
  State<WorkerDetailsBottomSheet> createState() =>
      _WorkerDetailsBottomSheetState();
}

class _WorkerDetailsBottomSheetState extends State<WorkerDetailsBottomSheet> {
  WorkerProfileModel? _profile;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await widget.fetchProfile();
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _isLoading = false;
        _error = profile == null ? 'Profile not found' : null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  String get _displayName =>
      _profile?.name?.trim().isNotEmpty == true
          ? _profile!.name!
          : widget.worker.name;

  String? get _profileImageUrl {
    final fromProfile = _profile?.profilePicture;
    if (fromProfile != null && fromProfile.isNotEmpty) return fromProfile;
    final fromWorker = widget.worker.profileImage;
    if (fromWorker != null && fromWorker.isNotEmpty) return fromWorker;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final worker = widget.worker;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAvatar(),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _displayName,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _OnlineChip(isOnline: worker.isOnline),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            if (_isLoading) ...[
              const SizedBox(height: 24),
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Loading latest profile…',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            ] else if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                'Could not refresh profile. Showing map data.',
                style: TextStyle(color: Colors.orange[800], fontSize: 13),
              ),
            ],
            const SizedBox(height: 20),
            _DetailRow(
              icon: Icons.handyman_outlined,
              label: 'Service',
              value: worker.categoryName ?? '—',
            ),
            _DetailRow(
              icon: Icons.place_outlined,
              label: 'Distance',
              value: '${worker.distance.toStringAsFixed(1)} km away',
            ),
            _DetailRow(
              icon: Icons.star_rounded,
              iconColor: Colors.amber,
              label: 'Rating',
              value: worker.rating.toStringAsFixed(1),
            ),
            if (worker.perHourRate != null)
              _DetailRow(
                icon: Icons.payments_outlined,
                label: 'Rate',
                value: '\$${worker.perHourRate!.toStringAsFixed(0)}/hour',
              ),
            if (worker.completedJobs != null)
              _DetailRow(
                icon: Icons.work_outline,
                label: 'Completed jobs',
                value: '${worker.completedJobs}',
              ),
            if (_profile?.phoneNumber != null &&
                _profile!.phoneNumber!.isNotEmpty)
              _DetailRow(
                icon: Icons.phone_outlined,
                label: 'Phone',
                value: _profile!.phoneNumber!,
              ),
            if (_profile?.role != null)
              _DetailRow(
                icon: Icons.badge_outlined,
                label: 'Role',
                value: _profile!.role!,
              ),
            if (_profile?.status != null)
              _DetailRow(
                icon: Icons.verified_user_outlined,
                label: 'Status',
                value: _profile!.status!,
              ),
            if (_profile?.isActive != null)
              _DetailRow(
                icon: Icons.toggle_on_outlined,
                label: 'Active account',
                value: _profile!.isActive! ? 'Yes' : 'No',
              ),
            if (kDebugMode) ...[
              const SizedBox(height: 8),
              Text(
                'Worker ID: ${worker.id}',
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
            ],
            if (widget.onRequestService != null) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: widget.onRequestService,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Request Service',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    final url = _profileImageUrl;
    if (url != null) {
      return AppCacheImage(
        imageUrl: url,
        width: 72,
        height: 72,
        round: 36,
        boxFit: BoxFit.cover,
      );
    }
    return CircleAvatar(
      radius: 36,
      backgroundColor: Colors.grey[200],
      child: Icon(Icons.engineering, size: 36, color: Colors.grey[600]),
    );
  }
}

class _OnlineChip extends StatelessWidget {
  final bool isOnline;

  const _OnlineChip({required this.isOnline});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: (isOnline ? Colors.green : Colors.grey).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.circle,
            size: 8,
            color: isOnline ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 6),
          Text(
            isOnline ? 'Online' : 'Offline',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isOnline ? Colors.green[800] : Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: iconColor ?? Colors.grey[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
