import 'package:flutter/material.dart';
import '../../constant/app_color.dart';
import '../../core/utils/supabase_helper.dart';
import '../../core/services/database_service.dart';
import '../../core/services/promotion_service.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _loadingAdmin = true;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _checkAdmin();
  }

  Future<void> _checkAdmin() async {
    try {
      final isAdmin = await SupabaseHelper.isCurrentUserAdmin();
      setState(() {
        _isAdmin = isAdmin;
        _loadingAdmin = false;
      });
    } catch (e) {
      setState(() {
        _loadingAdmin = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Admin Dashboard')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (!_isAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Admin Dashboard')),
        body: Center(
          child: Text('Access denied', style: TextStyle(color: AppColor.error, fontSize: 18)),
        ),
      );
    }
    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: AppColor.primary,
        elevation: 2,
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
                Tab(text: 'Listings'),
                Tab(text: 'Support'),
                Tab(text: 'Analytics'),
                Tab(text: 'Notify'),
              ],
            ),
          ),
        ),
      ),
      body: Container(
        color: AppColor.background,
        child: TabBarView(
          controller: _tabController,
          children: [
            _ListingsAdminTab(),
            _SupportAdminTab(),
            _AnalyticsAdminTab(),
            _NotificationSenderTab(),
          ],
        ),
      ),
    );
  }
}

class _ListingsAdminTab extends StatefulWidget {
  @override
  State<_ListingsAdminTab> createState() => _ListingsAdminTabState();
}

class _ListingsAdminTabState extends State<_ListingsAdminTab> {
  bool _loading = true;
  List<Map<String, dynamic>> _listings = [];
  String _search = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await SupabaseHelper.client
          .from('listings')
          .select()
          .order('created_at', ascending: false)
          .limit(200);
      setState(() {
        _listings = List<Map<String, dynamic>>.from(data);
        _loading = false;
      });
    } catch (e) {
      setState(() { _loading = false; });
    }
  }

  Future<void> _toggleFlag(Map<String, dynamic> listing, String field) async {
    final id = listing['id'];
    final newValue = !(listing[field] == true);
    setState(() { listing[field] = newValue; });
    try {
      await SupabaseHelper.client
          .from('listings')
          .update({field: newValue, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', id);
    } catch (e) {
      setState(() { listing[field] = !newValue; });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Update failed')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final filtered = _listings.where((l) => l['title']?.toString().toLowerCase().contains(_search.toLowerCase()) ?? false).toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search listings'),
            onChanged: (v){ setState(()=> _search = v); },
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            child: ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (c,i){
                final l = filtered[i];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(child: Text(l['title']!=null && l['title'].toString().isNotEmpty ? l['title'][0] : '?')),
                    title: Text(l['title'] ?? ''),
                    subtitle: Row(children: [
                      if (l['is_promoted']==true) _pill('PROMOTED', Colors.amber),
                      if (l['is_featured']==true && l['is_promoted']!=true) _pill('FEATURED', Colors.blue),
                    ]),
                    trailing: Wrap(spacing:4, children: [
                      FilterChip(label: const Text('Promoted'), selected: l['is_promoted']==true, onSelected:(_)=> _toggleFlag(l,'is_promoted')),
                      FilterChip(label: const Text('Featured'), selected: l['is_featured']==true, onSelected:(_)=> _toggleFlag(l,'is_featured')),
                    ]),
                  ),
                );
              },
            ),
          ),
        )
      ],
    );
  }

  Widget _pill(String text, Color color){
    return Container(margin: const EdgeInsets.only(right:4), padding: const EdgeInsets.symmetric(horizontal:6, vertical:2), decoration: BoxDecoration(color: color.withOpacity(.15), borderRadius: BorderRadius.circular(8), border: Border.all(color: color)), child: Text(text, style: TextStyle(fontSize:10, fontWeight: FontWeight.bold, color: color))); }
}

class _SupportAdminTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String,dynamic>>>(
      future: DatabaseService.getSupportRequests(),
      builder: (c,s){
        if (s.connectionState==ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!s.hasData || s.data!.isEmpty) return const Center(child: Text('No support requests'));
        final items = s.data!;
        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (c,i){
            final r = items[i];
            return ExpansionTile(
              title: Text(r['subject']?? r['category']?? 'Request'),
              subtitle: Text(r['status']??'pending'),
              children: [
                Padding(padding: const EdgeInsets.all(12), child: Text(r['description']??'')),
                Row(children:[
                  TextButton(onPressed: (){ DatabaseService.updateSupportRequestStatus(r['id'].toString(), 'closed'); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Closed')));}, child: const Text('Close')),
                ])
              ],
            );
          },
        );
      },
    );
  }
}

class _AnalyticsAdminTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String,dynamic>>(
      future: PromotionService.getPromotionAnalytics(),
      builder: (c,s){
        if (s.connectionState==ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        final data = s.data ?? {};
        final status = (data['statusCounts'] as Map<String,int>? ) ?? {};
        final total = data['totalRequests'] ?? 0;
        final active = data['activePromotions'] ?? 0;
        final approved = status['approved'] ?? 0;
        final pending = status['pending'] ?? 0;
        final rejected = status['rejected'] ?? 0;
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.8,
              children: [
                _statCard('Promotion Requests', total.toString(), Icons.campaign, Colors.blue),
                _statCard('Active Promotions', active.toString(), Icons.star, Colors.amber.shade700),
                _statCard('Approved', approved.toString(), Icons.check_circle, Colors.green),
                _statCard('Pending', pending.toString(), Icons.hourglass_bottom, Colors.orange),
                _statCard('Rejected', rejected.toString(), Icons.cancel, Colors.red),
              ],
            ),
            const SizedBox(height:24),
            const Text('Status Breakdown', style: TextStyle(fontWeight: FontWeight.bold)),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: status.entries.map((e)=> Chip(label: Text('${e.key}: ${e.value}'))).toList(),
            ),
          ],
        );
      },
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color){
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withOpacity(.12), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                  const SizedBox(height:4),
                  Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _NotificationSenderTab extends StatefulWidget {
  @override
  State<_NotificationSenderTab> createState() => _NotificationSenderTabState();
}

class _NotificationSenderTabState extends State<_NotificationSenderTab> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  bool _sending = false;

  Future<void> _send() async {
    if(!_formKey.currentState!.validate()) return;
    setState(()=> _sending = true);
    try {
      await DatabaseService.createNotification({
        'title': _titleCtrl.text,
        'body': _bodyCtrl.text,
        'type': 'admin_broadcast'
      });
      if(mounted){
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notification queued')));
        _titleCtrl.clear();
        _bodyCtrl.clear();
      }
    } catch(_) {
      if(mounted){
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to send')));
      }
    } finally {
      if(mounted) setState(()=> _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: 'Title'),
              validator: (v)=> v==null || v.isEmpty ? 'Required' : null,
            ),
            TextFormField(
              controller: _bodyCtrl,
              decoration: const InputDecoration(labelText: 'Message'),
              maxLines: 4,
              validator: (v)=> v==null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _sending ? null : _send,
              icon: _sending ? const SizedBox(height:16, width:16, child: CircularProgressIndicator(strokeWidth:2)) : const Icon(Icons.send),
              label: const Text('Send Notification'),
            )
          ],
        ),
      ),
    );
  }
}
