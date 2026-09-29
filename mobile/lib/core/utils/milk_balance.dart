/// The milk balancing rule, the same as the server's (pkg/reconcile):
///
///   collected = sold (coolers included) + spoiled + unaccounted
///
/// Unaccounted above zero is milk MISSING; below zero, more was sold than
/// collected (OVERSOLD). Within the allowance it is BALANCED.
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
  }) {
    double round2(double v) => (v * 100).roundToDouble() / 100;
    final unaccounted = round2(collected - sold - spoiled);
    final allowance = round2(allowanceLitres < 0 ? 0 : allowanceLitres);
    final status = unaccounted.abs() <= allowance + 0.005
        ? 'BALANCED'
        : unaccounted > 0
        ? 'MISSING'
        : 'OVERSOLD';
    return MilkBalance._(unaccounted, status);
  }
}
