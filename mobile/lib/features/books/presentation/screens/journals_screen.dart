import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/layout/breakpoints.dart';
import '../../../../core/network/api_call.dart';
import '../../../../core/utils/money.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/skeleton.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../finance/presentation/finance_providers.dart'
    show Month, monthOf;
import '../../data/books_models.dart';
import '../books_providers.dart';
import '../widgets/books_widgets.dart';

const _kinds = {
  null: 'All journals',
  'AUTO': 'From records',
  'MANUAL': 'Made by hand',
};

/// Every journal, month by month, newest first; search by number or words.
class JournalsScreen extends ConsumerStatefulWidget {
  const JournalsScreen({super.key});

  @override
  ConsumerState<JournalsScreen> createState() => _JournalsScreenState();
}

class _JournalsScreenState extends ConsumerState<JournalsScreen> {
  Month _month = monthOf(DateTime.now());
  String? _kind;
  String _search = '';
  int _pages = 1;
  final _searchCtl = TextEditingController();

  @override
  void dispose() {
    _searchCtl.dispose();
    super.dispose();
  }

  /// A search looks through every month; otherwise the month shown.
  JournalQuery _query(int page) => (
    month: _search.isEmpty
        ? _month
        : (from: DateTime(2020), to: monthOf(DateTime.now()).to),
    kind: _kind,
    search: _search,
    page: page,
  );

  @override
  Widget build(BuildContext context) {
    final canManage =
        ref.watch(
          authControllerProvider.select(
            (s) => s.valueOrNull?.user?.canManageBooks,
          ),
        ) ??
        false;
    final first = ref.watch(journalsProvider(_query(1)));
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Journals',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          PopupMenuButton<String?>(
            tooltip: 'Which journals',
            icon: const Icon(Icons.filter_list_rounded),
            initialValue: _kind,
            onSelected: (v) => setState(() {
              _kind = v;
              _pages = 1;
            }),
            itemBuilder: (_) => [
              for (final e in _kinds.entries)
                PopupMenuItem(value: e.key, child: Text(e.value)),
            ],
          ),
        ],
      ),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              heroTag: 'new-journal',
              onPressed: () => context.push('/books/journals/new'),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Journal'),
            )
          : null,
      body: ReadableWidth(
        child: Column(
          children: [
            if (_search.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
                child: MonthSwitcher(
                  month: _month,
                  onChanged: (m) => setState(() {
                    _month = m;
                    _pages = 1;
                  }),
                ),
              ),
            Padding(
              padding: EdgeInsets.fromLTRB(16, _search.isEmpty ? 0 : 10, 16, 4),
              child: TextField(
                controller: _searchCtl,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  isDense: true,
                  prefixIcon: const Icon(Icons.search_rounded),
                  hintText: 'J-12, or words in the memo',
                  suffixIcon: _search.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear',
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => setState(() {
                            _searchCtl.clear();
                            _search = '';
                            _pages = 1;
                          }),
                        ),
                ),
                onSubmitted: (v) => setState(() {
                  _search = v.trim();
                  _pages = 1;
                }),
              ),
            ),
            if (_kind != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                child: Text(
                  _kinds[_kind]!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            Expanded(
              child: first.when(
                loading: () => const ListSkeleton(rows: 8),
                error: (e, _) => ErrorView(
                  message: errorText(e),
                  onRetry: () => ref.invalidate(journalsProvider(_query(1))),
                ),
                data: (page) => RefreshIndicator(
                  onRefresh: () {
                    setState(() => _pages = 1);
                    return ref.refresh(journalsProvider(_query(1)).future);
                  },
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                    children: [
                      if (page.journals.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'No journals.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      for (final j in page.journals) JournalTile(j),
                      for (var p = 2; p <= _pages; p++) ..._more(p),
                      if (_lastPage().hasMore)
                        TextButton(
                          onPressed: () => setState(() => _pages++),
                          child: Text('Show more (${page.total} in all)'),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  JournalPage _lastPage() =>
      ref.watch(journalsProvider(_query(_pages))).valueOrNull ??
      const JournalPage([], 0, 1, 50);

  List<Widget> _more(int p) {
    final page = ref.watch(journalsProvider(_query(p)));
    return page.when(
      loading: () => const [
        Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      ],
      error: (e, _) => [Text(errorText(e))],
      data: (pg) => [for (final j in pg.journals) JournalTile(j)],
    );
  }
}

/// A journal in a list: number, date, memo and amount.
class JournalTile extends StatelessWidget {
  final Journal j;

  const JournalTile(this.j, {super.key});

  @override
  Widget build(BuildContext context) {
    final reversed = j.reversedById != null || j.reversesId != null;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: () => context.push('/books/journals/${j.id}'),
      title: Text(
        j.memo,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: reversed ? AppColors.textSecondary : null),
      ),
      subtitle: Text(
        [
          j.label,
          DateFormat('d MMM').format(j.date),
          if (j.isManual) 'by hand',
          if (j.reversedByNumber != null || j.reversedById != null) 'reversed',
        ].join(' · '),
        style: const TextStyle(fontSize: 12),
      ),
      trailing: Text(
        thousands(j.total),
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}
