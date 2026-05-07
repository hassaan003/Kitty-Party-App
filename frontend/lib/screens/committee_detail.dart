import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'payment_screen.dart';
import 'dart:async';

class CommitteeDetailScreen extends StatefulWidget {
  final Map committee;
  final bool isAdmin;

  const CommitteeDetailScreen({
    super.key,
    required this.committee,
    this.isAdmin = false,
  });

  @override
  State<CommitteeDetailScreen> createState() => _CommitteeDetailScreenState();
}

class _CommitteeDetailScreenState extends State<CommitteeDetailScreen> {
  bool isLoading = true;

  List members = [];
  List remainingMembers = [];
  List cycles = [];
  Timer? liveTimer;
  String myMemberId = "";
  Map myMember = {};

  Map<String, dynamic>? currentWinner;
  Map<String, dynamic>? highestBidder;

  @override
  void initState() {
    super.initState();
    loadData();
    startLiveAuction();
  }
  @override
  void dispose() {
    liveTimer?.cancel();
    super.dispose();
  }

  String get type => widget.committee["committee_type"].toString();

  void startLiveAuction() {
    if (widget.committee["committee_type"].toString() != "2") return;

    liveTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      try {
        var data = await ApiService().getHighestBidder(widget.committee["_id"]);

        if (!mounted) return;

        setState(() {
          highestBidder = data;
        });
      } catch (e) {
        print(e);
      }
    });
  }

  Future<void> loadData() async {
    try {
      final id = widget.committee["_id"];

      final allMembers = await ApiService().getMembers(id);
      final profile = await ApiService().getProfile();

      Map tempMyMember = {};

      for (var m in allMembers) {
        if (m["user_id"].toString() == profile["_id"].toString()) {
          tempMyMember = m;
          break;
        }
      }
      print("MY MEMBER = $tempMyMember");
      print("MY MEMBER ID = ${tempMyMember["_id"]}");
      final remain = await ApiService().getRemainingMembers(id);
      final allCycles = await ApiService().getCycles(id);
      if (type == "2") {
        highestBidder = await ApiService().getHighestBidder(
          widget.committee["_id"],
        );
      }

      Map<String, dynamic>? winner;

      try {
        winner = await ApiService().getCurrentWinner(id);
      } catch (e) {
        print(e);
      }

      if (!mounted) return;

      setState(() {
        members = allMembers;
        remainingMembers = remain;
        cycles = allCycles;
        currentWinner = winner;
        myMember = tempMyMember;
        myMemberId = tempMyMember["_id"] ?? "";
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> placeBidDialog() async {
    TextEditingController bid = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Place Bid"),
        content: TextField(
          controller: bid,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: "Enter Bid Amount"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              await ApiService().placeBid(widget.committee["_id"], bid.text);
              if (!mounted) return;

              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text("Bid Submitted")));
              highestBidder = await ApiService().getHighestBidder(
                widget.committee["_id"],
              );
              setState(() {});
            },
            child: const Text("Submit"),
          ),
        ],
      ),
    );
  }

  void openPaymentScreen() {
    if (cycles.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentScreen(
          committee: widget.committee,
          memberId: myMemberId,
          cycleId: cycles.first["_id"],
        ),
      ),
    );
  }

  Future<void> leaveCommittee() async {
    await ApiService().exitCommittee(widget.committee);

    if (!mounted) return;

    Navigator.pop(context);
  }

  Widget topCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.indigo,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(
            widget.committee["committee_name"],
            style: const TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Rs ${widget.committee["amount"]}",
            style: const TextStyle(color: Colors.white, fontSize: 18),
          ),
        ],
      ),
    );
  }

  Widget duesCard() {
    return Card(
      child: ListTile(
        title: const Text("This Cycle Payment"),
        subtitle: Text("Pay Rs ${widget.committee["amount"]}"),
        trailing: ElevatedButton(
          onPressed: openPaymentScreen,
          child: const Text("Pay Now"),
        ),
      ),
    );
  }

  Widget winnerCard() {
    String text = "Winner Pending";

    if (currentWinner != null) {
      text = currentWinner!["user_detail"]["name"];
    }

    return Card(
      child: ListTile(
        title: const Text("Current Winner"),
        subtitle: Text(text),
      ),
    );
  }

  Widget highestBidderCard() {
    if (type != "2") return const SizedBox();

    if (highestBidder == null) {
      return const Card(
        child: ListTile(
          title: Text("Highest Bidder"),
          subtitle: Text("No bids yet"),
        ),
      );
    }

    return Card(
      child: ListTile(
        title: const Text("Highest Bidder"),
        subtitle: Text(
          "${highestBidder!["name"]} - Rs ${highestBidder!["amount"]}",
        ),
      ),
    );
  }

  Widget actionPanel() {
    if (type == "1") {
      return const SizedBox();
    }

    if (type == "2") {
      return Card(
        child: ListTile(
          title: const Text("Bidding Committee"),
          trailing: ElevatedButton(
            onPressed: placeBidDialog,
            child: const Text("Bid Now"),
          ),
        ),
      );
    }

    return Card(
      child: ListTile(
        title: const Text("Spin Committee"),
        trailing: ElevatedButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Spin available on final day")),
            );
          },
          child: const Text("Spin"),
        ),
      ),
    );
  }

  Widget membersCard() {
    return Card(
      child: ExpansionTile(
        title: const Text("Remaining Members"),
        children: remainingMembers.map((m) {
          return ListTile(
            title: Text(m["user_detail"]["name"]),
            subtitle: Text(m["user_detail"]["phoneno"]),
          );
        }).toList(),
      ),
    );
  }

  Widget leaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
        onPressed: leaveCommittee,
        child: const Text("Leave Committee"),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff4f6fa),
      appBar: AppBar(title: const Text("Committee")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  topCard(),
                  const SizedBox(height: 15),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: openPaymentScreen,
                      child: const Text("Pay Now"),
                    ),
                  ),
                  const SizedBox(height: 15),
                  duesCard(),
                  const SizedBox(height: 15),
                  winnerCard(),
                  const SizedBox(height: 15),
                  highestBidderCard(),
                  const SizedBox(height: 15),
                  actionPanel(),
                  const SizedBox(height: 15),
                  membersCard(),
                  const SizedBox(height: 25),
                  leaveButton(),
                ],
              ),
            ),
    );
  }
}
