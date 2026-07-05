import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Currency extends StatelessWidget {
  final double amount;
  final double size;
  final int fractionDigits;
  final Color color;

  /// Font weights
  final FontWeight amountWeight;
  final FontWeight currencyWeight;

  const Currency({
    super.key,
    required this.amount,
    this.size = 34,
    this.fractionDigits = 1,
    this.color = Colors.black,
    this.amountWeight = FontWeight.w600,
    this.currencyWeight = FontWeight.w700,
  });

  String formatPKR(double value) {
    final formatter = NumberFormat.currency(
      locale: 'en_PK',
      symbol: '',
      decimalDigits: fractionDigits,
    );
    return formatter.format(value);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        /// Currency symbol
        Text(
          'Rs.',
          style: TextStyle(
            fontSize: size * 0.75,
            fontWeight: currencyWeight,
            color: color,
          ),
        ),

        const SizedBox(width: 4),

        /// Amount
        Text(
          formatPKR(amount),
          style: TextStyle(
            fontSize: size,
            fontWeight: amountWeight,
            color: color,
          ),
        ),
      ],
    );
  }
}
