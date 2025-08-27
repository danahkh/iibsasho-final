import 'package:flutter/material.dart';
import 'dart:async';
import '../../constant/app_color.dart';
import '../../core/services/admin_access_service.dart';
import '../../core/services/database_service.dart';
import '../../core/model/support_request.dart';
import '../../core/model/support_message.dart';
import '../../core/notifiers/support_counts_notifier.dart';

class AdminSupportRequestsPage extends StatefulWidget {
  const AdminSupportRequestsPage({super.key});

  @override
  State<AdminSupportRequestsPage> createState() => _AdminSupportRequestsPageState();
}

class _AdminSupportRequestsPageState extends State<AdminSupportRequestsPage> {
  String _selectedFilter = 'all';
  bool _isAdmin = false;
  final int _openCount = 0; // local fallback only
  final int _resolvedCount = 0; // local fallback only
  static const int _pageSize = 25;
  int _currentPage = 0;
  bool _isLoadingMore = false;
  final List<SupportRequest> _pagedItems = [];
  Stream<List<SupportRequest>>? _stream;
  late final ScrollController _scrollController;
  Timer? _countsTimer; // deprecated by SupportCountsNotifier; kept as safety

  @override
  void initState() {
    super.initState();
  _checkAdminAccess();
  _scrollController = ScrollController()..addListener(_onScroll);
  _attachStream();
  _startCountsPolling();
  // Initial page
  WidgetsBinding.instance.addPostFrameCallback((_) => _loadNextPage());
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

  void _startCountsPolling() {
    // No-op: counts are now handled by SupportCountsNotifier app-wide.
    _countsTimer?.cancel();
  }

  void _attachStream() {
    // Build server-side filtered stream
  var base = DatabaseService
        .getSupportRequestsTyped()
        .asStream()
        .asyncExpand((initial) => DatabaseService.client
          .from('support_requests')
          .stream(primaryKey: ['id'])
          .order('created_at', ascending: false)
          .map((rows) => rows.map(SupportRequest.fromJson).toList())
        );
  // Note: Stream builder doesn't support or() reliably; keep base stream unfiltered
  _stream = base;
    // Reset pagination buffer
    _pagedItems.clear();
    _currentPage = 0;
  }

  void _onScroll() {
    if (_isLoadingMore) return;
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 200) {
      _loadNextPage();
    }
  }

