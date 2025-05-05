import 'package:flutter/material.dart';
import 'package:school_app/authentication/auth_service.dart';
import 'package:school_app/authentication/login_page.dart';
import 'package:school_app/dashboard/student_dashboard_screen.dart';
import 'package:school_app/screens/assignment_list_screen.dart';
import 'package:school_app/screens/attendance_mark_screen.dart';
import 'package:school_app/screens/student_attendance_screen.dart';
import 'package:school_app/screens/student_list_screen.dart';
import 'package:school_app/screens/timetable_list_screen.dart';
import 'package:school_app/screens/view_timetable_screen.dart';
import 'package:fluttertoast/fluttertoast.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  String? _userRole;
  bool _isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _loadUserRole() async {
    String? role = await _authService.getUserRole();
    setState(() {
      _userRole = role;
      _isLoading = false;
    });
  }

  void _logout() async {
    await _authService.logout();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
    Fluttertoast.showToast(msg: 'Logged out successfully');
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _buildDashboard(),
    );
  }

  Widget _buildDashboard() {
    return SafeArea(
      child: Column(
        children: [
          _buildAppBar(),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      'Dashboard',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: FadeTransition(
                        opacity: _animation,
                        child: _buildMenuGrid(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getGreeting(),
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _userRole == 'admin'
                    ? 'Admin'
                    : _userRole == 'teacher'
                        ? 'Teacher'
                        : 'Student',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {
                  // Notification functionality can be added here
                },
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _logout,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.logout,
                        color: Colors.red[700],
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Logout',
                        style: TextStyle(
                          color: Colors.red[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuGrid() {
    List<MenuOption> options = [];

    if (_userRole == 'admin') {
      options = [
        MenuOption(
          title: 'Manage Timetables',
          icon: Icons.calendar_month,
          color: Colors.blue,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const TimetableListScreen()),
          ),
        ),
        MenuOption(
          title: 'Manage Students',
          icon: Icons.people,
          color: Colors.green,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const StudentListScreen()),
          ),
        ),
        MenuOption(
          title: 'Manage Assignments',
          icon: Icons.assignment,
          color: Colors.orange,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AssignmentListScreen()),
          ),
        ),
        MenuOption(
          title: 'Mark Attendance',
          icon: Icons.fact_check,
          color: Colors.purple,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AttendanceMarkScreen()),
          ),
        ),
      ];
    } else if (_userRole == 'teacher') {
      options = [
        MenuOption(
          title: 'Manage Students',
          icon: Icons.people,
          color: Colors.green,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const StudentListScreen()),
          ),
        ),
        MenuOption(
          title: 'Manage Assignments',
          icon: Icons.assignment,
          color: Colors.orange,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AssignmentListScreen()),
          ),
        ),
        MenuOption(
          title: 'Mark Attendance',
          icon: Icons.fact_check,
          color: Colors.purple,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AttendanceMarkScreen()),
          ),
        ),
        MenuOption(
          title: 'View Timetable',
          icon: Icons.calendar_today,
          color: Colors.blue,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ViewTimetableScreen()),
          ),
        ),
      ];
    } else if (_userRole == 'student') {
      options = [
        MenuOption(
          title: 'View Timetable',
          icon: Icons.calendar_today,
          color: Colors.blue,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ViewTimetableScreen()),
          ),
        ),
        MenuOption(
          title: 'My Assignments',
          icon: Icons.assignment,
          color: Colors.orange,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const StudentDashboardScreen()),
          ),
        ),
        MenuOption(
          title: 'My Attendance',
          icon: Icons.fact_check,
          color: Colors.purple,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const StudentAttendanceScreen()),
          ),
        ),
      ];
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.1,
      ),
      itemCount: options.length,
      itemBuilder: (context, index) {
        return _buildMenuCard(options[index]);
      },
    );
  }

  Widget _buildMenuCard(MenuOption option) {
    return GestureDetector(
      onTap: option.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: option.color.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: option.color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                option.icon,
                color: option.color,
                size: 32,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                option.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MenuOption {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  MenuOption({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}
