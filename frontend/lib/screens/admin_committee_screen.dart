import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AdminCommitteeScreen extends StatefulWidget {
  final Map committee;

  const AdminCommitteeScreen({super.key, required this.committee});

  @override
  State<AdminCommitteeScreen> createState() => _AdminCommitteeScreenState();
}

class _AdminCommitteeScreenState extends State<AdminCommitteeScreen> {
  List members = [];
  bool loading = true;
  List cycles = [];
  List payments = [];
  List refunds = [];
  List membersForTransfer = [];
  String? selectedCycleId;
  String currentUserId = "";

  @override
  void initState() {
    super.initState();
    fetchMembers();
    fetchCycles();
    fetchRefunds();
    loadUser();
  }

  Future<void> loadUser() async {
    final user = await ApiService().getProfile();
    setState(() {
      currentUserId = user["_id"];
    });
  }

  Future<void> fetchCycles() async {
    try {
      String committeeId = widget.committee["_id"].toString();

      print("COMMITTEE ID SENT = $committeeId");

      final data = await ApiService().getCycles(committeeId);

      print("API RESPONSE = $data");

      if (!mounted) return;

      setState(() {
        cycles = data;
      });

      if (cycles.isNotEmpty) {
        selectedCycleId = cycles.last["_id"].toString();
        fetchPayments(selectedCycleId!);
      }
    } catch (e) {
      print("ERROR = $e");
    }
  }

  Future fetchMembersForTransfer() async {
    final data = await ApiService().getMembersForAdminTransfer(
      widget.committee["_id"].toString(),
      widget.committee["admin_id"].toString(),
    );

    setState(() {
      membersForTransfer = data;
    });
  }

  Future fetchRefunds() async {
    final data = await ApiService().getRefunds(widget.committee["_id"]);

    setState(() {
      refunds = data;
    });
  }

  Future<void> fetchPayments(String cycleId) async {
    final data = await ApiService().getPayments(cycleId);

    setState(() {
      payments = data;
    });
  }

  Future<void> fetchMembers() async {
    final data = await ApiService().getAllMembers(widget.committee["_id"]);
    setState(() {
      members = data;
      loading = false;
    });
  }

  Future<void> fetchCommitteeDetails() async {
    // simplest fix: just rebuild UI
    setState(() {});
  }

  Future<void> incrementRating(String userId, String memberId) async {
    await ApiService().incrementRating(userId, memberId);
    fetchMembers();
  }

  Future<void> decrementRating(String userId, String memberId) async {
    await ApiService().decrementRating(userId, memberId);
    fetchMembers();
  }

