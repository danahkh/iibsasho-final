import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../constant/app_color.dart';
import '../../widgets/standard_scaffold.dart';
import '../../core/services/database_service.dart';

class RequestsPage extends StatefulWidget {
  const RequestsPage({super.key});

  @override
  State<RequestsPage> createState() => _RequestsPageState();
}

class _RequestsPageState extends State<RequestsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isAdmin = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkAdmin();
  }

  Future<void> _checkAdmin() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        setState(() { _isAdmin = false; _loading = false; });
        return;
      }
      final profile = await Supabase.instance.client
          .from('users')
          .select('is_admin, role')
          .eq('id', user.id)
          .maybeSingle();
      final isAdmin = (profile != null && (profile['is_admin'] == true || profile['role'] == 'admin'));
      setState(() { _isAdmin = isAdmin; _loading = false; });
    } catch (e) {
      setState(() { _loading = false; });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return StandardScaffold(
      title: 'Requests',
      currentIndex: 4,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(44),
        child: Align(
          alignment: Alignment.centerLeft,
          child: TabBar(
            controller: _tabController,
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
              Tab(text: 'Promotions'),
              Tab(text: 'Subscriptions'),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _PromotionRequestTab(),
          _SubscriptionsTab(isAdmin: _isAdmin),
        ],
      ),
    );
  }
}

class _PromotionRequestTab extends StatefulWidget {
  @override
  State<_PromotionRequestTab> createState() => _PromotionRequestTabState();
}

class _PromotionRequestTabState extends State<_PromotionRequestTab> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedListingId;
  String _duration = '7';
  bool _submitting = false;
  List<Map<String, dynamic>> _myListings = [];
  bool _loadingListings = true;

  @override
  void initState() {
    super.initState();
    _loadListings();
  }

  Future<void> _loadListings() async {
    final data = await DatabaseService.getMyListings();
    setState(() { _myListings = data; _loadingListings = false; });
  }

  Future<void> _submit() async {
    if(!_formKey.currentState!.validate()) return;
    if(_selectedListingId == null) return;
    setState(()=> _submitting = true);
    try {
      final res = await DatabaseService.createPromotionRequest({
        'listing_id': _selectedListingId,
        'duration_days': int.tryParse(_duration) ?? 7,
        'status': 'pending',
      });
      if (mounted) {
        if (res != null) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Promotion request submitted')));
          setState(() { _selectedListingId = null; _duration = '7'; });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to submit')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(()=> _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Request a Promotion', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _loadingListings
              ? const Center(child: CircularProgressIndicator())
              : _myListings.isEmpty
                  ? const Text('You have no listings. Create one first.')
                  : Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DropdownButtonFormField<String>(
                            value: _selectedListingId,
                            items: _myListings
                                .map((l) => DropdownMenuItem(
                                      value: l['id'].toString(),
                                      child: Text(l['title'] ?? 'Untitled'),
                                    ))
                                .toList(),
                            decoration: const InputDecoration(labelText: 'Select Listing'),
                            onChanged: (v) => setState(() => _selectedListingId = v),
                            validator: (v) => v == null ? 'Please choose a listing' : null,
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: _duration,
                            decoration: const InputDecoration(labelText: 'Duration (days)'),
                            items: const [
                              DropdownMenuItem(value: '7', child: Text('7 days')),
                              DropdownMenuItem(value: '14', child: Text('14 days')),
                              DropdownMenuItem(value: '30', child: Text('30 days')),
                            ],
                            onChanged: (v) => setState(() => _duration = v ?? '7'),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _submitting ? null : _submit,
                              icon: _submitting
                                  ? const SizedBox(width:16, height:16, child: CircularProgressIndicator(strokeWidth:2))
                                  : const Icon(Icons.send),
                              label: const Text('Submit Request'),
                            ),
                          ),
                        ],
                      ),
                    ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 8),
          const Text('My Promotion Requests', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          FutureBuilder<List<Map<String,dynamic>>>(
            future: DatabaseService.getPromotionRequests(),
            builder: (c,s){
              if (s.connectionState==ConnectionState.waiting) return const Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator());
              final userId = Supabase.instance.client.auth.currentUser?.id;
              final items = s.data
                      ?.where((r)=> r['listing_id'] != null && (r['user_id'] == userId))
                      .toList() 
                  ?? [];
              if(items.isEmpty) return const Text('No promotion requests yet.');
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                separatorBuilder: (_, __)=> const SizedBox(height: 8),
                itemBuilder: (c,i){
                  final r = items[i];
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: AppColor.border),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Listing: ${r['listing_id']}', style: const TextStyle(fontWeight: FontWeight.w600)),
                              const SizedBox(height:4),
                              Text('Status: ${r['status']}', style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                        ),
                        Text('${r['duration_days'] ?? '-'} d', style: const TextStyle(fontSize:12, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SubscriptionsTab extends StatelessWidget {
  final bool isAdmin;
  const _SubscriptionsTab({required this.isAdmin});
  @override
  Widget build(BuildContext context) {
    if(!isAdmin){
      return const Center(child: Text('Admins only (coming soon)'));
    }
    return const Center(child: Text('Subscriptions management coming soon'));
  }
}
