<<<<<<< HEAD
import '../model/report.dart';

class ReportService {
  static Future<void> submitReport(Report report) async {
    // await SupabaseHelper.client.from('reports').insert(report.toMap());
  }
  static Stream<List<Report>> getReports({bool? resolved}) {
    return const Stream.empty(); // TODO
  }
  static Future<void> resolveReport(String id) async {
    // await SupabaseHelper.client.from('reports').update({'resolved': true}).eq('id', id);
=======
import 'package:supabase_flutter/supabase_flutter.dart';
import '../model/report.dart';

class ReportService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  static Future<void> submitReport(Report report) async {
    await _supabase.from('reports').insert(report.toMap());
  }

  static Stream<List<Report>> getReports({bool? resolved}) {
    return _supabase
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

  static Future<void> resolveReport(String id) async {
    await _supabase.from('reports').update({'resolved': true}).eq('id', id);
>>>>>>> c9b83a2 (Backup and sync: create local backup folder and prepare push to final repo)
  }
}
