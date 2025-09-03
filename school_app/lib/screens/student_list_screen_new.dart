import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:school_app/screens/add_student_screen.dart';
import 'package:school_app/screens/update_student_screen.dart';
import 'package:school_app/services/student_service.dart';
import 'package:school_app/services/class_service.dart';
import 'package:school_app/authentication/auth_service.dart' as auth_service;

class StudentListScreen extends StatefulWidget {
  const StudentListScreen({super.key});

  @override
  _StudentListScreenState createState() => _StudentListScreenState();
}

class _StudentListScreenState extends State<StudentListScreen> {
  final StudentService _studentService = StudentService();
  final ClassService _classService = ClassService();
  final auth_service.AuthService _authService = auth_service.AuthService();
  
  String? _selectedClassId;
  String? _selectedClassName;
  List<Map<String, dynamic>> _availableClasses = [];
  String? _userRole;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadUserRole() async {
    String? role = await _authService.getUserRole();
    setState(() {
      _userRole = role;
    });
    _loadAvailableClasses();
  }

  void _loadAvailableClasses() {
    if (_userRole == 'admin') {
      // Admin can see all classes
      _classService.getAllClasses().listen((snapshot) {
        List<Map<String, dynamic>> classes = [];
        for (var doc in snapshot.docs) {
          Map<String, dynamic> classData = doc.data() as Map<String, dynamic>;
          classData['id'] = doc.id;
          classes.add(classData);
        }
        setState(() {
          _availableClasses = classes;
        });
      });
    } else if (_userRole == 'teacher') {
      // Teacher can only see their classes
      _classService.getMyClasses().listen((snapshot) {
        List<Map<String, dynamic>> classes = [];
        for (var doc in snapshot.docs) {
          Map<String, dynamic> classData = doc.data() as Map<String, dynamic>;
          classData['id'] = doc.id;
          classes.add(classData);
        }
        setState(() {
          _availableClasses = classes;
        });
      });
    }
  }

  Stream<QuerySnapshot> _getStudentsStream() {
    if (_selectedClassId != null) {
      // Get students from specific class
      return FirebaseFirestore.instance
          .collection('profiles')
          .where('role', isEqualTo: 'student')
          .where('classId', isEqualTo: _selectedClassId)
          .snapshots();
    } else {
      // Get all students
      return _studentService.getStudents();
    }
  }

  List<DocumentSnapshot> _filterStudents(List<DocumentSnapshot> students) {
    if (_searchQuery.isEmpty) return students;
    
    return students.where((doc) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      String firstName = (data['firstName'] ?? '').toString().toLowerCase();
      String lastName = (data['lastName'] ?? '').toString().toLowerCase();
      String email = (data['email'] ?? '').toString().toLowerCase();
      String fullName = '$firstName $lastName';
      
      return fullName.contains(_searchQuery) || 
             firstName.contains(_searchQuery) ||
             lastName.contains(_searchQuery) ||
             email.contains(_searchQuery);
    }).toList();
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Students by Class'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.all_inclusive),
                title: const Text('All Students'),
                onTap: () {
                  setState(() {
                    _selectedClassId = null;
                    _selectedClassName = null;
                  });
                  Navigator.pop(context);
                },
              ),
              const Divider(),
              ..._availableClasses.map((classData) {
                return ListTile(
                  leading: const Icon(Icons.class_),
                  title: Text('${classData['className']} - ${classData['section']}'),
                  subtitle: Text('${classData['currentStudents'] ?? 0} students'),
                  onTap: () {
                    setState(() {
                      _selectedClassId = classData['id'];
                      _selectedClassName = '${classData['className']} - ${classData['section']}';
                    });
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final bool isTablet = screenSize.width > 600;
    final bool isDesktop = screenSize.width > 1024;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.indigo,
        title: const Text(
          'Student Management',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.indigo.withOpacity(0.05), Colors.white],
          ),
        ),
        child: Column(
          children: [
            _buildFilterHeader(),
            _buildSearchBar(),
            Expanded(
              child: _buildStudentList(isTablet, isDesktop),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddStudentScreen()),
          );
        },
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildFilterHeader() {
    if (_selectedClassId == null) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.indigo.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.indigo.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.class_, color: Colors.indigo, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Viewing students in: $_selectedClassName',
              style: TextStyle(
                color: Colors.indigo[800],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _selectedClassId = null;
                _selectedClassName = null;
              });
            },
            child: const Text('Clear Filter'),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search students by name or email...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey[100],
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value.toLowerCase();
          });
        },
      ),
    );
  }

  Widget _buildStudentList(bool isTablet, bool isDesktop) {
    return StreamBuilder<QuerySnapshot>(
      stream: _getStudentsStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                const SizedBox(height: 16),
                Text(
                  'Error loading students',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  snapshot.error.toString(),
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.indigo),
          );
        }

        List<DocumentSnapshot> students = snapshot.data?.docs ?? [];
        List<DocumentSnapshot> filteredStudents = _filterStudents(students);

        if (filteredStudents.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  _selectedClassId != null 
                      ? 'No students in this class'
                      : _searchQuery.isNotEmpty
                          ? 'No students found matching your search'
                          : 'No students registered yet',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  _selectedClassId != null 
                      ? 'Students can be assigned to this class from the Class Management section'
                      : 'Students will appear here once they register',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredStudents.length,
          itemBuilder: (context, index) {
            final student = filteredStudents[index];
            final data = student.data() as Map<String, dynamic>;
            
            return _buildStudentCard(student.id, data, isTablet);
          },
        );
      },
    );
  }

  Widget _buildStudentCard(String studentId, Map<String, dynamic> data, bool isTablet) {
    final String firstName = data['firstName'] ?? '';
    final String lastName = data['lastName'] ?? '';
    final String email = data['email'] ?? '';
    final String phone = data['phone'] ?? '';
    final String className = data['className'] ?? 'Not assigned';
    final String section = data['section'] ?? '';
    final String classDisplay = section.isNotEmpty ? '$className - $section' : className;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UpdateStudentScreen(
                studentId: studentId,
                studentData: data,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: isTablet ? 30 : 25,
                    backgroundColor: Colors.indigo.withOpacity(0.1),
                    child: Text(
                      firstName.isNotEmpty ? firstName[0].toUpperCase() : 'S',
                      style: TextStyle(
                        fontSize: isTablet ? 24 : 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$firstName $lastName'.trim(),
                          style: TextStyle(
                            fontSize: isTablet ? 18 : 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          email,
                          style: TextStyle(
                            fontSize: isTablet ? 14 : 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => UpdateStudentScreen(
                              studentId: studentId,
                              studentData: data,
                            ),
                          ),
                        );
                      } else if (value == 'delete') {
                        _showDeleteConfirmation(studentId, '$firstName $lastName');
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                          leading: Icon(Icons.edit, size: 20),
                          title: Text('Edit'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete, size: 20, color: Colors.red),
                          title: Text('Delete', style: TextStyle(color: Colors.red)),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoChip(
                      icon: Icons.class_,
                      label: 'Class',
                      value: classDisplay,
                      color: className != 'Not assigned' ? Colors.green : Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildInfoChip(
                      icon: Icons.phone,
                      label: 'Phone',
                      value: phone.isNotEmpty ? phone : 'Not provided',
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(String studentId, String studentName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Student'),
        content: Text('Are you sure you want to delete $studentName?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _studentService.deleteStudent(studentId);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$studentName has been deleted'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
