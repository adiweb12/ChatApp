import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Messages"),
        actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.search))],
      ),
      body: ListView.separated(
        itemCount: 10,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) => ListTile(
          leading: const CircleAvatar(backgroundColor: Color(0xFF25D366), child: Icon(Icons.person, color: Colors.white)),
          title: Text("User ${index + 1}"),
          subtitle: const Text("Hey, how's the app build going?"),
          trailing: const Text("10:00 AM", style: TextStyle(fontSize: 12)),
          onTap: () {},
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: const Color(0xFF25D366),
        child: const Icon(Icons.chat, color: Colors.white),
      ),
    );
  }
}
