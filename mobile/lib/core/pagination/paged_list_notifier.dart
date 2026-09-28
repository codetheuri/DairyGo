import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_colors.dart';
import 'page_result.dart';

/// Rows loaded so far for an infinitely scrolling list.
class PagedList<T> {
  final List<T> items;
  final int page;
  final bool hasMore;
  final bool loadingMore;

  /// Why the last "load more" failed, shown with a retry button.
  final String? loadMoreError;

  const PagedList({
    required this.items,
    required this.page,
    required this.hasMore,
    this.loadingMore = false,
    this.loadMoreError,
  });

  /// Whether the list should end with a footer (spinner, retry or trigger).
  bool get showFooter => hasMore || loadingMore || loadMoreError != null;

  PagedList<T> copyWith({
    List<T>? items,
    int? page,
    bool? hasMore,
    bool? loadingMore,
    String? loadMoreError,
  }) {
    return PagedList(
      items: items ?? this.items,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      loadingMore: loadingMore ?? this.loadingMore,
      loadMoreError: loadMoreError,
    );
  }
}

/// Thrown by [PagedListNotifier.debounce] when a newer search replaced this
/// one. Riverpod discards the result of a superseded build, so it never shows.
class _Superseded implements Exception {
  const _Superseded();
}

/// Loads a list page by page: the first page on build, the next when the
/// user scrolls to the end. Small pages arrive quickly on slow connections,
/// and nothing past what the user looks at is downloaded.
///
/// Subclasses read their filters with `ref.watch` in [build] and pass a page
/// loader to [loadFirstPage], so a filter change starts again from page 1.
abstract class PagedListNotifier<T> extends AsyncNotifier<PagedList<T>> {
  /// Rows per request.
  static const pageSize = 30;

  late Future<PageResult<T>> Function(int page) _fetchPage;

  /// Waits for a pause in typing before searching, so a slow connection is
  /// not sent one request per keystroke.
  Future<void> debounce(String search) async {
    if (search.isEmpty) return;
    var superseded = false;
    ref.onDispose(() => superseded = true);
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (superseded) throw const _Superseded();
  }

  /// Stores [fetchPage] for later pages and loads page 1.
  Future<PagedList<T>> loadFirstPage(Future<PageResult<T>> Function(int page) fetchPage) async {
    _fetchPage = fetchPage;
    final first = await fetchPage(1);
    return PagedList(items: first.items, page: 1, hasMore: first.hasMore);
  }

  /// Appends the next page. Safe to call repeatedly: it does nothing while a
  /// page is loading or when there are no more pages.
  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || current.loadingMore) return;

    state = AsyncData(current.copyWith(loadingMore: true));
    try {
      final next = await _fetchPage(current.page + 1);
      // A refresh or filter change while this page loaded replaced the list.
      if (!identical(state.valueOrNull?.items, current.items)) return;
      state = AsyncData(PagedList(
        items: [...current.items, ...next.items],
        page: current.page + 1,
        hasMore: next.hasMore,
      ));
    } catch (e) {
      if (!identical(state.valueOrNull?.items, current.items)) return;
      state = AsyncData(current.copyWith(
        loadingMore: false,
        loadMoreError: e.toString().replaceAll('Exception: ', ''),
      ));
    }
  }
}

/// The last row of a paged list. Building it asks for the next page, so the
/// list extends itself as the user scrolls; on failure it offers a retry.
class PagedListFooter extends StatefulWidget {
  final PagedList<dynamic> list;
  final VoidCallback onLoadMore;

  const PagedListFooter({super.key, required this.list, required this.onLoadMore});

  @override
  State<PagedListFooter> createState() => _PagedListFooterState();
}

class _PagedListFooterState extends State<PagedListFooter> {
  @override
  void initState() {
    super.initState();
    _requestIfNeeded();
  }

  @override
  void didUpdateWidget(PagedListFooter oldWidget) {
    super.didUpdateWidget(oldWidget);
    _requestIfNeeded();
  }

  void _requestIfNeeded() {
    final list = widget.list;
    if (list.hasMore && !list.loadingMore && list.loadMoreError == null) {
      // Not during build: loading changes provider state.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.onLoadMore();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final error = widget.list.loadMoreError;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: error == null
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.primary),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(error,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.error, fontSize: 12)),
                  TextButton.icon(
                    onPressed: widget.onLoadMore,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Load more'),
                  ),
                ],
              ),
      ),
    );
  }
}
