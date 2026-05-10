import 'package:flutter/material.dart';
import '../services/api_service.dart';

class NotificationScreen extends StatefulWidget {
  final Map userData;

  const NotificationScreen({
    super.key,
    required this.userData,
  });

  @override
  State<NotificationScreen> createState() =>
      _NotificationScreenState();
}

class _NotificationScreenState
    extends State<NotificationScreen> {

  List data = [];

  bool loading = true;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {

    final res = await ApiService().getNotifications(
      widget.userData["_id"],
    );

    if (!mounted) return;

    setState(() {
      data = res;
      loading = false;
    });
  }

  Future<void> approveJoin(String notificationId) async {

    await ApiService().approveJoinRequest(
      notificationId,
    );

    await load();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Request Approved"),
      ),
    );
  }

  Future<void> rejectJoin(String notificationId) async {

    await ApiService().rejectJoinRequest(
      notificationId,
    );

    await load();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Request Rejected"),
      ),
    );
  }

  Future<void> acceptInvite(String notificationId) async {

    await ApiService().acceptInvite(
      notificationId,
    );

    await load();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Invitation Accepted"),
      ),
    );
  }

  Future<void> clearNotification(String id) async {

    await ApiService().clearNotification(id);

    await load();
  }

  Widget buildNotificationCard(Map n) {

    final int type = n["notification_type"] ?? 0;

    final String message =
        n["message"]?.toString() ??
        "Notification";

    // =========================
    // JOIN REQUEST
    // =========================

    if (type == 1) {

      return Card(
        margin: const EdgeInsets.all(10),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [

              Text(
                message,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 14),

              Row(
                children: [

                  Expanded(
                    child: ElevatedButton(
                      onPressed: () =>
                          approveJoin(n["_id"]),
                      child: const Text("Accept"),
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: ElevatedButton(
                      onPressed: () =>
                          rejectJoin(n["_id"]),
                      style:
                          ElevatedButton.styleFrom(
                        backgroundColor:
                            Colors.red,
                      ),
                      child: const Text("Reject"),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      );
    }

    // =========================
    // INVITE
    // =========================

    if (type == 3) {

      return Card(
        margin: const EdgeInsets.all(10),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [

              Text(
                message,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 14),

              Row(
                children: [

                  Expanded(
                    child: ElevatedButton(
                      onPressed: () =>
                          acceptInvite(n["_id"]),
                      child: const Text("Accept"),
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {

                        await clearNotification(
                          n["_id"],
                        );

                      },
                      style:
                          ElevatedButton.styleFrom(
                        backgroundColor:
                            Colors.red,
                      ),
                      child: const Text("Reject"),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      );
    }

    // =========================
    // SIMPLE NOTIFICATIONS
    // =========================

    return Card(
      margin: const EdgeInsets.all(10),
      child: ListTile(

        leading: const Icon(
          Icons.notifications,
        ),

        title: Text(message),

        subtitle: Text(
          n["createdAt"]?.toString() ?? "",
        ),

        trailing: IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () async {

            await clearNotification(
              n["_id"],
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text("Notifications"),
      ),

      body: loading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : data.isEmpty
              ? const Center(
                  child:
                      Text("No Notifications"),
                )
              : RefreshIndicator(

                  onRefresh: load,

                  child: ListView.builder(
                    itemCount: data.length,

                    itemBuilder: (context, index) {

                      return buildNotificationCard(
                        data[index],
                      );
                    },
                  ),
                ),
    );
  }
}