import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
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
  String firstName = "";
  String lastName = "";
  String email = "";
  String address = "";
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
    final user = FirebaseAuth.instance.currentUser;
    final _db = FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: AuthService.kFirestoreDbId);
    final DocumentReference userProfileRef = _db.collection('profiles').doc(user?.uid);
    final userProfile = await userProfileRef.get();
    final loadedFirstName = userProfile['firstName'] ?? '';
    final loadedLastName = userProfile['lastName'] ?? '';
    final loadedAddress = userProfile['address'] ?? '';

    try {
      if (user != null) {
        setState(() {
          firstName = loadedFirstName;
          lastName = loadedLastName;
          address = loadedAddress;
          email = user.email ?? "No email";
          accountCreationDate = user.metadata.creationTime?.toString().split(' ')[0] ?? "Unknown";
          _isLoading = false;
        });

        // Update text controllers with real data
        _firstNameController.text = firstName;
        _lastNameController.text = lastName;
        _addressController.text = address;
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
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData(); // Load Firebase user data when page initializes
  }

  void _toggleEdit() async {
    if (_isEditing) {
      // Save changes when switching back from edit mode
      try {
        final newFirstName = _firstNameController.text;
        final newLastName = _lastNameController.text;
        final newAddress = _addressController.text;

        // Update Firebase profile
        await AuthService().updateUserProfile(
          firstName: newFirstName.isNotEmpty ? newFirstName : null,
          lastName: newLastName.isNotEmpty ? newLastName : null,
          address: newAddress.isNotEmpty ? newAddress : null,
        );

        setState(() {
          firstName = newFirstName;
          lastName = newLastName;
          address = newAddress;
        });

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
      onSubmitted: (_) => _toggleEdit(), // Submit on Enter - acts like save button
      style: const TextStyle(color: Colors.white, fontSize: 18),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white, fontSize: 16),
        prefixIcon: Icon(
          label.contains("Name")
              ? Icons.person
              : label == "Address"
                  ? Icons.location_city
                  : Icons.email,
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
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F7FA),
        centerTitle: false,
        elevation: 0,
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
                text: 'Exchange: ',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF93b9e1),
                ),
              ),
              TextSpan(
                text: 'Profile',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
        actions: [
          if (!_isEditing)
            Container(
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF93b9e1),
              ),
              child: IconButton(
                icon: Icon(
                  Icons.edit,
                  color: Colors.white,
                  size: 24,
                ),
                onPressed: _toggleEdit,
              ),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.0),
          child: Container(
            color: Color(0xFF93b9e1).withOpacity(0.2),
            height: 1.0,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: SingleChildScrollView(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.9,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _isEditing ? _buildEditMode() : _buildDisplayMode(),
                ),
              ),
            ),
    );
  }

  Widget _buildDisplayMode() {
    final lastInitial = lastName.isNotEmpty ? '${lastName[0]}.' : '';
    final displayName = '$firstName $lastInitial';

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
                _buildInfoRow(Icons.person, "Name", displayName),
                const SizedBox(height: 24),
                _buildInfoRow(Icons.email, "Email", email),
                const SizedBox(height: 24),
                _buildInfoRow(Icons.location_city, "Address", address),
                if (accountCreationDate != null) ...[
                  const SizedBox(height: 24),
                  _buildInfoRow(Icons.calendar_today, "Account Created", accountCreationDate!),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 40),

        // Logout button - less prominent
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.grey[600],
              side: BorderSide(color: Colors.grey[400]!, width: 1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: Colors.white,
            ),
            onPressed: _handleLogout,
            icon: const Icon(Icons.logout, size: 20),
            label: const Text(
              "Logout",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
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
            _buildEditField("First Name", _firstNameController),
            const SizedBox(height: 20),
            _buildEditField("Last Name", _lastNameController),
            const SizedBox(height: 20),
            _buildEditField("Address", _addressController),
            const SizedBox(height: 30),

            // Save button - larger and below edit fields
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: _toggleEdit,
                icon: const Icon(Icons.save, size: 28),
                label: const Text(
                  "Save Changes",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
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
