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
        // ScaffoldMessenger.of(
        //   context,
        // ).showSnackBar(const SnackBar(content: Text('Login successful!')));
        if (widget.onLoginSuccess != null) {
          widget.onLoginSuccess!();
        }
      }
    } on Exception catch (e) {
      setState(() => _error = AuthService().mapAuthError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
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
            width: 370, // Narrowed from 400
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              //border: Border.all(color: Colors.blueGrey, width: 1.5), // used for testing container size
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                 const SizedBox(height: 10),
                // // Welcome message
                // Text(
                //   "Sign in to start trading!",
                //   style: TextStyle(
                //     fontSize: 28,
                //     fontWeight: FontWeight.bold,
                //     color: Colors.grey[800],
                //   ),
                // ),
                const SizedBox(height: 20),

                // Static floating icons around hippo
                SizedBox(
                  height: 280,
                  width: 300,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Central Hippo Logo with rounded border
                      Container(
                        width: 170, // Slightly reduced from 180
                        height: 170,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24), // Rounded rectangle instead of circle
                          border: Border.all(
                            color: Color(0xFF93b9e1),
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(21), // Slightly smaller to account for border
                          child: Image.asset(
                            'assets/images/HippoExchangeLogo.png',
                            fit: BoxFit.cover, // Changed from contain to cover to fill the space
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        ),
                      ),
                      // Decorative icons around the logo - commented out as they look odd
                      // Positioned(
                      //   top: 20,
                      //   left: 60,
                      //   child: _buildDecorativeIcon(Icons.shopping_bag, Color(0xFF93b9e1)),
                      // ),
                      // Positioned(
                      //   top: 20,
                      //   right: 60,
                      //   child: _buildDecorativeIcon(Icons.handshake, Color(0xFF93b9e1)),
                      // ),
                      // Positioned(
                      //   bottom: 20,
                      //   left: 60,
                      //   child: _buildDecorativeIcon(Icons.swap_horiz, Color(0xFF93b9e1)),
                      // ),
                      // Positioned(
                      //   bottom: 20,
                      //   right: 60,
                      //   child: _buildDecorativeIcon(Icons.star, Color(0xFF93b9e1)),
                      // ),
                    ],
                  ),
                ),
                const SizedBox(height: 20), // Reduced from 25 to help achieve 30-pixel total reduction

                // Feature highlights - commented out as they look odd and aren't functional
                // Container(
                //   padding: const EdgeInsets.symmetric(horizontal: 20),
                //   child: Row(
                //     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                //     children: [
                //       _buildFeatureItem(Icons.swap_horiz, "Trade"),
                //       _buildFeatureItem(Icons.security, "Secure"),
                //       _buildFeatureItem(Icons.people, "Connect"),
                //     ],
                //   ),
                // ),
                // Removed SizedBox to reduce spacing by 30 pixels (was 25 + 25 = 50, now just 25)

                // Card containing login fields
                Card(
                  elevation: 6, // Increased from 4
                  color: Color(0xFF93b9e1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    width: double.infinity,
                    child: Padding(
                      padding: const EdgeInsets.all(30), // Returned to previous size
                      child: Column(
                        children: [
                          // Email text above field
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Email",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.white), // Increased from 16
                            ),
                          ),
                          const SizedBox(height: 12), // Increased from 8

                          // Email text field
                          Container(
                            height: 60, // Added explicit height
                            child: TextField(
                              controller: emailController,
                              style: TextStyle(fontSize: 16),
                              decoration: InputDecoration(
                                hintText: "Enter Email",
                                hintStyle: TextStyle(fontSize: 16),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                              ),
                            ),
                          ),
                          const SizedBox(height: 18), // Evened out spacing (was 25, reduced by 7)

                          // Password text above field
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Password",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.white), // Increased from 16
                            ),
                          ),
                          const SizedBox(height: 12), // Increased from 8

                          // Password field box
                          Container(
                            height: 60, // Added explicit height
                            child: TextField(
                              controller: passwordController,
                              obscureText: _isPasswordVisible,
                              onSubmitted: (_) => _handleLogin(), // Submit on Enter
                              style: TextStyle(fontSize: 16),
                              decoration: InputDecoration(
                                hintText: "Enter Password",
                                hintStyle: TextStyle(fontSize: 16),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
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
                          ),
                        
                          // Forgot Password link - commented out as it has no function
                          // Align(
                          //   alignment: Alignment.centerRight,
                          //   child: TextButton(
                          //     onPressed: () {
                          //       // TODO: Implement forgot password functionality
                          //       ScaffoldMessenger.of(context).showSnackBar(
                          //         const SnackBar(content: Text('Forgot password feature coming soon!')),
                          //       );
                          //     },
                          //     child: Text(
                          //       "Forgot Password?",
                          //       style: TextStyle(
                          //         color: Colors.white,
                          //         fontSize: 14,
                          //         decoration: TextDecoration.underline,
                          //         decorationColor: Colors.white,
                          //       ),
                          //     ),
                          //   ),
                          // ),
                          const SizedBox(height: 32), // Increased by 7 to compensate (was 25, now 32)
                          if (_loading)
                            const CircularProgressIndicator(color: Colors.white)
                          else
                            SizedBox(
                              width: double.infinity,
                              height: 55, // Increased from 50
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
                                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold), // Increased from 20
                                ),
                              ),
                            ),
                        ],
                      ),
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
                      fontSize: 18, // Increased from 16
                      fontWeight: FontWeight.w500, // Added weight
                    ),
                    ),
                    
                  ),
             

                const SizedBox(height: 20),
                
                // Footer section with app info
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      Divider(color: Colors.grey[300], thickness: 1),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.security, color: Colors.grey[600], size: 16),
                          const SizedBox(width: 8),
                          Text(
                            "Secure • Trusted • Easy",
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "© 2025 Hippo Exchange",
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                        ),
                      ),
                    ],
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