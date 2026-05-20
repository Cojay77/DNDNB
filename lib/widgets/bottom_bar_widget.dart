import 'package:dndnb/utils/theme.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class BottomBar extends StatefulWidget {
  const BottomBar({super.key});

  @override
  State<BottomBar> createState() => _BottomBarState();
}

class _BottomBarState extends State<BottomBar> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) setState(() => _version = info.version);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: Colors.black,
        // Fire gradient top border
        border: Border(
          top: BorderSide(
            color: DndColors.fire.withValues(alpha: 0.45),
            width: 1.5,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: DndSpacing.md,
        vertical: DndSpacing.xs,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset(
            'assets/furcula_logo.png',
            height: 34,
            fit: BoxFit.contain,
          ),
          const Spacer(),
          Text(
            _version.isEmpty ? "D&D&B" : "v$_version",
            style: const TextStyle(
              fontSize: 10,
              color: DndColors.onSurfaceMuted,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
