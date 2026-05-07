import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';

class PaymentScreen extends StatefulWidget {
  final Map committee;
  final String memberId;
  final String cycleId;

  const PaymentScreen({
    super.key,
    required this.committee,
    required this.memberId,
    required this.cycleId,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String paymentType = "cash";
  File? imageFile;
  bool loading = false;

  Future pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);

    if (file != null) {
      setState(() {
        imageFile = File(file.path);
      });
    }
  }

  Future submitPayment() async {
    setState(() {
      loading = true;
    });

    try {
      print("committee: ${widget.committee["_id"]}");
      print("memberId: ${widget.memberId}");
      print("cycleId: ${widget.cycleId}");
      print("paymentType: $paymentType");
      await ApiService().paymentHandle(
        committee: widget.committee,
        memberId: widget.memberId,
        cycleId: widget.cycleId,
        paymentType: paymentType,
        imageFile: imageFile,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Payment Request Sent")));
      Navigator.pop(context);
    } catch (e) {
      print(e);
    }

    if (!mounted) return;

    setState(() {
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pay Now")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            RadioListTile(
              value: "cash",
              groupValue: paymentType,
              title: const Text("Cash"),
              onChanged: (v) {
                setState(() {
                  paymentType = "cash";
                });
              },
            ),
            RadioListTile(
              value: "online",
              groupValue: paymentType,
              title: const Text("Online"),
              onChanged: (v) {
                setState(() {
                  paymentType = "online";
                });
              },
            ),

            if (paymentType == "online") ...[
              ElevatedButton(
                onPressed: pickImage,
                child: const Text("Select Screenshot"),
              ),
              const SizedBox(height: 10),
              if (imageFile != null) Text(imageFile!.path.split("/").last),
            ],

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: loading ? null : submitPayment,
                child: Text(loading ? "Please Wait..." : "Submit Payment"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
