import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../constant/app_color.dart';
import '../../core/services/database_service.dart';
import '../../core/utils/app_logger.dart';

class TestSupportPage extends StatefulWidget {
  const TestSupportPage({super.key});

  @override
  State<TestSupportPage> createState() => _TestSupportPageState();
}

class _TestSupportPageState extends State<TestSupportPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _reasonController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isSubmitting = false;
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
    _prefillUserInfo();
  }

  Future<void> _prefillUserInfo() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      setState(() {
        _nameController.text = user.userMetadata?['full_name'] ?? user.email?.split('@')[0] ?? '';
        _emailController.text = user.email ?? '';
      });
      
      // Get additional user info from Supabase if available
      try {
        final userData = await DatabaseService.client
            .from('users')
            .select()
            .eq('id', user.id)
            .maybeSingle();
        
        if (userData != null) {
          setState(() {
            _nameController.text = userData['full_name'] ?? user.userMetadata?['full_name'] ?? user.email?.split('@')[0] ?? '';
            _emailController.text = userData['email'] ?? user.email ?? '';
          });
        }
      } catch (e) {
        AppLogger.e('Error fetching user data', e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Contact Support'),
        backgroundColor: AppColor.primary,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How can we help you?',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColor.primary,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Submit your request and our support team will get back to you.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 24),
                
                // Category Selection
                Text(
                  'Category',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.grey[50],
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
                SizedBox(height: 16),

                // Name Field
                Text(
                  'Your Name',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: 'Enter your name',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),

                // Email Field
                Text(
                  'Email Address',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'Enter your email address',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.grey[50],
                    prefixIcon: Icon(Icons.email),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your email address';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),

                // Subject Field
                Text(
                  'Subject',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 8),
                TextFormField(
                  controller: _reasonController,
                  decoration: InputDecoration(
                    hintText: 'Brief description of your issue',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a subject';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),

                // Description Field
                Text(
                  'Description',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 6,
                  decoration: InputDecoration(
                    hintText: 'Please provide detailed information about your request...',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please provide a description';
                    }
                    if (value.trim().length < 10) {
                      return 'Please provide more details (at least 10 characters)';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 24),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitSupportRequest,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isSubmitting
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                              SizedBox(width: 12),
                              Text('Submitting...'),
                            ],
                          )
                        : Text(
                            'Submit Request',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitSupportRequest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final user = Supabase.instance.client.auth.currentUser;
      
      final requestData = {
        'category': _selectedCategory,
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'user_id': user?.id ?? '',
        'reason': _reasonController.text.trim(),
        'description': _descriptionController.text.trim(),
        'status': 'open',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      await DatabaseService.client
          .from('support_requests')
          .insert(requestData);
      
      // Support request created successfully

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Support request submitted successfully!'),
            backgroundColor: AppColor.success,
          ),
        );

        // Clear form
        _reasonController.clear();
        _descriptionController.clear();
        setState(() {
          _selectedCategory = 'General Inquiry';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting request: $e'),
            backgroundColor: AppColor.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _reasonController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
