import 'package:flutter/material.dart';
import '../services/api_service.dart';

class CreateCommitteeScreen extends StatefulWidget {
  final String userId;
  final VoidCallback? onCreated;

  const CreateCommitteeScreen({super.key, required this.userId, this.onCreated});

  @override
  State<CreateCommitteeScreen> createState() => _CreateCommitteeScreenState();
}

class _CreateCommitteeScreenState extends State<CreateCommitteeScreen> {
  final _formKey = GlobalKey<FormState>();
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
    if (!_formKey.currentState!.validate()) return;
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
      widget.onCreated?.call();
      Navigator.pop(context);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Committee Created")));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(top: 22, bottom: 6),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        ),
      );

  Widget boxField(String label, TextEditingController c, {bool numeric = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: TextFormField(
        controller: c,
        keyboardType: numeric ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          hintText: numeric ? 'Enter a number' : 'Enter $label',
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        ),
        validator: (v) {
          if (v == null || v.trim().isEmpty) return '$label is required';
          if (numeric) {
            final n = int.tryParse(v.trim());
            if (n == null) return '$label must be a number';
            if (n <= 0) return '$label must be greater than 0';
          }
          return null;
        },
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
      appBar: AppBar(title: const Text("Create Paty")),
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              boxField("Committee Name", name),
              boxField("Amount", amount, numeric: true),

              _label("Start Date"),
              GestureDetector(
                onTap: pickDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    suffixIcon: Icon(Icons.calendar_today, size: 18),
                  ),
                  child: Text(selectedDate.toString().split(" ")[0]),
                ),
              ),

              boxField("Days Gap", daysGap, numeric: true),
              boxField("Deadline Day", deadline, numeric: true),

              _label("Committee Saving Type"),
              RadioGroup<String>(
                groupValue: savingType,
                onChanged: (v) => setState(() => savingType = v!),
                child: const Column(
                  children: [
                    RadioListTile(value: "personal", title: Text("Personal")),
                    RadioListTile(value: "shared", title: Text("Shared")),
                  ],
                ),
              ),

              if (savingType == "personal")
                boxField("Total Cycles", totalCycles, numeric: true),

              if (savingType == "shared") ...[
                const Divider(height: 24),
                _label("Leaving Rule"),
                DropdownButtonFormField<String>(
                  initialValue: leavingType,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  ),
                  items: const [
                    DropdownMenuItem(value: "1", child: Text("Keep amount same")),
                    DropdownMenuItem(value: "2", child: Text("Divide leaving amount")),
                  ],
                  onChanged: (v) => setState(() => leavingType = v!),
                ),

                _label("Committee Type"),
                Row(
                  children: [
                    Expanded(child: choiceBtn("Simple", "1")),
                    const SizedBox(width: 8),
                    Expanded(child: choiceBtn("Bidding", "2")),
                    const SizedBox(width: 8),
                    Expanded(child: choiceBtn("Spin", "3")),
                  ],
                ),

                _label("Arrange Members"),
                RadioGroup<String>(
                  groupValue: arrangeType,
                  onChanged: (v) => setState(() => arrangeType = v!),
                  child: const Column(
                    children: [
                      RadioListTile(value: "1", title: Text("Arrange by Admin")),
                      RadioListTile(value: "2", title: Text("Arrange by Alphabet")),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: createCommittee,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text("Create Committee"),
              ),
              const SizedBox(height: 16),
            ],
          ),
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