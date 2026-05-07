import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController incomeController = TextEditingController();
  File? selectedImage;
  final ImagePicker picker = ImagePicker();

  bool isLoading = false;
  String message = "";

  void handleSignup() async {
    setState(() => isLoading = true);

    String response = await ApiService().signup(
      name: nameController.text.trim(),
      phone: phoneController.text.trim(),
      password: passwordController.text.trim(),
      income: incomeController.text.trim(),
      imageFile: selectedImage,
    );

    if (!mounted) return;

    setState(() {
      isLoading = false;
      message = response;
    });

    if (response == "user Created") {
      Navigator.pop(context); // go back to login
    }
  }

  Future<void> pickImage() async {
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        selectedImage = File(image.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25),
            child: Column(
              children: [
                const SizedBox(height: 60),

                const Text(
                  "Create Account",
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 40),

                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        // ignore: deprecated_member_use
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: pickImage,
                        child: CircleAvatar(
                          radius: 45,
                          backgroundColor: Colors.grey[300],
                          backgroundImage: selectedImage != null
                              ? FileImage(selectedImage!)
                              : null,
                          child: selectedImage == null
                              ? const Icon(Icons.camera_alt, size: 30)
                              : null,
                        ),
                      ),
                      const SizedBox(height: 20),

                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: "Full Name",
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 15),

                      TextField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: "Phone Number",
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 15),
                      
                      TextField(
                        controller: incomeController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: "Monthly Income",
                          border: OutlineInputBorder(),
                        ),
                      ),
                    

                      const SizedBox(height: 15),

                      TextField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: "Password",
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 25),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : handleSignup,
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text("Sign Up"),
                        ),
                      ),

                      const SizedBox(height: 15),

                      if (message.isNotEmpty)
                        Text(
                          message,
                          style: const TextStyle(color: Colors.red),
                        ),
                    ],
                  ),
                ),
 
                const SizedBox(height: 25),

                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Already have an account? Login"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
