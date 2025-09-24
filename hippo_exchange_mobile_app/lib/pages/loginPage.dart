import 'package:flutter/material.dart';
import 'package:hippo_exchange_mobile_app/auth_service.dart';



typedef RegisterCallback = void Function();

class LoginPage extends StatefulWidget {
  final RegisterCallback? onRegisterTap;
  const LoginPage({super.key, this.onRegisterTap});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
 final TextEditingController emailController = TextEditingController();
 final TextEditingController passwordController = TextEditingController();

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
   //waits for email and password from user
   //region email signin
   try {
     await AuthService().emailsignin(
       email: emailController.text.trim(),
       password: passwordController.text.trim(),
     );
     // AuthGate in main.dart will switch to HomePage automatically
     if (mounted) {
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('Login successful!')),
       );
     }
   } on Exception catch (e) {
     setState(() => _error = e.toString());
   } finally {
     if (mounted) setState(() => _loading = false );
   } //endregion
 }

  Widget build(BuildContext context) {
    return MaterialApp(
      //color: Colors.white,
      debugShowCheckedModeBanner: false, // removes debug banner
      home: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          title:  Text(
            'Hippo Enterprise',
            style: TextStyle(
              shadows: [
              Shadow(
                blurRadius: 10.0,
                color: Colors.black,
                offset: Offset(0, 0.3),
              ),
              ],
              fontSize: 40.0, // Adjust the font size as needed
              fontWeight: FontWeight.bold,

            ),
            
          ),
          centerTitle: true,
          
        ),
        
        body: Center(
        child: Container(
          alignment: Alignment.topCenter,
          width: 350,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            //border: Border.all(color: Colors.blueGrey, width: 1.5), // used for testing container size
            borderRadius: BorderRadius.circular(16),
           
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 150),


              // Username text above field
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Email",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
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
                  fillColor: Colors.grey[100],
                ),
              ),
              const SizedBox(height: 20),


              // Password text above field
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Password",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(height: 8),

              // Password field box 
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: "Enter Password",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
              
                ),
              ),
              const SizedBox(height: 20),
              if (_loading)
                const CircularProgressIndicator()
              else SizedBox(
                  width: double.infinity,
                  height: 50,
                  child:ElevatedButton(

                    style: ElevatedButton.styleFrom(

                      backgroundColor: Colors.blueGrey[800],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _handleLogin,
                    child: Text("Login", style: TextStyle(
                      color: Colors.white,
                      fontSize: 20
                      ),
                    ),
                  ),
                ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],

            // Text below login field
            if(!_loading)
            Text(
              "- Dont Have and Account? -",
              style: TextStyle(
                //decoration: TextDecoration,
                color: Colors.grey[700],
                fontSize: 16,

              ),
            ),
            const SizedBox(height: 15),

            // Registration button
            if(!_loading)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey[800],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: widget.onRegisterTap,
                child: Text(
                  "Register",
                  style: TextStyle(color: Colors.white, fontSize: 20),
                ),
              ),
            ),
                const SizedBox(height: 10),


      

            ],

          ),
        ),
      ),
      
      )
    );

  }
}



// ******************************
// ******************************