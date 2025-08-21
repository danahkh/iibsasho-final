import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/services/database_service.dart';
import '../../constant/app_color.dart';
import '../../core/services/admin_access_service.dart';
import '../../widgets/app_logo_widget.dart';
import '../../core/utils/supabase_helper.dart';

class SupportPage extends StatefulWidget {
  const SupportPage({super.key});

  @override
  State<SupportPage> createState() => _SupportPageState();
}

class _SupportPageState extends State<SupportPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _reasonController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isSubmitting = false;
  bool _isAdmin = false;
  bool _isLoadingAdminCheck = true;
  String _selectedCategory = 'General Inquiry';

  final List<String> _supportCategories = [
    'General Inquiry',
    'Technical Issue',
    'Account Problem',
    'Listing Issue',
    'Payment Problem',
    'Report Content',
    'Feature Request',
    'Bug Report',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
    _prefillUserInfo();
  }

  Future<void> _checkAdminStatus() async {
    final isAdmin = await AdminAccessService.isCurrentUserAdmin();
    setState(() {
      _isAdmin = isAdmin;
      _isLoadingAdminCheck = false;
    });
  }

  void _prefillUserInfo() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      _nameController.text = user.userMetadata?['display_name'] ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _reasonController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingAdminCheck) {
      return Scaffold(
        backgroundColor: AppColor.background,
        appBar: AppBar(
          title: Text(
            'Support & Help',
            style: TextStyle(
              color: AppColor.textOnPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: AppColor.primary,
          elevation: 0,
          iconTheme: IconThemeData(color: AppColor.iconLight),
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return DefaultTabController(
      length: _isAdmin ? 1 : 2,
      child: Scaffold(
        backgroundColor: AppColor.background,
        appBar: AppBar(
          backgroundColor: AppColor.primary,
          elevation: 2,
            shadowColor: AppColor.shadowColor,
          centerTitle: true,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: AppColor.textLight),
            onPressed: () => Navigator.pop(context),
          ),
          title: const AppLogoWidget(
            height: 28,
            isWhiteVersion: true,
          ),
          bottom: !_isAdmin ? PreferredSize(
            preferredSize: const Size.fromHeight(44),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TabBar(
                isScrollable: true,
                overlayColor: WidgetStateProperty.all(Colors.transparent),
                dividerColor: Colors.transparent,
                indicator: UnderlineTabIndicator(
                  borderSide: BorderSide(color: AppColor.accentLight, width: 3),
                  insets: const EdgeInsets.symmetric(horizontal: 12),
                ),
                indicatorSize: TabBarIndicatorSize.label,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white.withOpacity(0.65),
                labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, letterSpacing: 0.3),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                tabs: const [
                  Tab(text: 'Submit Ticket'),
                  Tab(text: 'My Cases'),
                ],
              ),
            ),
          ) : null,
        ),
        body: _isAdmin ? _buildAdminSupportView() : TabBarView(
          children: [
            _buildUserSupportForm(),
            _buildMyCasesTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminSupportView() {
    return Column(
      children: [
        // Admin Header
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColor.primary.withOpacity(0.1), AppColor.accent.withOpacity(0.1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.admin_panel_settings, size: 48, color: AppColor.primary),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Support Request Management',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColor.textDark,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Review and respond to user support requests',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColor.textMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Support Requests List
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: DatabaseService.getSupportRequests(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox, size: 64, color: AppColor.textMedium),
                      SizedBox(height: 16),
                      Text(
                        'No support requests yet',
                        style: TextStyle(
                          fontSize: 18,
                          color: AppColor.textMedium,
                        ),
                      ),
                    ],
                  ),
                );
              }

              final requests = snapshot.data!;
              return ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: requests.length,
                itemBuilder: (context, index) {
                  final request = requests[index];
                  return _buildSupportRequestCard(request['id'].toString(), request);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSupportRequestCard(String requestId, Map<String, dynamic> data) {
    final timestamp = data['created_at'];
    final status = data['status'] ?? 'open';
    final isResolved = status == 'resolved';

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showRequestDetails(requestId, data),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with status
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(data['category'] ?? 'Other'),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      data['category'] ?? 'Other',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Spacer(),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isResolved ? AppColor.success : AppColor.warning,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isResolved ? 'RESOLVED' : 'OPEN',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              // User info
              Text(
                'From: ${data['name'] ?? 'Anonymous'}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColor.textDark,
                ),
              ),
              if (data['email'] != null)
                Text(
                  data['email'],
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColor.textMedium,
                  ),
                ),
              SizedBox(height: 8),
              // Subject/Reason
              Text(
                data['reason'] ?? 'No subject',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColor.textDark,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 8),
              // Description preview
              Text(
                data['description'] ?? 'No description',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColor.textMedium,
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 12),
              // Timestamp
              Row(
                children: [
                  Icon(Icons.access_time, size: 14, color: AppColor.textMedium),
                  SizedBox(width: 4),
                  Text(
                    timestamp != null ? _formatTimestamp(timestamp) : 'Unknown date',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColor.textMedium,
                    ),
                  ),
                  Spacer(),
                  Icon(Icons.chevron_right, color: AppColor.textMedium),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Technical Issue':
        return AppColor.error;
      case 'Account Problem':
        return AppColor.warning;
      case 'Bug Report':
        return Colors.red;
      case 'Feature Request':
        return Colors.purple;
      case 'Payment Problem':
        return Colors.orange;
      default:
        return AppColor.primary;
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    DateTime date;
    if (timestamp is String) {
      date = DateTime.tryParse(timestamp) ?? DateTime.now();
    } else if (timestamp is DateTime) {
      date = timestamp;
    } else {
      return 'Unknown date';
    }
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _showRequestDetails(String requestId, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Support Request Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Category', data['category'] ?? 'Other'),
              _buildDetailRow('From', data['name'] ?? 'Anonymous'),
              if (data['email'] != null) _buildDetailRow('Email', data['email']),
              _buildDetailRow('Subject', data['reason'] ?? 'No subject'),
              SizedBox(height: 8),
              Text(
                'Description:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text(data['description'] ?? 'No description'),
              SizedBox(height: 16),
              Text(
                'Status: ${data['status'] ?? 'open'}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: data['status'] == 'resolved' ? AppColor.success : AppColor.warning,
                ),
              ),
            ],
          ),
        ),
        actions: [
          if (data['status'] != 'resolved')
            TextButton(
              onPressed: () => _markAsResolved(requestId),
              child: Text('Mark as Resolved', style: TextStyle(color: AppColor.success)),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Future<void> _markAsResolved(String requestId) async {
    try {
      final success = await DatabaseService.updateSupportRequestStatus(requestId, 'resolved');
      Navigator.of(context).pop(); // Close dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Support request marked as resolved' : 'Error updating request'),
          backgroundColor: success ? AppColor.success : AppColor.error,
        ),
      );
      setState(() {}); // Refresh list
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating request: $e'),
          backgroundColor: AppColor.error,
        ),
      );
    }
  }

  Widget _buildUserSupportForm() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColor.primary.withOpacity(0.1), AppColor.accent.withOpacity(0.1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColor.primary.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.support_agent, size: 48, color: AppColor.primary),
                SizedBox(height: 16),
                Text(
                  'How can we help you?',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColor.textDark,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'We\'re here to assist you with any questions or issues you may have. Fill out the form below and we\'ll get back to you as soon as possible.',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColor.textMedium,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 32),

          // Contact Form
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Contact Information',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColor.textDark,
                  ),
                ),
                SizedBox(height: 16),

                // Name Field
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Your Name',
                    hintText: 'Enter your full name',
                    prefixIcon: Icon(Icons.person, color: AppColor.primary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColor.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColor.primary, width: 2),
                    ),
                    filled: true,
                    fillColor: AppColor.surface,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),

                // Category Dropdown
                Text(
                  'Category',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColor.textDark,
                  ),
                ),
                SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.category, color: AppColor.primary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColor.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColor.primary, width: 2),
                    ),
                    filled: true,
                    fillColor: AppColor.surface,
                  ),
                  items: _supportCategories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value!;
                    });
                  },
                ),
                SizedBox(height: 20),

                // Reason/Subject Field
                TextFormField(
                  controller: _reasonController,
                  decoration: InputDecoration(
                    labelText: 'Subject',
                    hintText: 'Brief description of your issue',
                    prefixIcon: Icon(Icons.subject, color: AppColor.primary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColor.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColor.primary, width: 2),
                    ),
                    filled: true,
                    fillColor: AppColor.surface,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a subject';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),

                // Description Field
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 6,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    hintText: 'Please provide detailed information about your issue...',
                    prefixIcon: Padding(
                      padding: EdgeInsets.only(bottom: 80),
                      child: Icon(Icons.description, color: AppColor.primary),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColor.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppColor.primary, width: 2),
                    ),
                    filled: true,
                    fillColor: AppColor.surface,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please provide a description';
                    }
                    if (value.trim().length < 10) {
                      return 'Description must be at least 10 characters';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 32),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitSupportRequest,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                    ),
                    child: _isSubmitting
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                              SizedBox(width: 12),
                              Text('Submitting...'),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.send),
                              SizedBox(width: 8),
                              Text(
                                'Submit Request',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyCasesTab() {
    final userId = SupabaseHelper.currentUserId;
    if (userId == null) {
      return Center(child: Text('Please log in to view your cases'));
    }
    return FutureBuilder<List<Map<String,dynamic>>>(
      future: DatabaseService.getSupportRequests(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        final all = snapshot.data ?? [];
        final my = all.where((r)=> r['user_id']==userId).toList();
        if (my.isEmpty) {
          return Center(child: Text('You have not submitted any support tickets yet.'));
        }
        return ListView.separated(
          padding: EdgeInsets.all(16),
          itemBuilder: (c,i){
            final r = my[i];
            return ListTile(
              contentPadding: EdgeInsets.all(12),
              tileColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: AppColor.border)),
              title: Text(r['reason']??'No subject', maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height:4),
                  Text(r['category']??'Other', style: TextStyle(fontSize:12, color: AppColor.placeholder)),
                  SizedBox(height:4),
                  Text(_formatTimestamp(r['created_at']), style: TextStyle(fontSize:11, color: AppColor.textMedium)),
                ],
              ),
              trailing: Container(
                padding: EdgeInsets.symmetric(horizontal:8, vertical:4),
                decoration: BoxDecoration(
                  color: (r['status']=='resolved'? AppColor.success : AppColor.warning).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text((r['status']??'open').toString().toUpperCase(), style: TextStyle(fontSize:10, fontWeight: FontWeight.bold, color: r['status']=='resolved'? AppColor.success : AppColor.warning)),
              ),
              onTap: ()=> _showRequestDetails(r['id'].toString(), r),
            );
          },
          separatorBuilder: (_, __)=> SizedBox(height:8),
          itemCount: my.length,
        );
      },
    );
  }

  Future<void> _submitSupportRequest() async {
    if (!_formKey.currentState!.validate()) return;

    if (!SupabaseHelper.requireAuth(context, feature: 'contact support')) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      final requestData = {
        'name': _nameController.text.trim(),
        'email': user?.email,
        'user_id': user?.id,
        'category': _selectedCategory,
        'reason': _reasonController.text.trim(),
        'description': _descriptionController.text.trim(),
        'status': 'open',
      };
      final id = await DatabaseService.createSupportRequest(requestData);
      if (id != null) {
        // Clear form
        _nameController.clear();
        _reasonController.clear();
        _descriptionController.clear();
        setState(() {
          _selectedCategory = 'General Inquiry';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Support request submitted successfully!'),
              ],
            ),
            backgroundColor: AppColor.success,
            duration: Duration(seconds: 3),
          ),
        );
        setState(() {}); // Refresh list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting request'),
            backgroundColor: AppColor.error,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting request: $e'),
          backgroundColor: AppColor.error,
        ),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }
}
