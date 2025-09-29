import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hippo_exchange_mobile_app/Firebase/Firebase_service.dart';

typedef LogoutCallback = void Function();


class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key, this.onLogoutSuccess, /*this.onLogoutTap*/});
  final LogoutCallback? onLogoutSuccess;
  //final LogoutTap? onLogoutTap;


  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  bool _isEditing = false;

  bool _loading = false;
  String? _error;

  Future<void> _handleLogout() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await AuthService().signOut();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Logout Successful!')));
        if (widget.onLogoutSuccess != null) {
          widget.onLogoutSuccess!();
        }
      }
    } on Exception catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }



  // Example user details
  String name = "John Tester";
  String email = "Tester@test.com";
  String phone = "+1 (123) 456-7890";

  // Controllers for editing
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController.text = name;
    _emailController.text = email;
    _phoneController.text = phone;
  }

  void _toggleEdit() {
    setState(() {
      if (_isEditing) {
        // Save changes when switching back
        name = _nameController.text;
        email = _emailController.text;
        phone = _phoneController.text;
      }
      _isEditing = !_isEditing;
    });
  }

  Widget _buildDisplayTile(IconData icon, String label, String value) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(value),
      ),
    );
  }

  Widget _buildEditField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: label == "Name"
              ? const Icon(Icons.person)
              : label == "Email"
              ? const Icon(Icons.email)
              : const Icon(Icons.phone),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("User Profile"),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.save : Icons.edit),
            onPressed: _toggleEdit,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: _isEditing
            ? Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildEditField("Name", _nameController),
            _buildEditField("Email", _emailController),
            _buildEditField("Phone", _phoneController),
          ],
        )
            : Column(
          children: [
            // Profile header card
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 4,
              margin: const EdgeInsets.only(bottom: 20),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 35,
                      backgroundColor: Colors.blueAccent,
                      child: Icon(Icons.person,
                          size: 40, color: Colors.white),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name,
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          Text(email,
                              style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade700)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Info section
            _buildDisplayTile(Icons.phone, "Phone", phone),
            _buildDisplayTile(Icons.email, "Email", email),
            _buildDisplayTile(Icons.person, "Name", name),

            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
              onPressed: _handleLogout,
            )
          ],
        ),
      ),
    );
  }
}