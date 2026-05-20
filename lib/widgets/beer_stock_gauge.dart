import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';
import '../utils/theme.dart';

/// Animated beer stock progress bar.
/// Reads live data from [beerStockStreamProvider] and
/// [upcomingBeerContributionsProvider].
/// Admin users can tap the gauge to open a quick-edit bottom sheet.
class BeerStockGauge extends ConsumerWidget {
  const BeerStockGauge({super.key});

  static const double _max = 50;

  Color _stockColor(double stock) {
    if (stock >= 15) return DndColors.beerGreen;
    if (stock >= 8) return DndColors.beerOrange;
    return DndColors.beerRed;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stockAsync = ref.watch(beerStockStreamProvider);
    final contributionsAsync = ref.watch(upcomingBeerContributionsProvider);
    final isAdmin = ref.watch(isAdminProvider).value ?? false;

    return stockAsync.when(
      loading: () => const _GaugeSkeleton(),
      error: (_, __) => const _GaugeError(),
      data: (stock) {
        final contributions = contributionsAsync.valueOrNull ?? 0;
        final total = (stock + contributions).clamp(0, _max).toDouble();
        final stockFraction = (stock / _max).clamp(0.0, 1.0);
        final totalFraction = (total / _max).clamp(0.0, 1.0);
        final barColor = _stockColor(stock);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const SizedBox(width: DndSpacing.sm),
                Icon(Icons.sports_bar, size: 18, color: DndColors.amber),
                const SizedBox(width: DndSpacing.xs),
                Text(
                  "Réserve de bières",
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: DndColors.amber,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (isAdmin) ...[
                  const Spacer(),
                  GestureDetector(
                    onTap: () => _showQuickEdit(context, stock),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: DndSpacing.sm, vertical: DndSpacing.xs),
                      decoration: BoxDecoration(
                        color: DndColors.fire.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: DndColors.fire.withValues(alpha: 0.35)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit_outlined,
                              size: 13, color: DndColors.fire),
                          const SizedBox(width: 3),
                          Text(
                            "Éditer",
                            style: TextStyle(
                                fontSize: 11, color: DndColors.fire),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: DndSpacing.sm),
            GestureDetector(
              onTap: isAdmin ? () => _showQuickEdit(context, stock) : null,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Stack(
                  children: [
                    // Background track
                    Container(
                      height: 22,
                      width: double.infinity,
                      color: Colors.grey.shade800,
                    ),
                    // Contribution overlay (lighter tone)
                    if (contributions > 0)
                      FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: totalFraction,
                        child: Container(
                          height: 22,
                          color:
                              DndColors.beerGreen.withValues(alpha: 0.28),
                        ),
                      ),
                    // Current stock fill (animated)
                    AnimatedFractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: stockFraction,
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOutCubic,
                      child: Container(
                        height: 22,
                        decoration: BoxDecoration(
                          color: barColor,
                          boxShadow: [
                            BoxShadow(
                              color: barColor.withValues(alpha: 0.5),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Label overlay
                    Positioned.fill(
                      child: Center(
                        child: Text(
                          "${stock.toInt()} / ${_max.toInt()} 🍺",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            shadows: [
                              Shadow(
                                  color: Colors.black54, blurRadius: 4),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: DndSpacing.xs),
            if (contributions > 0)
              Padding(
                padding: const EdgeInsets.only(left: DndSpacing.sm),
                child: Text(
                  "+ $contributions apport${contributions > 1 ? 's' : ''} prévus → ${total.toInt()} total",
                  style: TextStyle(
                    fontSize: 11,
                    color: DndColors.beerGreen.withValues(alpha: 0.85),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(left: DndSpacing.sm),
                child: Text(
                  _stockLabel(stock),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade400,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  void _showQuickEdit(BuildContext context, double currentStock) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: DndColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: DndRadius.lg),
      ),
      builder: (_) => _BeerStockEditSheet(currentStock: currentStock),
    );
  }

  String _stockLabel(double stock) {
    if (stock >= 30) return "Le frigo déborde !";
    if (stock >= 15) return "Stock confortable";
    if (stock >= 8) return "Il reste de quoi faire ⚠️";
    if (stock > 0) return "Danger, stock critique ! 🚨";
    return "Plus de bières ! 💀";
  }
}

// ─── Quick-edit bottom sheet ──────────────────────────────────────────────────

class _BeerStockEditSheet extends StatefulWidget {
  final double currentStock;
  const _BeerStockEditSheet({required this.currentStock});

  @override
  State<_BeerStockEditSheet> createState() => _BeerStockEditSheetState();
}

class _BeerStockEditSheetState extends State<_BeerStockEditSheet> {
  static const double _max = 50;
  late double _value;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _value = widget.currentStock;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    await FirebaseDatabase.instance.ref('beerStock').set({
      'value': _value,
      'max': _max,
      'lastUpdateBy': uid,
    });
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final color = _value >= 15
        ? DndColors.beerGreen
        : _value >= 8
            ? DndColors.beerOrange
            : DndColors.beerRed;

    return Padding(
      padding: EdgeInsets.only(
        left: DndSpacing.lg,
        right: DndSpacing.lg,
        top: DndSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + DndSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade600,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: DndSpacing.lg),
          Row(
            children: [
              Icon(Icons.sports_bar, color: DndColors.amber, size: 22),
              const SizedBox(width: DndSpacing.sm),
              Text(
                "Modifier le stock de bières",
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: DndColors.amber),
              ),
            ],
          ),
          const SizedBox(height: DndSpacing.xl),

          // Big value display
          Text(
            "${_value.toInt()}",
            style: TextStyle(
              fontFamily: 'UncialAntiqua',
              fontSize: 64,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            "/ ${_max.toInt()} bières",
            style: TextStyle(
                fontSize: 13, color: DndColors.onSurfaceMuted),
          ),
          const SizedBox(height: DndSpacing.md),

          // Slider
          Slider(
            value: _value,
            min: 0,
            max: _max,
            divisions: 50,
            label: "${_value.toInt()}",
            activeColor: color,
            onChanged: (v) => setState(() => _value = v),
          ),

          // +/- stepper buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _StepButton(
                icon: Icons.remove,
                onTap: () =>
                    setState(() => _value = (_value - 1).clamp(0, _max)),
              ),
              const SizedBox(width: DndSpacing.xl),
              _StepButton(
                icon: Icons.add,
                onTap: () =>
                    setState(() => _value = (_value + 1).clamp(0, _max)),
              ),
            ],
          ),
          const SizedBox(height: DndSpacing.lg),

          // Save button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.save_outlined, size: 18),
              label: Text(_saving ? "Enregistrement…" : "Enregistrer"),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _StepButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: DndColors.surfaceVariant,
          shape: BoxShape.circle,
          border: Border.all(color: DndColors.fire.withValues(alpha: 0.4)),
        ),
        child: Icon(icon, color: DndColors.fire, size: 22),
      ),
    );
  }
}

// ─── Skeleton / Error states ──────────────────────────────────────────────────

class _GaugeSkeleton extends StatelessWidget {
  const _GaugeSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 14,
          width: 140,
          decoration: BoxDecoration(
            color: Colors.grey.shade800,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 22,
          decoration: BoxDecoration(
            color: Colors.grey.shade800,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ],
    );
  }
}

class _GaugeError extends StatelessWidget {
  const _GaugeError();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.error_outline, color: Colors.red.shade300, size: 16),
        const SizedBox(width: 6),
        Text(
          "Erreur chargement stock",
          style: TextStyle(color: Colors.red.shade300, fontSize: 12),
        ),
      ],
    );
  }
}
