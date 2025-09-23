import 'package:flutter/material.dart';
import 'package:hippo_exchange_mobile_app/auth_service.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: RegistrationPage(),
  ));
}

//Registration page class (Shouldn't interfere with coding)
class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegisterPageState();
}
  //the fun begins
  //plays middleman between the client and firebase
  class _RegisterPageState extends State<RegistrationPage> {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();

    //important states that lets the app and client know progress
    bool _loading = false;
    String? _error;
    String? _success;

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

      setState(() => _success = "Registration Successful!" );

      if (email.isEmpty || password.isEmpty) {
        setState(() => _error = 'Email and password are required.' );
        return;
      }
      if (password != confirm) {
        setState(() => _error = 'Passwords do not match.' );
        return;
      }


      //can change password length (firebase may already have a default
      if (password.length < 6) {
        setState(() => _error = 'Password must be at least 6 characters.' );
      }

      //region Server Communication

      setState(() {
        _loading = true;
        _error = null;
      });

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
        }
      } on Exception catch (e) {
        setState(() => _error = e.toString());
      } finally {
        if (mounted) setState(() => _loading = false );
      }
    }
    //endregion

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Hippo Exchange - Register",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha:0.4),
                      offset: const Offset(2, 2),
                      blurRadius: 3,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Example registration fields
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: "Display Name",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: "Email",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Password",
                  border: OutlineInputBorder(),
                ),
              ),
              TextField(
                controller: confirmController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Confirm Password",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              if (_loading)
                const CircularProgressIndicator()
              else
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _handleRegister,
                    child: const Text("Register"),
                  ),
                ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
