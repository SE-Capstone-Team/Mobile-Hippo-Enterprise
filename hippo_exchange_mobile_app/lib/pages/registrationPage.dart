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
