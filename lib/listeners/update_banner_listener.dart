import 'package:dndnb/listeners/update_detector.dart';
import 'package:dndnb/utils/platform_utils.dart';
import 'package:flutter/material.dart';

class UpdateBannerListener extends StatefulWidget {
  final Widget child;

  const UpdateBannerListener({super.key, required this.child});

  @override
  State<UpdateBannerListener> createState() => _UpdateBannerListenerState();
}

class _UpdateBannerListenerState extends State<UpdateBannerListener> {
  bool _showBanner = false;

  Future<void> checkUpdateAvailable() async {
    final isOutdated = await hasNewVersion();

    if (isOutdated && mounted) {
      setState(() {
        _showBanner = true;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    checkUpdateAvailable();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_showBanner)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.deepOrange.withValues(alpha: 0.95),
                    Colors.black.withValues(alpha: 0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: GestureDetector(
                onTap: () => reloadPage(),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.local_fire_department, color: Colors.white),
                    SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        "Nouvelle version disponible — Appuyez pour recharger",
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: 'Cinzel',
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
