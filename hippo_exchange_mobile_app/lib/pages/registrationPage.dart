import 'package:flutter/material.dart';
import 'package:hippo_exchange_mobile_app/Firebase/Firebase_service.dart';



typedef RegisterSuccessCallback = void Function();

//Registration page class (Shouldn't interfere with coding)
class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key, this.onRegisterSuccess, this.onLoginTap});
  final RegisterSuccessCallback? onRegisterSuccess;
  final VoidCallback? onLoginTap;

  @override
  State<RegistrationPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegistrationPage> {
  //final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final addressController = TextEditingController();
    //Used for being able to view password while entering
    bool _isPasswordVisible = false;
    bool _isConfirmPasswordVisible = false;
    //important states that lets the app and client know progress
    bool _loading = false;
    String? _error;

  //when finished sending data to firebase, we dispose of data
  //and let firebase do the work.
  @override
  void dispose() {
    //nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmController.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    addressController.dispose();
    super.dispose();
  }
  //this handles all the registration, this will run after the user hits
  //submit on registration
  Future<void> _handleRegister() async {
    final email = emailController.text.trim();
    final password = passwordController.text;
    final confirm = confirmController.text;
    //final displayName = nameController.text.trim();
    final firstName = firstNameController.text.trim();
    final lastName = lastNameController.text.trim();
    final address = addressController.text.trim();
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
        firstName: firstName,
        lastName: lastName,
        address: address,
       // displayName: displayName.isEmpty ? null : displayName,
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
        title: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Hippo Image
            Container(
              width: 50,
              height: 50,
              child: Image.asset(
                'assets/images/HippoExchangeLogo.png',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 12),
            // Centered Title Text
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'Hippo ',
                    style: TextStyle(
                      fontSize: 32.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  TextSpan(
                    text: 'Exchange',
                    style: TextStyle(
                      fontSize: 32.0,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF93b9e1),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              alignment: Alignment.topCenter,
              width: 365,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 20), // Reduced spacing to move card up

                  // Card containing registration fields
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
                          // Personal Info Label
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Personal Info",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white),
                            ),
                          ),
                          const SizedBox(height: 8),
                          
                          // First Name and Last Name on same row
                          Row(
                            children: [
                              // First Name
                              Expanded(
                                child: TextField(
                                  controller: firstNameController,
                                  decoration: InputDecoration(
                                    hintText: "First Name",
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Last Name
                              Expanded(
                                child: TextField(
                                  controller: lastNameController,
                                  decoration: InputDecoration(
                                    hintText: "Last Name",
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Address
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Address",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: addressController,
                            decoration: InputDecoration(
                              hintText: "Enter your address",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Email
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Email",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white),
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
                              fillColor: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Password
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Password",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: passwordController,
                            obscureText: !_isPasswordVisible,
                            decoration: InputDecoration(
                              hintText: "Enter password",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isPasswordVisible = !_isPasswordVisible;
                                  });
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Confirm Password
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Confirm Password",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: confirmController,
                            obscureText: !_isConfirmPasswordVisible,
                            onSubmitted: (_) => _handleRegister(), // Submit on Enter
                            decoration: InputDecoration(
                              hintText: "Re-enter password",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isConfirmPasswordVisible ? Icons.visibility_off : Icons.visibility,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                                  });
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Register button
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
                                onPressed: _handleRegister,
                                child: Text(
                                  "Register",
                                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                        ],
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
                  
                  const SizedBox(height: 15),
                  
                  // Login link
                  if (!_loading)
                    TextButton(
                      onPressed: widget.onLoginTap,
                      child: Text(
                        "- Already have an account? Login here -",
                        style: TextStyle(
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