  Future<void> _loadNextPage() async {
    if (_isLoadingMore) return;
    setState(() => _isLoadingMore = true);
    try {
      final from = _currentPage * _pageSize;
      final to = from + _pageSize - 1;
  dynamic q = DatabaseService.client.from('support_requests').select();
      if (_selectedFilter == 'open') {
        q = q.eq('status', 'open');
      } else if (_selectedFilter == 'resolved') {
        q = q.eq('status', 'resolved');
      }
      q = q.order('created_at', ascending: false).range(from, to);
      final rows = await q; // returns List<dynamic>
      if (!mounted) return;
  final list = (rows as List).map((e) => SupportRequest.fromJson(Map<String,dynamic>.from(e))).toList();
      setState(() {
        _pagedItems.addAll(list);
        if (list.isNotEmpty) _currentPage += 1;
      });
    } catch (_) {
      // ignore pagination errors gracefully
    } finally {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  // Realtime stream for support requests (server-side filtered)
  Stream<List<SupportRequest>> _supportRequestsStream() => _stream ?? const Stream.empty();

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
      body: Column(
        children: [
          // Counters
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(color: AppColor.primary.withOpacity(0.05)),
            child: Builder(
              builder: (context) {
                final counts = SupportCountsProvider.maybeOf(context);
                final open = counts?.open ?? _openCount;
                final resolved = counts?.resolved ?? _resolvedCount;
                return Row(
                  children: [
                    _statChip(Icons.inbox, 'Open', open, AppColor.warning),
                    SizedBox(width: 8),
                    _statChip(Icons.check_circle, 'Resolved', resolved, AppColor.success),
                  ],
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                FilterChip(
                  selected: _selectedFilter == 'all',
                  label: Text('All'),
                  onSelected: (_) {
                    setState(() => _selectedFilter = 'all');
                    _attachStream();
                    _loadNextPage();
                  },
                ),
                SizedBox(width: 8),
                FilterChip(
                  selected: _selectedFilter == 'open',
                  label: Text('Open'),
                  onSelected: (_) {
                    setState(() => _selectedFilter = 'open');
                    _attachStream();
                    _loadNextPage();
                  },
                ),
                SizedBox(width: 8),
                FilterChip(
                  selected: _selectedFilter == 'resolved',
                  label: Text('Resolved'),
                  onSelected: (_) {
                    setState(() => _selectedFilter = 'resolved');
                    _attachStream();
                    _loadNextPage();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<SupportRequest>>(
              stream: _supportRequestsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && _pagedItems.isEmpty) {
                  return Center(child: CircularProgressIndicator());
                }
                // Merge stream updates into the paged buffer by id (newest first)
                final updates = snapshot.data ?? [];
                if (updates.isNotEmpty) {
                  final byId = {for (final r in _pagedItems) (r.id ?? '').toString(): r};
                  for (final u in updates) {
                    byId[(u.id ?? '').toString()] = u;
                  }
                  final merged = byId.values.toList()
                    ..sort((a,b){
                      final ta = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
                      final tb = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
                      return tb.compareTo(ta);
                    });
                  // Show only what we've paged in so far
                  _pagedItems
                    ..clear()
                    ..addAll(merged.take((_currentPage+1) * _pageSize));

                  // Counts UI now reads from SupportCountsNotifier; we keep local
                  // values only if the notifier isn't found.
                }

                if (_pagedItems.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.support_agent, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No support requests found', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  key: const PageStorageKey<String>('admin_support_requests_list'),
                  controller: _scrollController,
                  padding: EdgeInsets.all(16),
                  itemCount: _pagedItems.length + 1,
                  itemBuilder: (context, index) {
                    if (index == _pagedItems.length) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        child: Center(
                          child: _isLoadingMore ? CircularProgressIndicator() : SizedBox.shrink(),
                        ),
                      );
                    }
                    final request = _pagedItems[index];
                    return KeyedSubtree(
                      key: ValueKey<String>((request.id ?? '').toString()),
                      child: _buildSupportRequestCard((request.id ?? '').toString(), request),
                    );
                  },
                );
              },
            ),
          ),
        ],
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

  Widget _buildSupportRequestCard(String requestId, SupportRequest data) {
  final status = data.status ?? 'open';
    final category = data.category ?? 'Other';
  final isResolved = status == 'resolved' || status == 'closed' || status == 'done';
  final createdAt = _formatDate(data.createdAt);
    
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
                data.reason ?? data.title ?? 'No subject',
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
                data.details ?? data.message ?? 'No description',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColor.textMedium,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 12),
              Row(children: [
                Icon(Icons.person, size: 16, color: AppColor.textMedium),
                SizedBox(width: 4),
                Text(
                  'Anonymous',
                  style: TextStyle(fontSize: 14, color: AppColor.textMedium, fontWeight: FontWeight.w500),
                ),
                Spacer(),
                Row(children: [
                  Icon(Icons.access_time, size: 14, color: AppColor.primary),
                  SizedBox(width: 4),
                  Text(createdAt, style: TextStyle(fontSize: 12, color: AppColor.primary)),
                ]),
              ]),
              // (Optional) admin response chip could go here if schema provides it.
            ],
          ),
        ),
      ),
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
      date = timestamp.toLocal();
    } else if (timestamp is String) {
      date = DateTime.parse(timestamp).toLocal();
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

  @override
  void dispose() {
    _countsTimer?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _showRequestDetails(String requestId, SupportRequest data) {
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
  final SupportRequest requestData;
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
  final List<Map<String, dynamic>> _localMsgs = [];

  String _newClientId() => UniqueKey().toString();

  Color _catColor(String category) {
    switch (category.toLowerCase()) {
      case 'technical issue':
        return AppColor.error;
      case 'account problem':
        return AppColor.warning;
      case 'listing issue':
        return AppColor.accent;
      case 'payment problem':
        return Colors.orange;
      case 'report content':
        return Colors.red;
      case 'bug report':
        return AppColor.error;
      case 'feature request':
        return Colors.purple;
      default:
        return AppColor.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
  final data = widget.requestData;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SafeArea(
        child: AnimatedPadding(
          duration: kThemeAnimationDuration,
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
          width: MediaQuery.of(context).size.width * 0.95,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
            maxWidth: 680,
          ),
          child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.support_agent, color: AppColor.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Support Request Details',
                      style: TextStyle(
                        color: AppColor.primary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, color: AppColor.textMedium),
                  ),
                ],
              ),
            ),
            // Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _catColor(data.category?.toString() ?? 'Other'),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            (data.category ?? 'Other').toString(),
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: ((['resolved','closed','done'].contains((data.status ?? '').toString())) ? AppColor.success : AppColor.warning).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                              (data.status ?? 'open').toUpperCase(),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: (['resolved','closed','done'].contains((data.status ?? '').toString())) ? AppColor.success : AppColor.warning,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text('Subject', style: TextStyle(fontWeight: FontWeight.bold, color: AppColor.primary)),
                    const SizedBox(height: 6),
                    Text(data.reason ?? data.title ?? 'No subject'),
                    const SizedBox(height: 16),
                    Text('Description', style: TextStyle(fontWeight: FontWeight.bold, color: AppColor.primary)),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: Offset(0, 2)),
                        ],
                      ),
                      child: Text(data.details ?? data.message ?? 'No description'),
                    ),
                    const SizedBox(height: 20),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    Text('Conversation', style: TextStyle(fontWeight: FontWeight.bold, color: AppColor.primary)),
                    const SizedBox(height: 8),
                    // Messages stream (merged with locally inserted messages for instant UX)
                    StreamBuilder<List<SupportMessage>>(
                      stream: DatabaseService.streamSupportMessagesTyped(widget.requestId),
                      builder: (context, snapshot) {
                        final fromStream = snapshot.data ?? [];
                           final Map<String, SupportMessage> keyed = {};
                           for (final m in fromStream) {
                             final mid = (m.id ?? _newClientId());
                             keyed[mid] = m;
                           }
                           for (final m in _localMsgs) {
                             final mid = (m['id']?.toString() ?? m['clientId']?.toString() ?? _newClientId());
                             keyed[mid] = SupportMessage(
                               id: mid,
                               supportRequestId: widget.requestId,
                               message: m['message']?.toString(),
                               senderRole: m['sender_role']?.toString(),
                               createdAt: DateTime.tryParse(m['created_at']?.toString() ?? ''),
                             );
                           }
                        final msgs = keyed.values.toList()
                          ..sort((a,b){
                            final ta = a.createdAt ?? DateTime.now();
                            final tb = b.createdAt ?? DateTime.now();
                            return ta.compareTo(tb);
                          });
                        if (msgs.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12.0),
                            child: Text('No messages yet.'),
                          );
                        }
                        return Column(
                          children: msgs.map((m) {
                            final isAdmin = (m.senderRole ?? '') == 'admin';
                            final ts = m.createdAt;
                            return Align(
                              alignment: isAdmin ? Alignment.centerRight : Alignment.centerLeft,
                              child: Container(
                                margin: EdgeInsets.symmetric(vertical: 6),
                                padding: EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isAdmin ? AppColor.primary.withOpacity(0.08) : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: (isAdmin ? AppColor.primary : Colors.grey[300]!) ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(m.message ?? ''),
                                    SizedBox(height: 4),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.access_time, size: 10, color: AppColor.textMedium),
                                        SizedBox(width: 4),
                                        Text(_formatDate(ts), style: TextStyle(fontSize: 10, color: AppColor.textMedium)),
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
            // Footer with respond + resolve
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey[200]!)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _responseController,
                      minLines: 1,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Type a response to the user...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                    IconButton(
                    tooltip: 'Send',
                    onPressed: _isSubmitting
                        ? null
                        : () async {
                            final text = _responseController.text.trim();
                            if (text.isEmpty) return;
                            setState(() => _isSubmitting = true);
                            try {
                              final clientId = _newClientId();
                              final local = {
                                'clientId': clientId,
                                'support_request_id': widget.requestId,
                                'message': text,
                                'sender_role': 'admin',
                                'created_at': DateTime.now().toIso8601String(),
                              };
                              setState(() => _localMsgs.add(local));
                              final res = await DatabaseService.addSupportMessage(widget.requestId, text, senderRole: 'admin');
                              if (res != null && mounted) {
                                // Replace local temp with server row if needed
                                setState(() {
                                  _localMsgs.removeWhere((m) => (m['clientId'] == clientId));
                                });
                              }
                              _responseController.clear();
                            } finally {
                              if (mounted) setState(() => _isSubmitting = false);
                            }
                          },
                    icon: Icon(Icons.send, color: AppColor.primary),
                  ),
                  const SizedBox(width: 8),
                  if (!['resolved','closed','done'].contains((data.status ?? 'open').toString()))
                    ElevatedButton(
                      onPressed: _isSubmitting
                          ? null
                          : () async {
                              setState(() => _isSubmitting = true);
                              try {
                                // Use 'resolved' to satisfy DB constraint (support_requests_status_check)
                                await DatabaseService.updateSupportRequestStatus(widget.requestId, 'resolved');
                              } finally {
                                if (mounted) {
                                  setState(() => _isSubmitting = false);
                                  Navigator.of(context).pop();
                                  widget.onResponseSent();
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(backgroundColor: AppColor.success, foregroundColor: Colors.white),
                      child: Text('Mark Resolved'),
                    ),
                ],
              ),
            ),
          ],
        ), // end Column
      ), // end Container
    ), // end AnimatedPadding
  ), // end SafeArea
);
  }

  @override
  void dispose() {
    _responseController.dispose();
    super.dispose();
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';
    DateTime date;
    if (timestamp is DateTime) {
      date = timestamp;
    } else if (timestamp is String) {
      date = DateTime.tryParse(timestamp) ?? DateTime.now();
    } else {
      return 'Unknown';
    }
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}
