import 'package:flutter/material.dart';
import 'package:school_app/services/profile_service.dart';
import 'package:intl/intl.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  ProfilePageState createState() => ProfilePageState();
}

class ProfilePageState extends State<ProfilePage> {
  final ProfileService _profileService = ProfileService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  // Common fields
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _dateOfBirthController = TextEditingController();
  
  // Teacher-specific fields
  final TextEditingController _employeeIdController = TextEditingController();
  final TextEditingController _departmentController = TextEditingController();
  final TextEditingController _qualificationController = TextEditingController();
  final TextEditingController _experienceController = TextEditingController();
  
  // Student-specific fields
  final TextEditingController _studentIdController = TextEditingController();
  final TextEditingController _gradeController = TextEditingController();
  final TextEditingController _rollNumberController = TextEditingController();
  final TextEditingController _parentNameController = TextEditingController();
  final TextEditingController _parentPhoneController = TextEditingController();
  final TextEditingController _emergencyContactController = TextEditingController();
  
  String _selectedGender = 'Male';
  String? _userRole;
  bool _isLoading = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _dateOfBirthController.dispose();
    _employeeIdController.dispose();
    _departmentController.dispose();
    _qualificationController.dispose();
    _experienceController.dispose();
    _studentIdController.dispose();
    _gradeController.dispose();
    _rollNumberController.dispose();
    _parentNameController.dispose();
    _parentPhoneController.dispose();
    _emergencyContactController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    
    try {
      _userRole = await _profileService.getUserRole();
      Map<String, dynamic>? profile = await _profileService.getUserProfile();
      
      if (profile != null) {
        _firstNameController.text = profile['firstName'] ?? '';
        _lastNameController.text = profile['lastName'] ?? '';
        _emailController.text = profile['email'] ?? '';
        _phoneController.text = profile['phone'] ?? '';
        _addressController.text = profile['address'] ?? '';
        _dateOfBirthController.text = profile['dateOfBirth'] ?? '';
        _selectedGender = profile['gender'] ?? 'Male';
        
        if (_userRole == 'teacher') {
          _employeeIdController.text = profile['employeeId'] ?? '';
          _departmentController.text = profile['department'] ?? '';
          _qualificationController.text = profile['qualification'] ?? '';
          _experienceController.text = profile['experience'] ?? '';
        } else if (_userRole == 'student') {
          _studentIdController.text = profile['studentId'] ?? '';
          _gradeController.text = profile['grade'] ?? '';
          _rollNumberController.text = profile['rollNumber'] ?? '';
          _parentNameController.text = profile['parentName'] ?? '';
          _parentPhoneController.text = profile['parentPhone'] ?? '';
          _emergencyContactController.text = profile['emergencyContact'] ?? '';
        }
      }
    } catch (e) {
      // Handle error
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      bool success = await _profileService.updateProfile(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        dateOfBirth: _dateOfBirthController.text.trim(),
        gender: _selectedGender,
        employeeId: _userRole == 'teacher' ? _employeeIdController.text.trim() : null,
        department: _userRole == 'teacher' ? _departmentController.text.trim() : null,
        qualification: _userRole == 'teacher' ? _qualificationController.text.trim() : null,
        experience: _userRole == 'teacher' ? _experienceController.text.trim() : null,
        studentId: _userRole == 'student' ? _studentIdController.text.trim() : null,
        grade: _userRole == 'student' ? _gradeController.text.trim() : null,
        rollNumber: _userRole == 'student' ? _rollNumberController.text.trim() : null,
        parentName: _userRole == 'student' ? _parentNameController.text.trim() : null,
        parentPhone: _userRole == 'student' ? _parentPhoneController.text.trim() : null,
        emergencyContact: _userRole == 'student' ? _emergencyContactController.text.trim() : null,
      );
      
      if (success) {
        setState(() => _isEditing = false);
      }
      
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    
    if (picked != null) {
      setState(() {
        _dateOfBirthController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            ),
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveProfile,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProfileHeader(),
                    const SizedBox(height: 24),
                    _buildPersonalInformation(),
                    const SizedBox(height: 24),
                    if (_userRole == 'teacher') _buildTeacherInformation(),
                    if (_userRole == 'student') _buildStudentInformation(),
                    const SizedBox(height: 32),
                    if (_isEditing) _buildActionButtons(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.white,
            child: Icon(
              _userRole == 'teacher' ? Icons.person : Icons.school,
              size: 50,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '${_firstNameController.text} ${_lastNameController.text}',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _userRole?.toUpperCase() ?? '',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInformation() {
    return _buildSection(
      'Personal Information',
      [
        Row(
          children: [
            Expanded(child: _buildTextField('First Name', _firstNameController, Icons.person)),
            const SizedBox(width: 16),
            Expanded(child: _buildTextField('Last Name', _lastNameController, Icons.person)),
          ],
        ),
        _buildTextField('Email', _emailController, Icons.email, enabled: false),
        _buildTextField('Phone', _phoneController, Icons.phone),
        _buildTextField('Address', _addressController, Icons.location_on, maxLines: 2),
        _buildDateField('Date of Birth', _dateOfBirthController),
        _buildGenderDropdown(),
      ],
    );
  }

  Widget _buildTeacherInformation() {
    return _buildSection(
      'Professional Information',
      [
        _buildTextField('Employee ID', _employeeIdController, Icons.badge),
        _buildTextField('Department', _departmentController, Icons.business),
        _buildTextField('Qualification', _qualificationController, Icons.school),
        _buildTextField('Experience (Years)', _experienceController, Icons.work),
      ],
    );
  }

  Widget _buildStudentInformation() {
    return _buildSection(
      'Academic Information',
      [
        Row(
          children: [
            Expanded(child: _buildTextField('Student ID', _studentIdController, Icons.badge)),
            const SizedBox(width: 16),
            Expanded(child: _buildTextField('Grade', _gradeController, Icons.class_)),
          ],
        ),
        _buildTextField('Roll Number', _rollNumberController, Icons.format_list_numbered),
        const SizedBox(height: 16),
        const Text(
          'Parent/Guardian Information',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        _buildTextField('Parent/Guardian Name', _parentNameController, Icons.person),
        _buildTextField('Parent Phone', _parentPhoneController, Icons.phone),
        _buildTextField('Emergency Contact', _emergencyContactController, Icons.emergency),
      ],
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...children.map((child) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: child,
          )),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {bool enabled = true, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      enabled: _isEditing && enabled,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: _isEditing && enabled ? Colors.white : Colors.grey.shade100,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter $label';
        }
        return null;
      },
    );
  }

  Widget _buildDateField(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      enabled: _isEditing,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.calendar_today),
        suffixIcon: _isEditing ? IconButton(
          icon: const Icon(Icons.calendar_month),
          onPressed: _selectDate,
        ) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: _isEditing ? Colors.white : Colors.grey.shade100,
      ),
      onTap: _isEditing ? _selectDate : null,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select date of birth';
        }
        return null;
      },
    );
  }

  Widget _buildGenderDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedGender,
      decoration: InputDecoration(
        labelText: 'Gender',
        prefixIcon: const Icon(Icons.people),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: _isEditing ? Colors.white : Colors.grey.shade100,
      ),
      items: ['Male', 'Female', 'Other'].map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: _isEditing ? (String? newValue) {
        setState(() {
          _selectedGender = newValue!;
        });
      } : null,
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              setState(() => _isEditing = false);
              _loadProfile(); // Reset to original values
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Cancel'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _saveProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Save Changes'),
          ),
        ),
      ],
    );
  }
}
