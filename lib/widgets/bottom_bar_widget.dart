// bottom_bar.dart
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
    setState(() {
      _version = info.version;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.black,
        border: const Border(top: BorderSide(color: Colors.grey)),
      ),
      child: Row(
        children: [
          Image.asset('assets/logo.png', height: 30, fit: BoxFit.contain),
          const SizedBox(width: 8),
          Image.asset(
            'assets/furcula_logo.png',
            height: 40,
            fit: BoxFit.contain,
          ),
          const Spacer(),
          Text(
            _version.isEmpty ? "D&D&B" : "D&D&B - version $_version",
            style: const TextStyle(fontSize: 9),
            textAlign: TextAlign.right,
          ),
        ],
      ),
    );
  }
}
