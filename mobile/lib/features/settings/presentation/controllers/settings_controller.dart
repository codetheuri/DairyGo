import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../../collection/data/models/milk_collection_model.dart';
import '../../../collection/presentation/controllers/collection_controller.dart';
import '../../../reports/presentation/controllers/report_controller.dart';
import '../../data/datasources/settings_remote_data_source.dart';
import '../../data/models/settings_models.dart';
import '../../data/repositories/settings_repository_impl.dart';
import '../../domain/repositories/settings_repository.dart';

final settingsRemoteDataSourceProvider = Provider<SettingsRemoteDataSource>((ref) {
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

final milkPriceHistoryProvider = FutureProvider<List<MilkPriceModel>>((ref) async {
  final repository = ref.watch(settingsRepositoryProvider);
  return repository.getPriceHistory();
});

class SetMilkPriceController extends StateNotifier<AsyncValue<MilkPriceModel?>> {
  final SettingsRepository _repository;
  final Ref _ref;

  SetMilkPriceController(this._repository, this._ref) : super(const AsyncValue.data(null));

  Future<bool> setMilkPrice(SetPriceRequestModel request) async {
    state = const AsyncValue.loading();
    try {
      final price = await _repository.setMilkPrice(request);
      state = AsyncValue.data(price);
      _ref.invalidate(activeMilkPriceProvider);
      _ref.invalidate(milkPriceHistoryProvider);
      invalidateAllAppMetrics(_ref);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final setMilkPriceControllerProvider =
    StateNotifierProvider.autoDispose<SetMilkPriceController, AsyncValue<MilkPriceModel?>>((ref) {
  final repository = ref.watch(settingsRepositoryProvider);
  return SetMilkPriceController(repository, ref);
});
