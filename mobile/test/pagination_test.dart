import 'package:dairy_sacco_mobile/core/pagination/page_result.dart';
import 'package:dairy_sacco_mobile/core/pagination/paged_list_notifier.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Serves 0..(total-1) in pages of 3; `failPage` fails once.
class _Numbers extends PagedListNotifier<int> {
  static int total = 7;
  static int? failPage;
  static final requested = <int>[];

  @override
  Future<PagedList<int>> build() => loadFirstPage((page) async {
        requested.add(page);
        if (page == failPage) {
          failPage = null;
          throw Exception('network down');
        }
        final start = (page - 1) * 3;
        final items = [for (var i = start; i < start + 3 && i < total; i++) i];
        return PageResult(items, hasMore: start + 3 < total);
      });
}

final _numbersProvider = AsyncNotifierProvider<_Numbers, PagedList<int>>(_Numbers.new);

void main() {
  setUp(() {
    _Numbers.total = 7;
    _Numbers.failPage = null;
    _Numbers.requested.clear();
  });

  test('PageResult reads rows and has_next from the API envelope', () {
    final r = PageResult.fromData(
      {
        'members': [
          {'n': 1},
          {'n': 2}
        ],
        'meta': {'has_next': true}
      },
      'members',
      (j) => j['n'] as int,
    );
    expect(r.items, [1, 2]);
    expect(r.hasMore, isTrue);
    expect(PageResult.fromData({}, 'members', (j) => 0).items, isEmpty);
  });

  test('fetchAllPages follows has_next and stops at the last page', () async {
    final pages = <int>[];
    final all = await fetchAllPages((page) async {
      pages.add(page);
      return PageResult([page], hasMore: page < 3);
    });
    expect(all, [1, 2, 3]);
    expect(pages, [1, 2, 3]);
  });

  test('loadMore appends pages until there are no more', () async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    final first = await c.read(_numbersProvider.future);
    expect(first.items, [0, 1, 2]);
    expect(first.showFooter, isTrue);

    final notifier = c.read(_numbersProvider.notifier);
    await notifier.loadMore();
    await notifier.loadMore();
    final list = c.read(_numbersProvider).value!;
    expect(list.items, [0, 1, 2, 3, 4, 5, 6]);
    expect(list.hasMore, isFalse);
    expect(list.showFooter, isFalse);

    await notifier.loadMore(); // nothing left: no request
    expect(_Numbers.requested, [1, 2, 3]);
  });

  test('a failed page keeps the rows and can be retried', () async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    await c.read(_numbersProvider.future);
    _Numbers.failPage = 2;

    final notifier = c.read(_numbersProvider.notifier);
    await notifier.loadMore();
    var list = c.read(_numbersProvider).value!;
    expect(list.items, [0, 1, 2]);
    expect(list.loadMoreError, 'network down');

    await notifier.loadMore();
    list = c.read(_numbersProvider).value!;
    expect(list.items, [0, 1, 2, 3, 4, 5]);
    expect(list.loadMoreError, isNull);
  });

  test('a page arriving after a refresh is dropped', () async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    await c.read(_numbersProvider.future);

    final notifier = c.read(_numbersProvider.notifier);
    final pending = notifier.loadMore();
    c.invalidate(_numbersProvider); // e.g. pull-to-refresh or a new filter
    await c.read(_numbersProvider.future);
    await pending;
    expect(c.read(_numbersProvider).value!.items, [0, 1, 2]);
  });
}
