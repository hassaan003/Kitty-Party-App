import 'package:flutter/material.dart';
import '../services/api_service.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List data = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  load() async {
    final res = await ApiService().getNotifications();

    setState(() {
      data = res;
    });
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text("Notifications"),
    ),
    body: data.isEmpty
        ? const Center(
            child: Text("No Notifications"),
          )
        : ListView.builder(
            itemCount: data.length,
            itemBuilder: (context, index) {
              final n = data[index];

              String msg =
                  n["message"]?.toString() ?? "New Notification";

              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  leading: const Icon(Icons.notifications),
                  title: Text(msg),
                  subtitle: Text(
                    n["createdAt"]?.toString() ?? "",
                  ),
                ),
              );
            },
          ),
  );
}
}