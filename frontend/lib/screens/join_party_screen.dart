import 'package:flutter/material.dart';
import '../services/api_service.dart';

class JoinPartyScreen extends StatefulWidget {
  final Map userData;

  const JoinPartyScreen({super.key, required this.userData});

  @override
  State<JoinPartyScreen> createState() => _JoinPartyScreenState();
}

class _JoinPartyScreenState extends State<JoinPartyScreen> {
  final TextEditingController phoneController = TextEditingController();
  late Map userData;
  @override
  void initState() {
    super.initState();
    userData = widget.userData;
  }

  List committees = [];
  bool isLoading = false;
  Map<String, int> selectedNumbers = {};

  void searchCommittees() async {
    setState(() => isLoading = true);

    final data = await ApiService().getCommitteesByPhone(phoneController.text);

    if (!mounted) return;

    setState(() {
      committees = data;
      isLoading = false;
    });
  }

  void joinCommittee(Map committee, int selectedNumber) async {
    final userId = userData["_id"];
    final committeeId = committee["committee_detail"]["_id"];
    final adminId = committee["committee_detail"]["admin_id"];

    var response = await ApiService().sendJoinRequest(
      committeeId: committeeId,
      adminId: adminId,
      userId: userId, // ✅ FIXED
      selectedNumber: selectedNumber,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(response)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Join Party")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: "Enter Admin Phone Number",
              ),
            ),

            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: searchCommittees,
              child: const Text("Search"),
            ),

            const SizedBox(height: 20),

            isLoading
                ? const CircularProgressIndicator()
                : Expanded(
                    child: ListView.builder(
                      itemCount: committees.length,

                      itemBuilder: (context, index) {
                        var committee = committees[index];
                        String id = committee["committee_detail"]["_id"];

                        selectedNumbers[id] ??= 1;

                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  committee["committee_detail"]["committee_name"],
                                ),

                                Row(
                                  children: [
                                    const Text("No of committees: "),
                                    IconButton(
                                      icon: const Icon(Icons.remove),
                                      onPressed: () {
                                        if ((selectedNumbers[id] ?? 1) > 1) {
                                          setState(() {
                                            selectedNumbers[id] =
                                                (selectedNumbers[id] ?? 1) - 1;
                                          });
                                        }
                                      },
                                    ),
                                    Text(selectedNumbers[id].toString()),
                                    IconButton(
                                      icon: const Icon(Icons.add),
                                      onPressed: () {
                                        setState(() {
                                          selectedNumbers[id] =
                                              (selectedNumbers[id] ?? 1) + 1;
                                        });
                                      },
                                    ),
                                  ],
                                ),

                                ElevatedButton(
                                  onPressed: () => joinCommittee(
                                    committee,
                                    selectedNumbers[id]!,
                                  ),
                                  child: const Text("Request"),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
