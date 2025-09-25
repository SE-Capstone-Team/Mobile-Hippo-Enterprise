import 'package:flutter/material.dart';
import 'package:hippo_exchange_mobile_app/Firebase_service.dart';


typedef RegisterSuccessCallback = void Function();

//Registration page class (Shouldn't interfere with coding)
class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key, this.onRegisterSuccess});
  final RegisterSuccessCallback? onRegisterSuccess;

  @override
  State<RegistrationPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegistrationPage> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();

  //important states that lets the app and client know progress
  bool _loading = false;
  String? _error;

  //when finished sending data to firebase, we dispose of data
  //and let firebase do the work.
  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    super.dispose();
  }
  //this handles all the registration, this will run after the user hits
  //submit on registration
  Future<void> _handleRegister() async {
    final email = emailController.text.trim();
    final password = passwordController.text;
    final confirm = confirmController.text;
    final displayName = nameController.text.trim();

    //region email password complexity
    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Email and password are required.' );
      return;
    }
    if (password != confirm) {
      setState(() => _error = 'Passwords do not match.' );
      return;
    }
    if (RegExp(r'\s').hasMatch(password)) {
      setState(() => _error =  'No spaces allowed in password.');
      return;
    }
    if (password.length < 8) {
      setState(() => _error = 'Password must be at least 8 characters.' );
      return;
    }
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      setState(() => _error = 'Add at least one uppercase letter.');
      return;
    }
    if (!RegExp(r'\d').hasMatch(password)) {
      setState(() => _error = 'Add at least one number.');
      return;
    }
    if (!RegExp(r'[^\w\s]').hasMatch(password)) { // any non-alphanumeric (no space)
      setState(() => _error = 'Add at least one symbol.');
      return;
    }
    //endregion


    setState(() {
      _loading = true;
      _error = null;
    });

    //region connection to firebase
    try{
      await AuthService().register(
        email: email,
        password: password,
        displayName: displayName.isEmpty ? null : displayName,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registered successfully!')),
        );
        if (widget.onRegisterSuccess != null) {
          widget.onRegisterSuccess!();
        }
      }
    } on Exception catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false );
    }//endregion


  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.white,
        centerTitle: true,
        title: Text(
          'Hippo Exchange',
          style: TextStyle(
            shadows: [
              Shadow(
                blurRadius: 10.0,
                color: Colors.black,
                offset: Offset(0, 0.3),
              ),
            ],
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 350),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 10),
                Center(
                  child: Image.asset(
                    'assets/images/HippoExchangeLogo.png',
                    height: 180, // make it bigger
                  ),
                ),
                const SizedBox(height: 30),

                // Display Name
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Display Name",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    hintText: "Enter your name",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                ),
                const SizedBox(height: 20),

                // Email
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Email",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    hintText: "Enter your email",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                ),
                const SizedBox(height: 20),

                // Password
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Password",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: "Enter password",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                ),
                const SizedBox(height: 20),

                // Confirm Password
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Confirm Password",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: confirmController,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: "Re-enter password",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                ),
                const SizedBox(height: 24),

                // Register button
                if (_loading)
                  const Center(child: CircularProgressIndicator())
                else
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueGrey[800],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _handleRegister,
                      child: const Text(
                        "Register",
                        style: TextStyle(color: Colors.white, fontSize: 20),
                      ),
                    ),
                  ),

                // Error message
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ],

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
