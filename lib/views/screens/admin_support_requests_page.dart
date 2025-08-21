import 'package:flutter/material.dart';
import '../../constant/app_color.dart';
import '../../core/services/admin_access_service.dart';
import '../../core/utils/app_logger.dart';

class AdminSupportRequestsPage extends StatefulWidget {
  const AdminSupportRequestsPage({super.key});

  @override
  State<AdminSupportRequestsPage> createState() => _AdminSupportRequestsPageState();
}

class _AdminSupportRequestsPageState extends State<AdminSupportRequestsPage> {
  String _selectedFilter = 'all';
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAdminAccess();
  }

  Future<void> _checkAdminAccess() async {
    final isAdmin = await AdminAccessService.isCurrentUserAdmin();
    if (!isAdmin && mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Access denied. Admin privileges required.'),
          backgroundColor: AppColor.error,
        ),
      );
      return;
    }
    setState(() {
      _isAdmin = isAdmin;
    });
  }

  Future<List<Map<String, dynamic>>> _fetchSupportRequests() async {
    try {
      // Return empty list for now - implement based on your DatabaseService
      return [];
    } catch (e) {
      AppLogger.e('Error fetching support requests', e);
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAdmin) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Support Requests'),
        backgroundColor: AppColor.primary,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _selectedFilter = value;
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'all', child: Text('All Requests')),
              PopupMenuItem(value: 'open', child: Text('Open Only')),
              PopupMenuItem(value: 'resolved', child: Text('Resolved Only')),
            ],
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.filter_list),
                  SizedBox(width: 4),
                  Text(_getFilterLabel()),
                ],
              ),
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchSupportRequests(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading support requests: ${snapshot.error}'),
            );
          }

          final requests = snapshot.data ?? [];

          if (requests.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.support_agent, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No support requests found',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

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
    );
  }

  String _getFilterLabel() {
    switch (_selectedFilter) {
      case 'open': return 'Open';
      case 'resolved': return 'Resolved';
      default: return 'All';
    }
  }

  Widget _buildSupportRequestCard(String requestId, Map<String, dynamic> data) {
    final status = data['status'] ?? 'open';
    final category = data['category'] ?? 'Other';
    final isResolved = status == 'resolved';
    
    return Card(
      margin: EdgeInsets.only(bottom: 12),
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
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(category),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      category,
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
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
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
              Text(
                data['description'] ?? 'No description',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColor.textMedium,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: AppColor.textMedium),
                  SizedBox(width: 4),
                  Text(
                    data['name'] ?? 'Anonymous',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColor.textMedium,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Spacer(),
                  Text(
                    _formatDate(data['createdAt']),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColor.textLight,
                    ),
                  ),
                ],
              ),
              if (data['adminResponse'] != null) ...[
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColor.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.admin_panel_settings, size: 16, color: AppColor.success),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Admin responded',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColor.success,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'technical issue': return AppColor.error;
      case 'account problem': return AppColor.warning;
      case 'listing issue': return AppColor.accent;
      case 'payment problem': return Colors.orange;
      case 'report content': return Colors.red;
      case 'bug report': return AppColor.error;
      case 'feature request': return Colors.purple;
      default: return AppColor.primary;
    }
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';
    
    DateTime date;
    if (timestamp is DateTime) {
      date = timestamp;
    } else if (timestamp is String) {
      date = DateTime.parse(timestamp);
    } else {
      return 'Unknown';
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
      builder: (context) => AdminSupportRequestDialog(
        requestId: requestId,
        requestData: data,
        onResponseSent: () {
          // Refresh the list or show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Response sent successfully!'),
              backgroundColor: AppColor.success,
            ),
          );
        },
      ),
    );
  }
}

class AdminSupportRequestDialog extends StatefulWidget {
  final String requestId;
  final Map<String, dynamic> requestData;
  final VoidCallback onResponseSent;

  const AdminSupportRequestDialog({
    super.key,
    required this.requestId,
    required this.requestData,
    required this.onResponseSent,
  });

  @override
  State<AdminSupportRequestDialog> createState() => _AdminSupportRequestDialogState();
}

class _AdminSupportRequestDialogState extends State<AdminSupportRequestDialog> {
  final _responseController = TextEditingController();
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final data = widget.requestData;
    
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          maxWidth: 600,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColor.primary,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.support_agent, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Support Request Details',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow('Category', data['category'] ?? 'Other'),
                    _buildDetailRow('From', data['name'] ?? 'Anonymous'),
                    if (data['email'] != null) _buildDetailRow('Email', data['email']),
                    _buildDetailRow('Subject', data['reason'] ?? 'No subject'),
                    SizedBox(height: 16),
                    Text(
                      'Description:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Text(data['description'] ?? 'No description'),
                    ),
                    SizedBox(height: 16),
                    
                    if (data['adminResponse'] != null) ...[
                      Text(
                        'Previous Admin Response:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColor.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColor.success.withOpacity(0.3)),
                        ),
                        child: Text(data['adminResponse']),
                      ),
                      SizedBox(height: 16),
                    ],
                    
                    Text(
                      'Admin Response:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    SizedBox(height: 8),
                    TextFormField(
                      controller: _responseController,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText: 'Type your response to the user...',
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('Cancel'),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _sendResponse,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColor.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: _isSubmitting
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text('Send Response'),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Future<void> _sendResponse() async {
    if (_responseController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a response'),
          backgroundColor: AppColor.error,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // For now, just show success message since DatabaseService needs to be implemented
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Support request marked as resolved'),
          backgroundColor: AppColor.success,
        ),
      );

      // Here you would typically send an email to the user
      // For now, we'll just show success
      
      if (mounted) {
        Navigator.of(context).pop();
        widget.onResponseSent();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending response: $e'),
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
    _responseController.dispose();
    super.dispose();
  }
}
