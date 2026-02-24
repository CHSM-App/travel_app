import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_agency_app/Screens/bottom_navigation_bar.dart';
import 'package:travel_agency_app/Screens/forgot_password.dart';
import 'package:travel_agency_app/Screens/signup_page.dart';
import 'package:travel_agency_app/domain/models/login_info.dart';
import 'package:travel_agency_app/domain/models/token_response.dart';
import 'package:travel_agency_app/presentation/providers/viewmodel_provider.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  //--------------------------------------------------
  // LOGIN FUNCTION
  //--------------------------------------------------
  Future<void> _login() async {

    final mobile = _mobileController.text.trim();
    final password = _passwordController.text.trim();

    if (mobile.isEmpty || password.isEmpty) {
      showMessage("Enter mobile and password");
      return;
    }

    //--------------------------------------------------
    // STEP 1: LOGIN API CALL
    //--------------------------------------------------

    final loginInfo = LoginInfo(
      mobile: mobile,
      password: password,
    );

    final loginResponse =
        await ref.read(loginViewModelProvider.notifier)
            .login(loginInfo);
    // CHECK LOGIN SUCCESS
    //--------------------------------------------------

    if (loginResponse == null || loginResponse.success != 1) {

      showMessage(loginResponse?.message ?? "Login Failed");

      return;
    }
    // STEP 2: CREATE LOGIN API CALL (TOKEN GENERATE)
    //--------------------------------------------------

    final tokenRequest = TokenResponse(
      mobile: loginResponse.mobile,
    deviceDetails: ""
    );

    final tokenResult =
        await ref.read(authViewModelProvider.notifier)
            .createLogin(tokenRequest);

    if (tokenResult == null) {

      showMessage("Token generation failed");

      return;
    }

    //--------------------------------------------------
    // STEP 3: NAVIGATE TO DASHBOARD
    //--------------------------------------------------

    if (mounted) {

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const MainBottomNav(),
        ),
      );
    }
  }

  //--------------------------------------------------
  // SHOW MESSAGE
  //--------------------------------------------------

  void showMessage(String message) {

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  //--------------------------------------------------
  // UI
  //--------------------------------------------------

  @override
  Widget build(BuildContext context) {

    final loginState = ref.watch(loginViewModelProvider);
    final authState = ref.watch(authViewModelProvider);

    final isLoading =
        loginState.isLoading || authState.isLoading;

    return Scaffold(

      backgroundColor: Colors.grey.shade50,

      body: Center(
        child: SingleChildScrollView(

          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),

            child: Column(

              children: [

                const SizedBox(height: 40),

                const CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.indigo,
                  child: Icon(
                    Icons.travel_explore,
                    size: 50,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 30),

                const Text(
                  "Welcome Back",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                  ),
                ),

                const SizedBox(height: 40),

                Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),

                  child: Padding(
                    padding: const EdgeInsets.all(20),

                    child: Column(

                      children: [

                        //--------------------------------
                        // MOBILE
                        //--------------------------------

                        TextField(
                          controller: _mobileController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: "Mobile Number",
                            prefixIcon: const Icon(Icons.phone),
                            filled: true,
                          ),
                        ),

                        const SizedBox(height: 20),

                        //--------------------------------
                        // PASSWORD
                        //--------------------------------

                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: "Password",
                            prefixIcon: const Icon(Icons.lock),
                            filled: true,
                          ),
                        ),

                        const SizedBox(height: 30),

                        //--------------------------------
                        // LOGIN BUTTON
                        //--------------------------------

                        SizedBox(
                          width: double.infinity,
                          height: 50,

                          child: ElevatedButton(

                            onPressed:
                                isLoading ? null : _login,

                            child: isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white)
                                : const Text("Login"),
                          ),
                        ),

                        const SizedBox(height: 10),

                        //--------------------------------
                        // FORGOT PASSWORD
                        //--------------------------------

                        TextButton(
                          onPressed: () {

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const ForgotPasswordPage(),
                              ),
                            );
                          },
                          child: const Text(
                              "Forgot Password?"),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                //--------------------------------
                // SIGNUP
                //--------------------------------

                TextButton(
                  onPressed: () {

                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const SignUpPage(),
                      ),
                    );
                  },
                  child: const Text("Sign Up"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}