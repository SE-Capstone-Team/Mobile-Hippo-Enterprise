import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hippo_exchange_mobile_app/Firebase/Firebase_service.dart';
import 'package:hippo_exchange_mobile_app/pages/mainPostLogin.dart';

typedef RegisterCallback = void Function();
typedef LoginSuccessCallback = void Function();

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, this.onRegisterTap, this.onLoginSuccess});
  final RegisterCallback? onRegisterTap;
  final LoginSuccessCallback? onLoginSuccess;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _isPasswordVisible = true;

  bool _loading = false;
  String? _error;

  //removes local variables when done sending to the server
  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await AuthService().emailsignin(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Login successful!')));
        if (widget.onLoginSuccess != null) {
          widget.onLoginSuccess!();
        }
      }
    } on Exception catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget build(BuildContext context) {
    return MaterialApp(
      //color: Colors.white,
      debugShowCheckedModeBanner: false, // removes debug banner
      home: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'Hippo ',
                  style: TextStyle(
                    fontSize: 40.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                TextSpan(
                  text: 'Exchange',
                  style: TextStyle(
                    fontSize: 40.0,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF93b9e1),
                  ),
                ),
              ],
            ),
          ),
          centerTitle: true,
        ),

        body: Center(
          child: SingleChildScrollView(
          child: Container(
            alignment: Alignment.topCenter,
            width: 365,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              //border: Border.all(color: Colors.blueGrey, width: 1.5), // used for testing container size
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                 const SizedBox(height: 10),
                Center(
                  child: Image.asset(
                    'assets/images/HippoExchangeLogo.png',
                    height: 250, // make it bigger
                  ),
                ),
                const SizedBox(height: 30),

                // Card containing login fields
                Card(
                  elevation: 4,
                  color: Color(0xFF93b9e1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        // Username text above field
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Email",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Username text field
                        TextField(
                          controller: emailController,
                          decoration: InputDecoration(
                            hintText: "Enter Email",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Password text above field
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            "Password",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Password field box
                        TextField(
                          controller: passwordController,
                          obscureText: _isPasswordVisible,
                          decoration: InputDecoration(
                            hintText: "Enter Password",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            suffixIcon: IconButton(
                              icon: Icon(
                                // Choose the icon based on the visibility state
                                _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                              ),
                              onPressed: () {
                                // Update the state to toggle visibility
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (_loading)
                          const CircularProgressIndicator(color: Colors.white)
                        else
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Color(0xFF93b9e1),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: _handleLogin,
                              child: Text(
                                "Login",
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                ],
                const SizedBox(height: 15),
                // Text below login field
                if (!_loading)
                  TextButton(
                    onPressed: widget.onRegisterTap,
                    child:Text( "- Need to create an account? -",
                    style: TextStyle(
                      //decoration: TextDecoration,
                      color: Colors.grey[700],
                      fontSize: 16,
                    ),
                    ),
                    
                  ),
             

                const SizedBox(height: 10),
              ],
            ),
          ),
          ),
        ),
      ),
    );
  }
}



// ******************************
// ******************************