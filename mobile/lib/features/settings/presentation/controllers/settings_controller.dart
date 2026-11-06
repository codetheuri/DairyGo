import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../../collection/data/models/milk_collection_model.dart';
import '../../../collection/presentation/controllers/collection_controller.dart';
import '../../../reports/presentation/controllers/report_controller.dart';
import '../../data/datasources/settings_remote_data_source.dart';
import '../../data/models/settings_models.dart';
import '../../data/repositories/settings_repository_impl.dart';
import '../../domain/repositories/settings_repository.dart';

final settingsRemoteDataSourceProvider = Provider<SettingsRemoteDataSource>((
  ref,
) {
  final dio = ref.watch(dioClientProvider);
  return SettingsRemoteDataSourceImpl(dio);
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final dataSource = ref.watch(settingsRemoteDataSourceProvider);
  return SettingsRepositoryImpl(dataSource);
});

final saccoProfileProvider = FutureProvider<SaccoProfileModel>((ref) async {
  final repository = ref.watch(settingsRepositoryProvider);
  return repository.getSaccoProfile();
});

final saccoSettingsProvider = FutureProvider.autoDispose<SaccoSettingsModel>((
  ref,
) async {
  return ref.watch(settingsRepositoryProvider).getSettings();
});

final milkPriceHistoryProvider = FutureProvider<List<MilkPriceModel>>((
  ref,
) async {
  final repository = ref.watch(settingsRepositoryProvider);
  return repository.getPriceHistory();
});

class SetMilkPriceController
    extends StateNotifier<AsyncValue<MilkPriceModel?>> {
  final SettingsRepository _repository;
  final Ref _ref;

  SetMilkPriceController(this._repository, this._ref)
    : super(const AsyncValue.data(null));

  /// What saving the price would change; nothing is saved. Null on failure.
  Future<SaccoPriceCheck?> check(SetPriceRequestModel request) async {
    state = const AsyncValue.loading();
    try {
      final check = await _repository.setMilkPrice(request, preview: true);
      state = const AsyncValue.data(null);
      return check;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }

  /// Saves the price; unpaid milk from its date follows. Null on failure.
  Future<SaccoPriceCheck?> setMilkPrice(
    SetPriceRequestModel request, {
    String? reason,
  }) async {
    state = const AsyncValue.loading();
    try {
      final saved = await _repository.setMilkPrice(request, reason: reason);
      state = const AsyncValue.data(null);
      _ref.invalidate(activeMilkPriceProvider);
      _ref.invalidate(milkPriceHistoryProvider);
      invalidateAllAppMetrics(_ref);
      return saved;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }
}

final setMilkPriceControllerProvider =
    StateNotifierProvider.autoDispose<SetMilkPriceController, AsyncValue<void>>(
      (ref) {
        final repository = ref.watch(settingsRepositoryProvider);
        return SetMilkPriceController(repository, ref);
      },
    );
