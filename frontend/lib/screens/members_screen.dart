import 'package:flutter/material.dart';
import '../services/api_service.dart';

class MembersScreen extends StatefulWidget {
  final String committeeId;

  const MembersScreen({super.key, required this.committeeId});

  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> {
  List members = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchMembers();
  }

  Future<void> fetchMembers() async {
    try {
      var data = await ApiService().getMembers(widget.committeeId);

      if (!mounted) return;

      setState(() {
        members = data;
        isLoading = false;
      });
    } catch (e) {
      print("ERROR: $e");

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Members")),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : members.isEmpty
              ? const Center(child: Text("No Members Found"))
              : ListView.builder(
                  itemCount: members.length,
                  itemBuilder: (context, index) {
                    var member = members[index];
                    var user = member["user_detail"];

                    return Card(
                      margin: const EdgeInsets.all(10),
                      child: ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.person),
                        ),

                        title: Text(user["name"] ?? "No Name"),

                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Phone: ${user["phoneno"] ?? ""}"),
                            Text("Rating: ${user["rating"] ?? 0}"),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}