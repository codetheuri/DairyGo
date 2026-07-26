import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final networkConnectivityServiceProvider = Provider<NetworkConnectivityService>((ref) {
  return NetworkConnectivityService();
});

final networkConnectivityProvider = StreamProvider.autoDispose<bool>((ref) {
  final service = ref.watch(networkConnectivityServiceProvider);
  return service.onConnectivityChanged;
});

final isConnectedProvider = Provider.autoDispose<bool>((ref) {
  final asyncVal = ref.watch(networkConnectivityProvider);
  return asyncVal.valueOrNull ?? true;
});

class NetworkConnectivityService {
  final Connectivity _connectivity = Connectivity();

  Stream<bool> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged.map((results) {
      return results.any((result) => result != ConnectivityResult.none);
    });
  }

  Future<bool> checkHasConnection() async {
    try {
      final results = await _connectivity.checkConnectivity();
      return results.any((result) => result != ConnectivityResult.none);
    } catch (_) {
      return true; // Default to true if check fails
    }
  }
}
