import 'package:dating_app/widgets/svg_icon.dart';
import 'package:flutter/material.dart';

class NoData extends StatelessWidget {
  // Variables
  final String? svgName;
  final Widget? icon;
  final String text;

  const NoData({super.key, this.svgName, this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    // Handle icon
    Widget? icon01;
    // Check svgName
    if (svgName != null) {
      // Get SVG icon
      icon01 = SvgIcon("assets/icons/$svgName.svg",
          width: 100, height: 100, color: Theme.of(context).primaryColor);
    } else {
      icon01 = icon;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          // Show icon
          icon01 ?? const SizedBox.shrink(),
          Text(text,
              style: const TextStyle(fontSize: 18),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
