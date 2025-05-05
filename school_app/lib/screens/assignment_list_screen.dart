import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:school_app/screens/add_assignment_screen.dart';
import 'package:school_app/screens/submission_screen.dart';
import 'package:school_app/services/assignment_service.dart';
import 'package:intl/intl.dart';

class AssignmentListScreen extends StatefulWidget {
  const AssignmentListScreen({super.key});

  @override
  State<AssignmentListScreen> createState() => _AssignmentListScreenState();
}

class _AssignmentListScreenState extends State<AssignmentListScreen> with SingleTickerProviderStateMixin {
  final AssignmentService _assignmentService = AssignmentService();
  late AnimationController _animationController;
  String _searchQuery = '';
  String _sortBy = 'deadline';
  bool _isAscending = true;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy • hh:mm a').format(date);
  }

  int _getDaysRemaining(DateTime deadline) {
    final now = DateTime.now();
    return deadline.difference(now).inDays;
  }

  Color _getDeadlineColor(DateTime deadline) {
    final daysRemaining = _getDaysRemaining(deadline);
    
    if (daysRemaining < 0) {
      return Colors.red;
    } else if (daysRemaining <= 1) {
      return Colors.orange;
    } else if (daysRemaining <= 3) {
      return Colors.amber;
    } else {
      return Colors.green;
    }
  }

  List<QueryDocumentSnapshot> _sortAssignments(List<QueryDocumentSnapshot> assignments) {
    switch (_sortBy) {
      case 'title':
        assignments.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aTitle = aData['title'] ?? '';
          final bTitle = bData['title'] ?? '';
          return _isAscending ? aTitle.compareTo(bTitle) : bTitle.compareTo(aTitle);
        });
        break;
      case 'deadline':
      default:
        assignments.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aDeadline = (aData['deadline'] as Timestamp).toDate();
          final bDeadline = (bData['deadline'] as Timestamp).toDate();
          return _isAscending ? aDeadline.compareTo(bDeadline) : bDeadline.compareTo(aDeadline);
        });
    }
    return assignments;
  }

  List<QueryDocumentSnapshot> _filterAssignments(List<QueryDocumentSnapshot> assignments) {
    if (_searchQuery.isEmpty) {
      return assignments;
    }
    
    return assignments.where((assignment) {
      final data = assignment.data() as Map<String, dynamic>;
      final title = (data['title'] ?? '').toLowerCase();
      final description = (data['description'] ?? '').toLowerCase();
      final query = _searchQuery.toLowerCase();
      
      return title.contains(query) || description.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                expandedHeight: 120,
                floating: true,
                pinned: true,
                backgroundColor: Theme.of(context).primaryColor,
                flexibleSpace: FlexibleSpaceBar(
                  title: const Text(
                    'Assignment Management',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  background: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          right: -10,
                          top: -20,
                          child: Icon(
                            Icons.assignment,
                            size: 100,
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(60),
                  child: Container(
                    height: 60,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: Theme.of(context).primaryColor,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextField(
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Search assignments...',
                          prefixIcon: const Icon(Icons.search),
                          border: InputBorder.none,
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_searchQuery.isNotEmpty)
                                IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    setState(() {
                                      _searchQuery = '';
                                    });
                                  },
                                ),
                              PopupMenuButton<String>(
                                icon: const Icon(Icons.sort),
                                tooltip: 'Sort assignments',
                                onSelected: (value) {
                                  setState(() {
                                    if (_sortBy == value) {
                                      _isAscending = !_isAscending;
                                    } else {
                                      _sortBy = value;
                                      _isAscending = true;
                                    }
                                  });
                                },
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    value: 'deadline',
                                    child: Row(
                                      children: [
                                        Icon(
                                          _sortBy == 'deadline'
                                              ? _isAscending
                                                  ? Icons.arrow_upward
                                                  : Icons.arrow_downward
                                              : Icons.calendar_today,
                                          size: 18,
                                          color: _sortBy == 'deadline'
                                              ? Theme.of(context).primaryColor
                                              : null,
                                        ),
                                        const SizedBox(width: 8),
                                        const Text('Sort by deadline'),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'title',
                                    child: Row(
                                      children: [
                                        Icon(
                                          _sortBy == 'title'
                                              ? _isAscending
                                                  ? Icons.arrow_upward
                                                  : Icons.arrow_downward
                                              : Icons.sort_by_alpha,
                                          size: 18,
                                          color: _sortBy == 'title'
                                              ? Theme.of(context).primaryColor
                                              : null,
                                        ),
                                        const SizedBox(width: 8),
                                        const Text('Sort by title'),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ];
          },
          body: _buildAssignmentList(),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddAssignmentScreen()),
          );
        },
        backgroundColor: Theme.of(context).primaryColor,
        icon: const Icon(Icons.add),
        label: const Text('New Assignment'),
      ),
    );
  }

  Widget _buildAssignmentList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _assignmentService.getAssignments(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _buildErrorState('Error loading assignments');
        }
        
        if (!snapshot.hasData) {
          return _buildLoadingState();
        }

        final allAssignments = snapshot.data!.docs;
        
        if (allAssignments.isEmpty) {
          return _buildEmptyState();
        }
        
        final sortedAssignments = _sortAssignments(allAssignments);
        final filteredAssignments = _filterAssignments(sortedAssignments);
        
        if (filteredAssignments.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off,
                  size: 60,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No assignments match your search',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredAssignments.length,
            itemBuilder: (context, index) {
              final assignment = filteredAssignments[index];
              final data = assignment.data() as Map<String, dynamic>;
              final deadline = (data['deadline'] as Timestamp).toDate();
              final daysRemaining = _getDaysRemaining(deadline);
              final deadlineColor = _getDeadlineColor(deadline);
              
              return _buildAssignmentCard(
                assignment: assignment,
                data: data,
                deadline: deadline,
                daysRemaining: daysRemaining,
                deadlineColor: deadlineColor,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildAssignmentCard({
    required QueryDocumentSnapshot assignment,
    required Map<String, dynamic> data,
    required DateTime deadline,
    required int daysRemaining,
    required Color deadlineColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.assignment_outlined,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    data['title'] ?? 'No Title',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['description'] ?? 'No description provided',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: deadlineColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Deadline: ${_formatDate(deadline)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: deadlineColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      daysRemaining < 0 
                          ? Icons.warning 
                          : Icons.timer,
                      size: 16,
                      color: deadlineColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      daysRemaining < 0
                          ? 'Overdue by ${daysRemaining.abs()} days'
                          : daysRemaining == 0
                              ? 'Due today'
                              : '$daysRemaining days remaining',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: deadlineColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _buildActionButton(
                      icon: Icons.assignment_turned_in,
                      label: 'Submissions',
                      color: Colors.green,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SubmissionScreen(
                              assignmentId: assignment.id,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    _buildActionButton(
                      icon: Icons.edit,
                      label: 'Edit',
                      color: Colors.blue,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddAssignmentScreen(
                              assignmentId: assignment.id,
                              assignmentData: data,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    _buildActionButton(
                      icon: Icons.delete,
                      label: 'Delete',
                      color: Colors.red,
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete Assignment'),
                            content: const Text(
                              'Are you sure you want to delete this assignment? This action cannot be undone.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.red,
                                ),
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                        
                        if (confirm == true) {
                          await _assignmentService.deleteAssignment(assignment.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Assignment deleted'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: color,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 60,
            color: Colors.red[300],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              setState(() {});
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          const Text(
            'Loading assignments...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'No Assignments',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first assignment by clicking the button below',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddAssignmentScreen()),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Create Assignment'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}
