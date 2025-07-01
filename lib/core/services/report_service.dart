import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/report.dart';

class ReportService {
  final CollectionReference reports = FirebaseFirestore.instance.collection('reports');

  Future<void> submitReport(Report report) async {
    await reports.add(report.toMap());
  }

  Stream<List<Report>> getReports({bool? resolved}) {
    Query query = reports;
    if (resolved != null) {
      query = query.where('resolved', isEqualTo: resolved);
    }
    return query.snapshots().map((snapshot) =>
      snapshot.docs.map((doc) => Report.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList()
    );
  }

  Future<void> resolveReport(String id) async {
    await reports.doc(id).update({'resolved': true});
  }
}
