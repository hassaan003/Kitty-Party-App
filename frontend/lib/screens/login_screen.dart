import 'package:flutter/material.dart';
import 'package:kittypartyapp/screens/signup_screen.dart';
import '../services/api_service.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;
  String message = "";

  void handleLogin() async {
    // setState(() => isLoading = true);

    String response = await ApiService().login(
      phoneController.text.trim(),
      passwordController.text.trim(),
    );
    print("api hello:$response");
    if (!mounted) return;

    setState(() {
      isLoading = false;
      message = response;
    });

    if (response == "User Found") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
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

                const SizedBox(height: 80),

                const Text(
                  "Kitty Party",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                const Text(
                  "Login to continue",
                  style: TextStyle(color: Colors.grey),
                ),

                const SizedBox(height: 50),

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

                      TextField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: "Phone Number",
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 20),

                      TextField(
                        controller: passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: "Password",
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 30),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : handleLogin,
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text("Login"),
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

                const SizedBox(height: 30),

                Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [
    const Text("Don't have an account? "),
    GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SignupScreen()),
        );
      },
      child: const Text(
        "Sign Up",
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ),
    ),
  ],
),

              ],
            ),
          ),
        ),
      ),
    );
  }
}