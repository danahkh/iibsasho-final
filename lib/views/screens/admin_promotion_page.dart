import 'package:flutter/material.dart';
import '../../constant/app_color.dart';
import '../../core/services/promotion_service.dart';
import '../../core/services/admin_access_service.dart';

class AdminPromotionPage extends StatefulWidget {
  const AdminPromotionPage({super.key});

  @override
  _AdminPromotionPageState createState() => _AdminPromotionPageState();
}

class _AdminPromotionPageState extends State<AdminPromotionPage> with TickerProviderStateMixin {
  late TabController _tabController;
  String selectedFilter = 'all'; // all, pending, approved, rejected, active
  
  // Add refresh keys to trigger rebuilds
  Key _requestsKey = UniqueKey();
  Key _activeKey = UniqueKey();
  Key _analyticsKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: AdminAccessService.isCurrentUserAdmin(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        
        if (!snapshot.hasData || !snapshot.data!) {
          return Scaffold(
            appBar: AppBar(title: Text('Access Denied')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Admin Access Required',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text('This feature is only available to administrators'),
                ],
              ),
            ),
          );
        }
        
        return Scaffold(
          backgroundColor: AppColor.background,
          appBar: AppBar(
            backgroundColor: Colors.orange,
            title: Text(
              'Promotion Management',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: [
                Tab(text: 'Requests'),
                Tab(text: 'Active'),
                Tab(text: 'Analytics'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildRequestsTab(),
              _buildActivePromotionsTab(),
              _buildAnalyticsTab(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRequestsTab() {
    return Column(
      children: [
        // Filter Bar
        Container(
          padding: EdgeInsets.all(16),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All', 'all'),
                SizedBox(width: 8),
                _buildFilterChip('Pending', 'pending'),
                SizedBox(width: 8),
                _buildFilterChip('Approved', 'approved'),
                SizedBox(width: 8),
                _buildFilterChip('Rejected', 'rejected'),
              ],
            ),
          ),
        ),
        
        // Requests List with refresh key
        Expanded(
          key: _requestsKey,
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: PromotionService.fetchPromotionRequests(
              status: selectedFilter == 'all' ? null : selectedFilter,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              
              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, size: 64, color: Colors.red),
                      SizedBox(height: 16),
                      Text('Error loading requests'),
                      Text('${snapshot.error}'),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _refreshData,
                        child: Text('Retry'),
                      ),
                    ],
                  ),
                );
              }
              
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.request_page, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No Requests Found',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text('No promotion requests match the current filter'),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _refreshData,
                        child: Text('Refresh'),
                      ),
                    ],
                  ),
                );
              }
              
              return RefreshIndicator(
                onRefresh: () async => _refreshData(),
                child: ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final request = snapshot.data![index];
                    return _buildRequestCard(request);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActivePromotionsTab() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      key: _activeKey,
      future: PromotionService.fetchActivePromotions(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, size: 64, color: Colors.red),
                SizedBox(height: 16),
                Text('Error loading active promotions'),
                Text('${snapshot.error}'),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _refreshData,
                  child: Text('Retry'),
                ),
              ],
            ),
          );
        }
        
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.trending_up, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No Active Promotions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text('No listings are currently being promoted'),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _refreshData,
                  child: Text('Refresh'),
                ),
              ],
            ),
          );
        }
        
        return RefreshIndicator(
          onRefresh: () async => _refreshData(),
          child: ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final promotion = snapshot.data![index];
              return _buildActivePromotionCard(promotion);
            },
          ),
        );
      },
    );
  }

  Widget _buildAnalyticsTab() {
    return FutureBuilder<Map<String, dynamic>>(
      key: _analyticsKey,
      future: PromotionService.getPromotionAnalytics(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, size: 64, color: Colors.red),
                SizedBox(height: 16),
                Text('Error loading analytics'),
                Text('${snapshot.error}'),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _refreshData,
                  child: Text('Retry'),
                ),
              ],
            ),
          );
        }
        
        if (!snapshot.hasData) {
          return Center(child: Text('No analytics data available'));
        }

        final analytics = snapshot.data!;
        final statusCounts = analytics['statusCounts'] as Map<String, int>;
        final totalRequests = analytics['totalRequests'] as int;
        final totalRevenue = analytics['totalRevenue'] as double;
        final activePromotions = analytics['activePromotions'] as int;
        
        final pendingRequests = statusCounts['pending'] ?? 0;
        final approvedRequests = statusCounts['approved'] ?? 0;
        final rejectedRequests = statusCounts['rejected'] ?? 0;

        return RefreshIndicator(
          onRefresh: () async => _refreshData(),
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Analytics Overview',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColor.textDark,
                  ),
                ),
                SizedBox(height: 20),
                
                // Stats Grid
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.5,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    _buildStatCard('Total Requests', totalRequests.toString(), Icons.request_page, Colors.blue),
                    _buildStatCard('Active Promotions', activePromotions.toString(), Icons.trending_up, Colors.green),
                    _buildStatCard('Pending', pendingRequests.toString(), Icons.pending, Colors.orange),
                    _buildStatCard('Total Revenue', '\$${totalRevenue.toStringAsFixed(2)}', Icons.attach_money, Colors.purple),
                  ],
                ),
                
                SizedBox(height: 24),
                
                // Status Breakdown
                Text(
                  'Request Status Breakdown',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColor.textDark,
                  ),
                ),
                SizedBox(height: 16),
                
                _buildStatusBar('Approved', approvedRequests, totalRequests, Colors.green),
                SizedBox(height: 8),
                _buildStatusBar('Pending', pendingRequests, totalRequests, Colors.orange),
                SizedBox(height: 8),
                _buildStatusBar('Rejected', rejectedRequests, totalRequests, Colors.red),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          selectedFilter = value;
          _requestsKey = UniqueKey(); // Refresh requests when filter changes
        });
      },
      selectedColor: AppColor.primary.withOpacity(0.2),
      checkmarkColor: AppColor.primary,
      labelStyle: TextStyle(
        color: isSelected ? AppColor.primary : AppColor.textSecondary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> request) {
    final status = request['status'] ?? 'pending';
    final createdAt = DateTime.tryParse(request['created_at'] ?? '');
    final promotionType = request['promotion_type'] ?? 'featured';
    final days = request['duration_days'] ?? 0;
    final price = (request['price'] ?? 0).toDouble();
    
    // Get listing info from joined data
    final listing = request['listings'] as Map<String, dynamic>?;
    final listingTitle = listing?['title'] ?? 'Unknown Listing';
    final currency = listing?['currency'] ?? 'USD';
    
    // Get user info from joined data
    final user = request['users'] as Map<String, dynamic>?;
    final userName = user?['display_name'] ?? 'Unknown User';
    final userEmail = user?['email'] ?? '';
    
    final statusColor = _getStatusColor(status);
    final statusIcon = _getStatusIcon(status);

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(statusIcon, color: statusColor, size: 20),
                  SizedBox(width: 8),
                  Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Text(
                createdAt != null ? '${createdAt.day}/${createdAt.month}/${createdAt.year}' : 'Unknown date',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            listingTitle,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: AppColor.textDark,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'User: $userName ($userEmail)',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
          SizedBox(height: 4),
          Row(
            children: [
              Text(
                'Type: ${promotionType == 'featured' ? 'Featured Listing' : 'Promoted Listing'}',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
              Spacer(),
              Text(
                '$currency \$${price.toStringAsFixed(2)}',
                style: TextStyle(
                  color: Colors.green.shade600,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Text(
            'Duration: $days days',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
          
          if (status == 'pending') ...[
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showApproveDialog(request['id'], request['listing_id']),
                    icon: Icon(Icons.check, size: 16),
                    label: Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showRejectDialog(request['id']),
                    icon: Icon(Icons.close, size: 16),
                    label: Text('Reject'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
          
          if (status == 'approved') ...[
            SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _activatePromotion(request['id']),
                icon: Icon(Icons.play_arrow, size: 16),
                label: Text('Activate Promotion'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActivePromotionCard(Map<String, dynamic> promotion) {
    final startDate = DateTime.tryParse(promotion['start_date'] ?? '');
    final endDate = DateTime.tryParse(promotion['end_date'] ?? '');
    final promotionType = promotion['promotion_type'] ?? 'featured';
    final durationDays = promotion['duration_days'] ?? 0;
    final price = (promotion['price'] ?? 0).toDouble();
    
    // Get listing info from joined data
    final listing = promotion['listings'] as Map<String, dynamic>?;
    final listingTitle = listing?['title'] ?? 'Unknown Listing';
    final currency = listing?['currency'] ?? 'USD';
    
    // Get user info from joined data
    final user = promotion['users'] as Map<String, dynamic>?;
    final userName = user?['display_name'] ?? 'Unknown User';
    final userEmail = user?['email'] ?? '';
    
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.trending_up, color: Colors.blue, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'ACTIVE',
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: () => _stopPromotion(promotion['id']),
                icon: Icon(Icons.stop, color: Colors.red),
                tooltip: 'Stop Promotion',
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            listingTitle,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: AppColor.textDark,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'User: $userName ($userEmail)',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Type: ${promotionType == 'featured' ? 'Featured' : 'Promoted'}',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
          Text(
            'Duration: $durationDays days',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
          if (startDate != null && endDate != null) ...[
            Text(
              'Period: ${startDate.day}/${startDate.month}/${startDate.year} - ${endDate.day}/${endDate.month}/${endDate.year}',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ],
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Revenue: $currency \$${price.toStringAsFixed(2)}',
                style: TextStyle(
                  color: Colors.green.shade600,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColor.textDark,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: AppColor.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBar(String label, int count, int total, Color color) {
    final percentage = total > 0 ? (count / total) : 0.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(fontWeight: FontWeight.w600)),
            Text('$count (${(percentage * 100).toStringAsFixed(1)}%)', 
                 style: TextStyle(color: AppColor.textSecondary)),
          ],
        ),
        SizedBox(height: 4),
        LinearProgressIndicator(
          value: percentage,
          backgroundColor: Colors.grey.shade200,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.blue;
      case 'rejected':
        return Colors.red;
      case 'active':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.pending;
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'active':
        return Icons.trending_up;
      default:
        return Icons.help;
    }
  }

  // Action Methods
  void _refreshData() {
    setState(() {
      _requestsKey = UniqueKey();
      _activeKey = UniqueKey();
      _analyticsKey = UniqueKey();
    });
  }

  void _showApproveDialog(String requestId, String listingId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Approve Promotion Request'),
        content: Text('Are you sure you want to approve this promotion request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final success = await PromotionService.approvePromotionRequest(requestId);
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Promotion request approved successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
                _refreshData();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to approve promotion request'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text('Approve', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(String requestId) {
    final reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reject Promotion Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Please provide a reason for rejecting this request:'),
            SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                hintText: 'Rejection reason...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (reasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Please provide a reason')),
                );
                return;
              }
              
              Navigator.of(context).pop();
              final success = await PromotionService.rejectPromotionRequest(
                requestId, 
                reasonController.text.trim(),
              );
              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Promotion request rejected'),
                    backgroundColor: Colors.red,
                  ),
                );
                _refreshData();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to reject promotion request'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Reject', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _activatePromotion(String requestId) async {
    final success = await PromotionService.approvePromotionRequest(requestId);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Promotion activated successfully'),
          backgroundColor: Colors.green,
        ),
      );
      _refreshData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to activate promotion'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _stopPromotion(String requestId) async {
    final success = await PromotionService.cancelPromotion(requestId);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Promotion stopped successfully'),
          backgroundColor: Colors.green,
        ),
      );
      _refreshData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to stop promotion'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
