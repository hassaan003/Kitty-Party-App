import 'package:flutter/material.dart';
import '../services/api_service.dart';

class CreateCommitteeScreen extends StatefulWidget {
  final String userId;

  const CreateCommitteeScreen({super.key, required this.userId});

  @override
  State<CreateCommitteeScreen> createState() => _CreateCommitteeScreenState();
}

class _CreateCommitteeScreenState extends State<CreateCommitteeScreen> {
  final name = TextEditingController();
  final amount = TextEditingController();
  final daysGap = TextEditingController();
  final deadline = TextEditingController();
  final totalCycles = TextEditingController();

  String savingType = "personal"; 
  String committeeType = "1"; 
  String leavingType = "1";   
  String arrangeType = "1";
  DateTime selectedDate = DateTime.now();       

  Future createCommittee() async {
    try {
      if (savingType == "personal") {
        await ApiService().createPersonalCommittee({
          "committee_admin_id": widget.userId,
          "committee_name": name.text,
          "amount": int.parse(amount.text),
          "start_date": selectedDate.toIso8601String(),
          "days_gap": int.parse(daysGap.text),
          "deadline_day": int.parse(deadline.text),
          "total_cycle": int.parse(totalCycles.text),
        });
      } else {
        await ApiService().createSharedCommittee({
          "committee_name": name.text,
          "amount": int.parse(amount.text),
          "start_date": selectedDate.toIso8601String(),
          "days_gap": int.parse(daysGap.text),
          "deadline_day": int.parse(deadline.text),

          "committee_leaving_type": leavingType,
          "committee_type": committeeType,
          "members_arrange_type": arrangeType,

          "enrollment_period": true,
          "number_of_member": 0,
          "admin_id": widget.userId,
        });
      }
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Committee Created")));

      Navigator.pop(context);
      setState(() {}); // refresh home screen
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Widget boxField(String hint, TextEditingController c) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: c,
        decoration: InputDecoration(
          hintText: hint,
          border: OutlineInputBorder(),
        ),
      ),
    );
  }

  Future pickDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime(2035),
      initialDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Committee")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            /// Name
            boxField("Committee Name", name),

            /// Amount
            boxField("Amount", amount),

            /// Date
            ElevatedButton(
              onPressed: pickDate,
              child: Text(
                selectedDate.toString().split(" ")[0],
              ),
            ),

            boxField("Days Gap", daysGap),
            boxField("Deadline Day", deadline),

            const SizedBox(height: 10),

            /// Saving Type
            const Text("Committee Saving Type"),

            RadioListTile(
              value: "personal",
              groupValue: savingType,
              title: const Text("Personal"),
              onChanged: (v) {
                setState(() {
                  savingType = v!;
                });
              },
            ),

            RadioListTile(
              value: "shared",
              groupValue: savingType,
              title: const Text("Shared"),
              onChanged: (v) {
                setState(() {
                  savingType = v!;
                });
              },
            ),

            const SizedBox(height: 10),

            /// PERSONAL
            if (savingType == "personal") boxField("Total Cycles", totalCycles),

            /// SHARED
            if (savingType == "shared") ...[
              const Divider(),

              const Text("Leaving Rule"),

              DropdownButton<String>(
                value: leavingType,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(
                    value: "1",
                    child: Text("1: Keep amount same"),
                  ),
                  DropdownMenuItem(
                    value: "2",
                    child: Text("2: Divide leaving amount"),
                  ),
                ],
                onChanged: (v) {
                  setState(() {
                    leavingType = v!;
                  });
                },
              ),

              const SizedBox(height: 10),

              const Text("Committee Type"),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  choiceBtn("Simple", "1"),
                  choiceBtn("Bidding", "2"),
                  choiceBtn("Spin", "3"),
                ],
              ),

              const SizedBox(height: 10),

              const Text("Arrange Members"),

              RadioListTile(
                value: "1",
                groupValue: arrangeType,
                title: const Text("Arrange by Admin"),
                onChanged: (v) {
                  setState(() {
                    arrangeType = v!;
                  });
                },
              ),

              RadioListTile(
                value: "2",
                groupValue: arrangeType,
                title: const Text("Arrange by Alphabet"),
                onChanged: (v) {
                  setState(() {
                    arrangeType = v!;
                  });
                },
              ),
            ],

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: createCommittee,
              child: const Text("Create"),
            ),
          ],
        ),
      ),
    );
  }

  Widget choiceBtn(String text, String value) {
    final selected = committeeType == value;

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: selected ? Colors.green : Colors.grey,
      ),
      onPressed: () {
        setState(() {
          committeeType = value;
        });
      },
      child: Text(text),
    );
  }
}
