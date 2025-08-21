import 'package:flutter/material.dart';
import '../../constant/app_color.dart';
import '../../core/services/commission_service.dart';
import '../../core/utils/supabase_helper.dart';

class CommissionPage extends StatefulWidget {
  const CommissionPage({super.key});

  @override
  _CommissionPageState createState() => _CommissionPageState();
}

class _CommissionPageState extends State<CommissionPage> with TickerProviderStateMixin {
  late TabController _tabController;
  List<PaymentMethod> paymentMethods = [];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    paymentMethods = CommissionService.getPaymentMethods();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = SupabaseHelper.currentUser;
    
    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Commission Management')),
        body: Center(
          child: Text('Please log in to view commissions'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: Text(
          'Commission Management',
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
            Tab(text: 'Overview'),
            Tab(text: 'History'),
            Tab(text: 'Payment'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(currentUser.id),
          _buildHistoryTab(currentUser.id),
          _buildPaymentTab(),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(String userId) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Commission Rate Info Card
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade100, Colors.green.shade50],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.percent, color: Colors.green, size: 28),
                    SizedBox(width: 8),
                    Text(
                      'Commission Rate',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade800,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  'Only ${(CommissionService.COMMISSION_RATE * 100).toStringAsFixed(1)}% commission on sales',
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Minimum commission: \$${CommissionService.MINIMUM_COMMISSION.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: Colors.green.shade600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 20),
          
          // Commission Calculator
          _buildCommissionCalculator(),
          
          SizedBox(height: 20),
          
          // User Commission Stats
          FutureBuilder<Map<String, dynamic>?>(
            future: SupabaseHelper.selectSingle('users', 'id', userId)
                .then((data) => data as Map<String, dynamic>?),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Center(child: CircularProgressIndicator());
              }
              
              final userData = snapshot.data;
              final totalCommissionsDue = userData?['totalCommissionsDue'] ?? 0.0;
              
              return _buildCommissionStatsCard(totalCommissionsDue);
            },
          ),
          
          SizedBox(height: 20),
          
          // Payment Methods Info
          _buildPaymentMethodsInfo(),
        ],
      ),
    );
  }

  Widget _buildCommissionCalculator() {
    final TextEditingController priceController = TextEditingController();
    double calculatedCommission = 0.0;
    
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: StatefulBuilder(
        builder: (context, setState) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.calculate, color: AppColor.primary),
                  SizedBox(width: 8),
                  Text(
                    'Commission Calculator',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColor.textDark,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Sale Price (\$)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.money),
                ),
                onChanged: (value) {
                  final price = double.tryParse(value) ?? 0.0;
                  setState(() {
                    calculatedCommission = CommissionService.calculateCommission(price);
                  });
                },
              ),
              SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Commission Amount:',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '\$${calculatedCommission.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: Colors.green.shade800,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCommissionStatsCard(double totalCommissionsDue) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_balance_wallet, color: AppColor.primary),
              SizedBox(width: 8),
              Text(
                'Your Commission Summary',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColor.textDark,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  title: 'Total Due',
                  value: '\$${totalCommissionsDue.toStringAsFixed(2)}',
                  color: Colors.orange,
                  icon: Icons.pending,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildStatItem(
                  title: 'Paid',
                  value: '\$0.00',
                  color: Colors.green,
                  icon: Icons.check_circle,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  title: 'This Month',
                  value: '\$${totalCommissionsDue.toStringAsFixed(2)}',
                  color: Colors.blue,
                  icon: Icons.calendar_month,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildStatItem(
                  title: 'Next Due',
                  value: '30 days',
                  color: Colors.purple,
                  icon: Icons.schedule,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              SizedBox(width: 4),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodsInfo() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.payment, color: AppColor.primary),
              SizedBox(width: 8),
              Text(
                'Accepted Payment Methods',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColor.textDark,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          ...paymentMethods.map((method) => _buildPaymentMethodItem(method)),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodItem(PaymentMethod method) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: method.isOnline ? Colors.green.shade100 : Colors.blue.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              method.isOnline ? Icons.online_prediction : Icons.account_balance,
              color: method.isOnline ? Colors.green : Colors.blue,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  method.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  method.isOnline ? 'Online Payment' : 'Bank Transfer',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (method.isOnline)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Instant',
                style: TextStyle(
                  color: Colors.green.shade700,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab(String userId) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: CommissionService.getSellerCommissions(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No commission history yet',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey.shade600,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Start selling to see your commission history here',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          );
        }
        
        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final commissionData = snapshot.data![index];
            final commission = Commission.fromJson(commissionData);
            return _buildCommissionHistoryItem(commission);
          },
        );
      },
    );
  }

  Widget _buildCommissionHistoryItem(Commission commission) {
    Color statusColor;
    IconData statusIcon;
    
    switch (commission.status) {
      case 'pending':
        statusColor = Colors.orange;
        statusIcon = Icons.pending;
        break;
      case 'paid':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'disputed':
        statusColor = Colors.red;
        statusIcon = Icons.error;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help;
    }

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
                    commission.status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Text(
                '\$${commission.commissionAmount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColor.textDark,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Sale Price: \$${commission.salePrice.toStringAsFixed(2)}',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
          Text(
            'Payment: ${commission.paymentMethod}',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
          Text(
            'Date: ${commission.createdAt.day}/${commission.createdAt.month}/${commission.createdAt.year}',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
          if (commission.dueDate != null)
            Text(
              'Due: ${commission.dueDate!.day}/${commission.dueDate!.month}/${commission.dueDate!.year}',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPaymentTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Payment Instructions
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue),
                    SizedBox(width: 8),
                    Text(
                      'Payment Instructions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Text(
                  '1. Commission payments are due within 30 days of sale',
                  style: TextStyle(color: Colors.blue.shade700),
                ),
                Text(
                  '2. Use any of the accepted payment methods below',
                  style: TextStyle(color: Colors.blue.shade700),
                ),
                Text(
                  '3. Upload payment receipt for verification',
                  style: TextStyle(color: Colors.blue.shade700),
                ),
                Text(
                  '4. Payments are verified within 24-48 hours',
                  style: TextStyle(color: Colors.blue.shade700),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 20),
          
          // Payment Method Selection
          Text(
            'Select Payment Method',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColor.textDark,
            ),
          ),
          SizedBox(height: 16),
          
          ...paymentMethods.map((method) => _buildPaymentMethodCard(method)),
          
          SizedBox(height: 20),
          
          // Manual Payment Upload
          _buildManualPaymentUpload(),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodCard(PaymentMethod method) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: Card(
        child: ListTile(
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: method.isOnline ? Colors.green.shade100 : Colors.blue.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              method.isOnline ? Icons.credit_card : Icons.account_balance,
              color: method.isOnline ? Colors.green : Colors.blue,
            ),
          ),
          title: Text(
            method.name,
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            method.isOnline ? 'Pay instantly online' : 'Bank transfer with receipt upload',
          ),
          trailing: ElevatedButton(
            onPressed: () {
              if (method.isOnline) {
                _showOnlinePaymentDialog(method);
              } else {
                _showBankTransferDialog(method);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: method.isOnline ? Colors.green : Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: Text('Pay'),
          ),
        ),
      ),
    );
  }

  Widget _buildManualPaymentUpload() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Upload Payment Receipt',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColor.textDark,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'If you\'ve already made a payment, upload your receipt here',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Receipt upload feature coming soon!')),
                    );
                  },
                  icon: Icon(Icons.upload_file),
                  label: Text('Choose File'),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Receipt submitted successfully!')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.primary,
                  ),
                  child: Text('Submit'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showOnlinePaymentDialog(PaymentMethod method) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Online Payment - ${method.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.credit_card, size: 64, color: Colors.green),
            SizedBox(height: 16),
            Text(
              'You will be redirected to ${method.name} payment gateway.',
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'This is a demo. Payment integration will be implemented in the next phase.',
              style: TextStyle(
                color: Colors.orange.shade700,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Redirecting to ${method.name}...'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: Text('Proceed'),
          ),
        ],
      ),
    );
  }

  void _showBankTransferDialog(PaymentMethod method) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Bank Transfer - ${method.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bank Details:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('Bank: Sample Bank'),
            Text('Account Name: iibsasho Commission'),
            Text('Account Number: 1234567890'),
            Text('Sort Code: 123456'),
            SizedBox(height: 16),
            Text(
              'After transfer, upload your receipt in the Payment tab.',
              style: TextStyle(
                color: Colors.blue.shade700,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Got It'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _tabController.animateTo(2); // Switch to payment tab
            },
            child: Text('Upload Receipt'),
          ),
        ],
      ),
    );
  }
}