  Widget buildStars(int rating) {
    return Row(
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star : Icons.star_border,
          color: Colors.orange,
        );
      }),
    );
  }

  Widget buildPaymentSection() {
    if (cycles.isEmpty) {
      return const Text("No Cycles Found");
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 🔹 Cycle Dropdown
        DropdownButton<String>(
          value: selectedCycleId,
          items: cycles.map<DropdownMenuItem<String>>((c) {
            return DropdownMenuItem<String>(
              value: c["_id"].toString(),
              child: Text("Cycle ${c["cycle_number"]}"),
            );
          }).toList(),
          onChanged: (value) {
            if (value == null) return;

            setState(() {
              selectedCycleId = value;
            });

            fetchPayments(value);
          },
        ),

        const SizedBox(height: 10),

        // 🔹 Payments List
        payments.isEmpty
            ? const Text("No Payments Found")
            : Column(
                children: payments.map((p) {
                  final user = p["user_detail"];

                  bool isPaid = p["payment_status"] == true;
                  bool isApproved = p["approval"] == true;

                  String statusText = "Not Paid";

                  if (isPaid && isApproved) {
                    statusText = "Paid & Approved";
                  } else if (isPaid) {
                    statusText = "Paid Waiting Approval";
                  }

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        children: [
                          ListTile(
                            title: Text(user["name"]),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Status: $statusText"),
                                Text("Type: ${p["payment_type"] ?? "N/A"}"),
                              ],
                            ),
                          ),

                          if (p["payment_img"] != null)
                            Image.network(
                              "http://192.168.18.99:8080/Images/${p["payment_img"]}",
                              height: 120,
                            ),

                          const SizedBox(height: 10),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              // Approve only if not approved yet
                              if (!isApproved)
                                ElevatedButton(
                                  onPressed: () async {
                                    await ApiService().approvePayment(
                                      p["cycle_id"].toString(),
                                      p["member_id"].toString(),
                                      user["_id"].toString(),
                                      widget.committee["_id"].toString(),
                                    );

                                    fetchPayments(selectedCycleId!);
                                  },
                                  child: const Text("Approve"),
                                ),

                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                onPressed: () async {
                                  TextEditingController reasonController =
                                      TextEditingController();

                                  showDialog(
                                    context: context,
                                    builder: (_) {
                                      return AlertDialog(
                                        title: const Text("Reject Payment"),
                                        content: TextField(
                                          controller: reasonController,

                                          maxLines: 3,
                                          decoration: const InputDecoration(
                                            hintText: "Write rejection reason",
                                            border: OutlineInputBorder(),
                                          ),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              Navigator.pop(context);
                                            },
                                            child: const Text("Cancel"),
                                          ),

                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red,
                                            ),
                                            onPressed: () async {
                                              Navigator.pop(context);

                                              await ApiService().rejectPayment(
                                                p["cycle_id"].toString(),
                                                p["member_id"].toString(),
                                                user["_id"].toString(),
                                                widget.committee["_id"]
                                                    .toString(),
                                                reasonController.text,
                                              );

                                              fetchPayments(selectedCycleId!);
                                            },
                                            child: const Text("Reject"),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                                child: const Text("Reject"),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
      ],
    );
  }

  Widget buildMemberCard(member) {
    final user = member["user_detail"];

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        title: Text(user["name"]),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildStars(member["user_rating"] ?? 1),
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    incrementRating(user["_id"], member["_id"]);
                  },
                  icon: const Icon(Icons.add),
                ),
                IconButton(
                  onPressed: () {
                    decrementRating(user["_id"], member["_id"]);
                  },
                  icon: const Icon(Icons.remove),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildMembersSection() {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (members.isEmpty) {
      return const Center(child: Text("No Members Found"));
    }

    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: members.map((m) => buildMemberCard(m)).toList(),
    );
  }

  Widget buildRefundSection() {
    if (refunds.isEmpty) {
      return const Text("No Refund Requests");
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: refunds.map((r) {
        return Card(
          child: ListTile(
            title: Text("User ID: ${r["user_id"]}"),
            subtitle: Text("Amount: ${r["amount"]}"),

            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    await ApiService().approveRefund({
                      "committee_id": widget.committee["_id"],
                      "user_id": r["user_id"],
                      "payment_type": "cash",
                      "message": "Refund paid",
                      "amount": r["amount"],
                      "committee_detail": widget.committee,
                    });

                    fetchRefunds();
                  },
                  child: const Text("Approve"),
                ),

                const SizedBox(width: 5),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () async {
                    await ApiService().rejectRefund({
                      "committee_id": widget.committee["_id"],
                      "user_id": r["user_id"],
                      "message": "Refund rejected",
                    });

                    fetchRefunds();
                  },
                  child: const Text("Reject"),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget buildAdminActions() {
    return Column(
      children: [
        ElevatedButton(
          onPressed: () async {
            await fetchMembersForTransfer();
            if (!mounted) return;
            showDialog(
              context: context,
              builder: (_) {
                return AlertDialog(
                  title: const Text("Select New Admin"),
                  content: SizedBox(
                    width: double.maxFinite,
                    child: ListView(
                      shrinkWrap: true,
                      children: membersForTransfer.map((m) {
                        final user = m["user"];

                        return ListTile(
                          title: Text(user["name"]),
                          onTap: () async {
                            await ApiService().transferAdmin(
                              widget.committee["_id"],
                              widget.committee["admin_id"],
                              user["_id"],
                            );
                            if (!mounted) return;
                            if (widget.committee["admin_id"] != currentUserId) {
                              Navigator.pop(context);
                            }

                            if (!mounted) return;

                            Navigator.pop(context);
                            setState(() {});

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Admin Transferred"),
                              ),
                            );
                          },
                        );
                      }).toList(),
                    ),
                  ),
                );
              },
            );
          },
          child: const Text("Transfer Admin"),
        ),
        ElevatedButton(
          onPressed: () {
            TextEditingController phoneController = TextEditingController();

            showDialog(
              context: context,
              builder: (_) {
                return AlertDialog(
                  title: const Text("Invite Member"),
                  content: TextField(
                    controller: phoneController,
                    decoration: const InputDecoration(
                      hintText: "Enter phone number",
                    ),
                  ),
                  actions: [
                    ElevatedButton(
                      onPressed: () async {
                        final user = await ApiService().findUser(
                          phoneController.text,
                        );
                        if (!mounted) return;

                        if (user == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("User not found")),
                          );
                          return;
                        }

                        await ApiService().sendJoinRequest(
                          committeeId: widget.committee["_id"],
                          adminId: widget.committee["admin_id"],
                          userId: user["_id"],
                          selectedNumber: 1,
                        );
                        if (!mounted) return;

                        Navigator.pop(context);

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Invite Sent")),
                        );
                      },
                      child: const Text("Invite"),
                    ),
                  ],
                );
              },
            );
          },
          child: const Text("Add Members"),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () async {
            await ApiService().deleteCommittee(widget.committee["_id"]);
            if (!mounted) return;
            Navigator.pop(context);
          },
          child: const Text("Delete Committee"),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Admin Panel")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              "Payments approval",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            buildPaymentSection(),

            const SizedBox(height: 20),
            const Text(
              "Members & Ratings",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            buildMembersSection(),
            const SizedBox(height: 20),
            const Text(
              "Refund Requests",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            buildRefundSection(),
            const SizedBox(height: 20),
            buildAdminActions(),
          ],
        ),
      ),
    );
  }
}
