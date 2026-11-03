import 'package:flutter/material.dart';
import '../widgets/custom_text.dart';
import '../currency_formatter.dart';

class UIHelperService {
  static Widget buildBreakdownRow(
    BuildContext context,
    String label,
    double? amount,
  ) {
    if (amount == null || amount == 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CustomText(text: label, color: Colors.grey),
          CustomText(
            text: CurrencyFormatter.formatAmount(context, amount),
            fontWeight: FontWeight.w500,
          ),
        ],
      ),
    );
  }
}
