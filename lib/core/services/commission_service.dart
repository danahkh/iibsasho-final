import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/app_logger.dart';

class CommissionService {
  static final SupabaseClient _supabase = Supabase.instance.client;
  static const double COMMISSION_RATE = 0.01; // 1% commission like Haraj
  static const double MINIMUM_COMMISSION = 5.0; // Minimum commission amount
  
  /// Calculate commission for a listing sale
  static double calculateCommission(double salePrice) {
    double commission = salePrice * COMMISSION_RATE;
    return commission < MINIMUM_COMMISSION ? MINIMUM_COMMISSION : commission;
  }
  
  /// Record commission when a sale is made
  static Future<bool> recordCommission({
    required String listingId,
    required String sellerId,
    required String buyerId,
    required double salePrice,
    required String paymentMethod,
  }) async {
    try {
      final commission = calculateCommission(salePrice);
      
      await _supabase.from('commissions').insert({
        'listing_id': listingId,
        'seller_id': sellerId,
        'buyer_id': buyerId,
        'sale_price': salePrice,
        'commission_amount': commission,
        'payment_method': paymentMethod,
        'status': 'pending', // pending, paid, disputed
        'created_at': DateTime.now().toIso8601String(),
        'due_date': DateTime.now().add(Duration(days: 30)).toIso8601String(),
      });
      
      // Update seller's commission balance
      await _updateSellerCommissionBalance(sellerId, commission);
      
      return true;
    } catch (e) {
      AppLogger.e('Error recording commission', e);
      return false;
    }
  }
  
  /// Update seller's total commission balance
  static Future<void> _updateSellerCommissionBalance(String sellerId, double amount) async {
    try {
      // Get current balance
      final user = await _supabase
          .from('users')
          .select('totalCommissionsDue')
          .eq('id', sellerId)
          .single();
      
      final currentBalance = (user['totalCommissionsDue'] ?? 0.0) as double;
      
      await _supabase
          .from('users')
          .update({
            'totalCommissionsDue': currentBalance + amount,
            'lastCommissionDate': DateTime.now().toIso8601String(),
          })
          .eq('id', sellerId);
    } catch (e) {
      AppLogger.e('Error updating commission balance', e);
    }
  }
  
  /// Get seller's commission history
  static Stream<List<Map<String, dynamic>>> getSellerCommissions(String sellerId) {
    return _supabase
        .from('commissions')
        .stream(primaryKey: ['id'])
        .eq('seller_id', sellerId)
        .order('created_at', ascending: false)
        .map((data) => data.cast<Map<String, dynamic>>());
  }

  /// Process commission payment
  static Future<bool> processCommissionPayment({
    required String commissionId,
    required String paymentMethod,
    required double amount,
    String? receiptUrl,
    String? transactionId,
  }) async {
    try {
      await _supabase.from('commission_payments').insert({
        'commissionId': commissionId,
        'paymentMethod': paymentMethod,
        'amount': amount,
        'receiptUrl': receiptUrl,
        'transactionId': transactionId,
        'status': 'submitted',
        'submittedAt': DateTime.now().toIso8601String(),
        'userId': _supabase.auth.currentUser?.id,
      });
      
      // Update commission status
      await _supabase
          .from('commissions')
          .update({
            'status': 'payment_submitted',
            'paymentSubmittedAt': DateTime.now().toIso8601String(),
          })
          .eq('id', commissionId);
      
      return true;
    } catch (e) {
      AppLogger.e('Error processing commission payment', e);
      return false;
    }
  }
  
  /// Get payment methods (like Haraj's multiple options)
  static List<PaymentMethod> getPaymentMethods() {
    return [
      PaymentMethod(
        id: 'mada',
        name: 'MADA Card',
        icon: 'assets/icons/mada.png',
        isOnline: true,
      ),
      PaymentMethod(
        id: 'visa',
        name: 'Visa/Mastercard',
        icon: 'assets/icons/visa.png',
        isOnline: true,
      ),
      PaymentMethod(
        id: 'bank_transfer',
        name: 'Bank Transfer',
        icon: 'assets/icons/bank.png',
        isOnline: false,
      ),
      PaymentMethod(
        id: 'apple_pay',
        name: 'Apple Pay',
        icon: 'assets/icons/apple_pay.png',
        isOnline: true,
      ),
    ];
  }

  /// Get commission statistics
  static Future<Map<String, dynamic>> getCommissionStats(String sellerId) async {
    try {
      final response = await _supabase
          .from('commissions')
          .select('commission_amount, status')
          .eq('seller_id', sellerId);

      double totalPending = 0.0;
      double totalPaid = 0.0;
      int pendingCount = 0;
      int paidCount = 0;

      for (var commission in response) {
        final amount = (commission['commission_amount'] ?? 0.0) as double;
        final status = commission['status'] as String;

        if (status == 'pending') {
          totalPending += amount;
          pendingCount++;
        } else if (status == 'paid') {
          totalPaid += amount;
          paidCount++;
        }
      }

      return {
        'totalPending': totalPending,
        'totalPaid': totalPaid,
        'pendingCount': pendingCount,
        'paidCount': paidCount,
        'totalCommissions': totalPending + totalPaid,
      };
    } catch (e) {
      AppLogger.e('Error getting commission stats', e);
      return {};
    }
  }
}

class PaymentMethod {
  final String id;
  final String name;
  final String icon;
  final bool isOnline;
  
  PaymentMethod({
    required this.id,
    required this.name,
    required this.icon,
    required this.isOnline,
  });
}

/// Commission model
class Commission {
  final String id;
  final String listingId;
  final String sellerId;
  final String buyerId;
  final double salePrice;
  final double commissionAmount;
  final String paymentMethod;
  final String status;
  final DateTime createdAt;
  final DateTime? dueDate;
  
  Commission({
    required this.id,
    required this.listingId,
    required this.sellerId,
    required this.buyerId,
    required this.salePrice,
    required this.commissionAmount,
    required this.paymentMethod,
    required this.status,
    required this.createdAt,
    this.dueDate,
  });
  
  factory Commission.fromJson(Map<String, dynamic> data) {
    return Commission(
      id: data['id'] ?? '',
      listingId: data['listing_id'] ?? '',
      sellerId: data['seller_id'] ?? '',
      buyerId: data['buyer_id'] ?? '',
      salePrice: (data['sale_price'] ?? 0).toDouble(),
      commissionAmount: (data['commission_amount'] ?? 0).toDouble(),
      paymentMethod: data['payment_method'] ?? '',
      status: data['status'] ?? 'pending',
      createdAt: DateTime.parse(data['created_at']),
      dueDate: data['due_date'] != null ? DateTime.parse(data['due_date']) : null,
    );
  }
}
