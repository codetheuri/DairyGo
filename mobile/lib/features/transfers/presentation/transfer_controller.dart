import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/audit_log_model.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/pagination/page_result.dart';
import '../../field_operations/presentation/controllers/field_ops_controller.dart';
import '../../reports/presentation/controllers/report_controller.dart';
import '../data/transfer_models.dart';
import '../data/transfer_repository.dart';

final transferRepositoryProvider = Provider<TransferRepository>(
  (ref) => TransferRepository(ref.watch(dioClientProvider)),
);

/// Transfers on the day chosen on the Sales screen. Collectors get the ones
/// they sent or received; admins and board members every collector's.
final dayTransfersProvider = FutureProvider<List<MilkTransferModel>>((
  ref,
) async {
  ref.reloadWhenNewerDataArrives();
  final date = ref.watch(fieldOpsFilterDateProvider);
  final repository = ref.watch(transferRepositoryProvider);
  return fetchAllPages(
    (page) => repository.list(fromDate: date, toDate: date, page: page),
  );
});

/// Colleagues milk can be transferred to (loaded when the form opens).
final transferRecipientsProvider =
    FutureProvider.autoDispose<List<TransferRecipientModel>>(
      (ref) => ref.watch(transferRepositoryProvider).recipients(),
    );

final transferHistoryProvider = FutureProvider.autoDispose
    .family<List<AuditLogModel>, String>(
      (ref, id) => ref.watch(transferRepositoryProvider).history(id),
    );

/// One collector's transfers (sent and received) in a report period.
final collectorPeriodTransfersProvider =
    FutureProvider.family<List<MilkTransferModel>, CollectorPeriod>((
      ref,
      arg,
    ) async {
      final repository = ref.watch(transferRepositoryProvider);
      return fetchAllPages(
        (page) => repository.list(
          collectorId: arg.collectorId,
          fromDate: arg.fromDate,
          toDate: arg.toDate,
          page: page,
        ),
      );
    });

/// Everything a transfer changes: both collectors' balances, the day's list,
/// dashboards and reports.
void _refreshAfterTransfer(Ref ref) {
  ref.invalidate(dayTransfersProvider);
  ref.invalidate(collectorPeriodTransfersProvider);
  invalidateAllAppMetrics(ref);
}

/// Saves transfers and corrections. Each method returns null on success or
/// the message to show.
class TransferActions {
  final Ref _ref;

  TransferActions(this._ref);

  TransferRepository get _repository => _ref.read(transferRepositoryProvider);

  static String _message(Object e) =>
      e.toString().replaceAll('Exception: ', '');

  Future<String?> record({
    required int toCollectorId,
    required double litres,
    String? transferDate,
    int? fromCollectorId,
    String? notes,
  }) async {
    try {
      await _repository.record(
        toCollectorId: toCollectorId,
        litres: litres,
        transferDate: transferDate,
        fromCollectorId: fromCollectorId,
        notes: notes,
      );
      _refreshAfterTransfer(_ref);
      return null;
    } catch (e) {
      return _message(e);
    }
  }

  Future<String?> correct(
    String id, {
    int? toCollectorId,
    double? litres,
    String? reason,
  }) async {
    try {
      await _repository.update(
        id,
        toCollectorId: toCollectorId,
        litres: litres,
        reason: reason,
      );
      _refreshAfterTransfer(_ref);
      _ref.invalidate(transferHistoryProvider(id));
      return null;
    } catch (e) {
      return _message(e);
    }
  }

  Future<String?> cancel(String id, String reason) async {
    try {
      await _repository.cancel(id, reason);
      _refreshAfterTransfer(_ref);
      _ref.invalidate(transferHistoryProvider(id));
      return null;
    } catch (e) {
      return _message(e);
    }
  }
}

final transferActionsProvider = Provider<TransferActions>(TransferActions.new);
