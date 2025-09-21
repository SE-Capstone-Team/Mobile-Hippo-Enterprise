import 'package:flutter/material.dart';
import 'package:hippo_exchange_mobile_app/auth_service.dart';


class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
 final TextEditingController emailController = TextEditingController();
 final TextEditingController passwordController = TextEditingController();

 bool _loading = false;
 String? _error;

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
     // AuthGate in main.dart will switch to HomePage automatically
   } catch (e) {
     setState(() => _error = e.toString());
   } finally {
     if (mounted) setState(() => _loading = false);
   }
 }
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // removes debug banner
      home: Scaffold(
        appBar: AppBar(
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
              SizedBox(
                width: double.infinity,
                height: 50,
                child:ElevatedButton(
                    
                  style: ElevatedButton.styleFrom(
                 
                    backgroundColor: Colors.blueGrey[800],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: (){},
                  child: Text("Login", style: TextStyle(
                    color: Colors.white,
                    fontSize: 20
                    ),
                  )
                )
              ),
            const SizedBox(height: 10),
            
            // Text below login field
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
                onPressed: () {},
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
        // DEMO NAV BAR
        bottomNavigationBar: BottomNavigationBar(
          //type: BottomNavigationBarType.shifting,
          // selected items settings
          selectedItemColor: Colors.black,
          selectedIconTheme: IconThemeData(color: Colors.blueGrey[800]),
          selectedLabelStyle: TextStyle(fontSize: 15),
          
          // unselected items settings
          unselectedItemColor: Colors.black,
          unselectedLabelStyle: TextStyle(fontSize: 15),
          unselectedIconTheme: IconThemeData(color: Colors.blueGrey[800],  ),
          
          // List of items in the actual bar
          items: [
          BottomNavigationBarItem(
            icon: Icon(
              Icons.home,
              ),
            label: "Home",
          
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.login),
            label: "Login",
            ),
          BottomNavigationBarItem(
            icon: Icon(Icons.app_registration),
            label: "Registration"
            ),

          ]
        ),
      
      )
    );

  }
}



// ******************************
// ******************************