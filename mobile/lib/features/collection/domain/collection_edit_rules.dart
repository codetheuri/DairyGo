import '../../auth/domain/entities/user_entity.dart';
import '../data/models/milk_collection_model.dart';

/// Returns why [user] may not edit [collection], or null when the edit is allowed.
///
/// Mirrors the server rule (canEditCollection in the Go collection service) so the
/// UI only offers edits the API will accept. The server remains the authority.
/// - VERIFIED and REJECTED records are locked; an admin must reopen them as ADJUSTED.
/// - Sacco admins may edit SUBMITTED and ADJUSTED records.
/// - Collectors may edit only their own SUBMITTED records on the day they were recorded.
String? collectionEditBlockReason(
  MilkCollectionModel collection,
  UserEntity user, {
  DateTime? now,
}) {
  if (collection.status == 'VERIFIED' || collection.status == 'REJECTED') {
    return 'This entry is ${collection.status.toLowerCase()} and locked. An admin must reopen it first.';
  }
  if (user.isSaccoAdmin) return null;
  if (user.isExecutive) return 'Board members have read-only access.';
  if (collection.collectorId != user.id) {
    return 'You can only edit entries you recorded.';
  }
  if (collection.status != 'SUBMITTED') {
    return 'This entry has been adjusted by an admin and can no longer be edited by collectors.';
  }

  final created = DateTime.tryParse(collection.createdAt ?? '')?.toLocal();
  final today = now ?? DateTime.now();
  final sameDay = created != null &&
      created.year == today.year &&
      created.month == today.month &&
      created.day == today.day;
  if (!sameDay) {
    return 'Entries can only be edited on the day they were recorded. Ask an admin to correct it.';
  }
  return null;
}
