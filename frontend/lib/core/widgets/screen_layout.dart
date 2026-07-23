import 'package:flutter/material.dart';

class ScreenLayout extends StatelessWidget {
  final Widget child;
  final String title;
  final Widget? floatingActionButton;
  final bool scrollable;

  const ScreenLayout({
    super.key,
    required this.child,
    required this.title,
    this.floatingActionButton,
    this.scrollable = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), centerTitle: true),
      body: scrollable
          ? SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 24.0,
              ),
              child: child,
            )
          : Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 24.0,
              ),
              child: child,
            ),
      floatingActionButton: floatingActionButton,
    );
  }
}
