/// The milk balancing rule, the same as the server's (pkg/reconcile):
///
///   collected + received = sold (coolers included) + transferred out
///                          + spoiled + unaccounted
///
/// "Received" and "transferred out" are milk from and to other collectors.
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
