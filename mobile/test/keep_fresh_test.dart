import 'dart:io';

import 'package:dairy_sacco_mobile/core/cache/keep_fresh.dart';
import 'package:dairy_sacco_mobile/core/cache/response_cache.dart';
import 'package:dairy_sacco_mobile/core/network/dio_client.dart';
import 'package:dairy_sacco_mobile/core/pagination/paged_list_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _answerTime = Duration(milliseconds: 100);

/// Counts how often the screen's data is fetched.
int _fetches = 0;

final _dataProvider = FutureProvider<int>((ref) async {
  final n = ++_fetches;
  await Future<void>.delayed(_answerTime);
  return n;
});

/// A long list the user has scrolled to its third page.
final _pagedProvider = FutureProvider<PagedList<int>>((ref) async {
  _fetches++;
  return const PagedList(items: [1, 2, 3], page: 3, hasMore: true);
});

/// A tab (visible or not, as [visible] says) holding a screen that shows
/// [provider].
Widget _screen(
  ValueNotifier<bool> visible,
  ProviderBase<AsyncValue<Object?>> provider, {
  Duration? every,
}) {
  return ProviderScope(
    child: MaterialApp(
      home: ValueListenableBuilder<bool>(
        valueListenable: visible,
        builder: (context, isVisible, child) =>
            TickerMode(enabled: isVisible, child: child!),
        child: RefreshOnShow(
          providers: [provider],
          every: every,
          child: Consumer(
            builder: (context, ref, _) => Text(
              ref
                  .watch(provider)
                  .when(
                    data: (v) => 'data $v',
                    loading: () => 'loading',
                    error: (e, _) => 'error',
                  ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Lets a triggered reload start (one frame) and its answer arrive.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
  await tester.pump(_answerTime);
}

void main() {
  setUp(() => _fetches = 0);

  group('RefreshOnShow', () {
    testWidgets('reloads when the screen is shown again, keeping the '
        'old data on screen meanwhile', (tester) async {
      final visible = ValueNotifier(true);
      await tester.pumpWidget(_screen(visible, _dataProvider));
      await tester.pump(_answerTime);
      expect(find.text('data 1'), findsOneWidget);
      expect(_fetches, 1, reason: 'the first load is not repeated');

      visible.value = false; // another tab selected
      await tester.pump(const Duration(seconds: 5));
      expect(_fetches, 1, reason: 'nothing is fetched while hidden');

      visible.value = true; // back to this tab
      await tester.pump(); // shown
      await tester.pump(); // reloading
      expect(_fetches, 2);
      expect(
        find.text('data 1'),
        findsOneWidget,
        reason: 'no spinner while the server is asked',
      );
      await tester.pump(_answerTime);
      expect(find.text('data 2'), findsOneWidget);
    });

    testWidgets('reloads once when shown twice in quick succession', (
      tester,
    ) async {
      final visible = ValueNotifier(true);
      await tester.pumpWidget(_screen(visible, _dataProvider));
      await tester.pump(_answerTime);

      for (var i = 0; i < 2; i++) {
        visible.value = false;
        await tester.pump();
        visible.value = true;
        await _settle(tester);
      }
      expect(_fetches, 2);

      await tester.pump(const Duration(seconds: 3));
      visible.value = false;
      await tester.pump();
      visible.value = true;
      await _settle(tester);
      expect(_fetches, 3, reason: 'a later return reloads again');
    });

    testWidgets('reloads when the app returns from the background', (
      tester,
    ) async {
      final visible = ValueNotifier(true);
      await tester.pumpWidget(_screen(visible, _dataProvider));
      await tester.pump(_answerTime);

      for (final state in [
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
        AppLifecycleState.hidden,
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(state);
      }
      await _settle(tester);
      expect(_fetches, 2);
      expect(find.text('data 2'), findsOneWidget);
    });

    testWidgets('keeps the place in a list scrolled past its first page', (
      tester,
    ) async {
      final visible = ValueNotifier(true);
      await tester.pumpWidget(_screen(visible, _pagedProvider));
      await tester.pump();
      visible.value = false;
      await tester.pump();
      visible.value = true;
      await tester.pump();
      await tester.pump();
      expect(_fetches, 1);
    });

    testWidgets('reloads on the timer only while showing and the app is '
        'open', (tester) async {
      final visible = ValueNotifier(true);
      await tester.pumpWidget(
        _screen(visible, _dataProvider, every: const Duration(minutes: 1)),
      );
      await tester.pump(_answerTime);

      await tester.pump(const Duration(minutes: 1));
      await _settle(tester);
      expect(_fetches, 2);

      visible.value = false;
      await tester.pump();
      await tester.pump(const Duration(minutes: 3));
      expect(_fetches, 2, reason: 'stopped while another tab shows');

      visible.value = true; // shown again: reloads and restarts the timer
      await _settle(tester);
      expect(_fetches, 3);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      await tester.pump(const Duration(minutes: 3));
      expect(_fetches, 3, reason: 'stopped while the app is in background');

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await _settle(tester);
      expect(_fetches, 4);
    });
  });

  group('refreshFromServer', () {
    late Directory dir;
    setUp(() => dir = Directory.systemTemp.createTempSync('keep_fresh'));
    tearDown(() => dir.deleteSync(recursive: true));

    testWidgets('skips saved copies and waits for the answers', (tester) async {
      final cache = ResponseCache(() async => dir);
      final failing = FutureProvider<int>((ref) async {
        await Future<void>.delayed(_answerTime);
        throw Exception('offline');
      });
      late WidgetRef widgetRef;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [responseCacheProvider.overrideWithValue(cache)],
          child: Consumer(
            builder: (context, ref, _) {
              widgetRef = ref;
              ref.watch(_dataProvider);
              ref.watch(failing);
              return const SizedBox();
            },
          ),
        ),
      );
      await tester.pump(_answerTime);

      final saved = CachedResponse(null, DateTime.now());
      expect(cache.canShowInstantly(saved), isTrue);

      var done = false;
      widgetRef
          .refreshFromServer([_dataProvider.future, failing.future])
          .then((_) => done = true);
      await tester.pump();
      expect(
        cache.canShowInstantly(saved),
        isFalse,
        reason: 'the pull asks the server, not the saved copy',
      );
      expect(done, isFalse, reason: 'the pull spinner stays until answered');
      await tester.pump(_answerTime);
      expect(done, isTrue, reason: 'a failure shows on screen, not thrown');
      expect(_fetches, 2);
    });
  });
}
