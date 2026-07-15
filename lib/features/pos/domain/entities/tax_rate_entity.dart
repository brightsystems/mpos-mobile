import 'package:equatable/equatable.dart';

class TaxRateEntity extends Equatable {
  const TaxRateEntity({
    required this.id,
    required this.name,
    required this.code,
    required this.ratePercent,
    this.morTaxCode,
  });

  final String id;
  final String name;
  final String code;
  final double ratePercent;
  final String? morTaxCode;

  @override
  List<Object?> get props => [id, code, ratePercent, morTaxCode];
}

double calculateTaxesAmount(double subtotal, List<TaxRateEntity> taxes) {
  var total = 0.0;
  for (final tax in taxes) {
    total += (subtotal * (tax.ratePercent / 100) * 100).roundToDouble() / 100;
  }
  return total;
}

String formatTaxLabel(List<TaxRateEntity> taxes) {
  if (taxes.isEmpty) {
    return 'No tax';
  }

  return taxes.map((t) => '${t.name} ${t.ratePercent.toStringAsFixed(t.ratePercent == t.ratePercent.roundToDouble() ? 0 : 2)}%').join(' + ');
}
