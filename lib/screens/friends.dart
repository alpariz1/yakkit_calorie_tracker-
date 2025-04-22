import 'package:flutter/material.dart';

/// A simple placeholder FriendsPage.
/// Later, you can add more functionality here.
class FriendsPage extends StatelessWidget {
  const FriendsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Arkadaşlar"),
      ),
      body: const Center(
        child: Text("Arkadaşlar Sayfası", style: TextStyle(fontSize: 18)),
      ),
    );
  }
}
