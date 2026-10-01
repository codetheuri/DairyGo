/// The milk balancing rule, the same as the server's (pkg/reconcile):
///
///   collected + received = sold (coolers included) + transferred out
///                          + spoiled + unaccounted
///
/// "Received" and "transferred out" are milk from and to other collectors.
///
/// Unaccounted above zero is MISSING (shown as "not sold yet"); below zero,
/// more was sold than collected (OVERSOLD, "sold over collected"). Within
/// the allowance it is BALANCED.
class MilkBalance {
  final double unaccountedLitres;
  final String status;

  const MilkBalance._(this.unaccountedLitres, this.status);

  /// [allowanceLitres] is the Sacco's tolerance times the collector-days
  /// being checked (one day: the tolerance itself).
  factory MilkBalance.compute({
    required double collected,
    required double sold,
    required double spoiled,
    required double allowanceLitres,
    double received = 0,
    double transferredOut = 0,
  }) {
    double round2(double v) => (v * 100).roundToDouble() / 100;
    final unaccounted = round2(
      collected + received - sold - transferredOut - spoiled,
    );
    final allowance = round2(allowanceLitres < 0 ? 0 : allowanceLitres);
    final status = unaccounted.abs() <= allowance + 0.005
        ? 'BALANCED'
        : unaccounted > 0
        ? 'MISSING'
        : 'OVERSOLD';
    return MilkBalance._(unaccounted, status);
  }
}

/// The milk difference as people read it: never a negative "not sold yet".
/// Above zero it is milk not sold yet; below zero, more was sold than
/// collected, shown as a positive number.
class BalanceFigure {
  /// Full wording, where there is room.
  final String label;

  /// One or two words, for narrow figure cells.
  final String short;

  /// Always zero or more.
  final double litres;

  const BalanceFigure._(this.label, this.short, this.litres);

  factory BalanceFigure.of(double unaccountedLitres) => unaccountedLitres < 0
      ? BalanceFigure._('Sold over collected', 'Oversold', -unaccountedLitres)
      : BalanceFigure._('Not sold yet', 'Not sold yet', unaccountedLitres);

  bool get oversold => short == 'Oversold';

  /// "196.5 L more sold than collected" or "12.0 L not sold yet".
  String get sentence => oversold
      ? '${litres.toStringAsFixed(1)} L more sold than collected'
      : '${litres.toStringAsFixed(1)} L not sold yet';
}
