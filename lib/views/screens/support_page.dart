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
  final _replyController = TextEditingController();
  bool _isSubmitting = false;
  bool _isSendingReply = false;
  bool _isAdmin = false;
  bool _isLoadingAdminCheck = true;
  String _selectedCategory = 'General Inquiry';
  bool _nameReadOnly = false;
  String _adminFilter = 'all'; // all | open | resolved
  int _openCount = 0;
  int _resolvedCount = 0;

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
    if (!mounted) return;
    setState(() {
      _isAdmin = isAdmin;
      _isLoadingAdminCheck = false;
    });
  }

  Future<void> _prefillUserInfo() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
  final profile = await DatabaseService.getCurrentUserProfile();
  final fromProfile = (profile?['display_name'] as String?)?.trim();
      final meta = user.userMetadata ?? {};
      final displayNameMeta = (meta['display_name'] as String?)?.trim();
      final fullNameMeta = (meta['full_name'] as String?)?.trim();
      final email = (user.email ?? '').trim();

      String derived = '';
      if (fromProfile != null && fromProfile.isNotEmpty) {
        derived = fromProfile;
      } else if (displayNameMeta != null && displayNameMeta.isNotEmpty) {
        derived = displayNameMeta;
      } else if (fullNameMeta != null && fullNameMeta.isNotEmpty) {
        derived = fullNameMeta;
      } else if (email.isNotEmpty && email.contains('@')) {
        derived = email.split('@').first;
      }

      if (derived.isNotEmpty) {
        setState(() {
          _nameController.text = derived;
          _nameReadOnly = true;
        });
      }
    } catch (_) {
      // Best effort only
    }
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

    if (_isAdmin) {
      return Scaffold(
        backgroundColor: AppColor.background,
        appBar: AppBar(
          centerTitle: true,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: AppColor.textOnPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          title: const AppLogoWidget(
            height: 28,
            isWhiteVersion: true,
          ),
          backgroundColor: AppColor.primary,
          elevation: 0,
          iconTheme: IconThemeData(color: AppColor.iconLight),
        ),
        body: _buildAdminSupportView(),
      );
    }

    // Non-admin: tabs for Submit + My Cases
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColor.background,
        appBar: AppBar(
          centerTitle: true,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: AppColor.textOnPrimary),
            onPressed: () => Navigator.pop(context),
          ),
          title: const AppLogoWidget(
            height: 28,
            isWhiteVersion: true,
          ),
          backgroundColor: AppColor.primary,
          elevation: 0,
          iconTheme: IconThemeData(color: AppColor.iconLight),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(44),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TabBar(
                isScrollable: true,
                dividerColor: Colors.transparent,
                indicator: UnderlineTabIndicator(
                  borderSide: BorderSide(color: AppColor.accentLight, width: 3),
                  insets: const EdgeInsets.symmetric(horizontal: 12),
                ),
                indicatorSize: TabBarIndicatorSize.label,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white.withOpacity(0.7),
                labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, letterSpacing: 0.3),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                tabs: const [
                  Tab(text: 'Submit Ticket'),
                  Tab(text: 'My Cases'),
                ],
              ),
            ),
          ),
        ),
        body: TabBarView(
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
        // Counters row
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(color: AppColor.primary.withOpacity(0.05)),
          child: Row(
            children: [
              _statChip(Icons.inbox, 'Open', _openCount, AppColor.warning),
              SizedBox(width: 8),
              _statChip(Icons.check_circle, 'Resolved', _resolvedCount, AppColor.success),
            ],
          ),
        ),
        // Filters
        Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(
            children: [
              FilterChip(
                selected: _adminFilter == 'all',
                label: Text('All'),
                onSelected: (_) => setState(() => _adminFilter = 'all'),
              ),
              SizedBox(width: 8),
              FilterChip(
                selected: _adminFilter == 'open',
                label: Text('Open'),
                onSelected: (_) => setState(() => _adminFilter = 'open'),
              ),
              SizedBox(width: 8),
              FilterChip(
                selected: _adminFilter == 'resolved',
                label: Text('Resolved'),
                onSelected: (_) => setState(() => _adminFilter = 'resolved'),
              ),
            ],
          ),
        ),
        // Support Requests List (Realtime)
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: Supabase.instance.client
                .from('support_requests')
                .stream(primaryKey: ['id'])
                .order('created_at', ascending: false),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              final all = snapshot.data ?? [];
              bool isOpen(Map<String,dynamic> e){
                final st = (e['status'] ?? 'open').toString();
                return st == 'open' || st == 'pending' || st == 'new';
              }
              bool isResolvedLike(Map<String,dynamic> e){
                final st = (e['status'] ?? '').toString();
                return st == 'resolved' || st == 'closed' || st == 'done';
              }
              _openCount = all.where(isOpen).length;
              _resolvedCount = all.where(isResolvedLike).length;
              final requests = _adminFilter == 'open'
                  ? all.where(isOpen).toList()
                  : _adminFilter == 'resolved'
                      ? all.where(isResolvedLike).toList()
                      : all;

              if (requests.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox, size: 64, color: AppColor.textMedium),
                      SizedBox(height: 16),
                      Text(
                        'No support requests yet',
                        style: TextStyle(fontSize: 18, color: AppColor.textMedium),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                key: const PageStorageKey<String>('user_support_requests_list'),
                padding: EdgeInsets.all(16),
                itemCount: requests.length,
                itemBuilder: (context, index) {
                  final request = requests[index];
                  return KeyedSubtree(
                    key: ValueKey<String>(request['id'].toString()),
                    child: _buildSupportRequestCard(request['id'].toString(), request),
                  );
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
  final isResolved = status == 'resolved' || status == 'closed' || status == 'done';

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
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SafeArea(
          child: AnimatedPadding(
            duration: kThemeAnimationDuration,
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          constraints: BoxConstraints(maxWidth: 640, maxHeight: MediaQuery.of(context).size.height * 0.85),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: Offset(0, 4)),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: AppColor.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text('Support Request Details', style: TextStyle(color: AppColor.primary, fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    IconButton(onPressed: () => Navigator.of(context).pop(), icon: Icon(Icons.close, color: AppColor.textMedium)),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow('Category', data['category'] ?? 'Other'),
                      _buildDetailRow('From', data['name'] ?? 'Anonymous'),
                      if (data['email'] != null) _buildDetailRow('Email', data['email']),
                      _buildDetailRow('Subject', data['reason'] ?? 'No subject'),
                      const SizedBox(height: 16),
                      Text('Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColor.primary)),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: Offset(0, 2))],
                        ),
                        child: Text(data['description'] ?? 'No description'),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Text('Status: ', style: TextStyle(fontWeight: FontWeight.bold, color: AppColor.primary)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: (data['status'] == 'resolved' ? AppColor.success : AppColor.warning).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              (data['status'] ?? 'open').toString().toUpperCase(),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: data['status'] == 'resolved' ? AppColor.success : AppColor.warning,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Divider(height: 1),
                      const SizedBox(height: 12),
                      Text('Conversation', style: TextStyle(fontWeight: FontWeight.bold, color: AppColor.primary)),
                      const SizedBox(height: 8),
                      StreamBuilder<List<Map<String, dynamic>>>(
                        stream: DatabaseService.streamSupportMessages(requestId),
                        builder: (context, snapshot) {
                          final fromStream = snapshot.data ?? [];
                          final keyed = <String, Map<String, dynamic>>{};
                          for (final m in fromStream) {
                            final id = (m['id']?.toString() ?? m['clientId']?.toString() ?? UniqueKey().toString());
                            keyed[id] = m;
                          }
                          final msgs = keyed.values.toList()
                            ..sort((a,b){
                              final ta = DateTime.tryParse(a['created_at']?.toString() ?? '') ?? DateTime.now();
                              final tb = DateTime.tryParse(b['created_at']?.toString() ?? '') ?? DateTime.now();
                              return ta.compareTo(tb);
                            });
                          if (msgs.isEmpty) {
                            return Padding(
                              padding: EdgeInsets.symmetric(vertical: 12.0),
                              child: Text('No messages yet.'),
                            );
                          }
                          return Column(
                            children: msgs.map((m) {
                              final isAdminMsg = (m['sender_role']?.toString() ?? '') == 'admin';
                              final ts = m['created_at'];
                              return Align(
                                alignment: isAdminMsg ? Alignment.centerRight : Alignment.centerLeft,
                                child: Container(
                                  margin: const EdgeInsets.symmetric(vertical: 6),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: isAdminMsg ? AppColor.primary.withOpacity(0.08) : Colors.grey[100],
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: (isAdminMsg ? AppColor.primary : Colors.grey[300]!) ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(m['message']?.toString() ?? ''),
                                      const SizedBox(height: 4),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.access_time, size: 10, color: AppColor.textMedium),
                                          const SizedBox(width: 4),
                                          Text(_formatTimestamp(ts), style: const TextStyle(fontSize: 10, color: AppColor.textMedium)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey[200]!))),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _replyController,
                        minLines: 1,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: 'Write a message...',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Send',
                      onPressed: _isSendingReply
                          ? null
                          : () async {
                              final text = _replyController.text.trim();
                              if (text.isEmpty) return;
                              setState(() => _isSendingReply = true);
                              try {
                                // Note: server response will stream back; local optimistic add is optional here
                                await DatabaseService.addSupportMessage(requestId, text, senderRole: _isAdmin ? 'admin' : 'user');
                                _replyController.clear();
                              } finally {
                                if (mounted) setState(() => _isSendingReply = false);
                              }
                            },
                      icon: Icon(Icons.send, color: AppColor.primary),
                    ),
                    const SizedBox(width: 8),
                    if (_isAdmin && !['resolved','closed','done'].contains((data['status'] ?? 'open').toString()))
                      ElevatedButton(
                        onPressed: _isSendingReply
                            ? null
                            : () async {
                                await _markAsResolved(requestId);
                              },
                        style: ElevatedButton.styleFrom(backgroundColor: AppColor.success, foregroundColor: Colors.white),
                        child: Text('Mark Resolved'),
                      ),
                  ],
                ),
              ),
            ],
          ),
            ),
          ),
        ),
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
      // Use 'resolved' to comply with current DB check constraint
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
          fillColor: _nameReadOnly ? Colors.grey[100] : AppColor.surface,
                  ),
                  readOnly: _nameReadOnly,
                  validator: (value) {
                    // If logged-in, auto-fill is allowed and name is optional
                    final user = Supabase.instance.client.auth.currentUser;
                    if (user == null) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your name';
                      }
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
        // Hide resolved tickets after 24 hours
        final now = DateTime.now();
        final my = all.where((r){
          if (r['user_id'] != userId) return false;
          final status = (r['status'] ?? 'open').toString();
          final isResolvedLike = status == 'resolved' || status == 'closed' || status == 'done';
          if (!isResolvedLike) return true;
          final closedAtStr = (r['resolved_at'] ?? r['updated_at'] ?? r['created_at'])?.toString();
          if (closedAtStr == null) return true;
          final parsed = DateTime.tryParse(closedAtStr);
          final closedAt = parsed?.toLocal();
          if (closedAt == null) return true;
          return now.difference(closedAt).inHours < 24;
        }).toList();
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
                  color: ((r['status']=='resolved' || r['status']=='closed' || r['status']=='done') ? AppColor.success : AppColor.warning).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text((r['status']??'open').toString().toUpperCase(), style: TextStyle(fontSize:10, fontWeight: FontWeight.bold, color: (r['status']=='resolved' || r['status']=='closed' || r['status']=='done') ? AppColor.success : AppColor.warning)),
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

  Widget _statChip(IconData icon, String label, int count, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          SizedBox(width: 6),
          Text('$label: $count', style: TextStyle(color: color, fontWeight: FontWeight.w600)),
        ],
      ),
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
      // Ensure name is set for logged-in users even if field was empty
      String name = _nameController.text.trim();
      if ((name.isEmpty) && user != null) {
        final meta = user.userMetadata ?? {};
        final displayName = (meta['display_name'] as String?)?.trim();
        final fullName = (meta['full_name'] as String?)?.trim();
        final email = (user.email ?? '').trim();
        if (displayName != null && displayName.isNotEmpty) {
          name = displayName;
        } else if (fullName != null && fullName.isNotEmpty) {
          name = fullName;
        } else if (email.isNotEmpty && email.contains('@')) {
          name = email.split('@').first;
        }
      }
      final requestData = {
        'name': name,
        'email': user?.email,
        'user_id': user?.id,
        'category': _selectedCategory,
        'reason': _reasonController.text.trim(),
    // Provide a title for backends with NOT NULL constraint
    'title': _reasonController.text.trim().isNotEmpty
      ? _reasonController.text.trim()
      : (_selectedCategory.isNotEmpty
        ? 'Support: $_selectedCategory'
        : 'Support Request'),
        'description': _descriptionController.text.trim(),
    // Some schemas use "message" NOT NULL; mirror description into message
    'message': _descriptionController.text.trim().isNotEmpty
      ? _descriptionController.text.trim()
      : (_reasonController.text.trim().isNotEmpty
        ? _reasonController.text.trim()
        : 'Support request'),
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

  @override
  void dispose() {
    _nameController.dispose();
    _reasonController.dispose();
    _descriptionController.dispose();
    _replyController.dispose();
    super.dispose();
  }
}
