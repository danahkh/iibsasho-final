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
  }
}
