import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_agency_app/Screens/login.dart';
import 'package:travel_agency_app/domain/models/login_info.dart';
import 'package:travel_agency_app/presentation/providers/viewmodel_provider.dart';

class SignUpPage extends ConsumerStatefulWidget {
  const SignUpPage({super.key});

  @override
  ConsumerState<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends ConsumerState<SignUpPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _agencyController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _agreeTerms = false;

  @override
  Widget build(BuildContext context) {

    final loginState = ref.watch(loginViewModelProvider);

    return Scaffold(
      backgroundColor: Colors.indigo.shade50,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
          child: Column(
            children: [

              const SizedBox(height: 20),

              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.indigo,
                child: const Icon(Icons.travel_explore,
                    size: 50, color: Colors.white),
              ),

              const SizedBox(height: 20),

              const Text(
                "Create Account",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.indigo,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                "Sign up to get started",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.indigoAccent,
                ),
              ),

              const SizedBox(height: 30),

              Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [

                      buildTextField(_nameController, "Full Name", Icons.person),
                      const SizedBox(height: 15),

                      buildTextField(_addressController, "Address", Icons.home),
                      const SizedBox(height: 15),

                      buildTextField(_agencyController, "Agency Name", Icons.apartment),
                      const SizedBox(height: 15),

                      buildTextField(_cityController, "City", Icons.location_city),
                      const SizedBox(height: 15),

                      buildTextField(_mobileController, "Mobile No", Icons.phone,
                          keyboard: TextInputType.phone),
                      const SizedBox(height: 15),

                      buildTextField(_emailController, "Email", Icons.email,
                          keyboard: TextInputType.emailAddress),
                      const SizedBox(height: 15),

                      buildTextField(_passwordController, "Password", Icons.lock,
                          obscure: true),
                      const SizedBox(height: 15),

                      buildTextField(_confirmPasswordController, "Confirm Password",
                          Icons.lock,
                          obscure: true),

                      const SizedBox(height: 15),

                      Row(
                        children: [
                          Checkbox(
                            value: _agreeTerms,
                            activeColor: Colors.indigo,
                            onChanged: (value) {
                              setState(() {
                                _agreeTerms = value ?? false;
                              });
                            },
                          ),
                          const Expanded(
                            child: Text(
                              "I agree to the Terms & Conditions",
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      loginState.isLoading
                          ? const CircularProgressIndicator()
                          : ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.indigo,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 100, vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: _agreeTerms ? _signUp : null,
                              child: const Text(
                                "Sign Up",
                                style: TextStyle(
                                    fontSize: 18, color: Colors.white),
                              ),
                            ),

                      if (loginState.error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(
                            loginState.error!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),

                      const SizedBox(height: 15),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Already have an account? "),
                          TextButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const LoginPage(),
                                ),
                              );
                            },
                            child: const Text(
                              "Login",
                              style: TextStyle(
                                color: Colors.indigo,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
Future<void> _signUp() async {

  if (_passwordController.text != _confirmPasswordController.text) {

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Password not match")),
    );

    return;
  }

  final loginInfo = LoginInfo(
    name: _nameController.text.trim(),
    address: _addressController.text.trim(),
    agencyName: _agencyController.text.trim(),
    city: _cityController.text.trim(),
    mobile: _mobileController.text.trim(),
    email: _emailController.text.trim(),
    password: _passwordController.text.trim(),
  );

  final response = await ref
      .read(loginViewModelProvider.notifier)
      .addAdmin(loginInfo);

  if (response != null) {

    /// Show message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(response.message)),
    );

    /// Success → Navigate
    if (response.success == 1) {

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const LoginPage(),
        ),
      );

    }

  }
}


  Widget buildTextField(
      TextEditingController controller,
      String label,
      IconData icon,
      {bool obscure = false,
      TextInputType keyboard = TextInputType.text}) {

    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.indigo),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.indigo.shade50,
      ),
    );
  }
}
