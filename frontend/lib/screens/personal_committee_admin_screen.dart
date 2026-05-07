import 'package:flutter/material.dart';
import '../services/api_service.dart';

class PersonalCommitteeAdminScreen extends StatefulWidget {
  final Map committee;

  const PersonalCommitteeAdminScreen({
    super.key,
    required this.committee,
  });

  @override
  State<PersonalCommitteeAdminScreen> createState() =>
      _PersonalCommitteeAdminScreenState();
}

class _PersonalCommitteeAdminScreenState
    extends State<PersonalCommitteeAdminScreen> {
  Map progress = {};
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadProgress();
  }

  Future<void> loadProgress() async {
    var data = await ApiService()
        .getPersonalProgress(widget.committee["_id"]);

    setState(() {
      progress = data;
      loading = false;
    });
  }

  Future<void> markPaid() async {
    await ApiService().personalPay(
      widget.committee["_id"],
      progress["nextCycle"],
    );

    loadProgress();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text(widget.committee["committee_name"]),
      ),
      body: loading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : Padding(
              padding:
                  const EdgeInsets.all(16),
              child: Column(
                children: [

                  Card(
                    child: ListTile(
                      title:
                          const Text("Paid"),
                      subtitle: Text(
                        "${progress["paid"]} / ${progress["total"]}",
                      ),
                    ),
                  ),

                  Card(
                    child: ListTile(
                      title: const Text(
                          "Saved Amount"),
                      subtitle: Text(
                        "${progress["saved"]}",
                      ),
                    ),
                  ),

                  Card(
                    child: ListTile(
                      title: const Text(
                          "Remaining"),
                      subtitle: Text(
                        "${progress["remaining"]}",
                      ),
                    ),
                  ),

                  const SizedBox(
                      height: 30),

                  ElevatedButton(
                    onPressed:
                        progress["remaining"] == 0
                            ? null
                            : markPaid,
                    child: const Text(
                      "Mark Installment Paid",
                    ),
                  )
                ],
              ),
            ),
    );
  }
}