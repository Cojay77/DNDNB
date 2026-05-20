import 'package:flutter/material.dart';
import '../utils/theme.dart';

class BeerStockGauge extends StatelessWidget {
  final double stock;
  final int contributions;

  const BeerStockGauge({
    super.key,
    required this.stock,
    required this.contributions,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const SizedBox(width: 8),
            Text(
              "🍻 Réserve + Apports",
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(
                    color: Colors.amber,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            children: [
              Container(
                height: 20,
                width: double.infinity,
                color: Colors.grey.shade800,
              ),
              FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: (stock / 50).clamp(0.0, 1.0),
                child: Container(
                  height: 20,
                  color: AppTheme.getStockColor(stock),
                ),
              ),
              FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: ((stock + contributions) / 50).clamp(0.0, 1.0),
                child: Container(
                  height: 20,
                  color: Colors.green.withValues(alpha: 0.3),
                ),
              ),
              Center(
                child: Text(
                  "${(stock + contributions).clamp(0, 50).toInt()} bières",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "Stock actuel : ${stock.toInt()}  |  Apports prévus : $contributions",
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade400,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}
