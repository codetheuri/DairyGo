import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/dio_client.dart';
import '../pagination/paged_list_notifier.dart';

/// Reloads a screen's data each time the screen comes into view, so records
/// saved on another phone appear without the user pulling to refresh.
///
/// "Comes into view" means: its tab is selected, a screen opened on top of it
/// is closed, or the app returns from the background while it is showing.
/// Tabs and covered screens stay alive with their data, so without this they
/// keep showing what they loaded the first time.
///
/// The saved copy stays on screen while the server is asked (see
/// [CacheFirstInterceptor]); if the answer differs, the screen updates in
/// place. Nothing is asked when the copy is only a few seconds old
/// ([ResponseCache.freshFor]). Offline, the saved copy simply stays.
///
/// [every] also reloads on a timer while the screen is showing and the app
/// is open, for screens left open to watch (the dashboard).
class RefreshOnShow extends ConsumerStatefulWidget {
  /// The providers behind the screen. A provider that is loading is left
  /// alone, and so is a long list the user has scrolled past its first page,
  /// so their place in it is kept.
  final List<ProviderBase<AsyncValue<Object?>>> providers;
  final Duration? every;
  final Widget child;

  const RefreshOnShow({
    super.key,
    required this.providers,
    this.every,
    required this.child,
  });

  @override
  ConsumerState<RefreshOnShow> createState() => _RefreshOnShowState();
}

class _RefreshOnShowState extends ConsumerState<RefreshOnShow> {
  /// Showing and hiding in quick succession (a tab tapped twice, the app
  /// resuming while a tab switches) reloads once.
  static const _minGap = Duration(seconds: 2);

  ValueListenable<TickerModeData>? _ticker;
  late final AppLifecycleListener _lifecycle;
  bool _visible = false;
  bool _foreground = true;
  Timer? _coolDown;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onResume: () {
        _foreground = true;
        if (_visible) _refresh();
        _schedule();
      },
      onHide: () {
        _foreground = false;
        _schedule();
      },
    );
    // The first time a tab opens, its data may come from the warm-up at
    // start; after this frame so a provider built by this screen is left to
    // finish its first load.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _visible) _refresh();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ticker = TickerMode.getValuesNotifier(context);
    if (identical(ticker, _ticker)) return;
    _ticker?.removeListener(_onVisibilityChanged);
    _ticker = ticker..addListener(_onVisibilityChanged);
    _visible = ticker.value.enabled;
    _schedule();
  }

  // Called while the tree is building, where providers must not change.
  void _onVisibilityChanged() {
    final visible = _ticker!.value.enabled;
    if (visible && !_visible) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _visible) _refresh();
      });
    }
    _visible = visible;
    _schedule();
  }

  void _schedule() {
    _timer?.cancel();
    _timer = null;
    final every = widget.every;
    if (every != null && _visible && _foreground) {
      _timer = Timer.periodic(every, (_) => _refresh());
    }
  }

  void _refresh() {
    if (_coolDown?.isActive ?? false) return;
    var reloaded = false;
    for (final provider in widget.providers) {
      if (!ref.exists(provider)) continue; // built when first watched
      final current = ref.read(provider);
      if (current.isLoading) continue;
      final value = current.valueOrNull;
      if (value is PagedList && value.page > 1) continue;
      ref.invalidate(provider);
      reloaded = true;
    }
    if (reloaded) _coolDown = Timer(_minGap, () {});
  }

  @override
  void dispose() {
    _timer?.cancel();
    _coolDown?.cancel();
    _ticker?.removeListener(_onVisibilityChanged);
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Pull to refresh.
extension RefreshFromServer on WidgetRef {
  /// Reloads [providers] from the server, skipping saved copies, so one pull
  /// always shows the latest data (offline, the saved copy is still used).
  /// Completes when the answers arrive, so the pull spinner shows until
  /// then. Failures show on the screen through the providers, so they are
  /// not rethrown here.
  Future<void> refreshFromServer(
    List<Refreshable<Future<Object?>>> providers,
  ) async {
    read(responseCacheProvider)?.markAllStale();
    await Future.wait(
      providers.map((p) => refresh(p).then<void>((_) {}, onError: (_) {})),
    );
  }
}
