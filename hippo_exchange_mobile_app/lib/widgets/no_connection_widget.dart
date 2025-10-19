import 'package:flutter/material.dart';

class NoConnectionWidget extends StatelessWidget {
  const NoConnectionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/SleepingHippo.png',
            width: 150,
            height: 150,
          ),
          const SizedBox(height: 24),
          const Text(
            'No connection found',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
