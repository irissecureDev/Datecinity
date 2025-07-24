import 'package:flutter/material.dart';

class NotificationCounter extends StatelessWidget {
  // Variables
  final Widget icon;
  final int counter;

  const NotificationCounter({super.key, required this.icon, required this.counter});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        icon,
        Positioned(
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$counter',
              style: const TextStyle(color: Colors.white, fontSize: 15),
              textAlign: TextAlign.center,
            ),
          ),
        )
      ],
    );
  }
}
