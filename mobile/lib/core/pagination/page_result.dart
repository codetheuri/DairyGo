/// One page of a list endpoint, plus whether another page follows.
class PageResult<T> {
  final List<T> items;
  final bool hasMore;

  const PageResult(this.items, {required this.hasMore});

  /// Parses the API's list envelope: `data[key]` holds the rows and
  /// `data.meta.has_next` says whether more pages exist.
  factory PageResult.fromData(
    Map<String, dynamic> data,
    String key,
    T Function(Map<String, dynamic> json) fromJson,
  ) {
    final rows = (data[key] as List? ?? const [])
        .map((e) => fromJson(e as Map<String, dynamic>))
        .toList();
    final meta = data['meta'];
    final hasMore = meta is Map && meta['has_next'] == true;
    return PageResult(rows, hasMore: hasMore);
  }
}

/// The largest page the API serves.
const int maxPageSize = 100;

/// Loads every page of a list. Use it only for lists that are small once
/// filtered, such as one farmer's or one collector's month; screens that list
/// a whole Sacco load page by page with `PagedListNotifier` instead.
///
/// [maxPages] guards against an endless loop if the server keeps reporting
/// more pages.
Future<List<T>> fetchAllPages<T>(
  Future<PageResult<T>> Function(int page) fetchPage, {
  int maxPages = 50,
}) async {
  final all = <T>[];
  for (var page = 1; page <= maxPages; page++) {
    final result = await fetchPage(page);
    all.addAll(result.items);
    if (!result.hasMore) break;
  }
  return all;
}
