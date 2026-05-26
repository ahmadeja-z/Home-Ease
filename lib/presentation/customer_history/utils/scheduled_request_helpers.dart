import 'package:homeease/models/service_request_model.dart';

/// Scheduled booking status helpers (customer-side only).
class ScheduledRequestHelpers {
  ScheduledRequestHelpers._();

  static const _tripStartedStatuses = {
    RequestStatus.workerOnTheWay,
    RequestStatus.arrived,
    RequestStatus.inProgress,
    RequestStatus.workSubmitted,
    RequestStatus.billGenerated,
    RequestStatus.paid,
    RequestStatus.completed,
  };

  static const _cancellableStatuses = {
    RequestStatus.pendingAdminApproval,
    RequestStatus.approved,
    RequestStatus.assigned,
    RequestStatus.accepted,
    RequestStatus.overdue,
    RequestStatus.workerNoShow,
  };

  static DateTime? localScheduledTime(ServiceRequestModel request) {
    final t = request.scheduledTime;
    if (t == null) return null;
    return t.toLocal();
  }

  static Duration? timeUntilScheduled(ServiceRequestModel request) {
    final scheduled = localScheduledTime(request);
    if (scheduled == null) return null;
    final diff = scheduled.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  static Duration? calculateOverdueDuration(ServiceRequestModel request) {
    final scheduled = localScheduledTime(request);
    if (scheduled == null) return null;
    final now = DateTime.now();
    if (now.isBefore(scheduled)) return null;
    return now.difference(scheduled);
  }

  static String formatDuration(Duration d) {
    if (d.inDays > 0) {
      return '${d.inDays}d ${d.inHours.remainder(24)}h';
    }
    if (d.inHours > 0) {
      return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
    }
    return '${d.inMinutes}m';
  }

  static String formatCountdown(Duration d) {
    if (d.inDays > 0) {
      return '${d.inDays} day${d.inDays == 1 ? '' : 's'}, '
          '${d.inHours.remainder(24)} hr';
    }
    if (d.inHours > 0) {
      return '${d.inHours} hr ${d.inMinutes.remainder(60)} min';
    }
    return '${d.inMinutes} min';
  }

  static bool hasWorkerStartedTrip(ServiceRequestModel request) {
    return _tripStartedStatuses.contains(request.status);
  }

  static bool isScheduledTimePassed(ServiceRequestModel request) {
    final scheduled = localScheduledTime(request);
    if (scheduled == null) return false;
    return DateTime.now().isAfter(scheduled);
  }

  static bool shouldShowCountdown(ServiceRequestModel request) {
    if (request.status != RequestStatus.accepted) return false;
    if (hasWorkerStartedTrip(request)) return false;
    final remaining = timeUntilScheduled(request);
    if (remaining == null) return false;
    return remaining <= const Duration(hours: 2) && remaining > Duration.zero;
  }

  static bool shouldShowNotStartedWarning(ServiceRequestModel request) {
    if (request.status == RequestStatus.overdue ||
        request.status == RequestStatus.workerNoShow) {
      return false;
    }
    if (hasWorkerStartedTrip(request)) return false;
    if (!isScheduledTimePassed(request)) return false;
    return const {
      RequestStatus.accepted,
      RequestStatus.assigned,
      RequestStatus.approved,
    }.contains(request.status);
  }

  static bool canCustomerCancel(ServiceRequestModel request) {
    return request.bookingType == RequestType.scheduled &&
        _cancellableStatuses.contains(request.status);
  }

  static String statusBannerMessage(ServiceRequestModel request) {
    switch (request.status) {
      case RequestStatus.pendingAdminApproval:
        return 'Your request is waiting for admin approval.';
      case RequestStatus.approved:
        return 'Admin approved your request. Worker will be assigned soon.';
      case RequestStatus.assigned:
        return 'Worker assigned. Waiting for worker confirmation.';
      case RequestStatus.accepted:
        if (shouldShowNotStartedWarning(request)) {
          return 'Worker has not started yet. Admin is monitoring this request.';
        }
        if (shouldShowCountdown(request)) {
          final remaining = timeUntilScheduled(request)!;
          return 'Worker scheduled to arrive in ${formatCountdown(remaining)}.';
        }
        return 'Worker accepted your scheduled job.';
      case RequestStatus.overdue:
        return 'Worker is late for your scheduled service.';
      case RequestStatus.workerNoShow:
        return 'Worker did not attend this scheduled job.';
      case RequestStatus.reassigned:
        return 'Your request has been reassigned to another worker.';
      case RequestStatus.workerOnTheWay:
        return 'Worker is on the way to your location.';
      case RequestStatus.arrived:
        return 'Worker has arrived at your location.';
      case RequestStatus.inProgress:
        return 'Work is in progress.';
      case RequestStatus.billGenerated:
        return 'Invoice is ready. Please review and confirm payment.';
      case RequestStatus.completed:
        return 'This scheduled job has been completed.';
      case RequestStatus.cancelled:
        return 'This request was cancelled.';
      case RequestStatus.rejected:
        return 'This request was rejected by admin.';
      default:
        return request.getStatusString();
    }
  }

  static String? notificationMessageForStatus(
    RequestStatus status, {
    String? workerName,
  }) {
    switch (status) {
      case RequestStatus.assigned:
        return workerName != null
            ? '$workerName has been assigned to your scheduled job.'
            : 'A worker has been assigned to your scheduled job.';
      case RequestStatus.accepted:
        return workerName != null
            ? '$workerName accepted your scheduled job.'
            : 'Your scheduled job was accepted by the worker.';
      case RequestStatus.workerOnTheWay:
        return 'Your worker is on the way.';
      case RequestStatus.overdue:
        return 'Your scheduled worker is late.';
      case RequestStatus.workerNoShow:
        return 'Worker did not attend your scheduled job. Our team has been notified.';
      case RequestStatus.reassigned:
        return 'Your scheduled job was reassigned to another worker.';
      case RequestStatus.billGenerated:
        return 'Invoice is ready for your scheduled service.';
      default:
        return null;
    }
  }
}
