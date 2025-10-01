import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hippo_exchange_mobile_app/Firebase/Firebase_service.dart';

typedef LogoutCallback = void Function();


class UserProfilePage extends StatefulWidget {
  const UserProfilePage({super.key});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  bool _isEditing = false;
  
  // User data from Firebase
  String name = "";
  String email = "";
  String? accountCreationDate;
  
  // Loading state
  bool _isLoading = true;

  Future<void> _handleLogout() async {
    try {
      await AuthService().signOut();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logout Successful!')),
        );
        // AuthGate will automatically handle navigation back to login
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logout failed: ${e.toString()}')),
        );
      }
    }
  }

  // Function to load current user data from Firebase
  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        setState(() {
          name = user.displayName ?? "No name set";
          email = user.email ?? "No email";
          accountCreationDate = user.metadata.creationTime?.toString().split(' ')[0] ?? "Unknown";
          _isLoading = false;
        });
        
        // Update text controllers with real data
        _nameController.text = name;
        _emailController.text = email;
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading user data: ${e.toString()}')),
        );
      }
    }
  }

  // Controllers for editing
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData(); // Load Firebase user data when page initializes
  }

  void _toggleEdit() async {
    if (_isEditing) {
      // Save changes when switching back from edit mode
      try {
        // Update local variables (only name since email is read-only)
        name = _nameController.text;
        
        // Update Firebase profile
        await AuthService().updateUserProfile(
          displayName: name.isNotEmpty ? name : null,
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating profile: ${e.toString()}')),
          );
        }
      }
    }
    
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  Widget _buildEditField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white, fontSize: 18),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white, fontSize: 16),
        prefixIcon: Icon(
          label == "Name" ? Icons.person : Icons.email,
          color: Colors.white,
          size: 24,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white, width: 3),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.15),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        centerTitle: false,
        title: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Hippo ',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              TextSpan(
                text: 'Exchange',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF93b9e1),
                ),
              ),
            ],
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF93b9e1),
            ),
            child: IconButton(
              icon: Icon(
                _isEditing ? Icons.save : Icons.edit,
                color: Colors.white,
                size: 24,
              ),
              onPressed: _toggleEdit,
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
            child: SingleChildScrollView(
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _isEditing
                    ? _buildEditMode()
                    : _buildDisplayMode(),
              ),
            ),
          ),
    );
  }

  Widget _buildDisplayMode() {
    return Column(
      children: [
        // Profile avatar in blue circle - larger
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFF93b9e1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(
            Icons.person,
            size: 70,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 40),
        
        // User info in blue card - larger padding and text
        Card(
          elevation: 4,
          color: Color(0xFF93b9e1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                _buildInfoRow(Icons.person, "Name", name),
                const SizedBox(height: 24),
                _buildInfoRow(Icons.email, "Email", email),
                if (accountCreationDate != null) ...[
                  const SizedBox(height: 24),
                  _buildInfoRow(Icons.calendar_today, "Account Created", accountCreationDate!),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 40),
        
        // Logout button - larger
        SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: _handleLogout,
            icon: const Icon(Icons.logout, size: 24),
            label: const Text(
              "Logout",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEditMode() {
    return Card(
      elevation: 4,
      color: Color(0xFF93b9e1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Edit title
            const Text(
              "Edit Profile",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            _buildEditField("Name", _nameController),
            const SizedBox(height: 20),
            // Show email as read-only info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.white.withOpacity(0.1),
                border: Border.all(color: Colors.white54),
              ),
              child: Row(
                children: [
                  Icon(Icons.email, color: Colors.white70, size: 24),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Email (Read-only)",
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          email,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}