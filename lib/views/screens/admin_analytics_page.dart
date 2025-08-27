import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../constant/app_color.dart';

class AdminAnalyticsPage extends StatefulWidget {
  const AdminAnalyticsPage({super.key});

  @override
  State<AdminAnalyticsPage> createState() => _AdminAnalyticsPageState();
}

class _AdminAnalyticsPageState extends State<AdminAnalyticsPage> {
  String _chartType = 'bar'; // bar | line
  String _range = '30d'; // 7d | 30d | 90d
  String _category = 'all';
  bool _loading = true;
  List<_Point> _series = [];
  List<_CategoryTotal> _categoryTotals = [];
  List<_SearchItem> _commonSearches = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(()=> _loading = true);
    try {
      final client = Supabase.instance.client;
      // Time series: daily views for listings by category filter
      final fromDate = DateTime.now().subtract(
        _range == '7d' ? const Duration(days: 7)
        : _range == '90d' ? const Duration(days: 90)
        : const Duration(days: 30)
      );

      // Assume a table listing_views(date, listing_id, category, count)
      // If not present, fallback to simple synthetic aggregation from listings.view_count is not time-based; so we only draw category totals.
      List<dynamic> rows = [];
      try {
        dynamic q = client.from('listing_views')
          .select('date,count,category')
          .gte('date', fromDate.toIso8601String().substring(0,10))
          .order('date');
        if (_category != 'all') {
          q = q.eq('category', _category);
        }
        rows = await q;
      } catch (_) {
        rows = [];
      }

      final series = <_Point>[];
      for (final r in rows) {
        final d = DateTime.tryParse(r['date'].toString());
        final c = (r['count'] as num?)?.toDouble() ?? 0;
        if (d != null) series.add(_Point(d, c));
      }

      // Category totals from listings table (sum view_count grouped by category)
      List<dynamic> catRows = [];
      try {
        catRows = await client
          .from('listings')
          .select('category, view_count')
          .limit(10000);
      } catch (_) {
        catRows = [];
      }
      final Map<String, double> catAgg = {};
      for (final r in catRows) {
        final cat = (r['category'] ?? 'other').toString();
        final v = (r['view_count'] as num?)?.toDouble() ?? 0;
        catAgg[cat] = (catAgg[cat] ?? 0) + v;
      }
      final catTotals = catAgg.entries
          .map((e) => _CategoryTotal(e.key, e.value))
          .toList()
        ..sort((a,b)=> b.total.compareTo(a.total));

      // Common searches (assume saved_searches table as proxy of common interest)
      List<dynamic> searchRows = [];
      try {
        searchRows = await client
          .from('saved_searches')
          .select('query')
          .limit(1000);
      } catch (_) {
        searchRows = [];
      }
      final Map<String,int> searchAgg = {};
      for (final r in searchRows) {
        final q = (r['query'] ?? '').toString().trim();
        if (q.isEmpty) continue;
        searchAgg[q] = (searchAgg[q] ?? 0) + 1;
      }
      final searches = searchAgg.entries
        .map((e)=> _SearchItem(e.key, e.value))
        .toList()
        ..sort((a,b)=> b.count.compareTo(a.count));

      if (!mounted) return;
      setState((){
        _series = series;
        _categoryTotals = catTotals;
        _commonSearches = searches.take(20).toList();
        _loading = false;
      });
    } catch (_) {
      if(!mounted) return;
      setState(()=> _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _header(),
          const SizedBox(height: 12),
          _filters(),
          const SizedBox(height: 12),
          _loading ? const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
                   : _chartCard(),
          const SizedBox(height: 16),
          _totalsCard(),
          const SizedBox(height: 16),
          _commonSearchesCard(),
        ],
      ),
    );
  }

  Widget _header(){
    return Row(
      children: [
        Icon(Icons.insights, color: AppColor.primary),
        const SizedBox(width: 8),
        Text('Analytics', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColor.textDark)),
      ],
    );
  }

  Widget _filters(){
    final categories = {
      'all': 'All categories',
      ...{for (final ct in _categoryTotals) ct.category: ct.category}
    };
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        DropdownButton<String>(
          value: _chartType,
          items: const [
            DropdownMenuItem(value: 'bar', child: Text('Bar chart')),
            DropdownMenuItem(value: 'line', child: Text('Line chart')),
          ],
          onChanged: (v){ if(v!=null) setState(()=> _chartType = v); },
        ),
        DropdownButton<String>(
          value: _range,
          items: const [
            DropdownMenuItem(value: '7d', child: Text('Last 7 days')),
            DropdownMenuItem(value: '30d', child: Text('Last 30 days')),
            DropdownMenuItem(value: '90d', child: Text('Last 90 days')),
          ],
          onChanged: (v){ if(v!=null){ setState(()=> _range = v); _load(); } },
        ),
        DropdownButton<String>(
          value: _category,
          items: categories.entries.map((e)=> DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
          onChanged: (v){ if(v!=null){ setState(()=> _category = v); _load(); } },
        ),
      ],
    );
  }

  Widget _chartCard(){
    final data = _series;
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: SizedBox(
          height: 260,
          child: data.isEmpty
            ? const Center(child: Text('No time-series data found'))
            : (_chartType=='bar' ? _barChart(data) : _lineChart(data)),
        ),
      ),
    );
  }

  Widget _barChart(List<_Point> points){
    final spots = <BarChartGroupData>[];
    for (var i=0; i<points.length; i++){
      spots.add(BarChartGroupData(x: i, barRods: [BarChartRodData(toY: points[i].y, color: AppColor.primary)]));
    }
    return BarChart(BarChartData(
      gridData: const FlGridData(show: false),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28, interval: 1, getTitlesWidget: (v, meta){
          final idx = v.toInt();
          if (idx<0 || idx>=points.length) return const SizedBox.shrink();
          final d = points[idx].x;
          return Padding(padding: const EdgeInsets.only(top:4), child: Text('${d.month}/${d.day}', style: const TextStyle(fontSize: 10)));
        })),
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 36)),
      ),
      barGroups: spots,
      borderData: FlBorderData(show: false),
    ));
  }

  Widget _lineChart(List<_Point> points){
    final spots = <FlSpot>[];
    for (var i=0; i<points.length; i++){
      spots.add(FlSpot(i.toDouble(), points[i].y));
    }
    return LineChart(LineChartData(
      gridData: const FlGridData(show: false),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28, interval: 1, getTitlesWidget: (v, meta){
          final idx = v.toInt();
          if (idx<0 || idx>=points.length) return const SizedBox.shrink();
          final d = points[idx].x;
          return Padding(padding: const EdgeInsets.only(top:4), child: Text('${d.month}/${d.day}', style: const TextStyle(fontSize: 10)));
        })),
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 36)),
      ),
      lineBarsData: [
        LineChartBarData(spots: spots, isCurved: true, color: AppColor.accent, barWidth: 3, dotData: const FlDotData(show: false)),
      ],
      borderData: FlBorderData(show: false),
    ));
  }

  Widget _totalsCard(){
    final totalViews = _categoryTotals.fold<double>(0, (s, e) => s + e.total);
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Total Views by Category', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('All categories total views: ${totalViews.toStringAsFixed(0)}', style: TextStyle(color: AppColor.textMedium)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categoryTotals.take(24).map((ct){
                return Chip(label: Text('${ct.category}: ${ct.total.toStringAsFixed(0)}'));
              }).toList(),
            )
          ],
        ),
      ),
    );
  }

  Widget _commonSearchesCard(){
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Common Searches', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (_commonSearches.isEmpty) const Text('No data') else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (c,i){
                final it = _commonSearches[i];
                return Row(
                  children: [
                    Expanded(child: Text(it.query, maxLines: 1, overflow: TextOverflow.ellipsis)),
                    const SizedBox(width: 8),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: AppColor.primary.withOpacity(.1), borderRadius: BorderRadius.circular(8)), child: Text('${it.count}', style: TextStyle(color: AppColor.primary)))
                  ],
                );
              },
              separatorBuilder: (_, __)=> const SizedBox(height: 8),
              itemCount: _commonSearches.length,
            )
          ],
        ),
      ),
    );
  }
}

class _Point { final DateTime x; final double y; _Point(this.x, this.y); }
class _CategoryTotal { final String category; final double total; _CategoryTotal(this.category, this.total); }
class _SearchItem { final String query; final int count; _SearchItem(this.query, this.count); }
