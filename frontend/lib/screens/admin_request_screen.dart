import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AdminRequestsScreen extends StatefulWidget {
  final Map userData;

  const AdminRequestsScreen({super.key, required this.userData});

  @override
  State<AdminRequestsScreen> createState() => _AdminRequestsScreenState();
}

class _AdminRequestsScreenState extends State<AdminRequestsScreen> {
  List requests = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchRequests();
  }

  void fetchRequests() async {
    var data = await ApiService().getJoinRequests(widget.userData["_id"]);

    if (!mounted) return;

    setState(() {
      requests = data;
      isLoading = false;
    });
  }

  void approve(String id) async {
    var res = await ApiService().approveRequest(id);
    print(  res); 

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res)));

    fetchRequests(); // refresh list
  }

  void reject(String id) async {
    var res = await ApiService().rejectRequest(id);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res)));

    fetchRequests(); // refresh list
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Join Requests")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : requests.isEmpty
          ? const Center(child: Text("No Requests"))
          : ListView.builder(
              itemCount: requests.length,
              itemBuilder: (context, index) {
                var req = requests[index];

                return Card(
                  child: ListTile(
                    title: Text(req["user_detail"]["name"]),
                    subtitle: Text(req["committee_detail"]["committee_name"]),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ElevatedButton(
                          onPressed: () async {
                           var res= await ApiService().acceptRequest(
                              req["_id"], // notification id
                              {
                                "committee_id": req["committee_id"],
                                "user_id": req["user_id"],
                                "number_of_committee": 1,
                            
                                "committee_details": req["committee_detail"],
                              },
                              
                            );
                            print("response from accept request");
                            print(res);

                            if (!mounted) return;
                            // ignore: use_build_context_synchronously
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Member Added Successfully"),
                              ),
                            );
                          },
                          child: const Text("Approve"),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.red),
                          onPressed: () => reject(req["_id"]),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
