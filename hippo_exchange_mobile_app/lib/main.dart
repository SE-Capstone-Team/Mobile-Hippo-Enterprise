import 'package:flutter/material.dart';

void main() {
  
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
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
                  "Username",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(height: 8),
              
              // Username text field
              TextField(
                decoration: InputDecoration(
                  hintText: "Enter Username",
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
            // HYPERLINK BUTTON FOR REGISTERATION 
            //  INSTEAD OF BUTTON OPTION
            // TextButton( onPressed: () {
              
            //   },
            //   child: Text(
            //        "Dont Have and Account?",
            //         style: TextStyle(
            //           decoration: TextDecoration.underline,
            //           color: Colors.grey[700],
            //           fontSize: 15,
            //         ),
            //       )
            
            // )
            
            // Text below login field
            Text(
              "Dont Have and Account?",
              style: TextStyle(
                decoration: TextDecoration.underline,
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
