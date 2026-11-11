import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../../finance/presentation/finance_providers.dart' show Month;
import '../data/books_models.dart';
import '../data/books_service.dart';

final booksServiceProvider = Provider<BooksService>(
  (ref) => BooksService(ref.watch(dioClientProvider)),
);

final booksStatusProvider = FutureProvider.autoDispose<BooksStatus>(
  (ref) => ref.watch(booksServiceProvider).status(),
);

final ledgerAccountsProvider = FutureProvider.autoDispose<List<LedgerAccount>>(
  (ref) => ref.watch(booksServiceProvider).accounts(),
);

final booksLinksProvider = FutureProvider.autoDispose<List<BooksLink>>(
  (ref) => ref.watch(booksServiceProvider).links(),
);

final journalProvider = FutureProvider.autoDispose.family<Journal, String>(
  (ref, id) => ref.watch(booksServiceProvider).journal(id),
);

final trialBalanceProvider = FutureProvider.autoDispose
    .family<TrialBalance, DateTime>(
      (ref, day) => ref.watch(booksServiceProvider).trialBalance(day),
    );

final accountLedgerProvider = FutureProvider.autoDispose
    .family<AccountLedger, ({String accountId, Month month})>(
      (ref, q) => ref
          .watch(booksServiceProvider)
          .ledger(q.accountId, q.month.from, q.month.to),
    );

/// What the journal list shows.
typedef JournalQuery = ({Month month, String? kind, String search, int page});

final journalsProvider = FutureProvider.autoDispose
    .family<JournalPage, JournalQuery>(
      (ref, q) => ref
          .watch(booksServiceProvider)
          .journals(
            from: q.month.from,
            to: q.month.to,
            kind: q.kind,
            search: q.search,
            page: q.page,
          ),
    );

/// Everything that shows the books, refreshed after a change.
void refreshBooks(WidgetRef ref) {
  ref.invalidate(booksStatusProvider);
  ref.invalidate(ledgerAccountsProvider);
  ref.invalidate(booksLinksProvider);
  ref.invalidate(journalsProvider);
  ref.invalidate(trialBalanceProvider);
  ref.invalidate(accountLedgerProvider);
  ref.invalidate(journalProvider);
}
