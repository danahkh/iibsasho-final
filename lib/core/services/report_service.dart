import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/report.dart';

class ReportService {
  final SupabaseClient supabase = Supabase.instance.client;

  Future<void> submitReport(Report report) async {
    await supabase.from('reports').insert(report.toMap());
  }

  Stream<List<Report>> getReports({bool? resolved}) {
    return supabase
        .from('reports')
        .stream(primaryKey: ['id'])
        .map((data) {
      var reports = data.map((item) => Report.fromMap(item, item['id'])).toList();
      
      if (resolved != null) {
        reports = reports.where((report) => report.resolved == resolved).toList();
      }
      
      return reports;
    });
  }

  Future<void> resolveReport(String id) async {
    await supabase.from('reports').update({'resolved': true}).eq('id', id);
  }
}
